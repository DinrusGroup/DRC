module dmd.backend.glue;

import dmd.common;
import dmd.Array;
import dmd.Dsymbol;
import dmd.File;
import dmd.FileName;
import dmd.Library;
import dmd.OutBuffer;
import dmd.Module;
import dmd.Identifier;
import dmd.AssertExp;
import dmd.TOK;
import dmd.Global;
import dmd.Param;
import dmd.backend.Config;
import dmd.backend.elem;
import dmd.backend.Configv;
import dmd.backend.StringTab;

import core.stdc.string;

version (Windows)
{
	extern (C++) extern
	{
		int go_flag(char* cp);
		void util_set64();
		void util_set386();
	}
}
else version (linux)
{
	extern (C++)
	{
		int go_flag(char* cp);
		void util_set64();
		void util_set386();
	}
}
else version (OSX)
{
	extern (C++)
	{
		int go_flag(char* cp);
		void util_set64();
		void util_set386();
	}
}
else
{
	static assert(false, "fix this");
}

version (CPP_MANGLE)
{
	string cpp_mangle(Dsymbol s)
	{
		assert(false, "port c++ mangling");
	}
}

import std.exception;
import std.string;

struct Outbuffer
{
    ubyte* buf;		// the buffer itself
    ubyte* pend;	// pointer past the end of the buffer
    ubyte* p;		// current position in buffer
    uint len;		// size of buffer
    uint inc;		// default increment size

    this(uint inc)
	{
		assert(false);
	}

    ~this()
	{
	}

    void reset()
	{
		assert(false);
	}

    // Reserve nbytes in buffer
    void reserve(uint nbytes)
	{
		assert(false);
	}

    // Write n zeros; return pointer to start of zeros
    void* writezeros(uint n)
	{
		assert(false);
	}

    // Position buffer to accept the specified number of bytes at offset
    int position(uint offset, uint nbytes);

    // Write an array to the buffer, no reserve check
    void writen(const(void)* b, int len)
    {
		memcpy(p,b,len);
		p += len;
    }

    // Clear bytes, no reserve check
    void clearn(int len)
    {
		int i;
		for (i=0; i< len; i++)
			*p++ = 0;
    }

    // Write an array to the buffer.
    void write(const void *b, int len)
	{
		assert(false);
	}

    void write(Outbuffer* b)
	{
		write(b.buf, b.p - b.buf);
	}

    /**
     * Flushes the stream. This will write any buffered
     * output bytes.
     */
    void flush() { }

    /**
     * Writes an 8 bit byte, no reserve check.
     */
    void writeByten(char v)
    {
		*p++ = v;
    }

    /**
     * Writes an 8 bit byte.
     */
    void writeByte(int v)
	{
		assert(false);
	}

    /**
     * Writes a 16 bit little-end short, no reserve check.
     */
    void writeWordn(int v)
    {
version (_WIN32) {
		*cast(ushort*)p = cast(short)v;
} else {
                assert(0, "Check this");
		p[0] = cast(ubyte)v;
		p[1] = cast(ubyte)(v >> 8);
}
		p += 2;
    }

    /**
     * Writes a 16 bit little-end short.
     */
    void writeWord(int v)
    {
		reserve(2);
		writeWordn(v);
    }

    /**
     * Writes a 16 bit big-end short.
     */
    void writeShort(int v)
    {
		if (pend - p < 2)
			reserve(2);

static if (false) {
		p[0] = (cast(ubyte*)&v)[1];
		p[1] = v;
} else {
		ubyte* q = p;
		q[0] = cast(ubyte)(v >> 8);
		q[1] = cast(ubyte)v;
}
		p += 2;
    }

    /**
     * Writes a 16 bit char.
     */
    void writeChar(int v)
    {
		writeShort(v);
    }

    /**
     * Writes a 32 bit int.
     */
    void write32(long v)
	{
		assert(false);
	}

    /**
     * Writes a 64 bit long.
     */
///#if __INTSIZE == 4
    void write64(long v)
	{
		assert(false);
	}
///#endif

    /**
     * Writes a 32 bit float.
     */
    void writeFloat(float v)
	{
		assert(false);
	}

    /**
     * Writes a 64 bit double.
     */
    void writeDouble(double v)
	{
		assert(false);
	}

    void write(const(char)* s)
	{
		assert(false);
	}

    void write(const(ubyte)* s)
	{
		assert(false);
	}

    void writeString(const(char)* s)
	{
		assert(false);
	}

    void prependBytes(const(char)* s)
	{
		assert(false);
	}

    void bracket(char c1, char c2)
	{
		assert(false);
	}

    /**
     * Returns the number of bytes written.
     */
    int size()
    {
		return p - buf;
    }

    char* toString()
	{
		assert(false);
	}

    void setsize(uint size)
	{
		assert(false);
	}

    void writesLEB128(long value)
	{
		assert(false);
	}

    void writeuLEB128(uint value)
	{
		assert(false);
	}
}

/**************************************
 * Append s to list of object files to generate later.
 */

void obj_append(Dsymbol s)
{
    global.obj_symbols_towrite.push(cast(void*)s);
}

version (Bug4059)
{
	private extern (C) void _Z8obj_initP9OutbufferPKcS2_(Outbuffer* objbuf, const(char)* filename, const(char)* csegname);
	void obj_init(Outbuffer* objbuf, const(char)* filename, const(char)* csegname) { return _Z8obj_initP9OutbufferPKcS2_(objbuf, filename, csegname); }
}
else
{
	extern (C++) {
		void obj_init(Outbuffer* objbuf, const(char)* filename, const(char)* csegname);
	}
}

extern (C++) {
	void backend_init();
	void backend_term();
	void obj_term();
	void rtlsym_reset();
    void slist_reset();
	void el_reset();
	void cg87_reset();
	void out_reset();
}

void clearStringTab()
{
    //printf("clearStringTab()\n");
    memset(global.stringTab.ptr, 0, global.stringTab.sizeof);
    global.stidx = 0;

//    assertexp_sfilename = null;
//    assertexp_name = null;
//    assertexp_mn = null;
}

void obj_start(char *srcfile)
{
    //printf("obj_start()\n");

    out_config_init();

    rtlsym_reset();
    slist_reset();
    clearStringTab();

    obj_init(&global.objbuf, srcfile, null);

    el_reset();
    cg87_reset();
    out_reset();
}

void obj_end(Library library, File objfile)
{
	obj_term();

	auto objbuf = &global.objbuf;

    if (library)
    {
		// Transfer image to library
		library.addObject(objfile.name.toChars(), objbuf.buf, objbuf.p - objbuf.buf);
		objbuf.buf = null;
    }
    else
    {
		// Transfer image to file
		objfile.setbuffer(objbuf.buf, objbuf.p - objbuf.buf);
		objbuf.buf = null;

		string p = FileName.path(objfile.name.toChars());
		FileName.ensurePathExists(p);
		//mem.free(p);

		//printf("write obj %s\n", objfile.name.toChars());
		objfile.writev();
    }

    objbuf.pend = null;
    objbuf.p = null;
    objbuf.len = 0;
    objbuf.inc = 0;
}

void obj_write_deferred(Library library)
{
	auto obj_symbols_towrite = global.obj_symbols_towrite;
	for (int i = 0; i < obj_symbols_towrite.dim; i++)
    {
		Dsymbol s = cast(Dsymbol)obj_symbols_towrite.data[i];
		Module m = s.getModule();

		string mname;
		if (m)
		{
			mname = m.srcfile.toChars();
			global.lastmname = mname;
		}
		else
		{
			//mname = s->ident->toChars();
			mname = global.lastmname;
			assert(mname.length != 0);
		}

		obj_start(cast(char*)toStringz(mname));

		int count = ++global.count;		// sequence for generating names

		/* Create a module that's a doppelganger of m, with just
		 * enough to be able to create the moduleinfo.
		 */
		auto idbuf = new OutBuffer();
		idbuf.printf("%s.%d", m ? m.ident.toChars() : mname, count);
		string idstr = idbuf.extractString();
		idbuf.data = null;
		Identifier id = new Identifier(idstr, TOK.TOKidentifier);

		auto md = new Module(mname, id, 0, 0);
		md.members = new Dsymbols();
		md.members.push(s);	// its only 'member' is s
		if (m)
		{
			md.doppelganger = 1;	// identify this module as doppelganger
			md.md = m.md;
			md.aimports.push(cast(void*)m);	// it only 'imports' m
			md.massert = m.massert;
			md.marray = m.marray;
		}

		md.genobjfile(0);

		/* Set object file name to be source name with sequence number,
		 * as mangled symbol names get way too long.
		 */
		string fname = FileName.removeExt(mname);

		OutBuffer namebuf = new OutBuffer();
		uint hash = 0;
		foreach (char c; s.toChars())
			hash += c;

		namebuf.printf("%s_%x_%x.%s", fname, count, hash, global.obj_ext);
		fname = namebuf.extractString();

		//printf("writing '%s'\n", fname);
		File objfile = new File(fname);
		obj_end(library, objfile);
    }

    obj_symbols_towrite.dim = 0;
}

/**************************************
 * Initialize config variables.
 */

void out_config_init()
{
    Param* params = &global.params;

    if (!config.target_cpu)
    {
		config.target_cpu = TARGET_PentiumPro;
		config.target_scheduler = config.target_cpu;
    }
    config.fulltypes = CVNONE;
    config.inline8087 = 1;
    config.memmodel = 0;
    config.flags |= CFGuchar;	// make sure TYchar is unsigned
version (TARGET_WINDOS) {
    if (params.isX86_64)
		config.exe = EX_WIN64;
    else
		config.exe = EX_NT;

    // Win32 eh
    config.flags2 |= CFG2seh;

    if (params.run)
		config.wflags |= WFexe;		// EXE file only optimizations
    else if (params.link && !global.params.deffile)
		config.wflags |= WFexe;		// EXE file only optimizations
    else if (params.exefile)		// if writing out EXE file
    {
		size_t len = params.exefile.length;
		if (len >= 4 && icmp(params.exefile[len-3..len], "exe") == 0)
			config.wflags |= WFexe;
    }
    config.flags4 |= CFG4underscore;
}
version (TARGET_LINUX) {
    if (params.isX86_64)
		config.exe = EX_LINUX64;
    else
		config.exe = EX_LINUX;
    config.flags |= CFGnoebp;
    config.flags |= CFGalwaysframe;
    if (params.pic)
		config.flags3 |= CFG3pic;
}
version (TARGET_OSX) {
    if (params.isX86_64)
		config.exe = EX_OSX64;
    else
		config.exe = EX_OSX;
    config.flags |= CFGnoebp;
    config.flags |= CFGalwaysframe;
    if (params.pic)
		config.flags3 |= CFG3pic;
}
version (TARGET_FREEBSD) {
    if (params.isX86_64)
		config.exe = EX_FREEBSD64;
    else
		config.exe = EX_FREEBSD;
    config.flags |= CFGnoebp;
    config.flags |= CFGalwaysframe;
    if (params.pic)
		config.flags3 |= CFG3pic;
}
version (TARGET_SOLARIS) {
    if (params.isX86_64)
		config.exe = EX_SOLARIS64;
    else
		config.exe = EX_SOLARIS;
    config.flags |= CFGnoebp;
    config.flags |= CFGalwaysframe;
    if (params.pic)
		config.flags3 |= CFG3pic;
}
    config.flags2 |= CFG2nodeflib;	// no default library
    config.flags3 |= CFG3eseqds;
static if (false) {
    if (env.getEEcontext().EEcompile != 2)
		config.flags4 |= CFG4allcomdat;
    if (env.nochecks())
		config.flags4 |= CFG4nochecks;	// no runtime checking
} else version (TARGET_OSX) {
} else {
    config.flags4 |= CFG4allcomdat;
}
    if (params.trace)
		config.flags |= CFGtrace;	// turn on profiler
    if (params.nofloat)
		config.flags3 |= CFG3wkfloat;

    configv.verbose = params.verbose;

    if (params.optimize)
		go_flag(cast(char*)"-o".ptr);

    if (params.symdebug)
    {
version (ELFOBJ_OR_MACHOBJ) {
	configv.addlinenumbers = 1;
	config.fulltypes = (params.symdebug == 1) ? CVDWARF_D : CVDWARF_C;
}
version (OMFOBJ) {
	configv.addlinenumbers = 1;
	config.fulltypes = CV4;
}
	if (!params.optimize)
	    config.flags |= CFGalwaysframe;
    }
    else
    {
		configv.addlinenumbers = 0;
		config.fulltypes = CVNONE;
		//config.flags &= ~CFGalwaysframe;
    }

    if (params.isX86_64)
    {
		util_set64();
		cod3_set64();
    }
    else
    {
		util_set386();
		cod3_set386();
    }

debug {
    debugb = params.debugb;
    debugc = params.debugc;
    debugf = params.debugf;
    debugr = params.debugr;
    debugw = params.debugw;
    debugx = params.debugx;
    debugy = params.debugy;
}
}
