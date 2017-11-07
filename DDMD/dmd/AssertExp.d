module dmd.AssertExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.Type;
import dmd.Global;
import dmd.InvariantDeclaration;
import dmd.TOK;
import dmd.PREC;
import dmd.AddrExp;
import dmd.DotVarExp;
import dmd.TY;
import dmd.TypeClass;
import dmd.GlobalExpressions;
import dmd.Module;
import dmd.WANT;
import dmd.FuncDeclaration;
import dmd.HaltExp;
import dmd.TypeStruct;
import dmd.backend.Util;
import dmd.codegen.Util;
import dmd.backend.OPER;
import dmd.backend.TYM;
import dmd.backend.RTLSYM;
import dmd.backend.Symbol;
import dmd.backend.dt_t;
import dmd.backend.SC;
import dmd.backend.FL;

import dmd.expression.Util;
import dmd.interpret.Util;

import core.stdc.string;
import std.string : toStringz;

import dmd.DDMDExtensions;

//static __gshared Symbol* assertexp_sfilename = null;
//static __gshared string assertexp_name = null;
//static __gshared Module assertexp_mn = null;

class AssertExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Expression msg;

	this(Loc loc, Expression e, Expression msg = null)
	{
		register();

		super(loc, TOK.TOKassert, AssertExp.sizeof, e);
		this.msg = msg;
	}

	override Expression syntaxCopy()
	{
		AssertExp ae = new AssertExp(loc, e1.syntaxCopy(),
				       msg ? msg.syntaxCopy() : null);
		return ae;
	}

	override Expression semantic(Scope sc)
	{
	version (LOGSEMANTIC) {
		printf("AssertExp.semantic('%s')\n", toChars());
	}
		UnaExp.semantic(sc);
		e1 = resolveProperties(sc, e1);
		// BUG: see if we can do compile time elimination of the Assert
		e1 = e1.optimize(WANTvalue);
		e1 = e1.checkToBoolean();
		if (msg)
		{
			msg = msg.semantic(sc);
			msg = resolveProperties(sc, msg);
			msg = msg.implicitCastTo(sc, Type.tchar.constOf().arrayOf());
			msg = msg.optimize(WANTvalue);
		}
		if (e1.isBool(false))
		{
			FuncDeclaration fd = sc.parent.isFuncDeclaration();
			fd.hasReturnExp |= 4;

			if (!global.params.useAssert)
			{
				Expression e = new HaltExp(loc);
				e = e.semantic(sc);
				return e;
			}
		}
		type = Type.tvoid;
		return this;
	}

	override Expression interpret(InterState istate)
	{   
		Expression e;
		Expression e1;

version (LOG) {
		writef("AssertExp::interpret() %s\n", toChars());
}
		if (this.e1.op == TOKaddress)
		{   
			// Special case: deal with compiler-inserted assert(&this, "null this") 
			AddrExp ade = cast(AddrExp)this.e1;
			if (ade.e1.op == TOKthis && istate.localThis)
				if (ade.e1.op == TOKdotvar
					&& (cast(DotVarExp)(istate.localThis)).e1.op == TOKthis)
					return getVarExp(loc, istate, (cast(DotVarExp)(istate.localThis)).var);
				else
					return istate.localThis.interpret(istate);
		}
		if (this.e1.op == TOKthis)
		{
			if (istate.localThis)
				return istate.localThis.interpret(istate);
		}
		e1 = this.e1.interpret(istate);
		if (e1 is EXP_CANT_INTERPRET)
			goto Lcant;
		if (e1.isBool(true))
		{
		}
		else if (e1.isBool(false))
		{
			if (msg)
			{
				e = msg.interpret(istate);
				if (e is EXP_CANT_INTERPRET)
					goto Lcant;
				error("%s", e.toChars());
			}
			else
				error("%s failed", toChars());
			goto Lcant;
		}
		else
			goto Lcant;
		return e1;

	Lcant:
		return EXP_CANT_INTERPRET;
	}

	override bool checkSideEffect(int flag)
	{
		return true;
	}

version (DMDV2) {
	override bool canThrow()
	{
		/* assert()s are non-recoverable errors, so functions that
		 * use them can be considered "nothrow"
		 */
		return false; //(global.params.useAssert != 0);
	}
}
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("assert(");
		expToCBuffer(buf, hgs, e1, PREC.PREC_assign);
		if (msg)
		{
			buf.writeByte(',');
			expToCBuffer(buf, hgs, msg, PREC_assign);
		}
		buf.writeByte(')');
	}

	override int inlineCost(InlineCostState* ics)
	{
		return 1 + e1.inlineCost(ics) + (msg ? msg.inlineCost(ics) : 0);
	}

	override Expression doInline(InlineDoState ids)
	{
		AssertExp ae = cast(AssertExp)copy();

		ae.e1 = e1.doInline(ids);
		if (msg)
			ae.msg = msg.doInline(ids);
		return ae;
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		e1 = e1.inlineScan(iss);
		if (msg)
			msg = msg.inlineScan(iss);
		return this;
	}

	static private void* castToVoid(int i)
	{
		return cast(void*)i;
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		elem* ea;
		Type t1 = e1.type.toBasetype();

		//printf("AssertExp.toElem() %s\n", toChars());
		if (global.params.useAssert)
		{
			e = e1.toElem(irs);

			InvariantDeclaration inv = cast(InvariantDeclaration)castToVoid(1);

			// If e1 is a class object, call the class invariant on it
			if (global.params.useInvariants && t1.ty == Tclass &&
				!(cast(TypeClass)t1).sym.isInterfaceDeclaration())
			{
		version (POSIX) {///TARGET_LINUX || TARGET_FREEBSD || TARGET_SOLARIS
				e = el_bin(OPcall, TYvoid, el_var(rtlsym[RTLSYM__DINVARIANT]), e);
		} else {
				e = el_bin(OPcall, TYvoid, el_var(rtlsym[RTLSYM_DINVARIANT]), e);
		}
			}
			// If e1 is a struct object, call the struct invariant on it
			else if (global.params.useInvariants &&
				t1.ty == Tpointer &&
				t1.nextOf().ty == Tstruct &&
				(inv = (cast(TypeStruct)t1.nextOf()).sym.inv) !is null)
			{
				e = callfunc(loc, irs, 1, inv.type.nextOf(), e, e1.type, inv, inv.type, null, null);
			}
			else
			{
				// Construct: (e1 || ModuleAssert(line))
				Symbol* sassert;
				Module m = irs.blx.module_;
				string mname = m.srcfile.toChars();

				//printf("filename = '%s'\n", loc.filename);
				//printf("module = '%s'\n", m.srcfile.toChars());

				/* If the source file name has changed, probably due
				 * to a #line directive.
				 */
				if (loc.filename && (msg || loc.filename != mname))
				{
					elem* efilename;

					/* Cache values.
					 */
					Symbol* assertexp_sfilename = null;
					string assertexp_name = null;
					Module assertexp_mn = null;

					if (!assertexp_sfilename || loc.filename != assertexp_name || assertexp_mn != m)
					{
						dt_t* dt = null;

						string id = loc.filename;
						int len = id.length;
						dtdword(&dt, len);
						dtabytes(&dt,TYnptr, 0, len + 1, toStringz(id));

						assertexp_sfilename = symbol_generate(SCstatic,type_fake(TYdarray));
						assertexp_sfilename.Sdt = dt;
						assertexp_sfilename.Sfl = FLdata;
			version (ELFOBJ) {
						assertexp_sfilename.Sseg = Segment.CDATA;
			}
			version (MACHOBJ) {
						assertexp_sfilename.Sseg = Segment.DATA;
			}
						outdata(assertexp_sfilename);

						assertexp_mn = m;
						assertexp_name = id;
					}

					efilename = el_var(assertexp_sfilename);

					if (msg)
					{
						elem* emsg = msg.toElem(irs);
						ea = el_var(rtlsym[RTLSYM_DASSERT_MSG]);
						ea = el_bin(OPcall, TYvoid, ea, el_params(el_long(TYint, loc.linnum), efilename, emsg, null));
					}
					else
					{
						ea = el_var(rtlsym[RTLSYM_DASSERT]);
						ea = el_bin(OPcall, TYvoid, ea, el_param(el_long(TYint, loc.linnum), efilename));
					}
				}
				else
				{
					sassert = m.toModuleAssert();
					ea = el_bin(OPcall,TYvoid,el_var(sassert),
						el_long(TYint, loc.linnum));
				}
				e = el_bin(OPoror,TYvoid,e,ea);
			}
		}
		else
		{
			// BUG: should replace assert(0); with a HLT instruction
			e = el_long(TYint, 0);
		}
		el_setLoc(e,loc);

		return e;
	}
}

