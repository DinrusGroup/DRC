module dmd.TemplateMixin;

import dmd.common;
import dmd.TemplateInstance;
import dmd.Array;
import dmd.Type;
import dmd.ArrayTypes;
import dmd.Loc;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.DYNCAST;
import dmd.AggregateDeclaration;
import dmd.TemplateDeclaration;
import dmd.Expression;
import dmd.DsymbolTable;
import dmd.PROT;
import dmd.ScopeDsymbol;
import dmd.Global;
import dmd.Util;

import dmd.DDMDExtensions;

extern(C++) void util_progress();

class TemplateMixin : TemplateInstance
{
	mixin insertMemberExtension!(typeof(this));

	Array idents;
	Type tqual;

	this(Loc loc, Identifier ident, Type tqual, Array idents, Objects tiargs)
	{
		register();
		super(loc, cast(Identifier)idents.data[idents.dim - 1]);
		//printf("TemplateMixin(ident = '%s')\n", ident ? ident.toChars() : "");
		this.ident = ident;
		this.tqual = tqual;
		this.idents = idents;
		this.tiargs = tiargs ? tiargs : new Objects();
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		TemplateMixin tm;

		Array ids = new Array();
		ids.setDim(idents.dim);
		for (int i = 0; i < idents.dim; i++)
		{	// Matches TypeQualified.syntaxCopyHelper()
			Identifier id = cast(Identifier)idents.data[i];
			if (id.dyncast() == DYNCAST.DYNCAST_DSYMBOL)
			{
				TemplateInstance ti = cast(TemplateInstance)id;

				ti = cast(TemplateInstance)ti.syntaxCopy(null);
				id = cast(Identifier)ti;
			}
			ids.data[i] = cast(void*)id;
		}

		tm = new TemplateMixin(loc, ident,
				cast(Type)(tqual ? tqual.syntaxCopy() : null),
				ids, tiargs);
		TemplateInstance.syntaxCopy(tm);
		return tm;
	}

	override void semantic(Scope sc)
	{
		version (LOG)
		{
			printf("+TemplateMixin.semantic('%s', this=%p)\n", toChars(), this);
			fflush(stdout);
		}
		if (semanticRun)
		{
			// This for when a class/struct contains mixin members, and
			// is done over because of forward references
			if (parent && toParent().isAggregateDeclaration())
				semanticRun = 1;		// do over
			else
			{
version (LOG)
{
				writef("\tsemantic done\n");
}
				return;
			}
		}
		if (!semanticRun)
			semanticRun = 1;
		version (LOG) {
			printf("\tdo semantic\n");
		}
		util_progress();

		Scope scx = null;
		if (scope_)
		{	sc = scope_;
			scx = scope_;		// save so we don't make redundant copies
			scope_ = null;
		}

		// Follow qualifications to find the TemplateDeclaration
		if (!tempdecl)
		{	Dsymbol s;
			int i;
			Identifier id;

			if (tqual)
			{   s = tqual.toDsymbol(sc);
				i = 0;
			}
			else
			{
				i = 1;
				id = cast(Identifier)idents.data[0];
				switch (id.dyncast())
				{
					case DYNCAST.DYNCAST_IDENTIFIER:
						s = sc.search(loc, id, null);
						break;

					case DYNCAST.DYNCAST_DSYMBOL:
						{
							TemplateInstance ti = cast(TemplateInstance)id;
							ti.semantic(sc);
							s = ti;
							break;
						}
					default:
						assert(0);
				}
			}

			for (; i < idents.dim; i++)
			{
				if (!s)
					break;
				id = cast(Identifier)idents.data[i];
				s = s.searchX(loc, sc, id);
			}
			if (!s)
			{
				error("is not defined");
				inst = this;
				return;
			}
			tempdecl = s.toAlias().isTemplateDeclaration();
			if (!tempdecl)
			{
				error("%s isn't a template", s.toChars());
				inst = this;
				return;
			}
		}

		// Look for forward reference
		assert(tempdecl);
		for (TemplateDeclaration td = tempdecl; td; td = td.overnext)
		{
			if (!td.semanticRun)
			{
				/* Cannot handle forward references if mixin is a struct member,
				 * because addField must happen during struct's semantic, not
				 * during the mixin semantic.
				 * runDeferred will re-run mixin's semantic outside of the struct's
				 * semantic.
				 */
				semanticRun = 0;
				AggregateDeclaration ad = toParent().isAggregateDeclaration();
				if (ad)
					ad.sizeok = 2;
				else
				{
					// Forward reference
					//printf("forward reference - deferring\n");
					scope_ = scx ? scx : sc.clone();
					scope_.setNoFree();
					scope_.module_.addDeferredSemantic(this);
				}
				return;
			}
		}

		// Run semantic on each argument, place results in tiargs[]
		semanticTiargs(sc);
		if (errors)
			return;

		tempdecl = findBestMatch(sc);
		if (!tempdecl)
		{	inst = this;
			return;		// error recovery
		}

		if (!ident)
			ident = genIdent();

		inst = this;
		parent = sc.parent;

		/* Detect recursive mixin instantiations.
		 */
		for (Dsymbol s = parent; s; s = s.parent)
		{
			//printf("\ts = '%s'\n", s.toChars());
			TemplateMixin tm = s.isTemplateMixin();
			if (!tm || tempdecl != tm.tempdecl)
				continue;

			/* Different argument list lengths happen with variadic args
			 */
			if (tiargs.dim != tm.tiargs.dim)
				continue;

			foreach (size_t i, Object o; tiargs)
			{
				Type ta = isType(o);
				Expression ea = isExpression(o);
				Dsymbol sa = isDsymbol(o);
				Object tmo = tm.tiargs[i];
				if (ta)
				{
					Type tmta = isType(tmo);
					if (!tmta)
						goto Lcontinue;
					if (!ta.equals(tmta))
						goto Lcontinue;
				}
				else if (ea)
				{	Expression tme = isExpression(tmo);
					if (!tme || !ea.equals(tme))
						goto Lcontinue;
				}
				else if (sa)
				{
					Dsymbol tmsa = isDsymbol(tmo);
					if (sa != tmsa)
						goto Lcontinue;
				}
				else
					assert(0);
			}
			error("recursive mixin instantiation");
			return;

Lcontinue:
			continue;
		}


		// Copy the syntax trees from the TemplateDeclaration
		members = Dsymbol.arraySyntaxCopy(tempdecl.members);
		if (!members)
			return;

		symtab = new DsymbolTable();

		for (Scope sce = sc; 1; sce = sce.enclosing)
		{
			ScopeDsymbol sds = cast(ScopeDsymbol)sce.scopesym;
			if (sds)
			{
				sds.importScope(this, PROT.PROTpublic);
				break;
			}
		}

		version (LOG) {
			printf("\tcreate scope for template parameters '%s'\n", toChars());
		}
		Scope scy = sc;
		scy = sc.push(this);
		scy.parent = this;

		argsym = new ScopeDsymbol();
		argsym.parent = scy.parent;
		Scope argscope = scy.push(argsym);

		uint errorsave = global.errors;

		// Declare each template parameter as an alias for the argument type
		declareParameters(argscope);

		// Add members to enclosing scope, as well as this scope
		foreach(size_t i, Dsymbol s; members)
		{
			s.addMember(argscope, this, cast(bool)i);
			//sc.insert(s);
			//printf("sc.parent = %p, sc.scopesym = %p\n", sc.parent, sc.scopesym);
			//printf("s.parent = %s\n", s.parent.toChars());
		}

		// Do semantic() analysis on template instance members
		version (LOG) {
			printf("\tdo semantic() on template instance members '%s'\n", toChars());
		}
		Scope sc2;
		sc2 = argscope.push(this);
		sc2.offset = sc.offset;

		//printf("%d\n", global.nest);
		if (++global.nest > 500)
		{
			global.gag = 0;			// ensure error message gets printed
			error("recursive expansion");
			fatal();
		}

		foreach(Dsymbol s; members)
			s.semantic(sc2);

		global.nest--;

		sc.offset = sc2.offset;

		/* The problem is when to parse the initializer for a variable.
		 * Perhaps VarDeclaration.semantic() should do it like it does
		 * for initializers inside a function.
		 */
		//    if (sc.parent.isFuncDeclaration())

		semantic2(sc2);

		if (sc.func)
		{
			semantic3(sc2);
		}

		// Give additional context info if error occurred during instantiation
		if (global.errors != errorsave)
		{
			error("error instantiating");
		}

		sc2.pop();

		argscope.pop();

		//    if (!isAnonymous())
		{
			scy.pop();
		}
		version (LOG) {
			printf("-TemplateMixin.semantic('%s', this=%p)\n", toChars(), this);
		}
	}

	override void semantic2(Scope sc)
	{
		if (semanticRun >= 2)
			return;
		semanticRun = 2;
		version (LOG) {
			printf("+TemplateMixin.semantic2('%s')\n", toChars());
		}
		if (members)
		{
			assert(sc);
			sc = sc.push(argsym);
			sc = sc.push(this);
			foreach(Dsymbol s; members)
			{
				version (LOG) {
					printf("\tmember '%s', kind = '%s'\n", s.toChars(), s.kind());
				}
				s.semantic2(sc);
			}
			sc = sc.pop();
			sc.pop();
		}
		version (LOG) {
			printf("-TemplateMixin.semantic2('%s')\n", toChars());
		}
	}

	override void semantic3(Scope sc)
	{
		if (semanticRun >= 3)
			return;
		semanticRun = 3;
		version (LOG) {
			printf("TemplateMixin.semantic3('%s')\n", toChars());
		}
		if (members)
		{
			sc = sc.push(argsym);
			sc = sc.push(this);
			foreach(Dsymbol s; members)
				s.semantic3(sc);
			sc = sc.pop();
			sc.pop();
		}
	}

	override void inlineScan()
	{
		TemplateInstance.inlineScan();
	}

	override string kind()
	{
		return "mixin";
	}

	override bool oneMember(Dsymbol* ps)
	{
		return Dsymbol.oneMember(ps);
	}

	override bool hasPointers()
	{
		//printf("TemplateMixin.hasPointers() %s\n", toChars());
		foreach(Dsymbol s; members)
		{
			//printf(" s = %s %s\n", s.kind(), s.toChars());
			if (s.hasPointers())
			{
				return 1;
			}
		}
		return 0;
	}

	override string toChars()
	{
		OutBuffer buf = new OutBuffer();
		HdrGenState hgs;
		string s;

		TemplateInstance.toCBuffer(buf, &hgs);
		s = buf.toChars();
		buf.data = null;
		return s;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("mixin ");

		for (int i = 0; i < idents.dim; i++)
		{   Identifier id = cast(Identifier)idents.data[i];

			if (i)
				buf.writeByte('.');
			buf.writestring(id.toChars());
		}
		buf.writestring("!(");
		if (tiargs)
		{
			for (int i = 0; i < tiargs.dim; i++)
			{   if (i)
				buf.writebyte(',');
				Object oarg = tiargs[i];
				Type t = isType(oarg);
				Expression e = isExpression(oarg);
				Dsymbol s = isDsymbol(oarg);
				if (t)
					t.toCBuffer(buf, null, hgs);
				else if (e)
					e.toCBuffer(buf, hgs);
				else if (s)
				{
					string p = s.ident ? s.ident.toChars() : s.toChars();
					buf.writestring(p);
				}
				else if (!oarg)
				{
					buf.writestring("null");
				}
				else
				{
					assert(0);
				}
			}
		}
		buf.writebyte(')');
		if (ident)
		{
			buf.writebyte(' ');
			buf.writestring(ident.toChars());
		}
		buf.writebyte(';');
		buf.writenl();
	}

	override void toObjFile(int multiobj)			// compile to .obj file
	{
		//printf("TemplateMixin.toObjFile('%s')\n", toChars());
		TemplateInstance.toObjFile(multiobj);
	}

	override TemplateMixin isTemplateMixin() { return this; }
}
