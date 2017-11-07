module dmd.AliasDeclaration;

import dmd.common;
import dmd.LINK;
import dmd.Declaration;
import dmd.TypedefDeclaration;
import dmd.VarDeclaration;
import dmd.FuncDeclaration;
import dmd.FuncAliasDeclaration;
import dmd.Dsymbol;
import dmd.ScopeDsymbol;
import dmd.Loc;
import dmd.Identifier;
import dmd.Type;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.STC;
import dmd.Expression;
import dmd.Global;

import dmd.DDMDExtensions;

class AliasDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));

	Dsymbol aliassym;
	Dsymbol overnext;		// next in overload list
	int inSemantic;

	this(Loc loc, Identifier ident, Type type)
	{
		register();
		super(ident);

		//printf("AliasDeclaration(id = '%s', type = %p)\n", id.toChars(), type);
		//printf("type = '%s'\n", type.toChars());
		this.loc = loc;
		this.type = type;
		this.aliassym = null;
		version (_DH) {
			this.htype = null;
			this.haliassym = null;
		}

		assert(type);
	}

	this(Loc loc, Identifier id, Dsymbol s)
	{
		register();
		super(id);

		//printf("AliasDeclaration(id = '%s', s = %p)\n", id->toChars(), s);
		assert(s !is this);	/// huh?
		this.loc = loc;
		this.type = null;
		this.aliassym = s;
		version (_DH) {
			this.htype = null;
			this.haliassym = null;
		}
		assert(s);
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("AliasDeclaration::syntaxCopy()\n");
		assert(!s);
		AliasDeclaration sa;
		if (type)
			sa = new AliasDeclaration(loc, ident, type.syntaxCopy());
		else
			sa = new AliasDeclaration(loc, ident, aliassym.syntaxCopy(null));
version (_DH) {
		// Syntax copy for header file
		if (!htype)	    // Don't overwrite original
		{	if (type)	// Make copy for both old and new instances
			{   htype = type.syntaxCopy();
				sa.htype = type.syntaxCopy();
			}
		}
		else			// Make copy of original for new instance
			sa.htype = htype.syntaxCopy();
		if (!haliassym)
		{	if (aliassym)
			{   haliassym = aliassym.syntaxCopy(s);
				sa.haliassym = aliassym.syntaxCopy(s);
			}
		}
		else
			sa.haliassym = haliassym.syntaxCopy(s);
} // version (_DH)
		return sa;
	}

	override void semantic(Scope sc)
	{
		//printf("AliasDeclaration.semantic() %s\n", toChars());
		if (aliassym)
		{
			if (aliassym.isTemplateInstance())
				aliassym.semantic(sc);
			return;
		}
		this.inSemantic = 1;

version(DMDV1) {   // don't really know why this is here
		if (storage_class & STC.STCconst)
			error("cannot be const");
}
		storage_class |= sc.stc & STC.STCdeprecated;

		// Given:
		//	alias foo.bar.abc def;
		// it is not knowable from the syntax whether this is an alias
		// for a type or an alias for a symbol. It is up to the semantic()
		// pass to distinguish.
		// If it is a type, then type is set and getType() will return that
		// type. If it is a symbol, then aliassym is set and type is null -
		// toAlias() will return aliasssym.

		Dsymbol s;
		Type t;
		Expression e;

		/* This section is needed because resolve() will:
		 *   const x = 3;
		 *   alias x y;
		 * try to alias y to 3.
		 */
		s = type.toDsymbol(sc);
		if (s && ((s.getType() && type.equals(s.getType())) || s.isEnumMember()))
			goto L2;			// it's a symbolic alias

///version (DMDV2) {
        type = type.addStorageClass(storage_class);
		if (storage_class & (STC.STCref | STCnothrow | STCpure | STCdisable))
		{	// For 'ref' to be attached to function types, and picked
			// up by Type.resolve(), it has to go into sc.
			sc = sc.push();
		    sc.stc |= storage_class & (STCref | STCnothrow | STCpure | STCshared | STCdisable);
			type.resolve(loc, sc, &e, &t, &s);
			sc = sc.pop();
		}
		else
///	#endif
			type.resolve(loc, sc, &e, &t, &s);
		if (s)
		{
			goto L2;
		}
		else if (e)
		{
			// Try to convert Expression to Dsymbol
			s = getDsymbol(e);
			if (s)
				goto L2;

			error("cannot alias an expression %s", e.toChars());
			t = e.type;
		}
		else if (t)
		{
			type = t;
		}
		if (overnext)
			ScopeDsymbol.multiplyDefined(Loc(0), this, overnext);
		this.inSemantic = 0;
		return;

L2:
		//printf("alias is a symbol %s %s\n", s.kind(), s.toChars());
		type = null;
		VarDeclaration v = s.isVarDeclaration();
		if (v && v.linkage == LINK.LINKdefault)
		{
			error("forward reference of %s", v.toChars());
			s = null;
		}
		else
		{
			FuncDeclaration f = s.toAlias().isFuncDeclaration();
			if (f)
			{
				if (overnext)
				{
					FuncAliasDeclaration fa = new FuncAliasDeclaration(f);
					if (!fa.overloadInsert(overnext))
						ScopeDsymbol.multiplyDefined(Loc(0), f, overnext);
					overnext = null;
					s = fa;
					s.parent = sc.parent;
				}
			}
			if (overnext)
				ScopeDsymbol.multiplyDefined(Loc(0), s, overnext);
			if (s == this)
			{
				assert(global.errors);
				s = null;
			}
		}
		//printf("setting aliassym %p to %p\n", this, s);
		aliassym = s;
		this.inSemantic = 0;
	}

	override bool overloadInsert(Dsymbol s)
	{
		/* Don't know yet what the aliased symbol is, so assume it can
		 * be overloaded and check later for correctness.
		 */

		//printf("AliasDeclaration.overloadInsert('%s')\n", s.toChars());
		if (overnext is null)
		{
static if (true)
{
			if (s is this)
				return true;
}
			overnext = s;
			return true;

		}
		else
		{
			return overnext.overloadInsert(s);
		}
	}

	override string kind()
	{
		return "alias";
	}

	override Type getType()
	{
		return type;
	}

	override Dsymbol toAlias()
	{
		//printf("AliasDeclaration::toAlias('%s', this = %p, aliassym = %p, kind = '%s')\n", toChars(), this, aliassym, aliassym ? aliassym->kind() : "");
		assert(this !is aliassym);
		//static int count; if (++count == 10) *(char*)0=0;
		if (inSemantic)
		{
			error("recursive alias declaration");
			aliassym = new TypedefDeclaration(loc, ident, Type.terror, null);
		}

		Dsymbol s = aliassym ? aliassym.toAlias() : this;
		return s;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("alias ");
///	static if (false) { // && _DH
///		if (hgs.hdrgen)
///		{
///			if (haliassym)
///			{
///				haliassym.toCBuffer(buf, hgs);
///				buf.writeByte(' ');
///				buf.writestring(ident.toChars());
///			}
///			else
///				htype.toCBuffer(buf, ident, hgs);
///		}
///		else
///	}
		{
		if (aliassym)
		{
			aliassym.toCBuffer(buf, hgs);
			buf.writeByte(' ');
			buf.writestring(ident.toChars());
		}
		else
			type.toCBuffer(buf, ident, hgs);
		}
		buf.writeByte(';');
		buf.writenl();
	}

	version (_DH) {
		Type htype;
		Dsymbol haliassym;
	}
	override void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}

	override AliasDeclaration isAliasDeclaration() { return this; }
	}
