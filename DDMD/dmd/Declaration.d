module dmd.Declaration;

import dmd.common;
import dmd.Dsymbol;
import dmd.Type;
import dmd.TypedefDeclaration;
import dmd.PROT;
import dmd.LINK;
import dmd.Identifier;
import dmd.Json;
import dmd.Scope;
import dmd.Loc;
import dmd.STC;
import dmd.FuncDeclaration;
import dmd.VarDeclaration;
import dmd.OutBuffer;

version (CPP_MANGLE)
{
	import dmd.backend.glue;
	import std.conv : to;
}

import dmd.DDMDExtensions;

import std.stdio : writef;

import core.stdc.ctype;
import core.stdc.stdio : sprintf;

string mangle(Declaration sthis)
{
	scope OutBuffer buf = new OutBuffer();

    string id;
    Dsymbol s = sthis;

    //printf(".mangle(%s)\n", sthis.toChars());
    do
    {
		//printf("mangle: s = %p, '%s', parent = %p\n", s, s.toChars(), s.parent);
		if (s.ident)
		{
			FuncDeclaration fd = s.isFuncDeclaration();
			if (s !is sthis && fd)
			{
				id = mangle(fd);
				buf.prependstring(id);
				goto L1;
			}
			else
			{
				id = s.ident.toChars();
				int len = id.length;
				char[len.sizeof * 3 + 1] tmp;
				buf.prependstring(id);
				len = sprintf(tmp.ptr, "%d".ptr, len);
				buf.prependstring(tmp[0..len]);
			}
		}
		else
			buf.prependstring("0");
		s = s.parent;
    } while (s);

//    buf.prependstring("_D");
L1:
    //printf("deco = '%s'\n", sthis.type.deco ? sthis.type.deco : "null");
    //printf("sthis.type = %s\n", sthis.type.toChars());
    FuncDeclaration fd = sthis.isFuncDeclaration();
    if (fd && (fd.needThis() || fd.isNested()))
		buf.writeByte(Type.needThisPrefix());
    if (sthis.type.deco)
		buf.writestring(sthis.type.deco);
    else
    {
debug
{
		if (!fd.inferRetType)
			writef("%s\n", fd.toChars());
}
		assert(fd && fd.inferRetType);
    }

    id = buf.extractString();
    return id;
}

class Declaration : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));
	
    Type type;
    Type originalType;		// before semantic analysis
    StorageClass storage_class = STC.STCundefined;
    PROT protection = PROT.PROTundefined;
    LINK linkage = LINK.LINKdefault;
    int inuse;			// used to detect cycles

    this(Identifier id)
	{
		register();
		super(id);
	}
	
    override void semantic(Scope sc)
	{
	}
	
    override string kind()
	{
		assert(false);
	}
	
    override uint size(Loc loc)
	{
		assert(false);
	}
	
	/*************************************
	 * Check to see if declaration can be modified in this context (sc).
	 * Issue error if not.
	 */
    void checkModify(Loc loc, Scope sc, Type t)
	{
		if (sc.incontract && isParameter())
			error(loc, "cannot modify parameter '%s' in contract", toChars());

		if (isCtorinit())
		{	
			// It's only modifiable if inside the right constructor
			Dsymbol s = sc.func;
			while (true)
			{
				FuncDeclaration fd = null;
				if (s)
					fd = s.isFuncDeclaration();
				if (fd && ((fd.isCtorDeclaration() && storage_class & STC.STCfield) || 
					(fd.isStaticCtorDeclaration() && !(storage_class & STC.STCfield))) &&
					fd.toParent() == toParent()
				   )
				{
					VarDeclaration v = isVarDeclaration();
					assert(v);
					v.ctorinit = 1;
					//printf("setting ctorinit\n");
				}
				else
				{
					if (s)
					{   
						s = s.toParent2();
						continue;
					}
					else
					{
						string p = isStatic() ? "static " : "";
						error(loc, "can only initialize %sconst %s inside %sconstructor", p, toChars(), p);
					}
				}
				break;
			}
		}
		else
		{
			VarDeclaration v = isVarDeclaration();
			if (v && v.canassign == 0)
			{
				string p = null;
				if (isConst())
					p = "const";
				else if (isImmutable())
					p = "immutable";
				else if (storage_class & STC.STCmanifest)
					p = "enum";
				else if (!t.isAssignable())
					p = "struct with immutable members";
				if (p)
				{	
					error(loc, "cannot modify %s", p);
				}
			}
		}
	}

    override void emitComment(Scope sc)
	{
		assert(false);
	}
	
    override void toJsonBuffer(OutBuffer buf)
    {
		//writef("Declaration.toJsonBuffer()\n");
		buf.writestring("{\n");
	
		JsonProperty(buf, Pname, toChars());
		JsonProperty(buf, Pkind, kind());
		if (type)
			JsonProperty(buf, Ptype, type.toChars());
	
		if (comment)
			JsonProperty(buf, Pcomment, comment);
	
		if (loc.linnum)
			JsonProperty(buf, Pline, loc.linnum);
	
		TypedefDeclaration td = isTypedefDeclaration();
		if (td)
		{
			JsonProperty(buf, "base", td.basetype.toChars());
		}
	
		JsonRemoveComma(buf);
		buf.writestring("}\n");
    }

    override void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}

    override string mangle()
	/+out (result)
	{
		try
		{
			int len = result.length;

			assert(len > 0);
			//printf("mangle: '%s' => '%s'\n", toChars(), result);
			for (int i = 0; i < len; i++)
			{
				assert(result[i] == '_' || result[i] == '@' || isalnum(result[i]) || result[i] & 0x80);
			}
		} catch {
			writef("Incorrect mangle: '%s'\n", result);
			assert(false);
		}
	}
	body+/
	{
version(Bug3602) { writef( "Bug3602: Uncomment outblock when fixed\n" );  }
		//writef("Declaration.mangle(this = %p, '%s', parent = '%s', linkage = %d)\n", this, toChars(), parent ? parent.toChars() : "null", linkage);
		if (!parent || parent.isModule() || linkage == LINK.LINKcpp) // if at global scope
		{
			// If it's not a D declaration, no mangling
			switch (linkage)
			{
			case LINK.LINKd:
				break;

			case LINK.LINKc:
			case LINK.LINKwindows:
			case LINK.LINKpascal:
				return ident.toChars();

			case LINK.LINKcpp:
version (CPP_MANGLE) {
				return cpp_mangle(this);
} else {
				// Windows C++ mangling is done by C++ back end
				return ident.toChars();
}

			case LINK.LINKdefault:
				error("forward declaration");
				return ident.toChars();

			default:
				writef("'%s', linkage = %d\n", toChars(), linkage);
				assert(0);
			}
		}

		string p = .mangle(this);
		scope OutBuffer buf = new OutBuffer();
		buf.writestring("_D");
		buf.writestring(p);
		p = buf.toChars();
		buf.data = null;
		//writef("Declaration.mangle(this = %p, '%s', parent = '%s', linkage = %d) = %s\n", this, toChars(), parent ? parent.toChars() : "null", linkage, p);
		return p;
	}
	
    bool isStatic() { return (storage_class & STC.STCstatic) != 0; }
	
    bool isDelete()
	{
		return false;
	}
	
    bool isDataseg()
	{
		return false;
	}
	
    bool isThreadlocal()
	{
		return false;
	}
	
    bool isCodeseg()
	{
		return false;
	}
	
    bool isCtorinit()     { return (storage_class & STC.STCctorinit) != 0; }
    
	bool isFinal()        { return (storage_class & STC.STCfinal) != 0; }
    
	bool isAbstract()     { return (storage_class & STC.STCabstract)  != 0; }
    
	bool isConst()        { return (storage_class & STC.STCconst) != 0; }
    
	bool isImmutable()    { return (storage_class & STC.STCimmutable) != 0; }
    
	bool isAuto()         { return (storage_class & STC.STCauto) != 0; }
    
	bool isScope()        { return (storage_class & (STC.STCscope | STC.STCauto)) != 0; }
    
	bool isSynchronized() { return (storage_class & STC.STCsynchronized) != 0; }
    
	bool isParameter()    { return (storage_class & STC.STCparameter) != 0; }
    
	override bool isDeprecated()   { return (storage_class & STC.STCdeprecated)  != 0; }
    
	bool isOverride()     { return (storage_class & STC.STCoverride) != 0; }

    bool isIn()    { return (storage_class & STC.STCin) != 0; }
    
	bool isOut()   { return (storage_class & STC.STCout) != 0; }
    
	bool isRef()   { return (storage_class & STC.STCref) != 0; }

    override PROT prot()
	{
		return protection;
	}

    override Declaration isDeclaration() { return this; }
}
