module dmd.TypeQualified;

import dmd.common;
import dmd.Type;
import dmd.Import;
import dmd.DsymbolExp;
import dmd.TypeExp;
import dmd.DotIdExp;
import dmd.VarDeclaration;
import dmd.EnumMember;
import dmd.TupleDeclaration;
import dmd.Id;
import dmd.VarExp;
import dmd.TemplateInstance;
import dmd.Loc;
import dmd.Array;
import dmd.TY;
import dmd.Identifier;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.DYNCAST;
import dmd.Expression;
import dmd.FuncDeclaration;
import dmd.Util;

import dmd.DDMDExtensions;

class TypeQualified : Type
{
	mixin insertMemberExtension!(typeof(this));

    Loc loc;
    Array idents;	// array of Identifier's representing ident.ident.ident etc.

    this(TY ty, Loc loc)
	{
		register();
		super(ty);
		this.loc = loc;
		
		idents = new Array();
	}
	
    void syntaxCopyHelper(TypeQualified t)
	{
		//printf("TypeQualified::syntaxCopyHelper(%s) %s\n", t->toChars(), toChars());
		idents.setDim(t.idents.dim);
		for (int i = 0; i < idents.dim; i++)
		{
			Object o = cast(Object)t.idents.data[i];
			if (TemplateInstance ti = cast(TemplateInstance)o)
			{
				o = ti.syntaxCopy(null);
			}

			idents.data[i] = cast(void*)o;
		}
	}
	
    void addIdent(Object ident)
	{
		assert(ident !is null);
		idents.push(cast(void*)ident);
	}
	
    void toCBuffer2Helper(OutBuffer buf, HdrGenState* hgs)
	{
		int i;

		for (i = 0; i < idents.dim; i++)
		{
			Identifier id = cast(Identifier)idents.data[i];
			buf.writeByte('.');

			if (id.dyncast() == DYNCAST.DYNCAST_DSYMBOL)
			{
				TemplateInstance ti = cast(TemplateInstance)id;
				ti.toCBuffer(buf, hgs);
			} else {
				buf.writestring(id.toChars());
			}
		}
	}
	
    override ulong size(Loc loc)
	{
		assert(false);
	}
	
	/*************************************
	* Takes an array of Identifiers and figures out if
	 * it represents a Type or an Expression.
	 * Output:
	 *	if expression, *pe is set
	 *	if type, *pt is set
	 */
    void resolveHelper(Loc loc, Scope sc, Dsymbol s, Dsymbol scopesym, Expression* pe, Type* pt, Dsymbol* ps)
	{
		VarDeclaration v;
        FuncDeclaration fd;
		EnumMember em;
		TupleDeclaration td;
		Expression e;

static if (false) {
		printf("TypeQualified.resolveHelper(sc = %p, idents = '%s')\n", sc, toChars());
		if (scopesym)
			printf("\tscopesym = '%s'\n", scopesym.toChars());
}
		*pe = null;
		*pt = null;
		*ps = null;
		if (s)
		{
			//printf("\t1: s = '%s' %p, kind = '%s'\n",s.toChars(), s, s.kind());
			s.checkDeprecated(loc, sc);		// check for deprecated aliases
			s = s.toAlias();
			//printf("\t2: s = '%s' %p, kind = '%s'\n",s.toChars(), s, s.kind());
			for (int i = 0; i < idents.dim; i++)
			{
				Object o = cast(Object)idents.data[i];
				
				Dsymbol sm = s.searchX(loc, sc, o);
				Identifier id = cast(Identifier)o;
				//printf("\t3: s = '%s' %p, kind = '%s'\n",s.toChars(), s, s.kind());
				//printf("\tgetType = '%s'\n", s.getType().toChars());
				if (!sm)
				{	
					Type t;

					v = s.isVarDeclaration();
					if (v && id == Id.length)
					{
						e = v.getConstInitializer();
						if (!e)
							e = new VarExp(loc, v);
						t = e.type;
						if (!t)
						goto Lerror;
						goto L3;
					}
					else if (v && id == Id.stringof_)
					{
						e = new DsymbolExp(loc, s, 0);
						do
						{
							id = cast(Identifier)idents.data[i];
							e = new DotIdExp(loc, e, id);
						} while (++i < idents.dim);
						e = e.semantic(sc);
						*pe = e;
						return;
					}
					
					t = s.getType();
					if (!t && s.isDeclaration())
						t = s.isDeclaration().type;
					if (t)
					{
						sm = t.toDsymbol(sc);
						if (sm)
						{	sm = sm.search(loc, id, 0);
						if (sm)
							goto L2;
						}
						//e = t.getProperty(loc, id);
						e = new TypeExp(loc, t);
						e = t.dotExp(sc, e, id);
						i++;
					L3:
						for (; i < idents.dim; i++)
						{
							id = cast(Identifier)idents.data[i];
							//printf("e: '%s', id: '%s', type = %p\n", e.toChars(), id.toChars(), e.type);
							if (id == Id.offsetof || !e.type)
							{   e = new DotIdExp(e.loc, e, id);
								e = e.semantic(sc);
							}
							else
								e = e.type.dotExp(sc, e, id);
						}
						*pe = e;
					}
					else
					  Lerror:
						error(loc, "identifier '%s' of '%s' is not defined", id.toChars(), toChars());
					return;
				}
			L2:
				s = sm.toAlias();
			}

			v = s.isVarDeclaration();
			if (v)
			{
				*pe = new VarExp(loc, v);
				return;
			}
//#if 0
//	fd = s->isFuncDeclaration();
//	if (fd)
//	{
//	    *pe = new DsymbolExp(loc, fd, 1);
//	    return;
//	}
//#endif
			em = s.isEnumMember();
			if (em)
			{
				// It's not a type, it's an expression
				*pe = em.value.copy();
				return;
			}

		L1:
			Type t = s.getType();
			if (!t)
			{
				// If the symbol is an import, try looking inside the import
				Import si;

				si = s.isImport();
				if (si)
				{
					s = si.search(loc, s.ident, 0);
					if (s && s != si)
						goto L1;
					s = si;
				}
				*ps = s;
				return;
			}
			if (t.ty == TY.Tinstance && t != this && !t.deco)
			{   
				error(loc, "forward reference to '%s'", t.toChars());
				return;
			}

			if (t != this)
			{
				if (t.reliesOnTident())
				{
					if (s.scope_)
						t = t.semantic(loc, s.scope_);
					else
					{
						/* Attempt to find correct scope in which to evaluate t.
						 * Not sure if this is right or not, or if we should just
						 * give forward reference error if s.scope is not set.
						 */
						for (Scope scx = sc; 1; scx = scx.enclosing)
						{
							if (!scx)
							{   
								error(loc, "forward reference to '%s'", t.toChars());
								return;
							}
							if (scx.scopesym == scopesym)
							{
								t = t.semantic(loc, scx);
								break;
							}
						}
					}

				}
			}
			if (t.ty == TY.Ttuple)
				*pt = t;
			else
				*pt = t.merge();
		}
		if (!s)
		{
			error(loc, "identifier '%s' is not defined", toChars());
		}
	}
}
