struct Symbol;
struct dt_t;
struct TYPE;
struct elem;
struct Blockx;
struct block;
enum BC {};

typedef TYPE type;

int reftoident(int a, unsigned long b, Symbol* c, unsigned long d, int e);

int reftoident(int a, unsigned int b, Symbol* c, unsigned int d, int e)
{
	return reftoident(a, (unsigned long)b, c, (unsigned long)d, e);
}

dt_t** dtnzeros(dt_t**, unsigned long);

dt_t** dtnzeros(dt_t** a, unsigned int b)
{
	return dtnzeros(a, (unsigned long)b);
}

TYPE* type_fake(unsigned long a);

TYPE* type_fake(unsigned int a)
{
	return type_fake((unsigned long)a);
}

elem* el_long(unsigned long a, long long b);

elem* el_long(unsigned int a, long long b)
{
	return el_long((unsigned long)a, b);
}

type* type_alloc(unsigned long a);

type* type_alloc(unsigned int a)
{
	return type_alloc((unsigned long)a);
}

elem* el_bin(unsigned int a, unsigned long b, elem* c, elem* d);

elem* el_bin(unsigned int a, unsigned int b, elem* c, elem* d)
{
	return el_bin(a, (unsigned long)b, c, d);
}

dt_t** dtnbytes(dt_t** a, unsigned long b, const char* c);

dt_t** dtnbytes(dt_t** a, unsigned int b, const char* c)
{
	return dtnbytes(a, (unsigned long)b, c);
}

extern unsigned char tytab[];
unsigned char* get_tytab()
{
	return tytab;
}

extern unsigned char tytab2[];
unsigned char* get_tytab2()
{
	return tytab2;
}

extern signed char tysize[];
signed char* get_tysize()
{
	return tysize;
}

type* type_setcv(type** pt, unsigned long cv);

type* type_setcv(type** pt, unsigned int cv)
{
	return type_setcv(pt, (unsigned long) cv);
}

elem* el_una(unsigned int op, unsigned long ty, elem* e1);

elem* el_una(unsigned int op, unsigned int ty, elem* e1)
{
	return el_una(op, (unsigned long) ty, e1);
}

type* type_allocn(unsigned long a, type* b);

type* type_allocn(unsigned int a, type* b)
{
	return type_allocn((unsigned long)a, b);
}

void block_next(Blockx* bctx, enum BC bc, block* bn);

void block_next(Blockx* bctx, int bc, block* bn)
{
	block_next(bctx, (enum BC)bc, bn);
}

block* block_goto(Blockx* bctx, enum BC bc, block* bn);

block* block_goto(Blockx* bctx, int bc, block* bn)
{
	return block_goto(bctx, (enum BC)bc, bn);
}

dt_t** dtxoff(dt_t** pdtend, Symbol* s, unsigned long offset, unsigned long ty);

dt_t** dtxoff(dt_t** pdtend, Symbol* s, unsigned int offset, unsigned int ty)
{
	return dtxoff(pdtend, s, (unsigned long)offset, (unsigned long)ty);
}

dt_t** dtabytes(dt_t** pdtend,  unsigned long ty, unsigned long offset, unsigned long size, const char* ptr);

dt_t** dtabytes(dt_t** pdtend,  unsigned int ty, unsigned int offset, unsigned int size, const char* ptr)
{
	return dtabytes(pdtend,  (unsigned long)ty, (unsigned long)offset, (unsigned long)size, ptr);
}

dt_t** dtdword(dt_t** pdtend, long value);

dt_t** dtdword(dt_t** pdtend, int value)
{
	return dtdword(pdtend, (long)value);
}

type* type_setty(type** a, long b);

type* type_setty(type** a, int b)
{
	return type_setty(a, (long)b);
}

elem* el_pair(unsigned long a, elem* b, elem* c);

elem* el_pair(unsigned int a, elem* b, elem* c)
{
	return el_pair((unsigned long)a, b, c);
}

extern unsigned char rel_not[];
extern unsigned char rel_swap[];
extern unsigned char rel_integral[];
extern unsigned char rel_exception[];
extern unsigned char rel_unord[];

unsigned char* get_rel_not() { return rel_not; }
unsigned char* get_rel_swap() { return rel_swap; }
unsigned char* get_rel_integral() { return rel_integral; }
unsigned char* get_rel_exception() { return rel_exception; }
unsigned char* get_rel_unord() { return rel_unord; }

unsigned long type_paramsize(type* t);
unsigned int type_paramsize_i(type* t)
{
	return (unsigned int)type_paramsize(t);
}

void cod3_thunk(Symbol* sthunk, Symbol* sfunc, unsigned int p, unsigned long thisty, unsigned long d, int i, unsigned long d2);
void cod3_thunk(Symbol* sthunk, Symbol* sfunc, unsigned int p, unsigned int  thisty, unsigned int  d, int i, unsigned int  d2)
{
	return cod3_thunk(sthunk, sfunc, p, (unsigned long)thisty, (unsigned long)d, i, (unsigned long)d2);
}

elem* el_const(unsigned long a, union eve* b);
elem* el_const(unsigned int a, union eve* b)
{
	return el_const((unsigned long)a, b);
}

extern const unsigned long tytouns[];
unsigned int* get_tytouns()
{
	return (unsigned int*)tytouns;
}
