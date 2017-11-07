module dmd.backend.Util;

import dmd.common;
import dmd.Array;
import dmd.Loc;

import dmd.backend.elem;
import dmd.backend.Symbol;
import dmd.backend.TYPE;
import dmd.backend.SC;
import dmd.backend.dt_t;
import dmd.backend.LIST;
import dmd.backend.block;
import dmd.backend.targ_types;
import dmd.backend.SYMIDX;
import dmd.backend.PARAM;
import dmd.backend.Blockx;
import dmd.backend.struct_t;
import dmd.backend.BC;
import dmd.backend.code;

import std.string;
import core.stdc.stdlib;
import core.stdc.string;
import core.memory;

alias ubyte mangle_t;

alias SC enum_SC;
alias uint SYMFLGS;

version (MARS) {
	enum SYM_PREDEF_SZ = 35;
} else {
	enum SYM_PREDEF_SZ = 22;
}

alias size_t tym_t;		// data type big enough for type masks
//alias ulong tym_t;		// data type big enough for type masks
alias elem* elem_p;		// data type big enough for type masks

void el_setLoc(elem* e, Loc loc) {
   size_t len = loc.filename.length;
   e.Esrcpos.Sfilename = cast(char*)GC.malloc(len + 1);
   memcpy(e.Esrcpos.Sfilename, loc.filename.ptr, len);
   e.Esrcpos.Sfilename[len] = 0;
	e.Esrcpos.Slinnum = loc.linnum;
}

void elem_setLoc(elem* e, Loc loc) {
	return el_setLoc(e, loc);
}

struct_t* struct_calloc() {
	return cast(struct_t *) mem_fcalloc(struct_t.sizeof);
}
///#define struct_free(st)	((void)(st))

version (Bug4059)
{
	private extern (C) {
		void _Z12obj_initfilePKcS0_S0_(const(char)* filename, const(char)* csegname, const(char)* modname);
		elem_p _Z6el_binjmP4elemS0_(uint, tym_t, elem_p, elem_p);
		elem_p _Z7el_pairmP4elemS0_(tym_t, elem_p, elem_p);
		elem_p _Z10el_combineP4elemS0_(elem_p, elem_p);
		elem* _Z8el_paramP4elemS0_(elem* e1, elem* e2);
		Symbol* _Z13symbol_callocPKc(const(char)* id);
		int _Z9objextdefPKc(const(char)* name);
		void _Z14obj_includelibPKc(const(char)* name);
		Symbol* _Z11symbol_namePKciP4TYPE(const(char)* name, int sclass, type* t);
		dt_t ** _Z8dtnbytesPP4dt_tmPKc(dt_t** pdtend, targ_size_t size, const(char)* ptr);
		dt_t** _Z8dtabytesPP4dt_tmmmPKc(dt_t** pdtend, tym_t ty, targ_size_t offset, targ_size_t size, const(char)* ptr);
		type* _Z10type_settyPP4TYPEl(type**, long);

		void _Z10cod3_thunkP6SymbolS0_jmmim(Symbol* sthunk, Symbol* sfunc, uint p, tym_t thisty, targ_size_t d, int i, targ_size_t d2);
	}
	void obj_initfile(const(char)* filename, const(char)* csegname, const(char)* modname) { return _Z12obj_initfilePKcS0_S0_(filename, csegname, modname); }
	elem_p el_bin(uint a, tym_t b, elem_p c, elem_p d) { return _Z6el_binjmP4elemS0_(a, b, c, d);  }
	elem_p el_pair(tym_t a, elem_p b, elem_p c) { return _Z7el_pairmP4elemS0_(a, b, c); }
	elem_p el_combine(elem_p a, elem_p b) { return _Z10el_combineP4elemS0_(a, b); }
	elem* el_param(elem* e1, elem* e2) { return _Z8el_paramP4elemS0_(e1, e2); }
	Symbol* symbol_calloc(const(char)* id) { return _Z13symbol_callocPKc(id); }
	int objextdef(const(char)* name) { return _Z9objextdefPKc(name); }
	void obj_includelib(const(char)* name) { return _Z14obj_includelibPKc(name); }
	Symbol* symbol_name(const(char)* name, int sclass, type* t) { return _Z11symbol_namePKciP4TYPE(name, sclass, t); }
	dt_t ** dtnbytes(dt_t** pdtend, targ_size_t size, const(char)* ptr) { return _Z8dtnbytesPP4dt_tmPKc(pdtend, size, ptr); }
	dt_t** dtabytes(dt_t** pdtend, tym_t ty, targ_size_t offset, targ_size_t size, const(char)* ptr) { return _Z8dtabytesPP4dt_tmmmPKc(pdtend, ty, offset, size, ptr); }
	type* type_setty(type** a, long b) { return _Z10type_settyPP4TYPEl(a, b); }

	void cod3_thunk(Symbol* sthunk, Symbol* sfunc, uint p, tym_t thisty, targ_size_t d, int i, targ_size_t d2) { return _Z10cod3_thunkP6SymbolS0_jmmim(sthunk, sfunc, p, thisty, d, i, d2); }
}
else
{
	extern (C++) {
		void obj_initfile(const(char)* filename, const(char)* csegname, const(char)* modname);
		dt_t ** dtnbytes(dt_t** pdtend, targ_size_t size, const(char)* ptr);
		elem_p el_bin(uint, tym_t, elem_p, elem_p);
		elem_p el_pair(tym_t, elem_p, elem_p);
		elem_p el_combine(elem_p, elem_p);
		elem* el_param(elem* e1, elem* e2);
		Symbol* symbol_calloc(const(char)* id);
		int objextdef(const(char)* name);
		void obj_includelib(const(char)* name);
		Symbol* symbol_name(const(char)* name, int sclass, type* t);
		dt_t** dtabytes(dt_t** pdtend, tym_t ty, targ_size_t offset, targ_size_t size, const(char)* ptr);
		type* type_setty(type**, int);

		void cod3_thunk(Symbol* sthunk, Symbol* sfunc, uint p, tym_t thisty, targ_size_t d, int i, targ_size_t d2);
	}
}

extern (C) {
    void code_term();
}

extern (C++) {
//__gshared:
	void obj_ehsections();
	void obj_staticdtor(Symbol *s);
	void* mem_fcalloc(uint numbytes);
	type* type_fake(tym_t);
	dt_t** dtnzeros(dt_t** pdtend, targ_size_t size);
	void outdata(Symbol* s);
	int reftoident(int seg, targ_size_t offset, Symbol* s, targ_size_t val, int flags);
	type* type_alloc(tym_t ty);
	elem_p el_params(elem_p, ...);
	elem_p el_ptr(Symbol*);
	elem_p el_long(tym_t, targ_long);
	elem_p el_var(Symbol*);
	block* block_calloc();
	void writefunc(Symbol* sfunc);
	void obj_termfile();
	SYMIDX symbol_add(Symbol* s);
	elem_p el_una(uint op, tym_t ty, elem_p e1);
	type* type_setcv(type** pt, tym_t cv);
	int type_jparam(type* t);
	void obj_export(Symbol* s, uint argsize);
	void obj_startaddress(Symbol* s);
	void symbol_func(Symbol* s);
	type* type_allocn(tym_t, type* tn);
	param_t* param_append_type(param_t** pp, type* t);
	void block_appendexp(block* b, elem* e);
	void block_next(Blockx* bctx, BC bc, block* bn);
	dt_t** dtxoff(dt_t** pdtend, Symbol* s,targ_size_t offset, tym_t ty);
	dt_t** dtdword(dt_t** pdtend, int value);
	void obj_moduleinfo(Symbol* scc);
	Symbol* symbol_genauto(TYPE* t);
	elem* el_same(elem**);
	void el_free(elem*);
	Symbol* symbol_generate(int sclass, type* t);
	elem* el_calloc();
	void dt_optimize(dt_t* dt);
	type* type_setmangle(type** pt, mangle_t mangle);
	list_t list_append(list_t* plist, void* ptr);
	dt_t** dtcat(dt_t** pdtend, dt_t* dt);
	elem_p el_copytree(elem_p);
	int el_allbits(elem *e, int bit);
	block* block_goto(Blockx* bctx, BC bc, block* bn);
//	block* block_calloc(Blockx* blx);
	targ_size_t type_paramsize_i(type* t);
	int os_critsecsize();
	void el_setVolatile(elem* e);
	elem* exp2_copytotemp(elem* e);
	elem* el_const(tym_t, eve*);
	elem *el_params(void** args, int length);

	/****************************************
	 * Allocate a new block, and set the tryblock.
	 */
	block *block_calloc(Blockx *blx)
	{
		block* b = block_calloc();
		b.Btry = blx.tryblock;
		return b;
	}

	version (SEH) {
		void nteh_declarvars(Blockx* bx);
		elem* nteh_setScopeTableIndex(Blockx* blx, int scope_index);
	}
}
