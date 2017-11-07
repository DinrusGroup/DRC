module dmd.ForeachStatement;

import dmd.common;
import dmd.Statement;
import dmd.TOK;
import dmd.Token;
import dmd.Loc;
import dmd.LINK;
import dmd.ArrayTypes;
import dmd.Expression;
import dmd.VarDeclaration;
import dmd.FuncDeclaration;
import dmd.Array;
import dmd.Scope;
import dmd.InterState;
import dmd.InlineScanState;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.IRState;
import dmd.BE;
import dmd.ScopeDsymbol;
import dmd.TypeAArray;
import dmd.Type;
import dmd.CallExp;
import dmd.WANT;
import dmd.TY;
import dmd.TypeTuple;
import dmd.TupleExp;
import dmd.Global;
import dmd.Initializer;
import dmd.ExpInitializer;
import dmd.IntegerExp;
import dmd.ExpStatement;
import dmd.DeclarationExp;
import dmd.Dsymbol;
import dmd.BreakStatement;
import dmd.DefaultStatement;
import dmd.CaseStatement;
import dmd.SwitchStatement;
import dmd.VarExp;
import dmd.AliasDeclaration;
import dmd.CompoundStatement;
import dmd.ScopeStatement;
import dmd.UnrolledLoopStatement;
import dmd.Identifier;
import dmd.Lexer;
import dmd.DeclarationStatement;
import dmd.CompoundDeclarationStatement;
import dmd.AggregateDeclaration;
import dmd.TypeClass;
import dmd.NotExp;
import dmd.TypeStruct;
import dmd.FuncLiteralDeclaration;
import dmd.IdentifierExp;
import dmd.TypeFunction;
import dmd.GotoStatement;
import dmd.FuncExp;
import dmd.ReturnStatement;
import dmd.IndexExp;
import dmd.ForStatement;
import dmd.SliceExp;
import dmd.DotIdExp;
import dmd.PostExp;
import dmd.AddAssignExp;
import dmd.CmpExp;
import dmd.Id;
import dmd.Parameter;
import dmd.STC;

import dmd.expression.Util;

import core.stdc.stdio;

import dmd.DDMDExtensions;

class ForeachStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    TOK op;		// TOKforeach or TOKforeach_reverse
    Parameters arguments;	// array of Argument*'s
    Expression aggr;
    Statement body_;

    VarDeclaration key;
    VarDeclaration value;

    FuncDeclaration func;	// function we're lexically in

    Array cases;	// put breaks, continues, gotos and returns here
    Array gotos;	// forward referenced goto's go here

    this(Loc loc, TOK op, Parameters arguments, Expression aggr, Statement body_)
	{
		register();
		super(loc);
		
		this.op = op;
		this.arguments = arguments;
		this.aggr = aggr;
		this.body_ = body_;
		
		gotos = new Array();
		cases = new Array();
	}
	
    override Statement syntaxCopy()
	{
		auto args = Parameter.arraySyntaxCopy(arguments);
		Expression exp = aggr.syntaxCopy();
		auto s = new ForeachStatement(loc, op, args, exp,
		body_ ? body_.syntaxCopy() : null);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		//printf("ForeachStatement.semantic() %p\n", this);
		ScopeDsymbol sym;
		Statement s = this;
		size_t dim = arguments.dim;
		TypeAArray taa = null;
        Dsymbol sapply = null;

		Type tn = null;
		Type tnv = null;

		func = sc.func;
		if (func.fes)
			func = func.fes.func;

		aggr = aggr.semantic(sc);
		aggr = resolveProperties(sc, aggr);
		aggr = aggr.optimize(WANT.WANTvalue);
		if (!aggr.type)
		{
			error("invalid foreach aggregate %s", aggr.toChars());
			return this;
		}

		inferApplyArgTypes(op, arguments, aggr);

		/* Check for inference errors
		 */
		if (dim != arguments.dim)
		{
			//printf("dim = %d, arguments.dim = %d\n", dim, arguments.dim);
			error("cannot uniquely infer foreach argument types");
			return this;
		}

		Type tab = aggr.type.toBasetype();

		if (tab.ty == TY.Ttuple)	// don't generate new scope for tuple loops
		{
			if (dim < 1 || dim > 2)
			{
				error("only one (value) or two (key,value) arguments for tuple foreach");
				return s;
			}

			auto tuple = cast(TypeTuple)tab;
			Statements statements = new Statements();
			//printf("aggr: op = %d, %s\n", aggr.op, aggr.toChars());
			size_t n;
			TupleExp te = null;
			if (aggr.op == TOK.TOKtuple)	// expression tuple
			{   
				te = cast(TupleExp)aggr;
				n = te.exps.dim;
			}
			else if (aggr.op == TOK.TOKtype)	// type tuple
			{
				n = Parameter.dim(tuple.arguments);
			}
			else
				assert(0);

			for (size_t j = 0; j < n; j++)
			{   
				size_t k = (op == TOK.TOKforeach) ? j : n - 1 - j;
				Expression e;
				Type t;
				if (te)
					e = te.exps[k];
				else
					t = Parameter.getNth(tuple.arguments, k).type;

				auto arg = arguments[0];
				auto st = new Statements();

				if (dim == 2)
				{   
					// Declare key
					if (arg.storageClass & (STC.STCout | STC.STCref | STC.STClazy))
						error("no storage class for key %s", arg.ident.toChars());
					TY keyty = arg.type.ty;
					if (keyty != TY.Tint32 && keyty != TY.Tuns32)
					{
						if (global.params.isX86_64)
						{
							if (keyty != TY.Tint64 && keyty != TY.Tuns64)
								error("foreach: key type must be int or uint, long or ulong, not %s", arg.type.toChars());
						}
						else
							error("foreach: key type must be int or uint, not %s", arg.type.toChars());
					}
					Initializer ie = new ExpInitializer(Loc(0), new IntegerExp(k));
					VarDeclaration var = new VarDeclaration(loc, arg.type, arg.ident, ie);
					var.storage_class |= STC.STCmanifest;
					DeclarationExp de = new DeclarationExp(loc, var);
					st.push(new ExpStatement(loc, de));
					arg = arguments[1];	// value
				}
				// Declare value
				if (arg.storageClass & (STC.STCout | STC.STCref | STC.STClazy))
					error("no storage class for value %s", arg.ident.toChars());
				Dsymbol var;
				if (te)
				{
					Type tb = e.type.toBasetype();
					if ((tb.ty == TY.Tfunction || tb.ty == TY.Tsarray) && e.op == TOK.TOKvar)
					{   
						auto ve = cast(VarExp)e;
						var = new AliasDeclaration(loc, arg.ident, ve.var);
					}
					else
					{
						arg.type = e.type;
						Initializer ie = new ExpInitializer(Loc(0), e);
						VarDeclaration v = new VarDeclaration(loc, arg.type, arg.ident, ie);
						if (e.isConst())
							v.storage_class |= STC.STCconst;

						var = v;
					}
				}
				else
				{
					var = new AliasDeclaration(loc, arg.ident, t);
				}

				auto de = new DeclarationExp(loc, var);
				st.push(new ExpStatement(loc, de));

				st.push(body_.syntaxCopy());
				s = new CompoundStatement(loc, st);
				s = new ScopeStatement(loc, s);
				statements.push(s);
			}

			s = new UnrolledLoopStatement(loc, statements);
			s = s.semantic(sc);
			return s;
		}

		sym = new ScopeDsymbol();
		sym.parent = sc.scopesym;
		sc = sc.push(sym);

		sc.noctor++;

	Lagain:
        Identifier idapply = (op == TOK.TOKforeach_reverse)
		        ? Id.applyReverse : Id.apply;
        sapply = null;
		switch (tab.ty)
		{
			case TY.Tarray:
			case TY.Tsarray:
				if (!checkForArgTypes())
					return this;

				if (dim < 1 || dim > 2)
				{
					error("only one or two arguments for array foreach");
					break;
				}

				/* Look for special case of parsing char types out of char type
				 * array.
				 */
				tn = tab.nextOf().toBasetype();
				if (tn.ty == TY.Tchar || tn.ty == TY.Twchar || tn.ty == TY.Tdchar)
				{	
					Parameter arg;

					int i = (dim == 1) ? 0 : 1;	// index of value
					arg = arguments[i];
					arg.type = arg.type.semantic(loc, sc);
					tnv = arg.type.toBasetype();
					if (tnv.ty != tn.ty && (tnv.ty == TY.Tchar || tnv.ty == TY.Twchar || tnv.ty == TY.Tdchar))
					{
						if (arg.storageClass & STC.STCref)
							error("foreach: value of UTF conversion cannot be ref");
						if (dim == 2)
						{	
							arg = arguments[0];
							if (arg.storageClass & STC.STCref)
								error("foreach: key cannot be ref");
						}
						goto Lapply;
					}
				}

				for (size_t i = 0; i < dim; i++)
				{	
					// Declare args
					auto arg = arguments[i];
					Type argtype = arg.type.semantic(loc, sc);
					auto var = new VarDeclaration(loc, argtype, arg.ident, null);
					var.storage_class |= STC.STCforeach;
					var.storage_class |= arg.storageClass & (STC.STCin | STC.STCout | STC.STCref | STC.STC_TYPECTOR);
					if (var.storage_class & (STC.STCref | STC.STCout))
						var.storage_class |= STC.STCnodtor;
					
					if (dim == 2 && i == 0)
					{   
						key = var;
						//var.storage_class |= STCfinal;
					}
					else
					{
						value = var;
						/* Reference to immutable data should be marked as const
						 */
						if (var.storage_class & STC.STCref && !tn.isMutable())
						{
							var.storage_class |= STC.STCconst;
						}
					}
static if (false)
{
					DeclarationExp de = new DeclarationExp(loc, var);
					de.semantic(sc);
}
				}

static if (true)
{
			{
				 /* Convert to a ForStatement
				  *   foreach (key, value; a) body =>
				  *   for (T[] tmp = a[], size_t key; key < tmp.length; ++key)
				  *   { T value = tmp[k]; body }
				  *
				  *   foreach_reverse (key, value; a) body =>
				  *   for (T[] tmp = a[], size_t key = tmp.length; key--; )
				  *   { T value = tmp[k]; body }
				  */
				Identifier id = Lexer.uniqueId("__aggr");
				ExpInitializer ie = new ExpInitializer(loc, new SliceExp(loc, aggr, null, null));
				VarDeclaration tmp = new VarDeclaration(loc, tab.nextOf().arrayOf(), id, ie);

				Expression tmp_length = new DotIdExp(loc, new VarExp(loc, tmp), Id.length);

				if (!key)
				{
					Identifier id2 = Lexer.uniqueId("__key");
					key = new VarDeclaration(loc, Type.tsize_t, id2, null);
				}

				if (op == TOK.TOKforeach_reverse)
					key.init = new ExpInitializer(loc, tmp_length);
				else
					key.init = new ExpInitializer(loc, new IntegerExp(0));

				auto cs = new Statements();
				cs.push(new DeclarationStatement(loc, new DeclarationExp(loc, tmp)));
				cs.push(new DeclarationStatement(loc, new DeclarationExp(loc, key)));
				Statement forinit = new CompoundDeclarationStatement(loc, cs);

				Expression cond;
				if (op == TOK.TOKforeach_reverse)
					// key--
					cond = new PostExp(TOK.TOKminusminus, loc, new VarExp(loc, key));
				else
					// key < tmp.length
					cond = new CmpExp(TOK.TOKlt, loc, new VarExp(loc, key), tmp_length);

				Expression increment = null;
				if (op == TOK.TOKforeach)
					// key += 1
					increment = new AddAssignExp(loc, new VarExp(loc, key), new IntegerExp(1));

				// T value = tmp[key];
				value.init = new ExpInitializer(loc, new IndexExp(loc, new VarExp(loc, tmp), new VarExp(loc, key)));
				Statement ds = new DeclarationStatement(loc, new DeclarationExp(loc, value));

				body_ = new CompoundStatement(loc, ds, body_);

				ForStatement fs = new ForStatement(loc, forinit, cond, increment, body_);
				s = fs.semantic(sc);
				break;
			}
} else {
			if (tab.nextOf().implicitConvTo(value.type) < MATCH.MATCHconst)
			{
				if (aggr.op == TOK.TOKstring)
					aggr = aggr.implicitCastTo(sc, value.type.arrayOf());
				else
					error("foreach: %s is not an array of %s",
					tab.toChars(), value.type.toChars());
				}

				if (key)
				{
					if (key.type.ty != Tint32 && key.type.ty != Tuns32)
					{
						if (global.params.isX86_64)
						{
						if (key.type.ty != Tint64 && key.type.ty != Tuns64)
							error("foreach: key type must be int or uint, long or ulong, not %s", key.type.toChars());
						}
						else
						error("foreach: key type must be int or uint, not %s", key.type.toChars());
					}

					if (key.storage_class & (STCout | STCref))
						error("foreach: key cannot be out or ref");
				}

				sc.sbreak = this;
				sc.scontinue = this;
				body_ = body_.semantic(sc);
				break;
}

			case TY.Taarray:
				if (!checkForArgTypes())
					return this;

				taa = cast(TypeAArray)tab;
				if (dim < 1 || dim > 2)
				{
					error("only one or two arguments for associative array foreach");
					break;
				}
version(SARRAYVALUE)
{
				/* This only works if Key or Value is a static array.
				 */
				tab = taa.getImpl().type;
				goto Lagain;
}
else
{
				if (op == TOK.TOKforeach_reverse)
				{
					error("no reverse iteration on associative arrays");
				}
				goto Lapply;
}
			case TY.Tclass:
			case TY.Tstruct:
version (DMDV2) {
	            /* Prefer using opApply, if it exists
	             */
	            if (dim != 1)	// only one argument allowed with ranges
		        goto Lapply;

	            sapply = search_function(cast(AggregateDeclaration)tab.toDsymbol(sc), idapply);
	            if (sapply)
		        goto Lapply;

			{   /* Look for range iteration, i.e. the properties
				 * .empty, .next, .retreat, .head and .rear
				 *    foreach (e; aggr) { ... }
				 * translates to:
				 *    for (auto __r = aggr[]; !__r.empty; __r.next)
				 *    {   auto e = __r.head;
				 *        ...
				 *    }
				 */
				AggregateDeclaration ad = (tab.ty == TY.Tclass)
					? cast(AggregateDeclaration)(cast(TypeClass)tab).sym
					: cast(AggregateDeclaration)(cast(TypeStruct)tab).sym;

				Identifier idhead;
				Identifier idnext;
				if (op == TOK.TOKforeach)
				{	
					idhead = Id.Fhead;
					idnext = Id.Fnext;
				}
				else
				{	
					idhead = Id.Ftoe;
					idnext = Id.Fretreat;
				}

				Dsymbol shead = search_function(ad, idhead);
				if (!shead)
					goto Lapply;

				/* Generate a temporary __r and initialize it with the aggregate.
				 */
				Identifier id = Identifier.generateId("__r");
				Expression rinit = new SliceExp(loc, aggr, null, null);
				rinit = rinit.trySemantic(sc);
				if (!rinit)			// if application of [] failed
					rinit = aggr;

				VarDeclaration r = new VarDeclaration(loc, null, id, new ExpInitializer(loc, rinit));

		//	    r.semantic(sc);
		//printf("r: %s, init: %s\n", r.toChars(), r.init.toChars());
				Statement init = new DeclarationStatement(loc, r);
		//printf("init: %s\n", init.toChars());

				// !__r.empty
				Expression e = new VarExp(loc, r);
				e = new DotIdExp(loc, e, Id.Fempty);
				Expression condition = new NotExp(loc, e);

				// __r.next
				e = new VarExp(loc, r);
				Expression increment = new DotIdExp(loc, e, idnext);

				/* Declaration statement for e:
				 *    auto e = __r.idhead;
				 */
				e = new VarExp(loc, r);
				Expression einit = new DotIdExp(loc, e, idhead);
		//	    einit = einit.semantic(sc);
				auto arg = arguments[0];
				auto ve = new VarDeclaration(loc, arg.type, arg.ident, new ExpInitializer(loc, einit));
				ve.storage_class |= STC.STCforeach;
				ve.storage_class |= arg.storageClass & (STC.STCin | STC.STCout | STC.STCref | STC.STC_TYPECTOR);

				auto de = new DeclarationExp(loc, ve);

				Statement body2 = new CompoundStatement(loc, new DeclarationStatement(loc, de), this.body_);
				s = new ForStatement(loc, init, condition, increment, body2);

	static if (false) {
				printf("init: %s\n", init.toChars());
				printf("condition: %s\n", condition.toChars());
				printf("increment: %s\n", increment.toChars());
				printf("body: %s\n", body2.toChars());
	}
				s = s.semantic(sc);
				break;
			}
}
			case TY.Tdelegate:
			Lapply:
			{   
				Expression ec;
				Expression e;
				Parameter a;

				if (!checkForArgTypes())
				{	
					body_ = body_.semantic(sc);
					return this;
				}

				Type tret = func.type.nextOf();

				// Need a variable to hold value from any return statements in body.
				if (!sc.func.vresult && tret && tret != Type.tvoid)
				{	
					auto v = new VarDeclaration(loc, tret, Id.result, null);
					v.noauto = true;
					v.semantic(sc);
					if (!sc.insert(v))
						assert(0);

					v.parent = sc.func;
					sc.func.vresult = v;
				}

				/* Turn body into the function literal:
				 *	int delegate(ref T arg) { body }
				 */
				auto args = new Parameters();
				for (size_t i = 0; i < dim; i++)
				{
					auto arg = arguments[i];
                    Identifier id;

					arg.type = arg.type.semantic(loc, sc);
					if (arg.storageClass & STC.STCref)
						id = arg.ident;
					else
					{   // Make a copy of the ref argument so it isn't
						// a reference.
						id = Lexer.uniqueId("__applyArg", i);

						Initializer ie = new ExpInitializer(Loc(0), new IdentifierExp(Loc(0), id));
						auto v = new VarDeclaration(Loc(0), arg.type, arg.ident, ie);
						s = new DeclarationStatement(Loc(0), v);
						body_ = new CompoundStatement(loc, s, body_);
					}
					a = new Parameter(STC.STCref, arg.type, id, null);
					args.push(a);
				}
				Type t = new TypeFunction(args, Type.tint32, 0, LINK.LINKd);
				FuncLiteralDeclaration fld = new FuncLiteralDeclaration(loc, Loc(0), t, TOK.TOKdelegate, this);
				fld.fbody = body_;
				Expression flde = new FuncExp(loc, fld);
				flde = flde.semantic(sc);
				fld.tookAddressOf = 0;

				// Resolve any forward referenced goto's
				for (size_t i = 0; i < gotos.dim; i++)
				{	
					auto cs = cast(CompoundStatement)gotos.data[i];
					auto gs = cast(GotoStatement)cs.statements[0];

					if (!gs.label.statement)
					{   
						// 'Promote' it to this scope, and replace with a return
						cases.push(cast(void*)gs);
						s = new ReturnStatement(Loc(0), new IntegerExp(cases.dim + 1));
						cs.statements[0] = s;
					}
				}

				if (tab.ty == TY.Taarray)
				{
					// Check types
					auto arg = arguments[0];
					if (dim == 2)
					{
						if (arg.storageClass & STC.STCref)
							error("foreach: index cannot be ref");
						if (!arg.type.equals(taa.index))
							error("foreach: index must be type %s, not %s", taa.index.toChars(), arg.type.toChars());

						arg = arguments[1];
					}
					if (!arg.type.equals(taa.nextOf()))
						error("foreach: value must be type %s, not %s", taa.nextOf().toChars(), arg.type.toChars());

					/* Call:
					 *	_aaApply(aggr, keysize, flde)
					 */
		            FuncDeclaration fdapply;
					if (dim == 2)
						fdapply = FuncDeclaration.genCfunc(Type.tindex, "_aaApply2");
					else
						fdapply = FuncDeclaration.genCfunc(Type.tindex, "_aaApply");

					ec = new VarExp(Loc(0), fdapply);
					auto exps = new Expressions();
					exps.push(aggr);
					size_t keysize = cast(uint)taa.index.size();
					keysize = (keysize + (PTRSIZE-1)) & ~(PTRSIZE-1);
					exps.push(new IntegerExp(Loc(0), keysize, Type.tsize_t));
					exps.push(flde);
					e = new CallExp(loc, ec, exps);
					e.type = Type.tindex;	// don't run semantic() on e
				}
				else if (tab.ty == TY.Tarray || tab.ty == TY.Tsarray)
				{
					/* Call:
					 *	_aApply(aggr, flde)
					 */
					enum char[9][3] fntab =
					[ "cc","cw","cd",
					  "wc","cc","wd",
					  "dc","dw","dd"
					];
					char[7+1+2+ dim.sizeof*3 + 1] fdname;
					int flag;

					switch (tn.ty)
					{
						case TY.Tchar:		flag = 0; break;
						case TY.Twchar:		flag = 3; break;
						case TY.Tdchar:		flag = 6; break;
						default: assert(false);
					}
					switch (tnv.ty)
					{
						case TY.Tchar:		flag += 0; break;
						case TY.Twchar:	flag += 1; break;
						case TY.Tdchar:	flag += 2; break;
						default: assert(false);
					}
					string r = (op == TOK.TOKforeach_reverse) ? "R" : "";
					int j = sprintf(fdname.ptr, "_aApply%.*s%.*s%zd".ptr, r, 2, fntab[flag].ptr, dim);
					assert(j < fdname.sizeof);
					FuncDeclaration fdapply = FuncDeclaration.genCfunc(Type.tindex, fdname[0..j].idup);

					ec = new VarExp(Loc(0), fdapply);
					auto exps = new Expressions();
					if (tab.ty == TY.Tsarray)
					   aggr = aggr.castTo(sc, tn.arrayOf());
					exps.push(aggr);
					exps.push(flde);
					e = new CallExp(loc, ec, exps);
					e.type = Type.tindex;	// don't run semantic() on e
				}
				else if (tab.ty == TY.Tdelegate)
				{
					/* Call:
					 *	aggr(flde)
					 */
					auto exps = new Expressions();
					exps.push(flde);
					e = new CallExp(loc, aggr, exps);
					e = e.semantic(sc);
					if (e.type != Type.tint32)
						error("opApply() function for %s must return an int", tab.toChars());
				}
				else
				{
					assert(tab.ty == TY.Tstruct || tab.ty == TY.Tclass);
					auto exps = new Expressions();
		            if (!sapply)
		                sapply = search_function(cast(AggregateDeclaration)tab.toDsymbol(sc), idapply);
static if (false) {
					TemplateDeclaration td;
					if (sapply && (td = sapply.isTemplateDeclaration()) !is null)
					{   
						/* Call:
						 *	aggr.apply!(fld)()
						 */
						Objects tiargs = new Objects();
						tiargs.push(cast(void*)fld);
						ec = new DotTemplateInstanceExp(loc, aggr, idapply, tiargs);
					}
					else
					{
						/* Call:
						 *	aggr.apply(flde)
						 */
						ec = new DotIdExp(loc, aggr, idapply);
						exps.push(cast(void*)flde);
					}
} else {
					ec = new DotIdExp(loc, aggr, idapply);
					exps.push(flde);
}
					e = new CallExp(loc, ec, exps);
					e = e.semantic(sc);
					if (e.type != Type.tint32) {
						error("opApply() function for %s must return an int", tab.toChars());
					}
				}

				if (!cases.dim)
				{
					// Easy case, a clean exit from the loop
					s = new ExpStatement(loc, e);
				}
				else
				{	// Construct a switch statement around the return value
					// of the apply function.
					auto a2 = new Statements();

					// default: break; takes care of cases 0 and 1
					s = new BreakStatement(Loc(0), null);
					s = new DefaultStatement(Loc(0), s);
					a2.push(s);

					// cases 2...
					for (int i = 0; i < cases.dim; i++)
					{
						s = cast(Statement)cases.data[i];
						s = new CaseStatement(Loc(0), new IntegerExp(i + 2), s);
						a2.push(s);
					}

					s = new CompoundStatement(loc, a2);
					s = new SwitchStatement(loc, e, s, false);
					s = s.semantic(sc);
				}
				break;
			}

			default:
				error("foreach: %s is not an aggregate type", aggr.type.toChars());
				s = null;	// error recovery
				break;
		}

		sc.noctor--;
		sc.pop();
		return s;
	}
	
    bool checkForArgTypes()
	{
		bool result = true;

		foreach (arg; arguments)
		{	
			if (!arg.type)
			{
				error("cannot infer type for %s", arg.ident.toChars());
				arg.type = Type.terror;
				result = false;
			}
		}
		return result;
	}
	
    override bool hasBreak()
	{
		return true;
	}
	
    override bool hasContinue()
	{
		return true;
	}
	
    override bool usesEH()
	{
		return body_.usesEH();
	}
	
    override BE blockExit()
	{
		BE result = BEfallthru;

		if (aggr.canThrow())
			result |= BEthrow;

		if (body_)
		{
			result |= body_.blockExit() & ~(BEbreak | BEcontinue);
		}
		return result;
	}
	
    override bool comeFrom()
	{
		if (body_)
			return body_.comeFrom();
			
		return false;
	}
	
    override Expression interpret(InterState istate)
	{
		assert(false);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
	    buf.writestring(Token.toChars(op));
		buf.writestring(" (");
		for (int i = 0; i < arguments.dim; i++)
		{
			auto a = arguments[i];
			if (i)
				buf.writestring(", ");
			if (a.storageClass & STCref) 
				buf.writestring((global.params.Dversion == 1) ? "inout " : "ref ");
			if (a.type)
				a.type.toCBuffer(buf, a.ident, hgs);
			else
				buf.writestring(a.ident.toChars());
		}
		buf.writestring("; ");
		aggr.toCBuffer(buf, hgs);
		buf.writebyte(')');
		buf.writenl();
		buf.writebyte('{');
		buf.writenl();
		if (body_)
			body_.toCBuffer(buf, hgs);
		buf.writebyte('}');
		buf.writenl();
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		aggr = aggr.inlineScan(iss);
		if (body_)
			body_ = body_.inlineScan(iss);
		return this;
	}

    override void toIR(IRState* irs)
	{
		assert(false);
	}
}
