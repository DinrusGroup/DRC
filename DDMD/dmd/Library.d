module dmd.Library;

import dmd.common;
import dmd.File;
import dmd.Array;
import dmd.StringTable;
import dmd.OutBuffer;
import dmd.ObjModule;
import dmd.String;
import dmd.Global;
import dmd.File;
import dmd.FileName;
import dmd.Util;
import dmd.StringValue;
import dmd.String;

import core.stdc.string;
import core.stdc.stdlib;

import std.string;

import core.memory;

struct LibHeader
{
align(1):
	ubyte  recTyp;      // 0xF0
	ushort pagesize;
	int    lSymSeek;
	ushort ndicpages;
	ubyte  flags;
}

struct Libheader
{
align(1):
	ubyte recTyp;
	ushort recLen;
	int trailerPosn;
	ushort ndicpages;
	ubyte flags;
	char[6] filler;
}

struct ObjSymbol
{
    string name;
    ObjModule* om;
}

/**************************
 * Record types:
 */

enum HASHMOD = 0x25;
enum BUCKETPAGE = 512;
enum BUCKETSIZE = (BUCKETPAGE - HASHMOD - 1);

/+
#define RHEADR	0x6E
#define REGINT	0x70
#define REDATA	0x72
#define RIDATA	0x74
#define OVLDEF	0x76
#define ENDREC	0x78
#define BLKDEF	0x7A
#define BLKEND	0x7C
#define DEBSYM	0x7E
+/
enum THEADR	= 0x80;
enum LHEADR	= 0x82;
/+#define PEDATA	0x84
#define PIDATA	0x86
+/
enum COMENT = 0x88;
enum MODEND = 0x8A;
enum M386END = 0x8B;	/* 32 bit module end record */
/+
#define EXTDEF	0x8C
#define TYPDEF	0x8E
+/
enum PUBDEF	= 0x90;
enum PUB386	= 0x91;
/+
#define LOCSYM	0x92
#define LINNUM	0x94
+/
enum LNAMES	= 0x96;
/+
#define SEGDEF	0x98
#define GRPDEF	0x9A
#define FIXUPP	0x9C
/*#define (none)	0x9E	*/
#define LEDATA	0xA0
#define LIDATA	0xA2
#define LIBHED	0xA4
#define LIBNAM	0xA6
#define LIBLOC	0xA8
#define LIBDIC	0xAA
#define COMDEF	0xB0
#define LEXTDEF	0xB4
#define LPUBDEF	0xB6
#define LCOMDEF	0xB8
#define CEXTDEF	0xBC
+/
enum COMDAT = 0xC2;
/+#define LINSYM	0xC4
+/
enum ALIAS = 0xC6;
enum LLNAMES = 0xCA;


enum LIBIDMAX = (512 - 0x25 - 3 - 4);	// max size that will fit in dictionary

extern (C) extern char* strdup(const(char)* ptr);

static uint parseName(ubyte** pp, char* name)
{
    ubyte* p = *pp;
    uint len = *p++;

    if (len == 0xFF && *p == 0)  // if long name
    {
        len = p[1] & 0xFF;
        len |= cast(uint)p[2] << 8;
	p += 3;
        assert(len <= LIBIDMAX);
    }

    memcpy(name, p, len);
    name[len] = 0;
    *pp = p + len;

	return len;
}

static ushort parseIdx(ubyte** pp)
{
    ubyte* p = *pp;
    ubyte c = *p++;

    ushort idx = cast(ushort)((0x80 & c) ? ((0x7F & c) << 8) + *p++ : c);
    *pp = p;
    return idx;
}

extern (C) int D_NameCompare(const(void*) a, const(void*) b)
{
	ObjSymbol** p1 = cast(ObjSymbol**)a;
	ObjSymbol** p2 = cast(ObjSymbol**)b;

    return cmp((*p1).name, (*p2).name);
}
version (Windows)
{
/*******************************************
 * Write a single entry into dictionary.
 * Returns:
 *	0	failure
 */

extern (C) extern uint _rotl(uint value, int shift);
extern (C) extern uint _rotr(uint value, int shift);

static int EnterDict(ubyte* bucketsP, ushort ndicpages, ubyte* entry, uint entrylen)
{
    ushort	uStartIndex;
    ushort	uStep;
    ushort	uStartPage;
    ushort	uPageStep;
    ushort	uIndex;
    ushort	uPage;
    ushort	n;
    uint u;
    uint nbytes;
    ubyte* aP;
    ubyte* zP;

    aP = entry;
    zP = aP + entrylen;		// point at last char in identifier

    uStartPage	= 0;
    uPageStep	= 0;
    uStartIndex	= 0;
    uStep	= 0;

    u = entrylen;
    while ( u-- )
    {
		uStartPage  = cast(ushort)_rotl( uStartPage,  2 ) ^ ( *aP   | 0x20 );
		uStep       = cast(ushort)_rotr( uStep,	  2 ) ^ ( *aP++ | 0x20 );
		uStartIndex = cast(ushort)_rotr( uStartIndex, 2 ) ^ ( *zP   | 0x20 );
		uPageStep   = cast(ushort)_rotl( uPageStep,	  2 ) ^ ( *zP-- | 0x20 );
    }

    uStartPage %= ndicpages;
    uPageStep  %= ndicpages;
    if ( uPageStep == 0 )
		uPageStep++;
    uStartIndex %= HASHMOD;
    uStep	%= HASHMOD;
    if ( uStep == 0 )
		uStep++;

    uPage = uStartPage;
    uIndex = uStartIndex;

    // number of bytes in entry
    nbytes = 1 + entrylen + 2;
    if (entrylen > 255)
		nbytes += 2;

    while (1)
    {
		aP = &bucketsP[uPage * BUCKETPAGE];
		uStartIndex = uIndex;
		while (1)
		{
			if ( 0 == aP[ uIndex ] )
			{
				// n = next available position in this page
				n = aP[ HASHMOD ] << 1;
				assert(n > HASHMOD);

				// if off end of this page
				if (n + nbytes > BUCKETPAGE )
				{   aP[ HASHMOD ] = 0xFF;
					break;			// next page
				}
				else
				{
					aP[ uIndex ] = cast(ubyte)(n >> 1);
					memcpy( (aP + n), entry, nbytes );
					aP[ HASHMOD ] += (nbytes + 1) >> 1;
					if (aP[HASHMOD] == 0)
					aP[HASHMOD] = 0xFF;
					return 1;
				}
			}
			uIndex += uStep;
			uIndex %= 0x25;
			/*if (uIndex > 0x25)
			uIndex -= 0x25;*/
			if( uIndex == uStartIndex )
				break;
		}
		uPage += uPageStep;
		if (uPage >= ndicpages)
			uPage -= ndicpages;
		if( uPage == uStartPage )
			break;
    }

    return 0;
}

import dmd.TObject;

class Library : TObject
{
    File libfile;
    Array objmodules;	// ObjModule[]
    Array objsymbols;	// ObjSymbol[]

    StringTable tab;

    this()
	{
		register();
		libfile = null;

		objmodules = new Array();
		objsymbols = new Array();
	}

	/***********************************
	 * Set the library file name based on the output directory
	 * and the filename.
	 * Add default library file name extension.
	 */
    void setFilename(string dir, string filename)
	{
		string arg = filename;
		if (arg.length == 0)
		{
			// Generate lib file name from first obj name
			string n = (cast(String)global.params.objfiles.data[0]).str;

			n = FileName.name(n);
			FileName fn = FileName.forceExt(n, global.lib_ext);
			arg = fn.toChars();
		}
		if (!FileName.absolute(arg))
			arg = FileName.combine(dir, arg);

		FileName libfilename = FileName.defaultExt(arg, global.lib_ext);
		libfile = new File(libfilename);
	}

	/***************************************
	 * Add object module or library to the library.
	 * Examine the buffer to see which it is.
	 * If the buffer is null, use module_name as the file name
	 * and load the file.
	 */
    void addObject(string module_name, void *buf, size_t buflen)
	{
	version (LOG) {
		printf("Library.addObject(%s)\n", module_name ? module_name : "");
	}
		if (!buf)
		{
			assert(module_name);
			scope FileName f = new FileName(module_name);
			scope File file = new File(f);
			file.readv();
			buf = file.buffer;
			buflen = file.len;
			file.ref_ = 1;
		}

		uint g_page_size;
		ubyte* pstart = cast(ubyte*)buf;
		int islibrary = 0;

		/* See if it's an OMF library.
		 * Don't go by file extension.
		 */

		/* Determine if it is an OMF library, an OMF object module,
		 * or something else.
		 */
		if (buflen < LibHeader.sizeof)
		{
		  Lcorrupt:
			error("corrupt object module");
		}
		LibHeader* lh = cast(LibHeader*)buf;
		if (lh.recTyp == 0xF0)
		{	/* OMF library
			 * The modules are all at buf[g_page_size .. lh.lSymSeek]
			 */
			islibrary = 1;
			g_page_size = lh.pagesize + 3;
			buf = cast(void*)(pstart + g_page_size);
			if (lh.lSymSeek > buflen ||
				g_page_size > buflen)
				goto Lcorrupt;
			buflen = lh.lSymSeek - g_page_size;
		}
		else if (lh.recTyp == '!' && memcmp(lh, "!<arch>\n".ptr, 8) == 0)
		{
			error("COFF libraries not supported");
			return;
		}
		else
		{
			// Not a library, assume OMF object module
			g_page_size = 16;
		}

		/* Split up the buffer buf[0..buflen] into multiple object modules,
		 * each aligned on a g_page_size boundary.
		 */

		ObjModule* om = null;
		int first_module	= 1;

		ubyte* p = cast(ubyte*)buf;
		ubyte* pend = p + buflen;
		ubyte* pnext;
		for (; p < pend; p = pnext)		// for each OMF record
		{
			if (p + 3 >= pend)
				goto Lcorrupt;
			ubyte recTyp = *p;
			ushort recLen = *cast(ushort*)(p + 1);
			pnext = p + 3 + recLen;
			if (pnext > pend)
				goto Lcorrupt;
			recLen--;                          /* forget the checksum */

			switch (recTyp)
			{
				case LHEADR :
				case THEADR :
					if (!om)
					{
						char[LIBIDMAX + 1] name;
						om = new ObjModule();
						om.flags = 0;
						om.base = p;
						p += 3;
						parseName(&p, name.ptr);
						if (first_module && module_name && !islibrary)
						{
							// Remove path and extension
							string fname = FileName.name(module_name);
							string ext = FileName.ext(fname);
							if (ext.length != 0) {
								fname = fname[0..$-ext.length-1];
							}

							om.name = fname;
						}
						else
						{
							/* Use THEADR name as module name,
							 * removing path and extension.
							 */
							string fname = FileName.name(fromStringz(name.ptr));
							string ext = FileName.ext(fname);
							if (ext.length != 0) {
								fname = fname[0..$-ext.length-1];
							}

							om.name = fname;
							om.flags |= MFtheadr;
						}
						if (strcmp(name.ptr, "C".ptr) == 0)	   // old C compilers did this
						{
							om.flags |= MFgentheadr;  // generate our own THEADR
							om.base = pnext;	   // skip past THEADR
						}
						objmodules.push(cast(void*)om);
						first_module = 0;
					}
					break;

				case MODEND :
				case M386END:
					if (om)
					{
						om.page = cast(ushort)((om.base - pstart) / g_page_size);
						om.length = pnext - om.base;
						om = null;
					}
					// Round up to next page
					uint t = pnext - pstart;
					t = (t + g_page_size - 1) & ~cast(uint)(g_page_size - 1);
					pnext = pstart + t;
					break;

				default:
					// ignore
					//;
			}
		}

		if (om)
			goto Lcorrupt;		// missing MODEND record
	}

    void addLibrary(void *buf, size_t buflen)
	{
		assert(false);
	}

    void write()
	{
		if (global.params.verbose)
			writef("library   %s\n", libfile.name.toChars());

		scope OutBuffer libbuf = new OutBuffer();
		WriteLibToBuffer(libbuf);

		// Transfer image to file
		libfile.setbuffer(libbuf.data, libbuf.offset);
		libbuf.extractData();

		string p = FileName.path(libfile.name.toChars());
		FileName.ensurePathExists(p);

		libfile.writev();
	}

  private:
    void addSymbol(ObjModule* om, string name, int pickAny = 0)
	{
	version (LOG) {
		printf("Library.addSymbol(%s, %s, %d)\n", om.name, name, pickAny);
	}
		Object* s = tab.insert(name);
		if (!s)
		{
			// already in table
			if (!pickAny)
			{
				s = tab.lookup(name);
				assert(s);
				ObjSymbol* os = *cast(ObjSymbol**)s;
				error("multiple definition of %s: %s and %s: %s",
				om.name, name, os.om.name, os.name);
			}
		}
		else
		{
			ObjSymbol* os = new ObjSymbol();
			os.name = name;
			os.om = om;
			*s = cast(Object)cast(void*)os; /// !!!!

			objsymbols.push(os);
		}
	}

    void scanObjModule(ObjModule* om)
	{
		int easyomf;
		uint u;
		ubyte result = 0;
		char[LIBIDMAX + 1] name;

		scope Array names = new Array();
		names.push(null);		// don't use index 0

		assert(om);
		easyomf = 0;				// assume not EASY-OMF
		ubyte* pend = om.base + om.length;

		ubyte* pnext;
		for (ubyte* p = om.base; 1; p = pnext)
		{
			assert(p < pend);
			ubyte recTyp = *p++;
			ushort recLen = *cast(ushort*)p;
			p += 2;
			pnext = p + recLen;
			recLen--;				// forget the checksum

			switch (recTyp)
			{
				case LNAMES:
				case LLNAMES:
					while (p + 1 < pnext)
					{
						uint len = parseName(&p, name.ptr);
						names.push(cast(void*)new String(name[0..len].idup));
					}
					break;

				case PUBDEF:
					if (easyomf)
						recTyp = PUB386;		// convert to MS format
				case PUB386:
					if (!(parseIdx(&p) | parseIdx(&p)))
						p += 2;			// skip seg, grp, frame
					while (p + 1 < pnext)
					{
						uint len = parseName(&p, name.ptr);
						p += (recTyp == PUBDEF) ? 2 : 4;	// skip offset
						parseIdx(&p);				// skip type index
						addSymbol(om, name[0..len].idup);
					}
					break;

				case COMDAT:
					if (easyomf)
						recTyp = COMDAT+1;		// convert to MS format
					case COMDAT+1:
					int pickAny = 0;

					if (*p++ & 5)		// if continuation or local comdat
						break;

					ubyte attr = *p++;
					if (attr & 0xF0)	// attr: if multiple instances allowed
						pickAny = 1;
					p++;			// align

					p += 2;			// enum data offset
					if (recTyp == COMDAT+1)
						p += 2;			// enum data offset

					parseIdx(&p);			// type index

					if ((attr & 0x0F) == 0)	// if explicit allocation
					{   parseIdx(&p);		// base group
						parseIdx(&p);		// base segment
					}

					uint idx = parseIdx(&p);	// public name index
					if( idx == 0 || idx >= names.dim)
					{
						//debug(printf("[s] name idx=%d, uCntNames=%d\n", idx, uCntNames));
						error("corrupt COMDAT");
						return;
					}

					//printf("[s] name='%s'\n",name);
					addSymbol(om, (cast(String)names.data[idx]).str, pickAny);
					break;

				case ALIAS:
					while (p + 1 < pnext)
					{
						uint len = parseName(&p, name.ptr);
						addSymbol(om, name[0..len].idup);
						parseName(&p, name.ptr);
					}
					break;

				case MODEND:
				case M386END:
					result = 1;
					goto Ret;

				case COMENT:
					// Recognize Phar Lap EASY-OMF format
					{
						enum ubyte[7] omfstr = [0x80,0xAA,'8','0','3','8','6'];

						if (recLen == omfstr.sizeof)
						{
							for (uint i = 0; i < omfstr.sizeof; i++)
								if (*p++ != omfstr[i])
									goto L1;
							easyomf = 1;
							break;
							L1:	;
						}
					}
					// Recognize .IMPDEF Import Definition Records
					{
						enum ubyte[3] omfstr = [0, 0xA0, 1];

						if (recLen >= 7)
						{
							p++;
							for (uint i = 1; i < omfstr.sizeof; i++)
								if (*p++ != omfstr[i])
									goto L2;
							p++;		// skip OrdFlag field
							uint len = parseName(&p, name.ptr);
							addSymbol(om, name[0..len].idup);
							break;
							L2:	;
						}
					}
					break;

				default:
					// ignore
					//;
			}
		}

	Ret:
		;
		///for (u = 1; u < names.dim; u++)
		///	free(names.data[u]);
	}

	/***********************************
	 * Calculates number of pages needed for dictionary
	 * Returns:
	 *	number of pages
	 */
    ushort numDictPages(uint padding)
	{
		ushort	ndicpages;
		ushort	bucksForHash;
		ushort	bucksForSize;
		uint symSize = 0;

		for (int i = 0; i < objsymbols.dim; i++)
		{
			ObjSymbol* s = cast(ObjSymbol*)objsymbols.data[i];
			symSize += ( s.name.length + 4 ) & ~1;
		}

		for (int i = 0; i < objmodules.dim; i++)
		{
			ObjModule* om = cast(ObjModule*)objmodules.data[i];

			size_t len = om.name.length;
			if (len > 0xFF)
				len += 2;			// Digital Mars long name extension
			symSize += ( len + 4 + 1 ) & ~1;
		}

		bucksForHash = cast(ushort)((objsymbols.dim + objmodules.dim + HASHMOD - 3) / (HASHMOD - 2));
		bucksForSize = cast(ushort)((symSize + BUCKETSIZE - padding - padding - 1) / (BUCKETSIZE - padding));

		ndicpages = (bucksForHash > bucksForSize ) ? bucksForHash : bucksForSize;
		//printf("ndicpages = %u\n",ndicpages);

		// Find prime number greater than ndicpages
		enum uint[] primes =
		[ 1,2,3,5,7,11,13,17,19,23,29,31,37,41,43,
		  47,53,59,61,67,71,73,79,83,89,97,101,103,
		  107,109,113,127,131,137,139,149,151,157,
		  163,167,173,179,181,191,193,197,199,211,
		  223,227,229,233,239,241,251,257,263,269,
		  271,277,281,283,293,307,311,313,317,331,
		  337,347,349,353,359,367,373,379,383,389,
		  397,401,409,419,421,431,433,439,443,449,
		  457,461,463,467,479,487,491,499,503,509,
		  //521,523,541,547,
		  0
		];

		for (int i = 0; 1; i++)
		{
			if ( primes[i] == 0 )
			{
				// Quick and easy way is out.
				// Now try and find first prime number > ndicpages
				uint prime;

				for (prime = (ndicpages + 1) | 1; 1; prime += 2)
				{   // Determine if prime is prime
					for (uint u = 3; u < prime / 2; u += 2)
					{
						if ((prime / u) * u == prime)
							goto L1;
					}
					break;

					L1: ;
				}
				ndicpages = cast(ushort)prime;
				break;
			}

			if (primes[i] > ndicpages)
			{
				ndicpages = cast(ushort)primes[i];
				break;
			}
		}

		return ndicpages;
	}

	/*******************************************
	 * Write the module and symbol names to the dictionary.
	 * Returns:
	 *	0	failure
	 */
    int FillDict(ubyte* bucketsP, ushort ndicpages)
	{
		ubyte[4 + LIBIDMAX + 2 + 1] entry;

		//printf("FillDict()\n");

		// Add each of the module names
		for (int i = 0; i < objmodules.dim; i++)
		{
			ObjModule* om = cast(ObjModule*)objmodules.data[i];

			ushort n = cast(ushort)om.name.length;
			if (n > 255)
			{
				entry[0] = 0xFF;
				entry[1] = 0;
				*cast(ushort*)(entry.ptr + 2) = cast(ushort)(n + 1);
				memcpy(entry.ptr + 4, om.name.ptr, n);
				n += 3;
			}
			else
			{
				entry[ 0 ] = cast(ubyte)(1 + n);
				memcpy(entry.ptr + 1, om.name.ptr, n );
			}
			entry[ n + 1 ] = '!';
			*(cast(ushort*)( n + 2 + entry.ptr )) = om.page;
			if ( n & 1 )
				entry[ n + 2 + 2 ] = 0;
			if ( !EnterDict( bucketsP, ndicpages, entry.ptr, n + 1 ) )
				return 0;
		}

		// Sort the symbols
		qsort( objsymbols.data, objsymbols.dim, 4, /*(cmpfunc_t)*/&D_NameCompare );

		// Add each of the symbols
		for (int i = 0; i < objsymbols.dim; i++)
		{
			ObjSymbol* os = cast(ObjSymbol*)objsymbols.data[i];

			ushort n = cast(ushort)os.name.length;
			if (n > 255)
			{
				entry[0] = 0xFF;
				entry[1] = 0;
				*cast(ushort*)(entry.ptr + 2) = n;
				memcpy(entry.ptr + 4, os.name.ptr, n);
				n += 3;
			}
			else
			{
				entry[ 0 ] = cast(ubyte)n;
				memcpy( entry.ptr + 1, os.name.ptr, n );
			}
			*(cast(ushort*)( n + 1 + entry.ptr )) = os.om.page;
			if ( (n & 1) == 0 )
				entry[ n + 3] = 0;
			if ( !EnterDict( bucketsP, ndicpages, entry.ptr, n ) )
			{
				return 0;
			}
		}

		return 1;
	}

	/**********************************************
	 * Create and write library to libbuf.
	 * The library consists of:
	 *	library header
	 *	object modules...
	 *	dictionary header
	 *	dictionary pages...
	 */
    void WriteLibToBuffer(OutBuffer libbuf)
	{
		/* Scan each of the object modules for symbols
		 * to go into the dictionary
		 */
		for (int i = 0; i < objmodules.dim; i++)
		{
			ObjModule* om = cast(ObjModule*)objmodules.data[i];
			scanObjModule(om);
		}

		uint g_page_size = 16;

		/* Calculate page size so that the number of pages
		 * fits in 16 bits. This is because object modules
		 * are indexed by page number, stored as an unsigned short.
		 */
		while (1)
		{
		  Lagain:
	version (LOG) {
			printf("g_page_size = %d\n", g_page_size);
	}
			uint offset = g_page_size;

			for (int i = 0; i < objmodules.dim; i++)
			{
				ObjModule* om = cast(ObjModule*)objmodules.data[i];

				uint page = offset / g_page_size;
				if (page > 0xFFFF)
				{
					// Page size is too small, double it and try again
					g_page_size *= 2;
					goto Lagain;
				}

				// Write out the object module m
				if (om.flags & MFgentheadr)		// if generate THEADR record
				{
					size_t size = om.name.length;
					assert(size <= LIBIDMAX);

					offset += size + 5;
					//offset += om.length - (size + 5);
					offset += om.length;
				}
				else
					offset += om.length;

				// Round the size of the file up to the next page size
				// by filling with 0s
				uint n = (g_page_size - 1) & offset;
				if (n)
					offset += g_page_size - n;
			}
			break;
		}


		/* Leave one page of 0s at start as a dummy library header.
		 * Fill it in later with the real data.
		 */
		libbuf.fill0(g_page_size);

		/* Write each object module into the library
		 */
		for (int i = 0; i < objmodules.dim; i++)
		{
			ObjModule* om = cast(ObjModule*)objmodules.data[i];

			uint page = libbuf.offset / g_page_size;
			assert(page <= 0xFFFF);
			om.page = cast(ushort)page;

			// Write out the object module om
			if (om.flags & MFgentheadr)		// if generate THEADR record
			{
				uint size = om.name.length;
				ubyte[4 + LIBIDMAX + 1] header;

				header [0] = THEADR;
				header [1] = cast(ubyte)(2 + size);
				header [2] = 0;
				header [3] = cast(ubyte)size;
				assert(size <= 0xFF - 2);

				memcpy(4 + header.ptr, om.name.ptr, size);

				// Compute and store record checksum
				uint n = size + 4;
				ubyte checksum = 0;
				ubyte* p = header.ptr;
				while (n--)
				{
					checksum -= *p;
					p++;
				}
				*p = checksum;

				libbuf.write(header.ptr, size + 5);
				//libbuf.write(om.base, om.length - (size + 5));
				libbuf.write(om.base, om.length);
			}
			else
				libbuf.write(om.base, om.length);

			// Round the size of the file up to the next page size
			// by filling with 0s
			uint n = (g_page_size - 1) & libbuf.offset;
			if (n)
				libbuf.fill0(g_page_size - n);
		}

		// File offset of start of dictionary
		uint offset = libbuf.offset;

		// Write dictionary header, then round it to a BUCKETPAGE boundary
		ushort size = (BUCKETPAGE - (cast(short)offset + 3)) & (BUCKETPAGE - 1);
		libbuf.writeByte(0xF1);
		libbuf.writeword(size);
		libbuf.fill0(size);

		// Create dictionary
		ubyte* bucketsP = null;
		ushort ndicpages;
		ushort padding = 32;
		for (;;)
		{
			ndicpages = numDictPages(padding);

		version (LOG) {
			printf("ndicpages = %d\n", ndicpages);
		}
			// Allocate dictionary
			if (bucketsP)
				bucketsP = cast(ubyte*)GC.realloc(bucketsP, ndicpages * BUCKETPAGE);
			else
				bucketsP = cast(ubyte*)GC.malloc(ndicpages * BUCKETPAGE);
			assert(bucketsP);
			memset(bucketsP, 0, ndicpages * BUCKETPAGE);
			for (uint u = 0; u < ndicpages; u++)
			{
				// 'next available' slot
				bucketsP[u * BUCKETPAGE + HASHMOD] = (HASHMOD + 1) >> 1;
			}

			if (FillDict(bucketsP, ndicpages))
				break;
			padding += 16;      // try again with more margins
		}

		// Write dictionary
		libbuf.write(bucketsP, ndicpages * BUCKETPAGE);
		///if (bucketsP)
		///    free(bucketsP);

		// Create library header
		Libheader libHeader;
		memset(&libHeader, 0, Libheader.sizeof);
		libHeader.recTyp = 0xF0;
		libHeader.recLen  = 0x0D;
		libHeader.trailerPosn = offset + (3 + size);
		libHeader.recLen = cast(ushort)(g_page_size - 3);
		libHeader.ndicpages = ndicpages;
		libHeader.flags = 1;		// always case sensitive

		// Write library header at start of buffer
		memcpy(libbuf.data, &libHeader, libHeader.sizeof);
	}
}
} // version (Windows)
else version(TARGET_LINUX)
{

import dmd.TObject;

class Library : TObject
{
    void setFilename(string dir, string filename)
    {
    	assert(0);
    }

    void addObject(string module_name, void *buf, size_t buflen)
    {
    	assert(0);
    }

    void write()
    {
    	assert(0);
    }

}
}

else version (TARGET_OSX)
{
	import dmd.TObject;

	class Library : TObject
	{
	    void setFilename(string dir, string filename)
	    {
	    	assert(0);
	    }

	    void addObject(string module_name, void *buf, size_t buflen)
	    {
	    	assert(0);
	    }

	    void write()
	    {
	    	assert(0);
	    }
	}
}