module dmd.Global;

import dmd.common;
import dmd.Array;
import dmd.Param;
import dmd.ClassDeclaration;
import dmd.DsymbolTable;
import dmd.StringTable;
import dmd.OutBuffer;
import dmd.Token;
import dmd.Scope;
import dmd.Module;
import dmd.Expression;
import dmd.Dsymbol;
import dmd.Type;
import dmd.TypeInfoDeclaration;
import dmd.Id;
import dmd.TY;
import dmd.LINK;
import dmd.MOD;
import dmd.Loc;
import dmd.TOK;
import dmd.TypeFunction;
import dmd.GlobalExpressions : initGlobalExpressions;

import dmd.codegen.Util;
import dmd.backend.elem;
import dmd.backend.Classsym;
import dmd.backend.Symbol;
import dmd.backend.glue;
import dmd.backend.iasm;
import dmd.backend.StringTab;

import core.stdc.time;
import core.stdc.stdio;

import dmd.TObject;

class Global : TObject
{
    string mars_ext = "d";
    string sym_ext	= "d";

version (TARGET_WINDOS) {
    string obj_ext = "obj";
} else version (POSIX) {	// TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
    string obj_ext = "o";
} else version (TARGET_NET) {
} else {
	static assert (false);
}

version (TARGET_WINDOS) {
    string lib_ext = "lib";
} else version (POSIX) {	// TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
	string lib_ext = "a";
} else version (TARGET_NET) {
} else {
	static assert (false);
}
    string doc_ext	= "html";	// for Ddoc generated files
    string ddoc_ext	= "ddoc";	// for Ddoc macro include files
    string json_ext = "json";
    string map_ext = "map";	// for .map files
    string hdr_ext	= "di";	// for D 'header' import files
    string copyright= "Copyright (c) 1999-2009 by Digital Mars";
    string written	= "written by Walter Bright, ported to D by community";
///version (TARGET_NET) {
///    "\nMSIL back-end (alpha release) by Cristian L. Vlasceanu and associates.";
///}

    string[] path;	// Array of char*'s which form the import lookup path
    string[] filePath;	// Array of char*'s which form the file import lookup path
    int structalign = 8;
    string version_ = "v2.040";

    Param params;
    uint errors;	// number of errors reported so far
    uint gag;	// !=0 means gag reporting of errors

	ClassDeclaration object;
    ClassDeclaration classinfo;

	// Used in FuncDeclaration.genCfunc()
	DsymbolTable st;

	// Used in Lexer.uniqueId()
	int num;

	// Used in Identifier.generateId()
	size_t i;

	// Used in Lexer
	StringTable stringtable;
    OutBuffer stringbuffer;
    Token* freelist;

	char[11+1] date;
	char[8+1] time;
	char[24+1] timestamp;

	// Used in Module
	Module rootModule;
    DsymbolTable modules;	// symbol table of all modules
    Array amodules;		// array of all modules
    Array deferred;	// deferred Dsymbol's needing semantic() run on them
    uint dprogress;	// progress resolving the deferred list
	int nested;
	Classsym* scc;
	ClassDeclaration moduleinfo;

	// Used in PowExp
	bool importMathChecked = false;

	// Used in Scope
	Scope scope_freelist;

	// Used in TemplateMixin
	int nest;

	// Used in Type
	StringTable type_stringtable;

	Type tvoidptr;		// void*
    Type tstring;		// immutable(char)[]

	ClassDeclaration typeinfo;
    ClassDeclaration typeinfoclass;
    ClassDeclaration typeinfointerface;
    ClassDeclaration typeinfostruct;
    ClassDeclaration typeinfotypedef;
    ClassDeclaration typeinfopointer;
    ClassDeclaration typeinfoarray;
    ClassDeclaration typeinfostaticarray;
    ClassDeclaration typeinfoassociativearray;
    ClassDeclaration typeinfoenum;
    ClassDeclaration typeinfofunction;
    ClassDeclaration typeinfodelegate;
    ClassDeclaration typeinfotypelist;
    ClassDeclaration typeinfoconst;
    ClassDeclaration typeinfoinvariant;
    ClassDeclaration typeinfoshared;
    ClassDeclaration typeinfowild;

	Type[TY.TMAX] basic;
	TypeInfoDeclaration[TMAX] internalTI;

	// Used in BinExp
	StringTable arrayfuncs;

	// Used in FuncDeclaration
	int hiddenparami;    // how many we've generated so far

	// Used in TypeAArray
	// Dumb linear symbol table - should use associative array!
	Array sarray;
	Symbol* AArray_s;

	// Used in TypeDelegate
	Symbol* Delegate_s;

	// Used in TypeInfoStructDeclaration
	TypeFunction tftohash;
	TypeFunction tftostring;

	// Used in backend.glue
	Array obj_symbols_towrite;
	Outbuffer objbuf;
	string lastmname;
	int count;
	elem* esharedctor;
	Array esharedctorgates;
	elem* eshareddtor;
	int shareddtorcount;

	// Used in backend.iasm
	ASM_STATE asmstate;
	Token* asmtok;
	TOK tok_value;

	// Used in backend.StringTab
	StringTab[STSIZE] stringTab;
	size_t stidx;

	// Used in backend.Util
	elem* eictor;
	Symbol* ictorlocalgot;
	elem* ector;
	Array ectorgates;
	elem* edtor;
	elem* etest;
	int dtorcount;
	Symbol* localgot;

    Dsymbol sdummy;
	Expression edummy;

	this()
	{
	    register();

	    initGlobalExpressions();

		params.versionids = new Vector!(string)();
		params.imppath = new Array();

		st = new DsymbolTable();
		stringbuffer = new OutBuffer();

		modules = new DsymbolTable();
		amodules = new Array();
		deferred = new Array();

		sarray = new Array();

		obj_symbols_towrite = new Array();

		ectorgates = new Array();
		esharedctorgates = new Array();

		sdummy = new Dsymbol();
		edummy = new Expression(Loc(0), TOK.init, 0);

		init_time();
	}

	void initClasssym()
	{
		scc = fake_classsym(Id.ClassInfo);

		scope Scope sc = new Scope();

		tftohash = new TypeFunction(null, Type.thash_t, 0, LINK.LINKd);
		tftohash.mod = MOD.MODconst;
		tftohash = cast(TypeFunction)tftohash.semantic(Loc(0), sc);

		tftostring = new TypeFunction(null, Type.tchar.invariantOf().arrayOf(), 0, LINK.LINKd);
		tftostring = cast(TypeFunction)tftostring.semantic(Loc(0), sc);
	}

	void init_time()
	{
		time_t tm;
		char* p;

		.time(&tm);
		p = ctime(&tm);
		assert(p);
		sprintf(date.ptr, "%.6s %.4s", p + 4, p + 20);
		sprintf(time.ptr, "%.8s", p + 11);
		sprintf(timestamp.ptr, "%.24s", p);
	}
}

__gshared Global global;
