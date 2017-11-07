module dmd.StructLiteralExp;

import dmd.common;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.MOD;
import dmd.TypeStruct;
import dmd.TypeSArray;
import dmd.expression.Util;
import dmd.ErrorExp;
import dmd.Array;
import dmd.Dsymbol;
import dmd.VarDeclaration;
import dmd.StructDeclaration;
import dmd.FuncDeclaration;
import dmd.ThisDeclaration;
import dmd.backend.elem;
import dmd.InterState;
import dmd.MATCH;
import dmd.WANT;
import dmd.TY;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.Initializer;
import dmd.InlineCostState;
import dmd.IRState;
import dmd.InlineDoState;
import dmd.backend.Symbol;
import dmd.HdrGenState;
import dmd.backend.dt_t;
import dmd.InlineScanState;
import dmd.ArrayLiteralExp;
import dmd.ArrayTypes;
import dmd.TOK;

import dmd.codegen.Util;
import dmd.backend.Util;
import dmd.backend.RTLSYM;
import dmd.backend.TYM;
import dmd.backend.mTY;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class StructLiteralExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	StructDeclaration sd;		// which aggregate this is for
	Expressions elements;	// parallels sd.fields[] with
				// NULL entries for fields to skip

    Symbol* sym;		// back end symbol to initialize with literal
    size_t soffset;		// offset from start of s
    int fillHoles;		// fill alignment 'holes' with zero

	this(Loc loc, StructDeclaration sd, Expressions elements)
	{
		register();
		super(loc, TOKstructliteral, StructLiteralExp.sizeof);
		this.sd = sd;
		this.elements = elements;
		this.sym = null;
		this.soffset = 0;
		this.fillHoles = 1;
	}

	override Expression syntaxCopy()
	{
		return new StructLiteralExp(loc, sd, arraySyntaxCopy(elements));
	}

	override Expression semantic(Scope sc)
	{
		Expression e;
		int nfields = sd.fields.dim - sd.isnested;

version (LOGSEMANTIC) {
		printf("StructLiteralExp.semantic('%s')\n", toChars());
}
		if (type)
			return this;

		// Run semantic() on each element
		foreach(size_t i, Expression e; elements)
		{	
			if (!e)
				continue;
			e = e.semantic(sc);
			elements[i] = e;
		}
		expandTuples(elements);
		size_t offset = 0;
		foreach(size_t i, Expression e; elements)
		{	
			if (!e)
				continue;

			if (!e.type)
				error("%s has no value", e.toChars());
			e = resolveProperties(sc, e);
			if (i >= nfields)
			{   
				error("more initializers than fields of %s", sd.toChars());
				return new ErrorExp();
			}
			auto s = sd.fields[i];
			VarDeclaration v = s.isVarDeclaration();
			assert(v);
			if (v.offset < offset)
				error("overlapping initialization for %s", v.toChars());
			offset = v.offset + cast(uint)v.type.size();

			Type telem = v.type;
			while (!e.implicitConvTo(telem) && telem.toBasetype().ty == Tsarray)
			{   
				/* Static array initialization, as in:
				 *	T[3][5] = e;
				 */
				telem = telem.toBasetype().nextOf();
			}

			e = e.implicitCastTo(sc, telem);

			elements[i] = e;
		}

		/* Fill out remainder of elements[] with default initializers for fields[]
		 */
		for (size_t i = elements.dim; i < nfields; i++)
		{	
			VarDeclaration v = sd.fields[i];
			assert(v);
			assert(!v.isThisDeclaration());

			if (v.offset < offset)
			{   
				e = null;
				sd.hasUnions = 1;
			}
			else
			{
				if (v.init)
				{   
					e = v.init.toExpression();
					if (!e)
					{
						error("cannot make expression out of initializer for %s", v.toChars());
						e = new ErrorExp();
					}
					else if (v.scope_)
					{
						// Do deferred semantic anaylsis
						Initializer i2 = v.init.syntaxCopy();
						i2 = i2.semantic(v.scope_, v.type);
						e = i2.toExpression();
						v.scope_ = null;
					}
				}
				else
				{	
					e = v.type.defaultInitLiteral(loc);
				}
				offset = v.offset + cast(uint)v.type.size();
			}
			elements.push(e);
		}

		type = sd.type;
		return this;
	}

	/**************************************
	 * Gets expression at offset of type.
	 * Returns null if not found.
	 */
	Expression getField(Type type, uint offset)
	{
		//printf("StructLiteralExp.getField(this = %s, type = %s, offset = %u)\n",
//		/*toChars()*/"", type.toChars(), offset);
		Expression e = null;
		int i = getFieldIndex(type, offset);

		if (i != -1)
		{
			//printf("\ti = %d\n", i);
			assert(i < elements.dim);
			e = elements[i];
			if (e)
			{
				//writef("e = %s, e.type = %s\n", e.toChars(), e.type.toChars());
	
				/* If type is a static array, and e is an initializer for that array,
				 * then the field initializer should be an array literal of e.
				 */
				if (e.type != type && type.ty == Tsarray)
				{
					TypeSArray tsa = cast(TypeSArray)type;
					size_t length = cast(size_t) tsa.dim.toInteger();
					Expressions z = new Expressions;
					z.setDim(length);
					for (int q = 0; q < length; ++q)
						z[q] = e.copy();
					e = new ArrayLiteralExp(loc, z);
					e.type = type;
				}
				else
				{
					e = e.copy();
					e.type = type;
				}
			}
		}
		return e;
	}

	int getFieldIndex(Type type, uint offset)
	{
		/* Find which field offset is by looking at the field offsets
		 */
		if (elements.dim)
		{
			foreach (size_t i, VarDeclaration v; sd.fields)
			{
				assert(v);
	
				if (offset == v.offset && type.size() == v.type.size())
				{
					auto e = elements[i];
					if (e)
					{
						return i;
					}
					break;
				}
			}
		}
		return -1;
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		size_t dim;

		//printf("StructLiteralExp.toElem() %s\n", toChars());

		// struct symbol to initialize with the literal
		Symbol* stmp = sym ? sym : symbol_genauto(sd.type.toCtype());

		e = null;

		if (fillHoles)
		{
			/* Initialize all alignment 'holes' to zero.
			 * Do before initializing fields, as the hole filling process
			 * can spill over into the fields.
			 */
			size_t offset = 0;
			foreach (VarDeclaration v; sd.fields)
			{
				assert(v);

				e = el_combine(e, fillHole(stmp, &offset, v.offset, sd.structsize));
				size_t vend = v.offset + cast(uint)v.type.size();
				if (offset < vend)
					offset = vend;
			}
			e = el_combine(e, fillHole(stmp, &offset, sd.structsize, sd.structsize));
		}

		if (elements)
		{
			dim = elements.dim;
			assert(dim <= sd.fields.dim);
			foreach (size_t i, Expression el; elements)
			{   
				if (!el)
					continue;

				VarDeclaration v = sd.fields[i];
				assert(v);
				assert(!v.isThisDeclaration());

				elem* e1;
				if (tybasic(stmp.Stype.Tty) == TYnptr)
				{	
					e1 = el_var(stmp);
					e1.EV.sp.Voffset = soffset;
				}
				else
				{	
					e1 = el_ptr(stmp);
					if (soffset)
						e1 = el_bin(OPadd, TYnptr, e1, el_long(TYsize_t, soffset));
				}
				e1 = el_bin(OPadd, TYnptr, e1, el_long(TYsize_t, v.offset));
				elem* ec = e1;			// pointer to destination

				elem* ep = el.toElem(irs);

				Type t1b = v.type.toBasetype();
				Type t2b = el.type.toBasetype();
				if (t1b.ty == Tsarray)
				{
					if (t2b.implicitConvTo(t1b))
					{
		///version (DMDV2) {
						// Determine if postblit is needed
						int postblit = 0;
						if (needsPostblit(t1b))
							postblit = 1;

						if (postblit)
						{
							/* Generate:
							 *	_d_arrayctor(ti, From: ep, To: e1)
							 */
							Expression ti = t1b.nextOf().toBasetype().getTypeInfo(null);
							elem* esize = el_long(TYsize_t, (cast(TypeSArray)t1b).dim.toInteger());
							e1 = el_pair(TYdarray, esize, e1);
							ep = el_pair(TYdarray, el_copytree(esize), array_toPtr(el.type, ep));
							ep = el_params(e1, ep, ti.toElem(irs), null);
							int rtl = RTLSYM_ARRAYCTOR;
							e1 = el_bin(OPcall, type.totym(), el_var(rtlsym[rtl]), ep);
						}
						else
		///}
						{
							elem* esize = el_long(TYsize_t, t1b.size());
							ep = array_toPtr(el.type, ep);
							e1 = el_bin(OPmemcpy, TYnptr, e1, el_param(ep, esize));
						}
					}
					else
					{
						elem* edim = el_long(TYsize_t, t1b.size() / t2b.size());
						e1 = setArray(e1, edim, t2b, ep, irs, TOKconstruct);
					}
				}
				else
				{
					tym_t ty = v.type.totym();
					e1 = el_una(OPind, ty, e1);
					if (tybasic(ty) == TYstruct)
						e1.Enumbytes = cast(uint)v.type.size();
					e1 = el_bin(OPeq, ty, e1, ep);
					if (tybasic(ty) == TYstruct)
					{   
						e1.Eoper = OPstreq;
						e1.Enumbytes = cast(uint)v.type.size();
					}
version (DMDV2) {
					/* Call postblit() on e1
					 */
					StructDeclaration sd = needsPostblit(v.type);
					if (sd)
					{   
						FuncDeclaration fd = sd.postblit;
						ec = el_copytree(ec);
						ec = callfunc(loc, irs, 1, Type.tvoid, ec, sd.type.pointerTo(), fd, fd.type, null, null);
						e1 = el_bin(OPcomma, ec.Ety, e1, ec);
					}
}
				}
				e = el_combine(e, e1);
			}
		}

version (DMDV2)
{
		if (sd.isnested)
		{	// Initialize the hidden 'this' pointer
			assert(sd.fields.dim);
			auto s = sd.fields[sd.fields.dim - 1];
			auto v = s.isThisDeclaration();
			assert(v);

			elem* e1;
			if (tybasic(stmp.Stype.Tty) == TYnptr)
			{   
				e1 = el_var(stmp);
				e1.EV.sp.Voffset = soffset;
			}
			else
			{   
				e1 = el_ptr(stmp);
				if (soffset)
					e1 = el_bin(OPadd, TYnptr, e1, el_long(TYsize_t, soffset));
			}
			e1 = el_bin(OPadd, TYnptr, e1, el_long(TYsize_t, v.offset));
			e1 = setEthis(loc, irs, e1, sd);

			e = el_combine(e, e1);
		}
}

		elem* ev = el_var(stmp);
		ev.Enumbytes = sd.structsize;
		e = el_combine(e, ev);
		el_setLoc(e,loc);
		return e;
	}

	override bool checkSideEffect(int flag)
	{
		bool f = 0;

		foreach (e; elements)
		{
			if (!e)
				continue;
	
			f |= e.checkSideEffect(2);
		}
		if (flag == 0 && f == 0)
		Expression.checkSideEffect(0);
		return f;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(sd.toChars());
		buf.writeByte('(');
		argsToCBuffer(buf, elements, hgs);
		buf.writeByte(')');
	}

	override void toMangleBuffer(OutBuffer buf)
	{
		size_t dim = elements ? elements.dim : 0;
		buf.printf("S%u", dim);
		for (size_t i = 0; i < dim; i++)
	    {
			auto e = elements[i];
			if (e)
				e.toMangleBuffer(buf);
			else
				buf.writeByte('v');	// 'v' for void
	    }
	}

	override void scanForNestedRef(Scope sc)
	{
		assert(false);
	}

	override Expression optimize(int result)
	{
		if (elements)
		{
			foreach (size_t i, Expression e; elements)
			{   
				if (!e)
					continue;
				e = e.optimize(WANTvalue | (result & WANTinterpret));
				elements[i] = e;
			}
		}
		return this;
	}

	override Expression interpret(InterState istate)
	{
		Expressions expsx = null;

version (LOG) {
		printf("StructLiteralExp.interpret() %.*s\n", toChars());
}
		/* We don't know how to deal with overlapping fields
		 */
		if (sd.hasUnions)
		{   
			error("Unions with overlapping fields are not yet supported in CTFE");
			return EXP_CANT_INTERPRET;
		}

		if (elements)
		{
			foreach (size_t i, Expression e; elements)
			{   
				if (!e)
					continue;

				Expression ex = e.interpret(istate);
				if (ex is EXP_CANT_INTERPRET)
				{   
					delete expsx;
					return EXP_CANT_INTERPRET;
				}

				/* If any changes, do Copy On Write
				 */
				if (ex != e)
				{
					if (!expsx)
					{   
						expsx = new Expressions();
						expsx.setDim(elements.dim);
						for (size_t j = 0; j < elements.dim; j++)
						{
							expsx[j] = elements[j];
						}
					}
					expsx[i] = ex;
				}
			}
		}
		if (elements && expsx)
		{
			expandTuples(expsx);
			if (expsx.dim != elements.dim)
			{   
				delete expsx;
				return EXP_CANT_INTERPRET;
			}
			StructLiteralExp se = new StructLiteralExp(loc, sd, expsx);
			se.type = type;
			return se;
		}
		return this;
	}

	override dt_t** toDt(dt_t** pdt)
	{
		scope dts = new Array;
		dt_t *dt;
		dt_t *d;
		uint offset;

		//printf("StructLiteralExp.toDt() %s)\n", toChars());
		dts.setDim(sd.fields.dim);
		dts.zero();
		assert(elements.dim <= sd.fields.dim);

		foreach (uint i, Expression e; elements)
		{
			if (!e)
				continue;

			dt = null;
			e.toDt(&dt);
			dts.data[i] = dt;
		}

		offset = 0;
		foreach (uint j, VarDeclaration v; sd.fields)
		{
			d = cast(dt_t*)dts.data[j];
			if (!d)
			{   // An instance specific initializer was not provided.
				// Look to see if there's a default initializer from the
				// struct definition
				if (v.init)
				{
					d = v.init.toDt();
				}
				else if (v.offset >= offset)
				{
					uint k;
					uint offset2 = v.offset + cast(uint)v.type.size();
					// Make sure this field (v) does not overlap any explicitly
					// initialized field.
					for (k = j + 1; 1; k++)
					{
						if (k == dts.dim)		// didn't find any overlap
						{
							v.type.toDt(&d);
							break;
						}
						VarDeclaration v2 = sd.fields[k];

						if (v2.offset < offset2 && dts.data[k])
							break;			// overlap
					}
				}
			}
			if (d)
			{
				if (v.offset < offset)
					error("duplicate union initialization for %s", v.toChars());
				else
				{	
					uint sz = dt_size(d);
					uint vsz = cast(uint)v.type.size();
					uint voffset = v.offset;
					assert(sz <= vsz);

					uint dim = 1;
					for (Type vt = v.type.toBasetype(); vt.ty == Tsarray; vt = vt.nextOf().toBasetype())
					{   
						TypeSArray tsa = cast(TypeSArray)vt;
						dim *= tsa.dim.toInteger();
					}

					for (size_t i = 0; i < dim; i++)
					{
						if (offset < voffset)
							pdt = dtnzeros(pdt, voffset - offset);
						if (!d)
						{
							if (v.init)
								d = v.init.toDt();
							else
								v.type.toDt(&d);
						}
						pdt = dtcat(pdt, d);
						d = null;
						offset = voffset + sz;
						voffset += vsz / dim;
						if (sz == vsz)
							break;
					}
				}
			}
		}
		
		if (offset < sd.structsize)
			pdt = dtnzeros(pdt, sd.structsize - offset);

		return pdt;
	}

version(DMDV2)
{
	override bool isLvalue()
	{
		return true;
	}
}

	override Expression toLvalue(Scope sc, Expression e)
	{
		return this;
	}

version(DMDV2)
{
	override bool canThrow()
	{
		return arrayExpressionCanThrow(elements);
	}
}

	override MATCH implicitConvTo(Type t)
	{
static if (false) {
		printf("StructLiteralExp.implicitConvTo(this=%.*s, type=%.*s, t=%.*s)\n",
			toChars(), type.toChars(), t.toChars());
}
		MATCH m = Expression.implicitConvTo(t);
		if (m != MATCHnomatch)
			return m;
		if (type.ty == t.ty && type.ty == Tstruct && (cast(TypeStruct)type).sym == (cast(TypeStruct)t).sym)
		{
			m = MATCHconst;
			foreach(e; elements)
			{   
				Type te = e.type;
				if (t.mod == 0)
					te = te.mutableOf();
				else
				{	
					assert(t.mod == MODimmutable);
					te = te.invariantOf();
				}
				MATCH m2 = e.implicitConvTo(te);
				//printf("\t%s => %s, match = %d\n", e.toChars(), te.toChars(), m2);
				if (m2 < m)
					m = m2;
			}
		}
		return m;
	}

	override int inlineCost(InlineCostState* ics)
	{
		assert(false);
	}

	override Expression doInline(InlineDoState ids)
	{
		assert(false);
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		assert(false);
	}
}

