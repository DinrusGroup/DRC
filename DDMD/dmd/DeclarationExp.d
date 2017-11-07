module dmd.DeclarationExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.InterState;
import dmd.ExpInitializer;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.STC;
import dmd.Scope;
import dmd.Util;
import dmd.InlineCostState;
import dmd.IRState;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.TupleDeclaration;
import dmd.InlineScanState;
import dmd.Dsymbol;
import dmd.AttribDeclaration;
import dmd.VarDeclaration;
import dmd.Global;
import dmd.TOK;
import dmd.VoidInitializer;
import dmd.GlobalExpressions;
import dmd.Type;
import dmd.codegen.Util;

import dmd.DDMDExtensions;

// Declaration of a symbol

class DeclarationExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Dsymbol declaration;

	this(Loc loc, Dsymbol declaration)
	{
		register();
		super(loc, TOK.TOKdeclaration, DeclarationExp.sizeof);
		this.declaration = declaration;
	}

	override Expression syntaxCopy()
	{
		return new DeclarationExp(loc, declaration.syntaxCopy(null));
	}

	override Expression semantic(Scope sc)
	{
		if (type)
			return this;

version (LOGSEMANTIC) {
		printf("DeclarationExp.semantic() %s\n", toChars());
}

		/* This is here to support extern(linkage) declaration,
		 * where the extern(linkage) winds up being an AttribDeclaration
		 * wrapper.
		 */
		Dsymbol s = declaration;

		AttribDeclaration ad = declaration.isAttribDeclaration();
		if (ad)
		{
			if (ad.decl && ad.decl.dim == 1)
				s = ad.decl[0];
		}

		if (s.isVarDeclaration())
		{
			// Do semantic() on initializer first, so:
			//	int a = a;
			// will be illegal.
			declaration.semantic(sc);
			s.parent = sc.parent;
		}

		//printf("inserting '%s' %p into sc = %p\n", s.toChars(), s, sc);
		// Insert into both local scope and function scope.
		// Must be unique in both.
		if (s.ident)
		{
			if (!sc.insert(s))
				error("declaration %s is already defined", s.toPrettyChars());
			else if (sc.func)
			{
				VarDeclaration v = s.isVarDeclaration();
				if (s.isFuncDeclaration() && !sc.func.localsymtab.insert(s))
					error("declaration %s is already defined in another scope in %s", s.toPrettyChars(), sc.func.toChars());
				else if (!global.params.useDeprecated)
				{
					// Disallow shadowing

					for (Scope scx = sc.enclosing; scx && scx.func is sc.func; scx = scx.enclosing)
					{
						Dsymbol s2;

						if (scx.scopesym && scx.scopesym.symtab && (s2 = scx.scopesym.symtab.lookup(s.ident)) !is null && s !is s2)
						{
							error("shadowing declaration %s is deprecated", s.toPrettyChars());
						}
					}
				}
			}
		}
		if (!s.isVarDeclaration())
		{
			Scope sc2 = sc;
			if (sc2.stc & (STC.STCpure | STC.STCnothrow))
				sc2 = sc.push();
			sc2.stc &= ~(STC.STCpure | STC.STCnothrow);
			declaration.semantic(sc2);
			if (sc2 != sc)
				sc2.pop();

			s.parent = sc.parent;
		}
		if (!global.errors)
		{
			declaration.semantic2(sc);
			if (!global.errors)
			{
				declaration.semantic3(sc);

				if (!global.errors && global.params.useInline)
					declaration.inlineScan();
			}
		}

		type = Type.tvoid;
		return this;
	}

	override Expression interpret(InterState istate)
	{
version (LOG) {
		printf("DeclarationExp.interpret() %s\n", toChars());
}
		Expression e;
		VarDeclaration v = declaration.isVarDeclaration();
		if (v)
		{
			Dsymbol s = v.toAlias();
			if (s == v && !v.isStatic() && v.init)
			{
				ExpInitializer ie = v.init.isExpInitializer();
				if (ie)
					e = ie.exp.interpret(istate);
				else if (v.init.isVoidInitializer())
					e = null;
			}
///version (DMDV2) {
			else if (s == v && (v.isConst() || v.isImmutable()) && v.init)
///} else {
///			else if (s == v && v.isConst() && v.init)
///}
			{
				e = v.init.toExpression();
				if (!e)
					e = EXP_CANT_INTERPRET;
				else if (!e.type)
					e.type = v.type;
			}
		}
		else if (declaration.isAttribDeclaration() ||
			 declaration.isTemplateMixin() ||
			 declaration.isTupleDeclaration())
		{
			// These can be made to work, too lazy now
			error("Declaration %s is not yet implemented in CTFE", toChars());

			e = EXP_CANT_INTERPRET;
		}
		else
		{	// Others should not contain executable code, so are trivial to evaluate
			e = null;
		}
version (LOG) {
		printf("-DeclarationExp.interpret(%.*s): %p\n", toChars(), e);
}
		return e;
	}

	override bool checkSideEffect(int flag)
	{
		return true;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		declaration.toCBuffer(buf, hgs);
	}

	override elem* toElem(IRState* irs)
	{
		//printf("DeclarationExp::toElem() %s\n", toChars());
		elem* e = Dsymbol_toElem(declaration, irs);
		return e;
	}

	override void scanForNestedRef(Scope sc)
	{
		//printf("DeclarationExp.scanForNestedRef() %s\n", toChars());
		declaration.parent = sc.parent;
	}

version (DMDV2) {
	override bool canThrow()
	{
		VarDeclaration v = declaration.isVarDeclaration();
		if (v && v.init)
		{
			ExpInitializer ie = v.init.isExpInitializer();
			return ie && ie.exp.canThrow();
		}

		return false;
	}
}
	override int inlineCost(InlineCostState* ics)
	{
		int cost = 0;
		VarDeclaration vd;

		//printf("DeclarationExp.inlineCost()\n");
		vd = declaration.isVarDeclaration();
		if (vd)
		{
			TupleDeclaration td = vd.toAlias().isTupleDeclaration();
			if (td)
			{
		static if (true) {
				return COST_MAX;	// finish DeclarationExp.doInline
		} else {
				for (size_t i = 0; i < td.objects.dim; i++)
				{
				Object o = cast(Object)td.objects.data[i];
				Expression eo = cast(Expression)o;
				if (eo is null)
					return COST_MAX;

				if (eo.op != TOKdsymbol)
					return COST_MAX;
				}

				return td.objects.dim;
		}
			}
			if (!ics.hdrscan && vd.isDataseg())
				return COST_MAX;

			cost += 1;

			// Scan initializer (vd.init)
			if (vd.init)
			{
				ExpInitializer ie = vd.init.isExpInitializer();

				if (ie)
				{
					cost += ie.exp.inlineCost(ics);
				}
			}
		}

		// These can contain functions, which when copied, get output twice.
		if (declaration.isStructDeclaration() ||
			declaration.isClassDeclaration() ||
			declaration.isFuncDeclaration() ||
			declaration.isTypedefDeclaration() ||
        	declaration.isAttribDeclaration() ||
			declaration.isTemplateMixin()
		)
			return COST_MAX;

		//printf("DeclarationExp.inlineCost('%s')\n", toChars());
		return cost;
	}

	override Expression doInline(InlineDoState ids)
	{
		DeclarationExp de = cast(DeclarationExp)copy();
		VarDeclaration vd;

		//printf("DeclarationExp.doInline(%s)\n", toChars());
		vd = declaration.isVarDeclaration();
		if (vd)
		{
	static if (false) {
		// Need to figure this out before inlining can work for tuples
		TupleDeclaration td = vd.toAlias().isTupleDeclaration();
		if (td)
		{
			for (size_t i = 0; i < td.objects.dim; i++)
			{
				DsymbolExp se = cast(DsymbolExp)td.objects.data[i];
				assert(se.op == TOKdsymbol);
				se.s;
			}
			return st.objects.dim;
		}
	}
		if (vd.isStatic())
		{
			//;
		}
		else
		{
			VarDeclaration vto = cloneThis(vd);

			vto.parent = ids.parent;
			vto.csym = null;
			vto.isym = null;

			ids.from.push(cast(void*)vd);
			ids.to.push(cast(void*)vto);

			if (vd.init)
			{
				if (vd.init.isVoidInitializer())
				{
					vto.init = new VoidInitializer(vd.init.loc);
				}
				else
				{
					Expression e = vd.init.toExpression();
					assert(e);
					vto.init = new ExpInitializer(e.loc, e.doInline(ids));
				}
			}
			de.declaration = vto;
		}
		}
		/* This needs work, like DeclarationExp.toElem(), if we are
		 * to handle TemplateMixin's. For now, we just don't inline them.
		 */
		return de;
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		//printf("DeclarationExp.inlineScan()\n");
		scanVar(declaration, iss);
		return this;
	}
}

