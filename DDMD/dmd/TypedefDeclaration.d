module dmd.TypedefDeclaration;

import dmd.common;
import dmd.Declaration;
import dmd.Initializer;
import dmd.Type;
import dmd.Loc;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Module;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.ExpInitializer;
import dmd.HdrGenState;
import dmd.TypeTypedef;
import dmd.Global;
import dmd.STC;
import dmd.Id;

import dmd.backend.SC;
import dmd.backend.FL;
import dmd.backend.SFL;
import dmd.backend.Symbol;
import dmd.backend.Util;
import dmd.backend.LIST;
import dmd.backend.Classsym;
import dmd.codegen.Util;

import dmd.DDMDExtensions;

class TypedefDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));

    Type basetype;
    Initializer init;
    int sem = 0;// 0: semantic() has not been run
				// 1: semantic() is in progress
				// 2: semantic() has been run
				// 3: semantic2() has been run

    this(Loc loc, Identifier id, Type basetype, Initializer init)
	{
		register();
		super(id);
		
		this.type = new TypeTypedef(this);
		this.basetype = basetype.toBasetype();
		this.init = init;

	version (_DH) {
		this.htype = null;
		this.hbasetype = null;
	}
		this.loc = loc;
		this.sinit = null;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		Type basetype = this.basetype.syntaxCopy();

		Initializer init = null;
		if (this.init)
			init = this.init.syntaxCopy();

		assert(!s);
		TypedefDeclaration st;
		st = new TypedefDeclaration(loc, ident, basetype, init);
version(_DH)
{
		// Syntax copy for header file
		if (!htype)		// Don't overwrite original
		{
			if (type)	// Make copy for both old and new instances
			{
				htype = type.syntaxCopy();
				st.htype = type.syntaxCopy();
			}
		}
		else			// Make copy of original for new instance
			st.htype = htype.syntaxCopy();
		if (!hbasetype)
		{
			if (basetype)
			{
				hbasetype = basetype.syntaxCopy();
				st.hbasetype = basetype.syntaxCopy();
			}
		}
		else
			st.hbasetype = hbasetype.syntaxCopy();
}
		return st;
	}
	
    override void semantic(Scope sc)
	{
		//printf("TypedefDeclaration::semantic(%s) sem = %d\n", toChars(), sem);
		if (sem == 0)
		{	
			sem = 1;
			basetype = basetype.semantic(loc, sc);
			sem = 2;
version(DMDV2) {
    	    type = type.addStorageClass(storage_class);
}
			type = type.semantic(loc, sc);
			if (sc.parent.isFuncDeclaration() && init)
				semantic2(sc);
			storage_class |= sc.stc & STCdeprecated;
		}
		else if (sem == 1)
		{
			error("circular definition");
		}
	}
	
    override void semantic2(Scope sc)
	{
		//printf("TypedefDeclaration::semantic2(%s) sem = %d\n", toChars(), sem);
		if (sem == 2)
		{	
			sem = 3;
			if (init)
			{
				init = init.semantic(sc, basetype);

				ExpInitializer ie = init.isExpInitializer();
				if (ie)
				{
					if (ie.exp.type == basetype)
						ie.exp.type = type;
				}
			}
		}
	}
	
    override string mangle()
	{
		//printf("TypedefDeclaration::mangle() '%s'\n", toChars());
		return Dsymbol.mangle();
	}
	
    override string kind()
	{
		assert(false);
	}
	
    override Type getType()
	{
		return type;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

version (_DH) {
    Type htype;
    Type hbasetype;
}

    override void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}

    override void toObjFile(int multiobj)			// compile to .obj file
	{
		//printf("TypedefDeclaration::toObjFile('%s')\n", toChars());
		if (global.params.symdebug)
			toDebug();

		type.getTypeInfo(null);	// generate TypeInfo

		TypeTypedef tc = cast(TypeTypedef)type;
		if (type.isZeroInit(Loc(0)) || !tc.sym.init) {
			//;
		} else
		{
			SC scclass = SCglobal;
			if (inTemplateInstance())
				scclass = SCcomdat;

			// Generate static initializer
			toInitializer();
			sinit.Sclass = scclass;
			sinit.Sfl = FLdata;

		version (ELFOBJ) { // Burton
			sinit.Sseg = Segment.CDATA;
		}
		version (MACHOBJ) {
			sinit.Sseg = Segment.DATA;
		}
			sinit.Sdt = tc.sym.init.toDt();
			outdata(sinit);
		}
	}
	
    void toDebug()
	{
		assert(false);
	}
	
    override int cvMember(ubyte* p)
	{
		assert(false);
	}

    override TypedefDeclaration isTypedefDeclaration() { return this; }

    Symbol* sinit;
    Symbol* toInitializer()
	{
		Symbol* s;
		Classsym* stag;

		if (!sinit)
		{
			stag = fake_classsym(Id.ClassInfo);
			s = toSymbolX("__init", SCextern, stag.Stype, "Z");
			s.Sfl = FLextern;
			s.Sflags |= SFLnodebug;
			slist_add(s);
			sinit = s;
		}
		return sinit;
	}
}
