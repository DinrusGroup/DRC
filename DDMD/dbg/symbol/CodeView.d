/**
 This module is used to extract CodeView symbolic debugging information and to
 perform queries upon that information.

 TODO:
	* Add support for CodeView 5.0 and PDB formats.
	* Add support to extract type information.

 Authors:
	Jeremie Pelletier

 References:
	$(LINK http://www.x86.org/ftp/manuals/tools/sym.pdf)
	$(LINK http://undocumented.rawol.com/sbs-w2k-1-windows-2000-debugging-support.pdf)
	$(LINK http://www.microsoft.com/msj/0399/hood/hood0399.aspx)
	$(LINK http://source.winehq.org/source/include/wine/mscvpdb.h)
	$(LINK http://www.digitalmars.com/d/2.0/abi.html)

 License:
	Public Domain
*/
module dbg.symbol.CodeView;

import dbg.Debug;

class CodeViewDebugInfo : ISymbolicDebugInfo {
	/**
	 Load CodeView data from the given memory view.
	*/
	this(in void[] view)
	in {
		assert(view.length && view.ptr);
	}
	body {
		_view = view;

		auto header = cast(CV_HEADER*)_view.ptr;
		CheckOffset(header.offset);

		// TODO: Only supporting NB09 (CodeView 4.10) right now
		if(!header.signature == CV_SIGNATURE_NB09)
			throw new CodeViewUnsupportedException(this);

		auto dir = cast(CV_DIRECTORY*)(view.ptr + header.offset);
		if(dir.dirSize != CV_DIRECTORY.sizeof || dir.entrySize != CV_ENTRY.sizeof)
			throw new CodeViewCorruptedException(this);

		CvModule globalModule;
		_modules ~= globalModule;

		foreach(ref e; dir.entries) {
			CheckOffset(e.offset);

			switch(e.sst) {
			case sstModule:			ParseModule(&e);		break;
			case sstLibraries:		ParseLibraries(&e);		break;
			case sstAlignSym:		ParseAlignSymbols(&e);	break;
			case sstSrcModule:		ParseSrcModule(&e);		break;
			case sstGlobalPub:
			case sstStaticSym:
			case sstGlobalSym:		ParseHashSymbols(&e);	break;
			case sstGlobalTypes:	ParseGlobalTypes(&e);	break;

			// TODO:
			/*case sstFileIndex:
			case sstSegMap:
			case sstSegName:*/

			default:
			}
		}
	}

	/**
	 Get the procedure symbol matching the given address.
	*/
	SymbolInfo ResolveSymbol(size_t rva) const
	in {
		assert(rva);
	}
	body {
		SymbolInfo symbol;

		foreach(ref m; _modules[0 .. _maxSymModule + 1])
			if(m.symbols.QueryProc(rva, &symbol))
				goto Found;

		foreach(ref m; _modules[0 .. _maxSymModule + 1])
			if(m.symbols.QueryCodeData(rva, &symbol))
				goto Found;

	Found:
		return symbol;
	}

	/**
	 Get the file/line mapping corresponding to the given relative address.
	*/
	FileLineInfo ResolveFileLine(size_t rva) const
	in {
		assert(rva);
	}
	body {
		FileLineInfo fileLine;

		if(_maxSrcModule)
			foreach(m; _modules[1 .. _maxSrcModule + 1])
				if(m.src.Query(rva, &fileLine))
					break;

		return fileLine;
	}

private:

	void ParseModule(in CV_ENTRY* e) {
		auto mod = cast(CV_MODULE*)(_view.ptr + e.offset);

		if(e.modIndex != _modules.length || mod.style != CV_MOD_STYLE)
			throw new CodeViewCorruptedException(this);

		with(*mod)
		_modules ~= CvModule(overlay, lib, segments, name.name);
	}

	void ParseLibraries(in CV_ENTRY* e) {
		if(e.modIndex != ushort.max) throw new CodeViewCorruptedException(this);

		auto name = cast(OMF_NAME*)(_view.ptr + e.offset);
		auto end = cast(const(void)*)name + e.size;

		while(name < end) {
			if(name.len) _libraries ~= name.name;

			name = cast(OMF_NAME*)(cast(void*)name + 1 + name.len);
		}
	}

	void ParseAlignSymbols(in CV_ENTRY* e) {
		if(e.modIndex == ushort.max || e.modIndex <= 0 || e.modIndex >= _modules.length)
			throw new CodeViewCorruptedException(this);

		if(e.modIndex > _maxSymModule) _maxSymModule = e.modIndex;

		auto sym = cast(CV_SYMBOL*)(_view.ptr + e.offset);

		if(sym.header.type == 0) sym = cast(CV_SYMBOL*)(cast(void*)sym + 4);

		_modules[e.modIndex].symbols.Init(sym, cast(void*)sym + e.size);
	}

	void ParseHashSymbols(in CV_ENTRY* e) {
		if(e.modIndex != ushort.max) throw new CodeViewCorruptedException(this);

		auto hash = cast(CV_SYMHASH*)(_view.ptr + e.offset);
		auto p = cast(void*)hash + CV_SYMHASH.sizeof;

		_modules[0].symbols.Init(cast(CV_SYMBOL*)p, p + hash.symInfoSize);
	}

	void ParseSrcModule(in CV_ENTRY* e) {
		if(e.modIndex == ushort.max || e.modIndex <= 0 || e.modIndex >= _modules.length)
			throw new CodeViewCorruptedException(this);

		if(e.modIndex > _maxSrcModule) _maxSrcModule = e.modIndex;

		auto src = cast(CV_SRCMODULE*)(_view.ptr + e.offset);

		with(_modules[e.modIndex].src) {
			data = src;
			fileOffsets = src.fileOffsets;
			codeOffsets = src.codeOffsets;
			segmentIds = src.segmentIds;
		}
	}

	void ParseGlobalTypes(in CV_ENTRY* e) {
		if(e.modIndex != ushort.max) throw new CodeViewCorruptedException(this);

		// TODO: this currently crash stuff randomly
		/*auto header = cast(CV_GLOBALTYPES*)(_view.ptr + e.offset);
		_types.Init(header, cast(void*)header + e.size);*/
	}

	void CheckOffset(int offset) {
		if(offset > _view.length) throw new CodeViewCorruptedException(this);
	}

	const(void)[]	_view;

	CvModule[]		_modules;
	uint			_maxSymModule;
	uint			_maxSrcModule;
	string[]		_libraries;
	CvTypes			_types;
}

abstract class CodeViewException : Exception {
	this(string msg) {
		super(msg);
	}
}

class CodeViewUnsupportedException : CodeViewException {
	this(in CodeViewDebugInfo cv) {
		super("CodeView version unsupported.");
	}
}

class CodeViewCorruptedException : CodeViewException {
	this(in CodeViewDebugInfo cv) {
		super("Corrupted CodeView data.");
	}
}

private:
alias int cmp_t;
uint BinarySearch(scope cmp_t delegate(uint i) dg, uint low, uint high) {
	if(high < low) return uint.max;

	uint mid = low + ((high - low) / 2);
	cmp_t cmp = dg(mid);

	if(cmp > 0) return BinarySearch(dg, low, mid - 1);
	if(cmp < 0) return BinarySearch(dg, mid + 1, high);
	return mid;
}

uint BinarySearch(in uint[] a, uint value, uint low, uint high) {
	if(high < low) return uint.max;

	uint mid = low + ((high - low) / 2);

	if(a[mid] > value) return BinarySearch(a, value, low, mid - 1);
	if(a[mid] < value) return BinarySearch(a, value, mid + 1, high);
	return mid;
}

struct CvModule {
	ushort			overlay;
	ushort			lib;
	CV_SEGMENT[]	segments;
	string			name;

	CvSymbols		symbols;
	CvSrcModule		src;
}

struct CvSymbols {
	ubyte		compileMachine;
	ubyte		compileLanguage;
	ushort		compileFlags;
	string		compileName;
	ushort		segment;

	CvProc[]	procSymbols;
	CvData[]	codeSymbols;

	void Init(const(CV_SYMBOL)* sym, in void* end) {
		int i = 0;
		while(sym < end && i < 100) {
			++i;
			switch(sym.header.type) {
			case S_COMPILE_V1:
				with(sym.compile_v1) {
					compileMachine = machine;
					compileLanguage = language;
					compileFlags = flags;
					compileName = name.name;
				}
				break;

			case S_SSEARCH_V1:
				if(!segment) segment = sym.ssearch.segment;
				break;

			case S_UDT_V1:
				break;

			case S_BPREL_V1:
				break;

			case S_LDATA_V1:
			case S_GDATA_V1:
			case S_PUB_V1:
				CvData data = void;

				with(sym.data_v1) {
					// TODO: its bad to assume 2 to always be the only code segment!
					if(segment != 2) break;

					data.offset = offset;
					data.name = name.name;
				}

				codeSymbols ~= data;
				break;

			case S_LPROC_V1:
			case S_GPROC_V1:
				CvProc proc = void;

				with(sym.proc_v1) {
					proc.offset = offset;
					proc.length = procLength;
					proc.name = name.name;
				}

				procSymbols ~= proc;
				break;

			case S_PROCREF_V1:
			case S_DATAREF_V1:
			case S_ALIGN_V1:
				break;

			case S_END_V1:
			case S_ENDARG_V1:
			case S_RETURN_V1:
				break;

			default:
			}

			sym = cast(CV_SYMBOL*)(cast(void*)sym + sym.header.size + 2);
		}

		codeSymbols.sort;
	}

	bool QueryProc(uint rva, SymbolInfo* symbol) const {
		if(!procSymbols.length) return false;

		cmp_t CmpProc(uint i) {
			if(i >= procSymbols.length) return 0;

			uint offset = procSymbols[i].offset;
			if(offset > rva) return 1;
			if(offset + procSymbols[i].length < rva) return -1;
			return 0;
		}

		uint index = BinarySearch(&CmpProc, 0, procSymbols.length - 1);

		if(index < procSymbols.length) with(procSymbols[index]) {
			symbol.name = name.idup;
			symbol.offset = rva - offset;
			return true;
		}

		return false;
	}

	bool QueryCodeData(uint rva, SymbolInfo* symbol) const {
		if(!codeSymbols.length) return false;

		cmp_t CmpData(uint i) {
			if(i >= codeSymbols.length) return 0;

			if(codeSymbols[i].offset > rva) return 1;
			if(i + 1 != codeSymbols.length && codeSymbols[i + 1].offset < rva) return -1;
			return 0;
		}

		uint index = BinarySearch(&CmpData, 0, codeSymbols.length - 1);

		if(index < codeSymbols.length) with(codeSymbols[index]) {
			symbol.name = name.idup;
			symbol.offset = rva - offset;
			return true;
		}

		return false;
	}
}

struct CvProc {
	uint	offset;
	uint	length;
	string	name;
}

struct CvData {
	uint offset;
	string name;

	cmp_t opCmp(ref const CvData data) const {
		if(data.offset < offset) return -1;
		return data.offset > offset;
	}
}

struct CvSrcModule {
	bool Query(uint rva, FileLineInfo* fileLine) const {
		if(!codeOffsets.length || rva < codeOffsets[0][0] || rva > codeOffsets[$ - 1][1])
			return false;

		uint fIndex;

		// Get the next CV_SRCFILE record having rva within it's code range
		// The code offsets here may overlap over file records, we have to walk
		// through them and possibly keep walking if the next section doesn't
		// find a matching line record.
	NextFile:
		if(fIndex == fileOffsets.length) return false;

		CV_SRCFILE* srcFile = cast(CV_SRCFILE*)(data + fileOffsets[fIndex++]);
		uint[2][] offsets = srcFile.codeOffsets;

		if(rva < offsets[0][0] || rva > offsets[$ - 1][1])
			goto NextFile;

		CV_SRCSEGMENT* srcSeg;

		// Address is possibly within this file, now get the CV_SEGMENT record.
		cmp_t CmpFile(uint i) {
			if(i >= offsets.length) return 0;

			if(offsets[i][0] > rva) return 1;
			if(offsets[i][1] < rva) return -1;

			srcSeg = cast(CV_SRCSEGMENT*)(data + srcFile.lineOffsets[i]);
			return 0;
		}

		// Ignore the return value from BinarySearch, if CmpSegment matched, we
		// already have srcSeg set. In some rare cases there may not be a
		// matching segment record even if the file's segment range said so.
		BinarySearch(&CmpFile, 0, offsets.length - 1);
		if(!srcSeg) goto NextFile;

		// Finally look within the segment's offsets for a matching record.
		uint[] segOffsets = srcSeg.offsets;
		ushort[] lineNumbers = srcSeg.lineNumbers;

		cmp_t CmpSegment(uint i) {
			if(i >= segOffsets.length) return 0;

			if(segOffsets[i] > rva) return 1;
			if(i + 1 < segOffsets.length && segOffsets[i + 1] < rva) return -1;

			return 0;
		}

		uint sIndex = BinarySearch(&CmpSegment, 0, segOffsets.length - 1);
		if(sIndex >= lineNumbers.length) goto NextFile;

		// Found our record
		fileLine.file = srcFile.name.name.idup;
		fileLine.line = srcSeg.lineNumbers[sIndex];

		return true;
	}

	const(void)*		data;
	const(uint)[]		fileOffsets;
	const(uint[2])[]	codeOffsets;
	const(ushort)[]		segmentIds;
}

// TODO!
struct CvTypes {
	void Init(in CV_GLOBALTYPES* gtypes, in void* end) {
		debug(CodeView) TraceA("CvTypes[%p].Init(gtypes=%p, end=%p)",
			&this, gtypes, end);

		offsets = gtypes.typeOffsets[0 .. gtypes.nTypes].idup;

		void* dataStart = gtypes.types;
		data = dataStart[0 .. end - dataStart].idup;
	}

	void GetType(ushort index) {
		/+
		CheckOffset(typeOffsets[index]);

		CV_TYPE* type = cast(CV_TYPE*)(p + typeOffsets[i]);

		switch(type.header.type) {
		case LF_MODIFIER_V1:
			break;

		case LF_POINTER_V1:
			break;

		case LF_ARRAY_V1:
			break;

		case LF_CLASS_V1:
			break;

		case LF_STRUCTURE_V1:
			break;

		case LF_UNION_V1:
			break;

		case LF_ENUM_V1:
			break;

		case LF_PROCEDURE_V1:
			break;

		case LF_MFUNCTION_V1:
			break;

		case LF_VTSHAPE_V1:
			break;

		case LF_OEM_V1:
			with(type.oem_v1) {
				// Ignore unknown OEMs
				if(oem != OEM_DIGITALMARS || nIndices != 2) break;

				switch(rec) {
				case D_DYN_ARRAY:
					break;

				case D_ASSOC_ARRAY:
					break;

				case D_DELEGATE:
					break;

				default:
				}
			}
			break;

		case LF_ARGLIST_V1:
			break;

		case LF_FIELDLIST_V1:
			break;

		case LF_DERIVED_V1:
			break;

		case LF_METHODLIST_V1:
			break;

		default:
			TraceA("New leaf %x", cast(uint)type.header.type);
			Pause;
		}
		+/
	}

	const(uint)[]	offsets;
	const(void)[]	data;
}

// ----------------------------------------------------------------------------
// O M F  S t r u c t u r e s
// ----------------------------------------------------------------------------

align(1):

/**
 Packed variant header
*/
struct OMF_HEADER {
	short size;
	short type;
}

/**
 Packed name, may be 0 padded to maintain alignment
*/
struct OMF_NAME {
	ubyte len;
	//char[1] name;

	string name() const {
		return (cast(immutable(char)*)(&len + 1))[0 .. len];
	}
}

// ----------------------------------------------------------------------------
// C o d e V i e w  C o m m o n  S t r u c t u r e s
// ----------------------------------------------------------------------------

/**
 Version signatures
*/
enum : uint {
	CV_SIGNATURE_NB09	= 0x3930424E,	/// CodeView 4.10
	CV_SIGNATURE_NB11	= 0x3131424E,	/// CodeView 5.0
	CV_SIGNATURE_NB10	= 0x3130424E,	/// CodeView PDB 2.0
	CV_SIGNATURE_RSDS	= 0x53445352	/// CodeView PDB 7.0
}

/**
 SubSection Types
*/
enum : ushort {
	sstModule 		= 0x0120,
	sstTypes 		= 0x0121,
	sstPublic 		= 0x0122,
	sstPublicSym 	= 0x0123,
	sstSymbols 		= 0x0124,
	sstAlignSym 	= 0x0125,
	sstSrcLnSeg 	= 0x0126,
	sstSrcModule 	= 0x0127,
	sstLibraries 	= 0x0128,
	sstGlobalSym 	= 0x0129,
	sstGlobalPub 	= 0x012A,
	sstGlobalTypes 	= 0x012B,
	sstMPC 			= 0x012C,
	sstSegMap 		= 0x012D,
	sstSegName 		= 0x012E,
	sstPreComp 		= 0x012F,
	sstPreCompMap 	= 0x0130,
	sstOffsetMap16 	= 0x0131,
	sstOffsetMap32 	= 0x0132,
	sstFileIndex 	= 0x0133,
	sstStaticSym 	= 0x0134
}

/**
 Header used with "NB09" and "NB11"
*/
struct CV_HEADER {
	uint	signature;
	int		offset;
}

/**
 Header used with "NB10"
*/
struct CV_HEADER_NB10 {
	uint			signature;
	int				offset;
	uint			timestamp;
	uint			age;
	OMF_NAME		name;
}

/**
 Header used with "RSDS"
*/
/*struct CV_HEADER_RSDS {
	uint			signature;
	GUID			guid;
	uint			age;
	OMF_NAME		name;
}*/

/**
 Directory header
*/
struct CV_DIRECTORY {
	ushort			dirSize;
	ushort			entrySize;
	uint			nEntries;
	int				offset;
	uint			flags;
	//CV_ENTRY[1]	entries;

	CV_ENTRY[] entries() const {
		return (cast(CV_ENTRY*)(&this + 1))[0 .. nEntries];
	}
}

/**
 Subsection record
*/
struct CV_ENTRY {
	ushort			sst;
	ushort			modIndex;
	int				offset;
	uint			size;
}

// ----------------------------------------------------------------------------
// sstModule
// ----------------------------------------------------------------------------

/**
 Module style, always "CV"
*/
enum CV_MOD_STYLE = 0x5643;

/**
 Module
*/
struct CV_MODULE {
	ushort			overlay;
	ushort			lib;
	ushort			nSegments;
	ushort			style;
	//CV_SEGMENT[1]	segments;
	//OMF_NAME		name;

	CV_SEGMENT[] segments() const {
		return (cast(CV_SEGMENT*)(&style + 1))[0 .. nSegments];
	}

	OMF_NAME name() const {
		return *cast(OMF_NAME*)(cast(void*)segments + nSegments * CV_SEGMENT.sizeof);
	}
}

/**
 Module segment
*/
struct CV_SEGMENT {
	ushort			segIndex;
	ushort			padding;
	uint			offset;
	uint			size;
}

// ----------------------------------------------------------------------------
// sstGlobalPub, sstStaticSym, sstGlobalSym, sstAlignSym
// ----------------------------------------------------------------------------

/**
 Symbol IDs, used by CV_SYMBOL.header.type
*/
enum : ushort {
	S_COMPILE_V1	= 0x0001,
	S_REGISTER_V1	= 0x0002,
	S_CONSTANT_V1	= 0x0003,
	S_UDT_V1		= 0x0004,
	S_SSEARCH_V1	= 0x0005,
	S_END_V1		= 0x0006,
	S_SKIP_V1		= 0x0007,
	S_CVRESERVE_V1	= 0x0008,
	S_OBJNAME_V1	= 0x0009,
	S_ENDARG_V1		= 0x000A,
	S_COBOLUDT_V1	= 0x000B,
	S_MANYREG_V1	= 0x000C,
	S_RETURN_V1		= 0x000D,
	S_ENTRYTHIS_V1	= 0x000E,

	S_BPREL_V1 		= 0x0200,
	S_LDATA_V1 		= 0x0201,
	S_GDATA_V1 		= 0x0202,
	S_PUB_V1 		= 0x0203,
	S_LPROC_V1 		= 0x0204,
	S_GPROC_V1 		= 0x0205,
	S_THUNK_V1 		= 0x0206,
	S_BLOCK_V1 		= 0x0207,
	S_WITH_V1 		= 0x0208,
	S_LABEL_V1 		= 0x0209,
	S_CEXMODEL_V1 	= 0x020A,
	S_VFTPATH_V1 	= 0x020B,
	S_REGREL_V1 	= 0x020C,
	S_LTHREAD_V1 	= 0x020D,
	S_GTHREAD_V1 	= 0x020E,

	S_PROCREF_V1	= 0x0400,
	S_DATAREF_V1	= 0x0401,
	S_ALIGN_V1		= 0x0402,
	S_LPROCREF_V1	= 0x0403,

	// Variants with 32bit type indices
	S_REGISTER_V2	= 0x1001,	/// CV_REGISTER_V2
	S_CONSTANT_V2	= 0x1002,	/// CV_CONSTANT_V2
	S_UDT_V2		= 0x1003,	/// CV_UDT_V2
	S_COBOLUDT_V2	= 0x1004,
	S_MANYREG_V2	= 0x1005,
	S_BPREL_V2		= 0x1006,	/// CV_BPREL_V2
	S_LDATA_V2		= 0x1007,	/// CV_DATA_V2
	S_GDATA_V2		= 0x1008,	/// CV_DATA_V2
	S_PUB_V2		= 0x1009,	/// CV_DATA_V2
	S_LPROC_V2		= 0x100A,	/// CV_PROC_V2
	S_GPROC_V2		= 0x100B,	/// CV_PROC_V2
	S_VFTTABLE_V2	= 0x100C,
	S_REGREL_V2		= 0x100D,
	S_LTHREAD_V2	= 0x100E,
	S_GTHREAD_V2	= 0x100F,
	S_FUNCINFO_V2	= 0x1012,
	S_COMPILAND_V2	= 0x1013,	/// CV_COMPILE_V2

	S_COMPILAND_V3	= 0x1101,
	S_THUNK_V3		= 0x1102,
	S_BLOCK_V3		= 0x1103,
	S_LABEL_V3		= 0x1105,
	S_REGISTER_V3	= 0x1106,
	S_CONSTANT_V3	= 0x1107,
	S_UDT_V3		= 0x1108,
	S_BPREL_V3		= 0x110B,
	S_LDATA_V3		= 0x110C,
	S_GDATA_V3		= 0x110D,
	S_PUB_V3		= 0x110E,
	S_LPROC_V3		= 0x110F,
	S_GPROC_V3		= 0x1110,
	S_BPREL_XXXX_V3	= 0x1111,  /* not really understood, but looks like bprel... */
	S_MSTOOL_V3		= 0x1116,  /* compiler command line options and build information */
	S_PUB_FUNC1_V3	= 0x1125,  /* didn't get the difference between the two */
	S_PUB_FUNC2_V3	= 0x1127,
	S_SECTINFO_V3	= 0x1136,
	S_SUBSECTINFO_V3= 0x1137,
	S_ENTRYPOINT_V3	= 0x1138,
	S_SECUCOOKIE_V3	= 0x113A,
	S_MSTOOLINFO_V3	= 0x113C,
	S_MSTOOLENV_V3	= 0x113D
}

/**
 Packed symbols header
*/
struct CV_SYMHASH {
	ushort			symIndex;
	ushort			addrIndex;
	uint			symInfoSize;
	uint			symHashSize;
	uint			addrHashSize;
}

/**
 Symbol variant record
*/
struct CV_SYMBOL {
	OMF_HEADER			header;
	union {
		CV_COMPILE_V1	compile_v1;
		CV_COMPILE_V2	compile_v2;
		CV_REGISTER_V1	register_v1;
		CV_REGISTER_V2	register_v2;
		CV_CONSTANT_V1	constant_v1;
		CV_CONSTANT_V2	constant_v2;
		CV_UDT_V1		udt_v1;
		CV_UDT_V2		udt_v2;
		CV_SSEARCH		ssearch;
		CV_STACK_V1		stack_v1;
		CV_STACK_V2		stack_v2;
		CV_DATA_V1		data_v1;
		CV_DATA_V2		data_v2;
		CV_PROC_V1		proc_v1;
		CV_PROC_V2		proc_v2;
		CV_THUNK		thunk;
		CV_BLOCK		block;
		CV_LABEL		label;
	}
}

/**
 Compiler information symbol
*/
struct CV_COMPILE_V1 {
	ubyte			machine;
	ubyte			language;
	ushort			flags;
	OMF_NAME		name;
}
struct CV_COMPILE_V2 {
	uint[4]			unknown1;
	ushort			unknown2;
	OMF_NAME		name;
}

/**
 Register data symbol
*/
struct CV_REGISTER_V1 {
	ushort			typeIndex;
	ushort			reg;
	OMF_NAME		name;
}
struct CV_REGISTER_V2 {
	uint			typeIndex;
	ushort			reg;
	OMF_NAME		name;
}

/**
 Constant data symbol
*/
struct CV_CONSTANT_V1 {
	ushort			typeIndex;
	ushort			value;
	OMF_NAME		name;
}
struct CV_CONSTANT_V2 {
	uint			typeIndex;
	ushort			value;
	OMF_NAME		name;
}

/**
 User defined type Symbol
*/
struct CV_UDT_V1 {
	ushort			typeIndex;
	OMF_NAME		name;
}
struct CV_UDT_V2 {
	uint			typeIndex;
	OMF_NAME		name;
}

/**
 Start of Search symbol
*/
struct CV_SSEARCH {
	uint			offset;
	ushort			segment;
}

/**
 Object name symbol
*/
struct CV_OBJNAME {
	uint			signature;
	OMF_NAME		name;
}

/**
 Stack data symbol
*/
struct CV_STACK_V1 {
	uint			offset;
	ushort			typeIndex;
	OMF_NAME		name;
}
struct CV_STACK_V2 {
	uint			offset;
	uint			typeIndex;
	OMF_NAME		name;
}

/**
 Data symbol
*/
struct CV_DATA_V1 {
	uint			offset;
	short			segment;
	short			typeIndex;
	OMF_NAME		name;
}
struct CV_DATA_V2 {
	uint			typeIndex;
	uint			offset;
	short			segment;
	OMF_NAME		name;
}

/**
 Procedure symbol
*/
struct CV_PROC_V1 {
	uint			parent;
	uint			end;
	uint			next;
	uint			procLength;
	uint			dbgStart;
	uint			dbgEnd;
	uint			offset;
	ushort			segment;
	ushort			procType;
	ubyte			flags;
	OMF_NAME		name;
}
struct CV_PROC_V2 {
	uint			parent;
	uint			end;
	uint			next;
	uint			procLength;
	uint			dbgStart;
	uint			dbgEnd;
	uint			procType;
	uint			offset;
	ushort			segment;
	ubyte			flags;
	OMF_NAME		name;
}

/**
 Thunk symbol
*/
struct CV_THUNK {
	uint 			parent;
	uint			end;
	uint			next;
	uint			offset;
	ushort			segment;
	ushort			size;
	ubyte			type;
	OMF_NAME		name;
}

/**
 Block symbol
*/
struct CV_BLOCK {
	uint			parent;
	uint			end;
	uint			length;
	uint			offset;
	ushort			segment;
	OMF_NAME		name;
}

/**
 Label symbol
*/
struct CV_LABEL {
	uint			offset;
	ushort			segment;
	ubyte			flags;
	OMF_NAME		name;
}

// ----------------------------------------------------------------------------
// sstSrcModule
// ----------------------------------------------------------------------------

/**
 Source module header
*/
struct CV_SRCMODULE {
	ushort			nFiles;			/// number of CV_SRCFILE records
	ushort			nSegments;		/// number of segments in module
	//uint[]		fileOffsets;
	//uint[2][]		codeOffsets;
	//ushort[]		segmentIds;

	/// array of offsets to every CV_SRCFILE record
	uint[] fileOffsets() const {
		return (cast(uint*)(&nSegments + 1))[0 .. nFiles];
	}

	/// array of segment start/end pairs, length = nSegments
	uint[2][] codeOffsets() const {
		return (cast(uint[2]*)(cast(void*)fileOffsets + nFiles * uint.sizeof))[0 .. nSegments];
	}

	/// array of linker indices, length = nSegments
	ushort[] segmentIds() const {
		return (cast(ushort*)(cast(void*)codeOffsets + nSegments * (uint[2]).sizeof))[0 .. nSegments];
	}
}

/**
 Source file record
*/
struct CV_SRCFILE {
	ushort			nSegments;		/// number of CV_SRCSEGMENT records
	ushort			reserved;
	//uint[]		lineOffsets;
	//uint[2][]		codeOffsets;
	//OMF_NAME		name;

	// array of offsets to every CV_SRCSEGMENT record, length = nSegments
	uint[] lineOffsets() const {
		return (cast(uint*)(&reserved + 1))[0 .. nSegments];
	}

	/// array of segment start/end pairs, length = nSegments
	uint[2][] codeOffsets() const {
		return (cast(uint[2]*)(cast(void*)lineOffsets + nSegments * uint.sizeof))[0 .. nSegments];
	}

	/// name of file padded to long boundary
	OMF_NAME* name() const {
		return cast(OMF_NAME*)(cast(void*)codeOffsets + nSegments * (uint[2]).sizeof);
	}
}

/**
 Source segment record
*/
struct CV_SRCSEGMENT {
	ushort			segment;		/// linker segment index
	ushort			nPairs;			/// count of line/offset pairs
	//uint[]		offsets;
	//ushort[]		lineNumbers;

	/// array of offsets in segment, length = nPairs
	uint[] offsets() const {
		return (cast(uint*)(&nPairs + 1))[0 .. nPairs];
	}

	/// array of line lumber in source, length = nPairs
	ushort[] lineNumbers() const {
		return (cast(ushort*)(cast(void*)offsets + nPairs * uint.sizeof))[0 .. nPairs];
	}
}

// ----------------------------------------------------------------------------
// sstGlobalTypes
// ----------------------------------------------------------------------------

/**
 Basic types

 Official MS documentation says that type (< 0x4000, so 12 bits) is made of:

 +----------+------+------+----------+------+
 |    11    | 10-8 | 7-4  |     3    | 2-0  |
 +----------+------+------+----------+------+
 | reserved | mode | type | reserved | size |
 +----------+------+------+----------+------+
*/

/**
 Basic type: Type bits
*/
enum : ubyte {
	T_SPECIAL_BITS		= 0x00,	/// Special
	T_SIGNED_BITS		= 0x10, /// Signed integral value
	T_UNSIGNED_BITS		= 0x20, /// Unsigned integral value
	T_BOOLEAN_BITS		= 0x30, /// Boolean
	T_REAL_BITS			= 0x40, /// Real
	T_COMPLEX_BITS		= 0x50, /// Complex
	T_SPECIAL2_BITS		= 0x60, /// Special2
	T_INT_BITS			= 0x70, /// Real int value
}

/**
 Basic type: Size bits
*/
enum : ubyte {
	// Special types
	T_NOTYPE_BITS		= 0x00, /// No type
	T_ABS_BITS			= 0x01, /// Absolute symbol
	T_SEGMENT_BITS		= 0x02, /// Segment
	T_VOID_BITS			= 0x03, /// Void
	T_CURRENCY_BITS		= 0x04, /// Basic 8-byte currency value
	T_NBASICSTR_BITS	= 0x05, /// Near Basic string
	T_FBASICSTR_BITS	= 0x06, /// Far Basic string
	T_NOTRANS_BITS		= 0x07, /// Untranslated type from previous Microsoft symbol formats

	// Signed/Unsigned/Boolean types
	T_INT08_BITS		= 0x00, /// 1 byte
	T_INT16_BITS		= 0x01, /// 2 byte
	T_INT32_BITS		= 0x02, /// 4 byte
	T_INT64_BITS		= 0x03, /// 8 byte

	// Real/Complex types
	T_REAL32_BITS		= 0x00, /// 32 bit
	T_REAL64_BITS		= 0x01, /// 64 bit
	T_REAL80_BITS		= 0x02, /// 80 bit
	T_REAL128_BITS		= 0x03, /// 128 bit
	T_REAL48_BITS		= 0x04, /// 48 bit

	// Special2 types
	T_BIT_BITS			= 0x00, /// Bit
	T_PASCHAR_BITS		= 0x01, /// Pascal CHAR

	// Real Int types
	T_CHAR_BITS			= 0x00, /// Char
	T_WCHAR_BITS		= 0x01, /// Wide character
	T_INT2_BITS			= 0x02, /// 2-byte signed integer
	T_UINT2_BITS		= 0x03, /// 2-byte unsigned integer
	T_INT4_BITS			= 0x04, /// 4-byte signed integer
	T_UINT4_BITS		= 0x05, /// 4-byte unsigned integer
	T_INT8_BITS			= 0x06, /// 8-byte signed integer
	T_UINT8_BITS		= 0x07, /// 8-byte unsigned integer
	T_DCHAR_BITS		= 0x08, /// dchar, DigitalMars D extension
}

/**
 Basic type: Mode bits
*/
enum : ushort {
	T_DIRECT_BITS		= 0x0000, /// Direct; not a pointer
	T_NEARPTR_BITS		= 0x0100, /// Near pointer
	T_FARPTR_BITS		= 0x0200, /// Far pointer
	T_HUGEPTR_BITS		= 0x0300, /// Huge pointer
	T_NEAR32PTR_BITS	= 0x0400, /// 32-bit near pointer
	T_FAR32PTR_BITS		= 0x0500, /// 32-bit far pointer
	T_NEAR64PTR_BITS	= 0x0600, /// 64-bit near pointer
}

/**
 Basic type bit masks
*/
enum : ushort {
	T_TYPE_MASK			= 0x00F0, /// type type mask (data treatment mode)
	T_SIZE_MASK			= 0x000F, /// type size mask (depends on 'type' value)
	T_MODE_MASK			= 0x0700, /// type mode mask (ptr/non-ptr)
}

/**
 Leaf types, used by CV_TYPE.header.type
*/
enum : ushort {
	// Can be referenced from symbols
	LF_MODIFIER_V1		= 0x0001,
	LF_POINTER_V1		= 0x0002,
	LF_ARRAY_V1			= 0x0003,
	LF_CLASS_V1			= 0x0004,
	LF_STRUCTURE_V1		= 0x0005,
	LF_UNION_V1			= 0x0006,
	LF_ENUM_V1			= 0x0007,
	LF_PROCEDURE_V1		= 0x0008,
	LF_MFUNCTION_V1		= 0x0009,
	LF_VTSHAPE_V1		= 0x000A,
	LF_COBOL0_V1		= 0x000B,
	LF_COBOL1_V1		= 0x000C,
	LF_BARRAY_V1		= 0x000D,
	LF_LABEL_V1			= 0x000E,
	LF_NULL_V1			= 0x000F,
	LF_NOTTRAN_V1		= 0x0010,
	LF_DIMARRAY_V1		= 0x0011,
	LF_VFTPATH_V1		= 0x0012,
	LF_PRECOMP_V1		= 0x0013,
	LF_ENDPRECOMP_V1	= 0x0014,
	LF_OEM_V1			= 0x0015,
	LF_TYPESERVER_V1	= 0x0016,

	LF_MODIFIER_V2		= 0x1001,
	LF_POINTER_V2		= 0x1002,
	LF_ARRAY_V2			= 0x1003,
	LF_CLASS_V2			= 0x1004,
	LF_STRUCTURE_V2		= 0x1005,
	LF_UNION_V2			= 0x1006,
	LF_ENUM_V2			= 0x1007,
	LF_PROCEDURE_V2		= 0x1008,
	LF_MFUNCTION_V2		= 0x1009,
	LF_COBOL0_V2		= 0x100A,
	LF_BARRAY_V2		= 0x100B,
	LF_DIMARRAY_V2		= 0x100C,
	LF_VFTPATH_V2		= 0x100D,
	LF_PRECOMP_V2		= 0x100E,
	LF_OEM_V2			= 0x100F,

	// Can be referenced from other type records
	LF_SKIP_V1			= 0x0200,
	LF_ARGLIST_V1		= 0x0201,
	LF_DEFARG_V1		= 0x0202,
	LF_LIST_V1			= 0x0203,
	LF_FIELDLIST_V1		= 0x0204,
	LF_DERIVED_V1		= 0x0205,
	LF_BITFIELD_V1		= 0x0206,
	LF_METHODLIST_V1	= 0x0207,
	LF_DIMCONU_V1		= 0x0208,
	LF_DIMCONLU_V1		= 0x0209,
	LF_DIMVARU_V1		= 0x020A,
	LF_DIMVARLU_V1		= 0x020B,
	LF_REFSYM_V1		= 0x020C,

	LF_SKIP_V2			= 0x1200,
	LF_ARGLIST_V2		= 0x1201,
	LF_DEFARG_V2		= 0x1202,
	LF_FIELDLIST_V2		= 0x1203,
	LF_DERIVED_V2		= 0x1204,
	LF_BITFIELD_V2		= 0x1205,
	LF_METHODLIST_V2	= 0x1206,
	LF_DIMCONU_V2		= 0x1207,
	LF_DIMCONLU_V2		= 0x1208,
	LF_DIMVARU_V2		= 0x1209,
	LF_DIMVARLU_V2		= 0x120A,

	// Field lists
	LF_BCLASS_V1		= 0x0400,
	LF_VBCLASS_V1		= 0x0401,
	LF_IVBCLASS_V1		= 0x0402,
	LF_ENUMERATE_V1		= 0x0403,
	LF_FRIENDFCN_V1		= 0x0404,
	LF_INDEX_V1			= 0x0405,
	LF_MEMBER_V1		= 0x0406,
	LF_STMEMBER_V1		= 0x0407,
	LF_METHOD_V1		= 0x0408,
	LF_NESTTYPE_V1		= 0x0409,
	LF_VFUNCTAB_V1		= 0x040A,
	LF_FRIENDCLS_V1		= 0x040B,
	LF_ONEMETHOD_V1		= 0x040C,
	LF_VFUNCOFF_V1		= 0x040D,
	LF_NESTTYPEEX_V1	= 0x040E,
	LF_MEMBERMODIFY_V1	= 0x040F,

	LF_BCLASS_V2		= 0x1400,
	LF_VBCLASS_V2		= 0x1401,
	LF_IVBCLASS_V2		= 0x1402,
	LF_FRIENDFCN_V2		= 0x1403,
	LF_INDEX_V2			= 0x1404,
	LF_MEMBER_V2		= 0x1405,
	LF_STMEMBER_V2		= 0x1406,
	LF_METHOD_V2		= 0x1407,
	LF_NESTTYPE_V2		= 0x1408,
	LF_VFUNCTAB_V2		= 0x1409,
	LF_FRIENDCLS_V2		= 0x140A,
	LF_ONEMETHOD_V2		= 0x140B,
	LF_VFUNCOFF_V2		= 0x140C,
	LF_NESTTYPEEX_V2	= 0x140D,

	LF_ENUMERATE_V3		= 0x1502,
	LF_ARRAY_V3			= 0x1503,
	LF_CLASS_V3			= 0x1504,
	LF_STRUCTURE_V3		= 0x1505,
	LF_UNION_V3			= 0x1506,
	LF_ENUM_V3			= 0x1507,
	LF_MEMBER_V3		= 0x150D,
	LF_STMEMBER_V3		= 0x150E,
	LF_METHOD_V3		= 0x150F,
	LF_NESTTYPE_V3		= 0x1510,
	LF_ONEMETHOD_V3		= 0x1511,

	// Numeric leaf types
	LF_NUMERIC			= 0x8000,
	LF_CHAR				= 0x8000,
	LF_SHORT			= 0x8001,
	LF_USHORT			= 0x8002,
	LF_LONG				= 0x8003,
	LF_ULONG			= 0x8004,
	LF_REAL32			= 0x8005,
	LF_REAL64			= 0x8006,
	LF_REAL80			= 0x8007,
	LF_REAL128			= 0x8008,
	LF_QUADWORD			= 0x8009,
	LF_UQUADWORD		= 0x800A,
	LF_REAL48			= 0x800B,
	LF_COMPLEX32		= 0x800C,
	LF_COMPLEX64		= 0x800D,
	LF_COMPLEX80		= 0x800E,
	LF_COMPLEX128		= 0x800F,
	LF_VARSTRING		= 0x8010,
	LF_DCHAR			= 0x8011
}

/**
 Global types header
*/
struct CV_GLOBALTYPES {
	ubyte[3]		unused;
	ubyte			flags;
	uint			nTypes;
	//uint[1]		typeOffsets;
	//CV_TYPE[1]	types;

	/// array of offsets to CV_TYPE records
	uint* typeOffsets() const {
		return cast(uint*)(&nTypes + 1);
	}

	// Get the first CV_TYPE record
	CV_TYPE* types() const {
		return cast(CV_TYPE*)(cast(void*)(&nTypes + 1) + nTypes * uint.sizeof);
	}
}

/**
 Type variant record
*/
struct CV_TYPE {
	OMF_HEADER			header;
	union {
		// Types
		CV_MODIFIER_V1	modifier_v1;
		CV_MODIFIER_V2	modifier_v2;
		CV_POINTER_V1	pointer_v1;
		CV_POINTER_V2	pointer_v2;
		CV_ARRAY_V1		array_v1;
		CV_ARRAY_V2		array_v2;
		CV_STRUCT_V1	struct_v1;
		CV_STRUCT_V2	struct_v2;
		CV_UNION_V1		union_v1;
		CV_UNION_V2		union_v2;
		CV_ENUM_V1		enum_v1;
		CV_ENUM_V2		enum_v2;
		CV_PROCEDURE_V1	proc_v1;
		CV_PROCEDURE_V2	proc_v2;
		CV_MFUNCTION_V1	method_v1;
		CV_MFUNCTION_V2	method_v2;
		CV_OEM_V1		oem_v1;
		CV_OEM_V2		oem_v2;

		// Referenced types
		CV_FIELDLIST	fieldlist;
		CV_BITFIELD_V1	bitfield_v1;
		CV_BITFIELD_V2	bitfield_v2;
		CV_ARGLIST_V1	arglist_v1;
		CV_ARGLIST_V2	arglist_v2;
		CV_DERIVED_V1	derived_v1;
		CV_DERIVED_V2	derived_v2;

		// Field types
	}
}

/**
 Modifier type
*/
struct CV_MODIFIER_V1 {
	ushort			attribute;
	ushort			type;
}
struct CV_MODIFIER_V2 {
	uint			type;
	ushort			attribute;
}

/**
 Pointer type
*/
struct CV_POINTER_V1 {
	ushort			attribute;
	ushort			type;
	OMF_NAME		name;
}
struct CV_POINTER_V2 {
	uint			type;
	uint			attribute;
	OMF_NAME		name;
}

/**
 Array type
*/
struct CV_ARRAY_V1 {
	ushort			elemType;
	ushort			indexType;
	ushort			length;		/// numeric leaf
	OMF_NAME		name;
}
struct CV_ARRAY_V2 {
	uint			elemType;
	uint			indexType;
	ushort			length;		/// numeric leaf
	OMF_NAME		name;
}

/**
 Struct type
*/
struct CV_STRUCT_V1 {
	ushort			nElement;
	ushort			fieldlist;
	ushort			property;
	ushort			derived;
	ushort			vshape;
	ushort			length;		/// numeric leaf
	OMF_NAME		name;
}
struct CV_STRUCT_V2 {
	ushort			nElement;
	ushort			property;
	uint			fieldlist;
	uint			derived;
	uint			vshape;
	ushort			length;		/// numeric leaf
	OMF_NAME		name;
}

/**
 Union type
*/
struct CV_UNION_V1 {
	ushort			count;
	ushort			fieldlist;
	ushort			property;
	ushort			length;		/// numeric leaf
	OMF_NAME		name;
}
struct CV_UNION_V2 {
	ushort			count;
	ushort			property;
	uint			fieldlist;
	ushort			length;		/// numeric leaf
	OMF_NAME		name;
}

/**
 Enumeration type
*/
struct CV_ENUM_V1 {
	ushort			length;
	ushort			id;
	ushort			count;
	ushort			type;
	ushort			fieldlist;
	ushort			property;
	OMF_NAME		p_name;
}
struct CV_ENUM_V2 {
	ushort			length;
	ushort			id;
	ushort			count;
	ushort			property;
	uint			type;
	uint			fieldlist;
	OMF_NAME		p_name;
}

/**
 Procedure type
*/
struct CV_PROCEDURE_V1 {
	ushort			retType;
	ubyte			call;
	ubyte			reserved;
	ushort			nParams;
	ushort			argList;
}
struct CV_PROCEDURE_V2 {
	uint			retType;
	ubyte			call;
	ubyte			reserved;
	ushort			nParams;
	uint			argList;
}

/**
 Method type
*/
struct CV_MFUNCTION_V1 {
	ushort			retType;
	ushort			classType;
	ushort			thisType;
	ubyte			call;
	ubyte			reserved;
	ushort			nParams;
	ushort			arglist;
	uint			thisAdjust;
}
struct CV_MFUNCTION_V2 {
	uint			retType;
	uint			classType;
	uint			thisType;
	ubyte			call;
	ubyte			reserved;
	ushort			nParams;
	uint			arglist;
	uint			thisAdjust;
}

/**
 OEM type
*/
struct CV_OEM_V1 {
	ushort			oem;
	ushort			rec;
	ushort			nIndices;
	//ushort[1]		indices;

	ushort* indices() const {
		return cast(ushort*)(&nIndices + 1);
	}
}
struct CV_OEM_V2 {
	// UNKNOWN!
}

enum {
	OEM_DIGITALMARS	= 0x0042,
	D_DYN_ARRAY		= 0x0001,
	D_ASSOC_ARRAY	= 0x0002,
	D_DELEGATE		= 0x0003
}

struct CV_D_DYNARRAY {
	ushort			indexType;
	ushort			elemType;
}

struct CV_D_ASSOCARRAY {
	ushort			keyType;
	ushort			elemType;
}

struct CV_D_DELEGATE {
	ushort			thisType;
	ushort			funcType;
}

/**
 Field list
*/
struct CV_FIELDLIST {
	ubyte[1]		list;
}

/**
 Bit field
*/
struct CV_BITFIELD_V1 {
	ubyte			nBits;
	ubyte			bitOffset;
	ushort			type;
}
struct CV_BITFIELD_V2 {
	uint			type;
	ubyte			nBits;
	ubyte			bitOffset;
}

/**
 Arguments list
*/
struct CV_ARGLIST_V1 {
	ushort			count;
	ushort[1]		args;
}
struct CV_ARGLIST_V2 {
	uint			count;
	uint[1]			args;
}

/**
 Derived
*/
struct CV_DERIVED_V1 {
	ushort			count;
	ushort[1]		derivedClasses;
}
struct CV_DERIVED_V2 {
	uint			count;
	uint[1]			derivedClasses;
}

/**
 Class type
*/
struct CV_CLASS_V1 {
	ushort			type;
	ushort			attribute;
	ushort			offset;		/// numeric leaf
}
struct CV_CLASS_V2 {
	ushort			attribute;
	uint			type;
	ushort			offset;		/// numeric leaf
}

struct CvTypeClass {
	ushort			count;
	ushort			fieldList;
	ushort			flags;
	ushort			dList;
	ushort			vShape;
	// length
	// name
}

// ----------------------------------------------------------------------------
// sstSegMap
// ----------------------------------------------------------------------------

struct CV_SEGMAP {
	ushort				total;
	ushort				logical;
	//CV_SEGMAPDESC[1]	descriptors;

	CV_SEGMAPDESC* descriptors() const {
		return cast(CV_SEGMAPDESC*)(&logical + 1);
	}
}

struct CV_SEGMAPDESC {
	ushort	flags;
	ushort	overlay;
	ushort	group;
	ushort	frame;
	ushort	name;
	ushort	className;
	uint	offset;
	uint	size;
}

// ----------------------------------------------------------------------------
// sstPreCompMap
// ----------------------------------------------------------------------------

struct OMFPreCompMap {
	ushort			FirstType;		// first precompiled type index
	ushort			cTypes;			// number of precompiled types
	uint			signature;		// precompiled types signature
	ushort			padding;
	//CV_typ_t[]	map;			// mapping of precompiled types
}

// ----------------------------------------------------------------------------
// sstOffsetMap16, sstOffsetMap32
// ----------------------------------------------------------------------------

struct OMFOffsetMap16 {
	uint			csegment;	// Count of physical segments

    // The next six items are repeated for each segment

    //uint			crangeLog;	// Count of logical offset ranges
    //ushort[]		rgoffLog;	// Array of logical offsets
    //short[]		rgbiasLog;	// Array of logical->physical bias
    //uint			crangePhys;	// Count of physical offset ranges
    //ushort[]		rgoffPhys;	// Array of physical offsets
    //short[]		rgbiasPhys;	// Array of physical->logical bias
}

struct OMFOffsetMap32 {
	uint			csection;	// Count of physical sections

    // The next six items are repeated for each section

    //uint			crangeLog;	// Count of logical offset ranges
    //uint[]		rgoffLog;	// Array of logical offsets
    //int[]			rgbiasLog;	// Array of logical->physical bias
    //uint			crangePhys;	// Count of physical offset ranges
    //uint[]		rgoffPhys;	// Array of physical offsets
    //int[]			rgbiasPhys;	// Array of physical->logical bias
}

// ----------------------------------------------------------------------------
// sstFileIndex
// ----------------------------------------------------------------------------

struct OMFFileIndex {
	ushort			cmodules;	// Number of modules
	ushort			cfilerefs;	// Number of file references
	//ushort[]		modulelist;	// Index to beginning of list of files
								// for module i. (0 for module w/o files)
	//ushort[]		cfiles;		// Number of file names associated
								// with module i.
	//uint[]		ulNames;	// Offsets from the beginning of this
								// table to the file names
	//char[]		Names;		// The length prefixed names of files
}

struct OMFMpcDebugInfo {
	ushort			cSeg;		// number of segments in module
	//ushort[]		mpSegFrame;	// map seg (zero based) to frame
}







// Procedure flags
enum {
	PROC_FPO		= 1 << 0, // Frame pointer omitted
	PROC_INTERRUPT	= 1 << 1, // Interrupt
	PROC_RETURN		= 1 << 2, // Far return
	PROC_NEVER		= 1 << 3, // Never returns
}

// Procedure calling conventions
enum {
	CALL_C_NEAR			= 0x00,
	CALL_C_FAR			= 0x01,
	CALL_PASCAL_NEAR	= 0x02,
	CALL_PASCAL_FAR		= 0x03,
	CALL_FASTCALL_NEAR	= 0x04,
	CALL_FASTCALL_FAR	= 0x05,
	CALL_STDCALL_NEAR	= 0x07,
	CALL_STDCALL_FAR	= 0x08,
	CALL_SYSCALL_NEAR	= 0x09,
	CALL_SYSCALL_FAR	= 0x10,
	CALL_THIS			= 0x11,
	CALL_MIPS			= 0x12,
	CALL_GENERIC		= 0x13
}

enum {
	STRUCT_PACKED		= 1 << 0,
	STRUCT_CTOR			= 1 << 1,
	STRUCT_OVERLOADS	= 1 << 2,
	STRUCT_IS_NESTED	= 1 << 3,
	STRUCT_HAS_NESTED	= 1 << 4,
	STRUCT_OPASSIGN		= 1 << 5,
	STRUCT_OPCAST		= 1 << 6,
	STRUCT_FWDREF		= 1 << 7,
	STRUCT_SCOPED		= 1 << 8
}
