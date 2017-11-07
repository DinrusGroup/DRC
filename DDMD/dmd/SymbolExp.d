module dmd.SymbolExp;

import dmd.common;
import dmd.Expression;
import dmd.Declaration;
import dmd.Loc;
import dmd.IRState;
import dmd.TOK;
import dmd.TY;
import dmd.Type;
import dmd.Id;
import dmd.SymOffExp;
import dmd.FuncDeclaration;
import dmd.VarDeclaration;
import dmd.backend.OPER;
import dmd.backend.TYM;
import dmd.backend.mTY;
import dmd.backend.SC;
import dmd.backend.elem;
import dmd.backend.Symbol;
import dmd.backend.Util;
import dmd.codegen.Util;

import dmd.DDMDExtensions;

version(DMDV2)
class SymbolExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Declaration var;

	bool hasOverloads;

	this(Loc loc, TOK op, int size, Declaration var, bool hasOverloads)
	{
		register();
		super(loc, op, size);
		assert(var);
		this.var = var;
		this.hasOverloads = hasOverloads;
	}

	override elem* toElem(IRState* irs)
	{
		Symbol* s;
		elem* e;
		tym_t tym;
		Type tb = (op == TOK.TOKsymoff) ? var.type.toBasetype() : type.toBasetype();
		int offset = (op == TOK.TOKsymoff) ? (cast(SymOffExp)this).offset : 0;
		FuncDeclaration fd;
		VarDeclaration v = var.isVarDeclaration();

		//printf("SymbolExp::toElem('%s') %p\n", toChars(), this);
		//printf("\tparent = '%s'\n", var.parent ? var.parent.toChars() : "null");
		if (op == TOK.TOKvar && var.needThis())
		{
			error("need 'this' to access member %s", toChars());
			return el_long(TYM.TYint, 0);
		}
		
	    /* The magic variable __ctfe is always false at runtime
		 */
		if (op == TOKvar && v && v.ident == Id.ctfe)
			return el_long(type.totym(), 0);

		s = var.toSymbol();
		fd = null;
		if (var.toParent2())
			fd = var.toParent2().isFuncDeclaration();

		int nrvo = 0;
		if (fd && fd.nrvo_can && fd.nrvo_var == var)
		{
			s = fd.shidden;
			nrvo = 1;
		}

		if (s.Sclass == SC.SCauto || s.Sclass == SC.SCparameter)
		{
			if (fd && fd != irs.getFunc())
			{   
				// 'var' is a variable in an enclosing function.
				elem* ethis;
				int soffset;

				ethis = getEthis(loc, irs, fd);
				ethis = el_una(OPER.OPaddr, TYM.TYnptr, ethis);

				if (v && v.offset)
					soffset = v.offset;
				else
				{
					soffset = s.Soffset;
					/* If fd is a non-static member function of a class or struct,
					 * then ethis isn't the frame pointer.
					 * ethis is the 'this' pointer to the class/struct instance.
					 * We must offset it.
					 */
					if (fd.vthis)
					{
						soffset -= fd.vthis.toSymbol().Soffset;
					}
					//printf("\tSoffset = x%x, sthis.Soffset = x%x\n", s.Soffset, irs.sthis.Soffset);
				}

				if (!nrvo)
					soffset += offset;

				e = el_bin(OPER.OPadd, TYM.TYnptr, ethis, el_long(TYM.TYnptr, soffset));

				if (op == TOK.TOKvar)
					e = el_una(OPER.OPind, TYM.TYnptr, e);
				if (ISREF(var, tb))
					e = el_una(OPER.OPind, s.ty(), e);
				else if (op == TOK.TOKsymoff && nrvo)
				{   
					e = el_una(OPER.OPind, TYM.TYnptr, e);
					e = el_bin(OPER.OPadd, e.Ety, e, el_long(TYM.TYint, offset));
				}
				goto L1;
			}
		}

		/* If var is a member of a closure
		 */
		if (v && v.offset)
		{	
			assert(irs.sclosure);
			e = el_var(irs.sclosure);
			e = el_bin(OPER.OPadd, TYM.TYnptr, e, el_long(TYM.TYint, v.offset));
			if (op == TOK.TOKvar)
			{   
				e = el_una(OPER.OPind, type.totym(), e);
				if (tybasic(e.Ety) == TYM.TYstruct)
				e.Enumbytes = cast(uint)type.size();
				el_setLoc(e, loc);
			}
			if (ISREF(var, tb))
			{   
				e.Ety = TYM.TYnptr;
				e = el_una(OPER.OPind, s.ty(), e);
			}
			else if (op == TOK.TOKsymoff && nrvo)
			{   e = el_una(OPER.OPind, TYM.TYnptr, e);
				e = el_bin(OPER.OPadd, e.Ety, e, el_long(TYM.TYint, offset));
			}
			else if (op == TOK.TOKsymoff)
			{
				e = el_bin(OPER.OPadd, e.Ety, e, el_long(TYM.TYint, offset));
			}
			goto L1;
		}

		if (s.Sclass == SC.SCauto && s.Ssymnum == -1)
		{
			//printf("\tadding symbol\n");
			symbol_add(s);
		}

		if (var.isImportedSymbol())
		{
			assert(op == TOK.TOKvar);
			e = el_var(var.toImport());
			e = el_una(OPER.OPind,s.ty(),e);
		}
		else if (ISREF(var, tb))
		{	
			// Static arrays are really passed as pointers to the array
			// Out parameters are really references
			e = el_var(s);
			e.Ety = TYM.TYnptr;
			if (op == TOK.TOKvar)
				e = el_una(OPER.OPind, s.ty(), e);
			else if (offset)
					e = el_bin(OPER.OPadd, TYM.TYnptr, e, el_long(TYM.TYint, offset));
		}
		else if (op == TOK.TOKvar)
			e = el_var(s);
		else
		{   
			e = nrvo ? el_var(s) : el_ptr(s);
			e = el_bin(OPER.OPadd, e.Ety, e, el_long(TYM.TYint, offset));
		}
	L1:
		if (op == TOK.TOKvar)
		{
			if (nrvo)
			{
				e.Ety = TYM.TYnptr;
				e = el_una(OPER.OPind, 0, e);
			}
			if (tb.ty == TY.Tfunction)
			{
				tym = s.Stype.Tty;
			}
			else
				tym = type.totym();
			e.Ejty = cast(ubyte)tym;
			e.Ety = e.Ejty;
			if (tybasic(tym) == TYM.TYstruct)
			{
				e.Enumbytes = cast(uint)type.size();
			}
			else if (tybasic(tym) == TYM.TYarray)
			{
				e.Ejty = TYM.TYstruct;
				e.Ety = e.Ejty;
				e.Enumbytes = cast(uint)type.size();
			}
		}
		el_setLoc(e,loc);
		return e;
	}
}

