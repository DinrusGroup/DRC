module dmd.Module;

import dmd.common;
import dmd.Package;
import dmd.DsymbolTable;
import dmd.backend.TYM;
import dmd.Array;
import dmd.StaticDtorDeclaration;
import dmd.Scope;
import dmd.Id;
import dmd.SharedStaticCtorDeclaration;
import dmd.SharedStaticDtorDeclaration;
import dmd.Import;
import dmd.ClassDeclaration;
import dmd.ModuleDeclaration;
import dmd.File;
import dmd.Identifier;
import dmd.Json;
import dmd.Dsymbol;
import dmd.ModuleInfoDeclaration;
import dmd.FuncDeclaration;
import dmd.Loc;
import dmd.Macro;
import dmd.Escape;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.ArrayTypes;
import dmd.FileName;
import dmd.Global;
import dmd.Parser;
import dmd.Lexer;
import dmd.Util;
import dmd.String;
import dmd.ScopeDsymbol;
import dmd.Type;
import dmd.backend.TYPE;
import dmd.backend.Cstate;
import dmd.backend.OPER;
import dmd.backend.REG;
import dmd.backend.Symbol;
import dmd.backend.elem;
import dmd.backend.mTYman;
import dmd.backend.Util;
import dmd.backend.SC;
import dmd.backend.FL;
import dmd.backend.SFL;
import dmd.backend.TF;
import dmd.backend.RTLSYM;
import dmd.backend.BC;
import dmd.backend.block;
import dmd.backend.targ_types;
import dmd.backend.dt_t;
import dmd.backend.TYM;
import dmd.backend.Util;
import dmd.backend.Classsym;
import dmd.backend.glue;
import dmd.backend.LIST;
import dmd.codegen.Util;

import dmd.DDMDExtensions;

import core.stdc.string;
import core.stdc.stdlib;

import core.memory;

uint readwordLE(ushort* p)
{
version (__I86__) {
    return *p;
} else {
    return ((cast(ubyte*)p)[1] << 8) | (cast(ubyte*)p)[0];
}
}

uint readwordBE(ushort* p)
{
    return ((cast(ubyte*)p)[0] << 8) | (cast(ubyte*)p)[1];
}

uint readlongLE(uint* p)
{
version (__I86__) {
    return *p;
} else {
    return (cast(ubyte*)p)[0] |
	((cast(ubyte*)p)[1] << 8) |
	((cast(ubyte*)p)[2] << 16) |
	((cast(ubyte*)p)[3] << 24);
}
}

uint readlongBE(uint* p)
{
    return (cast(ubyte*)p)[3] |
	((cast(ubyte*)p)[2] << 8) |
	((cast(ubyte*)p)[1] << 16) |
	((cast(ubyte*)p)[0] << 24);
}

/* Segments	*/
enum Segment {
	CODE = 1,	/* code segment			*/
	DATA = 2,	/* initialized data		*/
	CDATA = 3,	/* constant data		*/
	UDATA = 4,	/* uninitialized data		*/
	UNKNOWN	= -1,	/* unknown segment		*/
}

struct seg_data
{
    int              SDseg;		// omf file segment index
    targ_size_t		 SDoffset;	// starting offset for data

    bool isfarseg;
    int seg;				// segment number
    int lnameidx;			// lname idx of segment name
    int classidx;			// lname idx of class name
    uint attr;			// segment attribute
    targ_size_t origsize;		// original size
    int seek;				// seek position in output file
}

extern (C) extern __gshared seg_data** SegData;

ref targ_size_t Offset(Segment seg) {
	return SegData[seg].SDoffset;
}

ref targ_size_t Doffset() {
	return SegData[Segment.DATA].SDoffset;
}

ref targ_size_t CDoffset() {
	return SegData[Segment.CDATA].SDoffset;
}

ref targ_size_t UDoffset() {
	return SegData[Segment.UDATA].SDoffset;
}

enum CF {
	CFes	        = 1,	// generate an ES: segment override for this instr
	CFjmp16	        =  2,	// need 16 bit jump offset (long branch)
	CFtarg	        =  4,	// this code is the target of a jump
	CFseg	        =  8,	// get segment of immediate value
	CFoff	       = 0x10,	// get offset of immediate value
	CFss	       = 0x20,	// generate an SS: segment override (not with
			// CFes at the same time, though!)
	CFpsw	       = 0x40,	// we need the flags result after this instruction
	CFopsize       = 0x80,	// prefix with operand size
	CFaddrsize    = 0x100, 	// prefix with address size
	CFds	      = 0x200,	// need DS override (not with es, ss, or cs )
	CFcs	      = 0x400,	// need CS override
	CFfs	      = 0x800,	// need FS override
	CFgs	= (CFcs | CFfs),	// need GS override
	CFwait      = 0x1000,	// If I32 it indicates when to output a WAIT
	CFselfrel   = 0x2000, 	// if self-relative
	CFunambig   = 0x4000,    	// indicates cannot be accessed by other addressing
				// modes
	CFtarg2	    = 0x8000,	// like CFtarg, but we can't optimize this away
	CFvolatile  = 0x10000,	// volatile reference, do not schedule
	CFclassinit = 0x20000,	// class init code

	CFSEG	= (CFes | CFss | CFds | CFcs | CFfs | CFgs),
	CFPREFIX = (CFSEG | CFopsize | CFaddrsize),
}

class Module : Package
{
	mixin insertMemberExtension!(typeof(this));

    string arg;	// original argument name
    ModuleDeclaration md; // if !null, the contents of the ModuleDeclaration declaration
    File srcfile;	// input source file
    File objfile;	// output .obj file
    File hdrfile;	// 'header' file
    File symfile;	// output symbol file
    File docfile;	// output documentation file
    uint errors;	// if any errors in file
    uint numlines;	// number of lines in source file
    int isHtml;		// if it is an HTML file
    int isDocFile;	// if it is a documentation input file, not D source
    int needmoduleinfo; /// TODO: change to bool
version (IN_GCC) {
    int strictlyneedmoduleinfo;
}

    int selfimports;		// 0: don't know, 1: does not, 2: does
    int selfImports()		// returns !=0 if module imports itself
	{
		assert(false);
	}

    int insearch;
    Identifier searchCacheIdent;
    Dsymbol searchCacheSymbol;	// cached value of search
    int searchCacheFlags;	// cached flags

    int semanticstarted;	// has semantic() been started?
    int semanticRun;		// has semantic() been done?
    int root;			// != 0 if this is a 'root' module,
				// i.e. a module that will be taken all the
				// way to an object file
    Module importedFrom;	// module from command line we're imported from,
				// i.e. a module that will be taken all the
				// way to an object file

    Array decldefs;		// top level declarations for this Module

    Array aimports;		// all imported modules

    ModuleInfoDeclaration vmoduleinfo;

    uint debuglevel;	// debug level
    Vector!string debugids;		// debug identifiers
    Vector!string debugidsNot;		// forward referenced debug identifiers

    uint versionlevel;	// version level
    Vector!(string) versionids;		// version identifiers
    Vector!(string) versionidsNot;	// forward referenced version identifiers

    Macro macrotable;		// document comment macros
    Escape escapetable;	// document comment escapes
    bool safe;			// TRUE if module is marked as 'safe'

    this(string filename, Identifier ident, int doDocComment, int doHdrGen)
	{
		register();

		super(ident);

		versionids = new Vector!string;
		versionidsNot = new Vector!string;

		FileName objfilename;

		aimports = new Array();

	    //writefln("Module.Module(filename = '%s', ident = '%s')", filename, ident.toChars());
		this.arg = filename;

		FileName srcfilename = FileName.defaultExt(filename, global.mars_ext);
		if (!srcfilename.equalsExt(global.mars_ext) &&
			!srcfilename.equalsExt(global.hdr_ext) &&
			!srcfilename.equalsExt("dd"))
		{
			if (srcfilename.equalsExt("html") ||
				srcfilename.equalsExt("htm")  ||
				srcfilename.equalsExt("xhtml"))
			{
				if (!global.params.useDeprecated)
					error("html source files is deprecated %s", srcfilename.toChars());
				isHtml = 1;
			}
			else
			{
				error("source file name '%s' must have .%s extension", srcfilename.toChars(), global.mars_ext);
				fatal();
			}
		}

		string argobj;
		if (global.params.objname)
			argobj = global.params.objname;
		else if (global.params.preservePaths)
			argobj = filename;
		else
			argobj = FileName.name(filename);
		if (!FileName.absolute(argobj))
		{
			argobj = FileName.combine(global.params.objdir, argobj);
		}

		if (global.params.objname)
			objfilename = new FileName(argobj);
		else
			objfilename = FileName.forceExt(argobj, global.obj_ext);

		FileName symfilename = FileName.forceExt(filename, global.sym_ext);

		//writeln(srcfilename.toChars());
		srcfile = new File(srcfilename);

		if (doDocComment) {
			setDocfile();
		}

		if (doHdrGen) {
			setHdrfile();
		}

		objfile = new File(objfilename);
		symfile = new File(symfilename);
	}

    static Module load(Loc loc, Vector!Identifier packages, Identifier ident)
	{
		Module m;
		string filename;

		//writef("Module.load(ident = '%s')\n", ident.toChars());

		// Build module filename by turning:
		//	foo.bar.baz
		// into:
		//	foo\bar\baz
		filename = ident.toChars();
		if (packages && packages.dim)
		{
			scope OutBuffer buf = new OutBuffer();

			foreach (pid; packages)
			{
				buf.writestring(pid.toChars());
version (Windows)
{
				buf.writeByte('\\');
}
else
{
				buf.writeByte('/');
}
			}
			buf.writestring(filename);
			filename = buf.extractString();
		}

		m = new Module(filename, ident, 0, 0);
		m.loc = loc;

		/* Search along global.path for .di file, then .d file.
		 */
		string result = null;
		FileName fdi = FileName.forceExt(filename, global.hdr_ext);
		FileName fd  = FileName.forceExt(filename, global.mars_ext);
		string sdi = fdi.toChars();
		string sd  = fd.toChars();

		if (FileName.exists(sdi)) {
			result = sdi;
		} else if (FileName.exists(sd)) {
			result = sd;
		} else if (FileName.absolute(filename)) {
			//;
		}
		else
		{
			foreach (p; global.path)
			{
				string n = FileName.combine(p, sdi);

				if (FileName.exists(n))
				{
					result = n;
					break;
				}

				n = FileName.combine(p, sd);
				if (FileName.exists(n))
				{
					result = n;
					break;
				}
			}
		}

		if (result) {
			m.srcfile = new File(result);
		}

		if (global.params.verbose)
		{
			write("import    ");
			if (packages)
			{
				foreach (pid; packages)
				{
					writef("%s.", pid.toChars());
				}
			}
			writef("%s\t(%s)\n", ident.toChars(), m.srcfile.toChars());
		}

		m.read(loc);
		m.parse();

version (IN_GCC) {
		d_gcc_magic_module(m);
}

		return m;
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    override void toJsonBuffer(OutBuffer buf)
    {
		buf.writestring("{\n");

		if (md)
			JsonProperty(buf, Pname, md.toChars());

		JsonProperty(buf, Pkind, kind());

		JsonProperty(buf, Pfile, srcfile.toChars());

		if (comment)
			JsonProperty(buf, Pcomment, comment);

		JsonString(buf, Pmembers);
		buf.writestring(" : [\n");

		size_t offset = buf.offset;
		foreach (Dsymbol s; members)
		{
			if (offset != buf.offset)
			{
				buf.writestring(",\n");
				offset = buf.offset;
			}
			s.toJsonBuffer(buf);
		}

		JsonRemoveComma(buf);
		buf.writestring("]\n");

		buf.writestring("}\n");
	}

    override string kind()
	{
		return "module";
	}

    void setDocfile()	// set docfile member
	{
		assert(false);
	}

    void read(Loc loc)	// read file
	{
		//writefln("Module.read('%s') file '%s'", toChars(), srcfile.toChars());
		if (srcfile.read())
		{
			error(loc, "cannot read file '%s'", srcfile.toChars());
			fatal();
		}
	}

version (IN_GCC) {
    void parse(bool dump_source = false)	// syntactic parse
	{
		assert(false);
	}
} else {
    void parse()	// syntactic parse
	{
		uint le;
		uint bom;

		//printf("Module.parse()\n");

		string srcname = srcfile.name.toChars();
		//printf("Module.parse(srcname = '%s')\n", srcname);

		ubyte* buf = srcfile.buffer;
		uint buflen = srcfile.len;

		if (buflen >= 2)
		{
		/* Convert all non-UTF-8 formats to UTF-8.
		 * BOM : http://www.unicode.org/faq/utf_bom.html
		 * 00 00 FE FF	UTF-32BE, big-endian
		 * FF FE 00 00	UTF-32LE, little-endian
		 * FE FF	UTF-16BE, big-endian
		 * FF FE	UTF-16LE, little-endian
		 * EF BB BF	UTF-8
		 */

		bom = 1;		// assume there's a BOM
		if (buf[0] == 0xFF && buf[1] == 0xFE)
		{
			if (buflen >= 4 && buf[2] == 0 && buf[3] == 0)
			{	// UTF-32LE
			le = 1;

			Lutf32:
			OutBuffer dbuf = new OutBuffer();
			uint* pu = cast(uint*)buf;
			uint* pumax = &pu[buflen / 4];

			if (buflen & 3)
			{   error("odd length of UTF-32 char source %u", buflen);
				fatal();
			}

			dbuf.reserve(buflen / 4);
			for (pu += bom; pu < pumax; pu++)
			{
				uint u = le ? readlongLE(pu) : readlongBE(pu);
				if (u & ~0x7F)
				{
					if (u > 0x10FFFF)
					{   error("UTF-32 value %08x greater than 0x10FFFF", u);
						fatal();
					}
					dbuf.writeUTF8(u);
				}
				else
					dbuf.writeByte(u);
			}
			dbuf.writeByte(0);		// add 0 as sentinel for scanner
			buflen = dbuf.offset - 1;	// don't include sentinel in count
			buf = cast(ubyte*) dbuf.extractData();
			}
			else
			{
				// UTF-16LE (X86)
				// Convert it to UTF-8
				le = 1;

				Lutf16:
				OutBuffer dbuf = new OutBuffer();
				ushort* pu = cast(ushort*)(buf);
				ushort *pumax = &pu[buflen / 2];

				if (buflen & 1)
				{   error("odd length of UTF-16 char source %u", buflen);
					fatal();
				}

				dbuf.reserve(buflen / 2);
				for (pu += bom; pu < pumax; pu++)
				{
					uint u = le ? readwordLE(pu) : readwordBE(pu);
					if (u & ~0x7F)
					{
						if (u >= 0xD800 && u <= 0xDBFF)
						{   uint u2;

							if (++pu > pumax)
							{   error("surrogate UTF-16 high value %04x at EOF", u);
							fatal();
							}
							u2 = le ? readwordLE(pu) : readwordBE(pu);
							if (u2 < 0xDC00 || u2 > 0xDFFF)
							{   error("surrogate UTF-16 low value %04x out of range", u2);
							fatal();
							}
							u = (u - 0xD7C0) << 10;
							u |= (u2 - 0xDC00);
						}
						else if (u >= 0xDC00 && u <= 0xDFFF)
						{
							error("unpaired surrogate UTF-16 value %04x", u);
							fatal();
						}
						else if (u == 0xFFFE || u == 0xFFFF)
						{
							error("illegal UTF-16 value %04x", u);
							fatal();
						}
						dbuf.writeUTF8(u);
					}
					else
						dbuf.writeByte(u);
				}
				dbuf.writeByte(0);		// add 0 as sentinel for scanner
				buflen = dbuf.offset - 1;	// don't include sentinel in count
				buf = cast(ubyte*) dbuf.extractData();
			}
		}
		else if (buf[0] == 0xFE && buf[1] == 0xFF)
		{   // UTF-16BE
			le = 0;
			goto Lutf16;
		}
		else if (buflen >= 4 && buf[0] == 0 && buf[1] == 0 && buf[2] == 0xFE && buf[3] == 0xFF)
		{   // UTF-32BE
			le = 0;
			goto Lutf32;
		}
		else if (buflen >= 3 && buf[0] == 0xEF && buf[1] == 0xBB && buf[2] == 0xBF)
		{   // UTF-8

			buf += 3;
			buflen -= 3;
		}
		else
		{
			/* There is no BOM. Make use of Arcane Jill's insight that
			 * the first char of D source must be ASCII to
			 * figure out the encoding.
			 */

			bom = 0;
			if (buflen >= 4)
			{   if (buf[1] == 0 && buf[2] == 0 && buf[3] == 0)
			{   // UTF-32LE
				le = 1;
				goto Lutf32;
			}
			else if (buf[0] == 0 && buf[1] == 0 && buf[2] == 0)
			{   // UTF-32BE
				le = 0;
				goto Lutf32;
			}
			}
			if (buflen >= 2)
			{
			if (buf[1] == 0)
			{   // UTF-16LE
				le = 1;
				goto Lutf16;
			}
			else if (buf[0] == 0)
			{   // UTF-16BE
				le = 0;
				goto Lutf16;
			}
			}

			// It's UTF-8
			if (buf[0] >= 0x80)
			{	error("source file must start with BOM or ASCII character, not \\x%02X", buf[0]);
			fatal();
			}
		}
		}

version (IN_GCC) {
		// dump utf-8 encoded source
		if (dump_source)
		{	// %% srcname could contain a path ...
			d_gcc_dump_source(srcname, "utf-8", buf, buflen);
		}
}

		/* If it starts with the string "Ddoc", then it's a documentation
		 * source file.
		 */
		if (buflen >= 4 && memcmp(buf, "Ddoc".ptr, 4) == 0)
		{
		comment = cast(string) ((buf + 4)[0 .. buflen]);
		isDocFile = 1;
		if (!docfile)
			setDocfile();
		return;
		}
		if (isHtml)
		{
			assert(false);
			///OutBuffer dbuf = new OutBuffer();
			///Html h = new Html(srcname, buf, buflen);
			///h.extractCode(dbuf);
			///buf = dbuf.data;
			///buflen = dbuf.offset;

version (IN_GCC)
{
			// dump extracted source
			///if (dump_source)
			///	d_gcc_dump_source(srcname, "d.utf-8", buf, buflen);
}
		}

		auto p = new Parser(this, buf, buflen, docfile !is null);
		p.nextToken();
		members = p.parseModule();
		md = p.md;
		numlines = p.loc.linnum;

		DsymbolTable dst;

		if (md !is null)
		{
			this.ident = md.id;
			this.safe = md.safe;
			dst = super.resolve(md.packages, &this.parent, null);
		}
		else
		{
			dst = global.modules;

			/* Check to see if module name is a valid identifier
			 */
			if (!Lexer.isValidIdentifier(this.ident.toChars()))
				error("has non-identifier characters in filename, use module declaration instead");
			}

			// Update global list of modules
			if (!dst.insert(this))
			{
				if (md)
					error(loc, "is in multiple packages %s", md.toChars());
				else
					error(loc, "is in multiple defined");
			}
			else
			{
				global.amodules.push(cast(void*)this);
			}
		}
	}

	override void importAll(Scope prevsc)
	{
		//writef("+Module.importAll(this = %p, '%s'): parent = %p\n", this, toChars(), parent);

		if (scope_ !is null)
			return;			// already done

		/* Note that modules get their own scope, from scratch.
		 * This is so regardless of where in the syntax a module
		 * gets imported, it is unaffected by context.
		 * Ignore prevsc.
		 */
		Scope sc = Scope.createGlobal(this);	// create root scope

		// Add import of "object" if this module isn't "object"
		if (ident != Id.object)
		{
			if (members.dim == 0 || members[0].ident != Id.object)
			{
				Import im = new Import(Loc(), null, Id.object, null, 0);
				members.shift(im);
			}
		}

		if (!symtab)
		{
			// Add all symbols into module's symbol table
			symtab = new DsymbolTable();
			foreach (Dsymbol s; members)
				s.addMember(null, sc.scopesym, 1);
		}
		// anything else should be run after addMember, so version/debug symbols are defined

		/* Set scope for the symbols so that if we forward reference
		 * a symbol, it can possibly be resolved on the spot.
		 * If this works out well, it can be extended to all modules
		 * before any semantic() on any of them.
		 */
		setScope(sc);		// remember module scope for semantic
		foreach (Dsymbol s; members)
			s.setScope(sc);

		foreach (Dsymbol s; members)
			s.importAll(sc);

		sc = sc.pop();
		sc.pop();		// 2 pops because Scope::createGlobal() created 2
	}

    void semantic()	// semantic analysis
	{
		if (semanticstarted)
			return;

		//printf("+Module.semantic(this = %p, '%s'): parent = %p\n", this, toChars(), parent);
		semanticstarted = 1;

		// Note that modules get their own scope, from scratch.
		// This is so regardless of where in the syntax a module
		// gets imported, it is unaffected by context.
		Scope sc = scope_; // // see if already got one from importAll()
		if (!sc)
	    {
			writef("test2\n");
			Scope.createGlobal(this);	// create root scope
	    }

		//writef("Module = %p, linkage = %d\n", sc.scopesym, sc.linkage);

static if (false)
{
		// Add import of "object" if this module isn't "object"
		if (ident !is Id.object)
		{
			auto im = new Import(Loc(0), null, Id.object, null, 0);
			members.shift(im);
		}

		// Add all symbols into module's symbol table
		symtab = new DsymbolTable();
		foreach(s; members)
		{
			s.addMember(null, sc.scopesym, true);
		}

		/* Set scope for the symbols so that if we forward reference
		 * a symbol, it can possibly be resolved on the spot.
		 * If this works out well, it can be extended to all modules
		 * before any semantic() on any of them.
		 */
		foreach(Dsymbol s; members)
			s.setScope(sc);
}

		// Pass 1 semantic routines: do public side of the definition
		foreach (Dsymbol s; members)
		{
			//writef("\tModule('%s'): '%s'.semantic()\n", toChars(), s.toChars());
			s.semantic(sc);
			runDeferredSemantic();
		}

		if (!scope_)
	    {
			sc = sc.pop();
			sc.pop();		// 2 pops because Scope.createGlobal() created 2
	    }
		semanticRun = semanticstarted;
		//printf("-Module.semantic(this = %p, '%s'): parent = %p\n", this, toChars(), parent);
	}

    void semantic2()	// pass 2 semantic analysis
	{
		auto deferred = global.deferred;
		if (deferred.dim)
		{
			for (int i = 0; i < deferred.dim; i++)
			{
				Dsymbol sd = cast(Dsymbol)deferred.data[i];

				sd.error("unable to resolve forward reference in definition");
			}
			return;
		}
		//printf("Module.semantic2('%s'): parent = %p\n", toChars(), parent);
		if (semanticstarted >= 2)
			return;
		assert(semanticstarted == 1);
		semanticstarted = 2;

		// Note that modules get their own scope, from scratch.
		// This is so regardless of where in the syntax a module
		// gets imported, it is unaffected by context.
		Scope sc = Scope.createGlobal(this);	// create root scope
		//printf("Module = %p\n", sc.scopesym);

		// Pass 2 semantic routines: do initializers and function bodies
		foreach(Dsymbol s; members)
			s.semantic2(sc);

		sc = sc.pop();
		sc.pop();
		semanticRun = semanticstarted;
		//printf("-Module.semantic2('%s'): parent = %p\n", toChars(), parent);
	}

    void semantic3()	// pass 3 semantic analysis
	{
		//printf("Module.semantic3('%s'): parent = %p\n", toChars(), parent);
		if (semanticstarted >= 3)
			return;
		assert(semanticstarted == 2);
		semanticstarted = 3;

		// Note that modules get their own scope, from scratch.
		// This is so regardless of where in the syntax a module
		// gets imported, it is unaffected by context.
		Scope sc = Scope.createGlobal(this);	// create root scope
		//printf("Module = %p\n", sc.scopesym);

		// Pass 3 semantic routines: do initializers and function bodies
		foreach(Dsymbol s; members)
		{
			//printf("Module %s: %s.semantic3()\n", toChars(), s.toChars());
			s.semantic3(sc);
		}

		sc = sc.pop();
		sc.pop();
		semanticRun = semanticstarted;
	}

    override void inlineScan()	// scan for functions to inline
	{
		if (semanticstarted >= 4)
			return;

		assert(semanticstarted == 3);
		semanticstarted = 4;

		// Note that modules get their own scope, from scratch.
		// This is so regardless of where in the syntax a module
		// gets imported, it is unaffected by context.
		//printf("Module = %p\n", sc.scopesym);

		foreach(Dsymbol s; members)
		{
			//if (global.params.verbose)
				//printf("inline scan symbol %s\n", s.toChars());
			s.inlineScan();
		}

		semanticRun = semanticstarted;
	}

    void setHdrfile()	// set hdrfile member
	{
		FileName hdrfilename;
		string arghdr;

		if (global.params.hdrname)
			arghdr = global.params.hdrname;
		else if (global.params.preservePaths)
			arghdr = arg;
		else
			arghdr = FileName.name(arg);
		if (!FileName.absolute(arghdr))
		{
			//FileName.ensurePathExists(global.params.hdrdir);
			arghdr = FileName.combine(global.params.hdrdir, arghdr);
		}
		if (global.params.hdrname)
			hdrfilename = new FileName(arghdr);
		else
			hdrfilename = FileName.forceExt(arghdr, global.hdr_ext);

		if (hdrfilename.str == srcfile.name.str)
		{
			error("Source file and 'header' file have same name '%s'", srcfile.name.str);
			fatal();
		}

		hdrfile = new File(hdrfilename);
	}

version (_DH) {
    void genhdrfile()  // generate D import file
	{
		assert(false);
	}
}

	/**************************************
	 * Generate .obj file for Module.
	 */
    void genobjfile(int multiobj)
	{
		//EEcontext *ee = env.getEEcontext();

		//printf("Module.genobjfile(multiobj = %d) %s\n", multiobj, toChars());

		auto lastmname = global.lastmname = srcfile.toChars();

		obj_initfile(toStringz(lastmname), null, toStringz(toPrettyChars()));

		global.eictor = null;
		global.ictorlocalgot = null;
		global.ector = null;
		global.ectorgates.setDim(0);
		global.edtor = null;
	    global.esharedctor = null;
		global.esharedctorgates.setDim(0);
		global.eshareddtor = null;
		global.etest = null;
		global.dtorcount = 0;
	    global.shareddtorcount = 0;

		if (doppelganger)
		{
			/* Generate a reference to the moduleinfo, so the module constructors
			 * and destructors get linked in.
			 */
			Module m = cast(Module)aimports.data[0];
			assert(m);
			if (m.sictor || m.sctor || m.sdtor || m.ssharedctor || m.sshareddtor)
			{
				Symbol* s = m.toSymbol();
				//objextern(s);
				//if (!s.Sxtrnnum) objextdef(s.Sident);
				if (!s.Sxtrnnum)
				{
					//printf("%s\n", s.Sident);
static if (false) {
					/* This should work, but causes optlink to fail in common/newlib.asm */
					objextdef(s.Sident);
} else {
	version (ELFOBJ_OR_MACHOBJ) {///ELFOBJ || MACHOBJ
				int nbytes = reftoident(Segment.DATA, Offset(Segment.DATA), s, 0, CF.CFoff);
				Offset(Segment.DATA) += nbytes;
	} else {
				int nbytes = reftoident(Segment.DATA, Doffset, s, 0, CF.CFoff);
				Doffset() += nbytes;
	}
}
				}
			}
		}

		if (global.params.cov)
		{
			/* Create coverage identifier:
			 *  private uint[numlines] __coverage;
			 */
			cov = symbol_calloc("__coverage");
			cov.Stype = type_fake(TYM.TYint);
			cov.Stype.Tmangle = mTYman.mTYman_c;
			cov.Stype.Tcount++;
			cov.Sclass = SC.SCstatic;
			cov.Sfl = FL.FLdata;
version (ELFOBJ_OR_MACHOBJ) {
			cov.Sseg = Segment.UDATA;
}
			dtnzeros(&cov.Sdt, 4 * numlines);
			outdata(cov);
			slist_add(cov);

			covb = cast(uint*)GC.calloc(((numlines + 32) / 32) * (*covb).sizeof);
		}

		foreach(Dsymbol member; members)
			member.toObjFile(multiobj);

		if (global.params.cov)
		{
			/* Generate
			 *	bit[numlines] __bcoverage;
			 */
			Symbol* bcov = symbol_calloc("__bcoverage");
			bcov.Stype = type_fake(TYM.TYuint);
			bcov.Stype.Tcount++;
			bcov.Sclass = SC.SCstatic;
			bcov.Sfl = FL.FLdata;
version (ELFOBJ_OR_MACHOBJ) {
			bcov.Sseg = Segment.DATA;
}
			dtnbytes(&bcov.Sdt, (numlines + 32) / 32 * (*covb).sizeof, cast(char*)covb);
			outdata(bcov);

			///free(covb);
			covb = null;

			/* Generate:
			 *  _d_cover_register(uint[] __coverage, BitArray __bcoverage, string filename);
			 * and prepend it to the static constructor.
			 */

			/* t will be the type of the functions generated:
			 *	extern (C) void func();
			 */
			type* t = type_alloc(TYM.TYnfunc);
			t.Tflags |= TF.TFprototype | TF.TFfixed;
			t.Tmangle = mTYman.mTYman_c;
			t.Tnext = tsvoid;
			tsvoid.Tcount++;

			sictor = toSymbolX("__modictor", SC.SCglobal, t, "FZv");
			cstate.CSpsymtab = &sictor.Sfunc.Flocsym;
			global.localgot = global.ictorlocalgot;
			elem* e;

			e = el_params(el_ptr(cov), el_long(TYM.TYuint, numlines),
					  el_ptr(bcov), el_long(TYM.TYuint, numlines),
					  toEfilename(),
					  null);
			e = el_bin(OPER.OPcall, TYM.TYvoid, el_var(rtlsym[RTLSYM.RTLSYM_DCOVER]), e);
			global.eictor = el_combine(e, global.eictor);
			global.ictorlocalgot = global.localgot;
		}

		// If coverage / static constructor / destructor / unittest calls
	    if (global.eictor || global.ector || global.ectorgates.dim || global.edtor || global.esharedctor || global.esharedctorgates.dim || global.eshareddtor || global.etest)
		{
			/* t will be the type of the functions generated:
			 *	extern (C) void func();
			 */
			type* t = type_alloc(TYM.TYnfunc);
			t.Tflags |= TF.TFprototype | TF.TFfixed;
			t.Tmangle = mTYman.mTYman_c;
			t.Tnext = tsvoid;
			tsvoid.Tcount++;

			enum moddeco = "FZv";

			if (global.eictor)
			{
				global.localgot = global.ictorlocalgot;

				block* b = block_calloc();
				b.BC = BC.BCret;
				b.Belem = global.eictor;
				sictor.Sfunc.Fstartblock = b;
				writefunc(sictor);
			}

			if (global.ector || global.ectorgates.dim)
			{
				global.localgot = null;
				sctor = toSymbolX("__modctor", SC.SCglobal, t, moddeco);
				cstate.CSpsymtab = &sctor.Sfunc.Flocsym;

				for (int i = 0; i < global.ectorgates.dim; i++)
				{
					StaticDtorDeclaration f = cast(StaticDtorDeclaration)global.ectorgates.data[i];

					Symbol* s = f.vgate.toSymbol();
					elem* e = el_var(s);
					e = el_bin(OPER.OPaddass, TYM.TYint, e, el_long(TYM.TYint, 1));
					global.ector = el_combine(global.ector, e);
				}

				block* b = block_calloc();
				b.BC = BC.BCret;
				b.Belem = global.ector;
				sctor.Sfunc.Fstartblock = b;
				writefunc(sctor);
version (STATICCTOR) {
				obj_staticctor(sctor, dtorcount, 1);
}
			}

			if (global.edtor)
			{
				global.localgot = null;
				sdtor = toSymbolX("__moddtor", SC.SCglobal, t, moddeco);

				block* b = block_calloc();
				b.BC = BC.BCret;
				b.Belem = global.edtor;
				sdtor.Sfunc.Fstartblock = b;
				writefunc(sdtor);
			}
			
			if (global.esharedctor || global.esharedctorgates.dim)
			{
				global.localgot = null;
				ssharedctor = toSymbolX("__modsharedctor", SCglobal, t, moddeco);
				cstate.CSpsymtab = &ssharedctor.Sfunc.Flocsym;

				for (int i = 0; i < global.esharedctorgates.dim; i++)
				{	
					SharedStaticDtorDeclaration f = cast(SharedStaticDtorDeclaration)global.esharedctorgates.data[i];

					Symbol* s = f.vgate.toSymbol();
					elem* e = el_var(s);
					e = el_bin(OPaddass, TYint, e, el_long(TYint, 1));
					global.esharedctor = el_combine(global.esharedctor, e);
				}

				block* b = block_calloc();
				b.BC = BCret;
				b.Belem = global.esharedctor;
				ssharedctor.Sfunc.Fstartblock = b;
				writefunc(ssharedctor);
version (STATICCTOR) {
				obj_staticctor(ssharedctor, shareddtorcount, 1);
}
			}

			if (global.eshareddtor)
			{
				global.localgot = null;
				sshareddtor = toSymbolX("__modshareddtor", SCglobal, t, moddeco);

				block *b = block_calloc();
				b.BC = BCret;
				b.Belem = global.eshareddtor;
				sshareddtor.Sfunc.Fstartblock = b;
				writefunc(sshareddtor);
			}


			if (global.etest)
			{
				global.localgot = null;
				stest = toSymbolX("__modtest", SC.SCglobal, t, moddeco);

				block* b = block_calloc();
				b.BC = BC.BCret;
				b.Belem = global.etest;
				stest.Sfunc.Fstartblock = b;
				writefunc(stest);
			}

			if (doppelganger)
				genmoduleinfo();
		}

		if (doppelganger)
		{
			obj_termfile();
			return;
		}

		if (global.params.multiobj)
		{	/* This is necessary because the main .obj for this module is written
			 * first, but determining whether marray or massert are needed is done
			 * possibly later in the doppelganger modules.
			 * Another way to fix it is do the main one last.
			 */
			toModuleAssert();
			toModuleArray();
		}

		// If module assert
		for (int i = 0; i < 2; i++)
		{
			Symbol* ma = i ? marray : massert;

			if (ma)
			{
				elem* elinnum;
				elem* efilename;

				global.localgot = null;

				// Call dassert(filename, line)
				// Get sole parameter, linnum
				{
					Symbol* sp;

					sp = symbol_calloc("linnum".ptr);
					sp.Stype = type_fake(TYM.TYint);
					sp.Stype.Tcount++;
					sp.Sclass = SC.SCfastpar;
					sp.Spreg = REG.AX;
					sp.Sflags &= ~SFL.SFLspill;
					sp.Sfl = FL.FLpara;	// FLauto?
					cstate.CSpsymtab = &ma.Sfunc.Flocsym;
					symbol_add(sp);

					elinnum = el_var(sp);
				}

				efilename = toEmodulename();

				elem *e = el_var(rtlsym[i ? RTLSYM.RTLSYM_DARRAY : RTLSYM.RTLSYM_DASSERT]);
				e = el_bin(OPER.OPcall, TYM.TYvoid, e, el_param(elinnum, efilename));

				block* b = block_calloc();
				b.BC = BC.BCret;
				b.Belem = e;
				ma.Sfunc.Fstartblock = b;
				ma.Sclass = SC.SCglobal;
				ma.Sfl = 0;
				writefunc(ma);
			}
		}


static if (true) {
		// Always generate module info, because of templates and -cov
		if (1 || needModuleInfo())
			genmoduleinfo();
}

		obj_termfile();
	}

    void gensymfile()
	{
		assert(false);
	}

    void gendocfile()
	{
		assert(false);
	}

	/**********************************
	 * Determine if we need to generate an instance of ModuleInfo
	 * for this Module.
	 */
    bool needModuleInfo()
	{
    	// writef("needModuleInfo() %s, %d, %d\n", toChars(), needmoduleinfo, global.params.cov);
		return needmoduleinfo || global.params.cov;
	}

    override Dsymbol search(Loc loc, Identifier ident, int flags)
	{
		/* Since modules can be circularly referenced,
		 * need to stop infinite recursive searches.
		 * This is done with the cache.
		 */

		//printf("%s Module.search('%s', flags = %d) insearch = %d\n", toChars(), ident.toChars(), flags, insearch);
		Dsymbol s;
		if (insearch)
			s = null;
	    else if (searchCacheIdent == ident && searchCacheFlags == flags)
		{
			s = searchCacheSymbol;
			//printf("%s Module.search('%s', flags = %d) insearch = %d searchCacheSymbol = %s\n", toChars(), ident.toChars(), flags, insearch, searchCacheSymbol ? searchCacheSymbol.toChars() : "null");
		}
		else
		{
			insearch = 1;
			s = ScopeDsymbol.search(loc, ident, flags);
			insearch = 0;

			searchCacheIdent = ident;
			searchCacheSymbol = s;
			searchCacheFlags = flags;
		}
		return s;
	}

    void deleteObjFile()
	{
		if (global.params.obj)
			objfile.remove();
		if (docfile)
			docfile.remove();
	}

	override Dsymbol symtabInsert(Dsymbol s)
	{
		searchCacheIdent = null;	// symbol is inserted, so invalidate cache
		return Package.symtabInsert(s);
	}

	/*******************************************
	 * Can't run semantic on s now, try again later.
	 */
	void addDeferredSemantic(Dsymbol s)
	{
		auto deferred = global.deferred;
	    // Don't add it if it is already there
	    for (int i = 0; i < deferred.dim; i++)
	    {
		Dsymbol sd = cast(Dsymbol)deferred.data[i];

		if (sd == s)
		    return;
	    }

	    //printf("Module::addDeferredSemantic('%s')\n", s.toChars());
	    deferred.push(cast(void*)s);
	}

	/******************************************
	 * Run semantic() on deferred symbols.
	 */

    static void runDeferredSemantic()
	{
		if (global.dprogress == 0)
			return;
	
		if (global.nested)
			return;
		//if (deferred.dim) printf("+Module.runDeferredSemantic('%s'), len = %d\n", toChars(), deferred.dim);
		global.nested++;

		auto deferred = global.deferred;

		size_t len;
		do
		{
			global.dprogress = 0;
			len = deferred.dim;
			if (!len)
				break;

			Dsymbol *todo;
			Dsymbol tmp;
			if (len == 1)
			{
				todo = &tmp;
			}
			else
			{
				version(Bug4054)
				todo = cast(Dsymbol*)GC.malloc(len * (Dsymbol*).sizeof);
				else
				todo = cast(Dsymbol*)alloca(len * (Dsymbol*).sizeof);
				assert(todo);
			}
			memcpy(todo, deferred.data, len * (Dsymbol*).sizeof);
			deferred.setDim(0);

			for (int i = 0; i < len; i++)
			{
				Dsymbol s = todo[i];

				s.semantic(null);
				//printf("deferred: %s, parent = %s\n", s.toChars(), s.parent.toChars());
			}
			//printf("\tdeferred.dim = %d, len = %d, dprogress = %d\n", deferred.dim, len, dprogress);
		} while (deferred.dim < len || global.dprogress);	// while making progress
		global.nested--;
		//printf("-Module.runDeferredSemantic('%s'), len = %d\n", toChars(), deferred.dim);
	}

	/************************************
	 * Recursively look at every module this module imports,
	 * return TRUE if it imports m.
	 * Can be used to detect circular imports.
	 */
	bool imports(Module m)
	{
//		writef("%s Module::imports(%s)\n", toChars(), m.toChars());
		int aimports_dim = aimports.dim;
static if (false)
{
		for (int i = 0; i < aimports.dim; i++)
		{   Module mi = cast(Module)aimports.data[i];
			writef("\t[%d] %s\n", i, mi.toChars());
		}
}
		for (int i = 0; i < aimports.dim; i++)
		{   Module mi = cast(Module)aimports.data[i];
			if (mi == m)
				return true;
			if (!mi.insearch)
			{
				mi.insearch = 1;
				bool r = mi.imports(m);
				if (r)
					return r;
			}
		}
		return false;
	}

    // Back end

    int doppelganger;		// sub-module
    Symbol* cov;		// private uint[] __coverage;
    uint* covb;		// bit array of valid code line numbers

    Symbol* sictor;		// module order independent constructor
    Symbol* sctor;		// module constructor
    Symbol* sdtor;		// module destructor
    Symbol* ssharedctor;	// module shared constructor
    Symbol* sshareddtor;	// module shared destructor
    Symbol* stest;		// module unit test

    Symbol* sfilename;		// symbol for filename

    Symbol* massert;		// module assert function
    Symbol* toModuleAssert()	// get module assert function
	{
		if (!massert)
		{
			type* t;

			t = type_alloc(TYjfunc);
			t.Tflags |= TFprototype | TFfixed;
			t.Tmangle = mTYman_d;
			t.Tnext = tsvoid;
			tsvoid.Tcount++;

			massert = toSymbolX("__assert", SCextern, t, "FiZv");
			massert.Sfl = FLextern;
			massert.Sflags |= SFLnodebug;
			slist_add(massert);
		}
		return massert;
	}

    Symbol* marray;		// module array bounds function

	Symbol* toModuleArray()	// get module array bounds function
	{
		if (!marray)
		{
			type* t;

			t = type_alloc(TYjfunc);
			t.Tflags |= TFprototype | TFfixed;
			t.Tmangle = mTYman_d;
			t.Tnext = tsvoid;
			tsvoid.Tcount++;

			marray = toSymbolX("__array", SCextern, t, "Z");
			marray.Sfl = FLextern;
			marray.Sflags |= SFLnodebug;
			slist_add(marray);
		}
		return marray;
	}

    static Symbol* gencritsec()
	{
		assert(false);
	}

    elem* toEfilename()
	{
		elem* efilename;

		if (!sfilename)
		{
			dt_t* dt = null;

			string id = srcfile.toChars();
			int len = id.length;
			dtdword(&dt, len);
			dtabytes(&dt,TYnptr, 0, len + 1, toStringz(id));

			sfilename = symbol_generate(SCstatic,type_fake(TYdarray));
			sfilename.Sdt = dt;
			sfilename.Sfl = FLdata;
		version (ELFOBJ) {
			sfilename.Sseg = Segment.CDATA;
		}
		version (MACHOBJ) {
			// Because of PIC and CDATA being in the _TEXT segment, cannot
			// have pointers in CDATA
			sfilename.Sseg = Segment.DATA;
		}
			outdata(sfilename);
		}

		efilename = el_var(sfilename);
		return efilename;
	}

	/**************************************
	 * Generate elem that is a pointer to the module file name.
	 */
    elem* toEmodulename()
	{
		elem *efilename;

		// Get filename
		if (needModuleInfo())
		{
			/* Class ModuleInfo is defined in std.moduleinfo.
			 * The first member is the name of it, char name[],
			 * which will be at offset 8.
			 */

			Symbol* si = toSymbol();
		static if (true) {
			// Use this instead so -fPIC will work
			efilename = el_ptr(si);
			efilename = el_bin(OPadd, TYnptr, efilename, el_long(TYuint, 8));
			efilename = el_una(OPind, TYdarray, efilename);
		} else {
			efilename = el_var(si);
			efilename.Ety = TYdarray;
			efilename.EV.sp.Voffset += 8;
		}
		}
		else // generate our own filename
		{
			efilename = toEfilename();
		}
		return efilename;
	}

	/*************************************
	 * Create the "ModuleInfo" symbol
	 */
    override Symbol* toSymbol()
	{
		if (!csym)
		{
			Symbol* s;

			s = toSymbolX("__ModuleInfo", SC.SCextern, global.scc.Stype, "Z");
			s.Sfl = FL.FLextern;
			s.Sflags |= SFL.SFLnodebug;
			csym = s;
			slist_add(s);
		}
		return csym;
	}

	// Put out instance of ModuleInfo for this Module
    void genmoduleinfo()
	{
		//printf("Module.genmoduleinfo() %s\n", toChars());

		Symbol* msym = toSymbol();

		//dumpSymbol(msym);

		uint offset;
	version (DMDV2) {
		uint sizeof_ModuleInfo = 16 * PTRSIZE;
	} else {
		uint sizeof_ModuleInfo = 14 * PTRSIZE;
	}
	
		version (MODULEINFO_IS_STRUCT) {} else {
			sizeof_ModuleInfo -= 2 * PTRSIZE;
		}
		//printf("moduleinfo size = x%x\n", sizeof_ModuleInfo);

		//////////////////////////////////////////////

		csym.Sclass = SC.SCglobal;

		csym.Sfl = FL.FLdata;

		/* The layout is:
		   {
			void **vptr;
			monitor_t monitor;
			char[] name;		// class name
			ModuleInfo importedModules[];
			ClassInfo localClasses[];
			uint flags;			// initialization state
			void *ctor;
			void *dtor;
			void *unitTest;
			const(MemberInfo[]) function(string) xgetMembers;	// module getMembers() function
			void *ictor;
		    void *sharedctor;
			void *shareddtor;
			uint index;
			void*[1] reserved;
		   }
		 */
		dt_t* dt = null;
version (MODULEINFO_IS_STRUCT) {} else {
		if (global.moduleinfo)
			dtxoff(&dt, global.moduleinfo.toVtblSymbol(), 0, TYM.TYnptr); // vtbl for ModuleInfo
		else
		{
			//printf("moduleinfo is null\n");
			dtdword(&dt, 0);		// BUG: should be an assert()
		}
		dtdword(&dt, 0);			// monitor
}
		// name[]
		string name = toPrettyChars();
		size_t namelen = name.length;
		dtdword(&dt, namelen);
		dtabytes(&dt, TYM.TYnptr, 0, namelen + 1, toStringz(name));

		ClassDeclarations aclasses = new ClassDeclarations();

		//printf("members.dim = %d\n", members.dim);
		foreach(Dsymbol member; members)
		{
			//printf("\tmember '%s'\n", member.toChars());
			member.addLocalClass(aclasses);
		}

		// importedModules[]
		int aimports_dim = aimports.dim;
		for (int i = 0; i < aimports.dim; i++)
		{
			Module m = cast(Module)aimports.data[i];
			if (!m.needModuleInfo())
				aimports_dim--;
		}

		dtdword(&dt, aimports_dim);
		if (aimports_dim)
			dtxoff(&dt, csym, sizeof_ModuleInfo, TYM.TYnptr);
		else
			dtdword(&dt, 0);

		// localClasses[]
		dtdword(&dt, aclasses.dim);
		if (aclasses.dim)
			dtxoff(&dt, csym, sizeof_ModuleInfo + aimports_dim * PTRSIZE, TYM.TYnptr);
		else
			dtdword(&dt, 0);

		if (needmoduleinfo)
			dtdword(&dt, 8|0);		// flags (4 means MIstandalone)
		else
			dtdword(&dt, 8|4);		// flags (4 means MIstandalone)

		if (ssharedctor)
			dtxoff(&dt, ssharedctor, 0, TYnptr);
		else
			dtdword(&dt, 0);

		if (sshareddtor)
			dtxoff(&dt, sshareddtor, 0, TYnptr);
		else
			dtdword(&dt, 0);

		if (stest)
			dtxoff(&dt, stest, 0, TYM.TYnptr);
		else
			dtdword(&dt, 0);

///	version (DMDV2) {
		FuncDeclaration sgetmembers = findGetMembers();
		if (sgetmembers)
			dtxoff(&dt, sgetmembers.toSymbol(), 0, TYM.TYnptr);
		else
///	}
			dtdword(&dt, 0);			// xgetMembers

		if (sictor)
			dtxoff(&dt, sictor, 0, TYM.TYnptr);
		else
			dtdword(&dt, 0);

	version (DMDV2) {
		if (sctor)
			dtxoff(&dt, sctor, 0, TYnptr);
		else
			dtdword(&dt, 0);

		if (sdtor)
			dtxoff(&dt, sdtor, 0, TYnptr);
		else
			dtdword(&dt, 0);

		dtdword(&dt, 0);				// index

		// void*[1] reserved;
		dtdword(&dt, 0);
	}
		//////////////////////////////////////////////

		for (int i = 0; i < aimports.dim; i++)
		{
			Module m = cast(Module)aimports.data[i];

			if (m.needModuleInfo())
			{
				Symbol* s = m.toSymbol();

				/* Weak references don't pull objects in from the library,
				 * they resolve to 0 if not pulled in by something else.
				 * Don't pull in a module just because it was imported.
				 */
	version (OMFOBJ) {// Optlink crashes with weak symbols at EIP 41AFE7, 402000
	} else {
				s.Sflags |= SFL.SFLweak;
	}
				dtxoff(&dt, s, 0, TYM.TYnptr);
			}
		}

		foreach (cd; aclasses)
		{
			dtxoff(&dt, cd.toSymbol(), 0, TYM.TYnptr);
		}

		csym.Sdt = dt;
	version (ELFOBJ_OR_MACHOBJ) {
		// Cannot be CONST because the startup code sets flag bits in it
		csym.Sseg = Segment.DATA;
	}

		outdata(csym);

		//////////////////////////////////////////////

		obj_moduleinfo(msym);
	}

    override Module isModule() { return this; }
}
