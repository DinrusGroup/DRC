/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/
*/

import kong.internal.stdlib;

import kong.process;
import kong.hooking;
import kong.ELF.ELF;

char  function()[char  function()] call;


char A(){ return 'A'; }
char B(){ assert(call[&B]() == 'A'); return 'B'; }
char C(){ assert(call[&C]() == 'B'); return 'C'; }

void
test_mutual()
{
    foreach (ref memory_region r; process_map[])
        r.print();

    foreach (ref dynamic_object d; process_modules[])
        d.print();

    version (linux)   dynamic_object* d = process_modules["*libc*"];
    version (Windows) dynamic_object* d = process_modules["*Kernel32.dll"];
    assert(d);
    memory_region* m = &strerror in process_map;
    assert(m);

    print!("d=%-40.40s  ")(d.name, d.address);
    print!("region[%08x:%08x]")(m.base, &strerror);

    // test hooking system

    assert(A() == 'A');

    call[&B] = hook(&A, &B);  assert(A() == 'B');
    call[&C] = hook(&A, &C);  assert(A() == 'C');

    unhook(&A); assert(A() == 'B');
    unhook(&A); assert(A() == 'A');
}

version (linux)
{
void
main(string[] argv)
{
    test_mutual();

    dynamic_object* obj = process_modules[IMAGE_SELF];

    call2[&D] = hook(obj, "strerror", &D);  assert(!strcmp("D", strerror(0)));
    call2[&E] = hook(obj, "strerror", &E);  assert(!strcmp("E", strerror(0)));
    unhook(obj, "strerror");                assert(!strcmp("D", strerror(0)));
    unhook(obj, "strerror");                assert(!strcmp("Success", strerror(0)));


    call2[&D] = hook("libc-2.6.1.so", "strerror", &D); assert(!strcmp("D", strerror(0)));
    call2[&E] = hook("libc-2.6.1.so", "strerror", &E); assert(!strcmp("E", strerror(0)));
    unhook("libc-2.6.1.so", "strerror");               assert(!strcmp("D", strerror(0)));
    unhook("libc-2.6.1.so", "strerror");               assert(!strcmp("Success", strerror(0)));

}

extern (C){
char* function(int)[char* function(int)] call2;
char* strerror(int errnum);
char* D(int a){ assert(!strcmp("Success", call2[&D](a))); return cast(char*) "D"; }
char* E(int a){ assert(!strcmp("D",       call2[&E](a))); return cast(char*) "E"; }
}

}


// -----------------------------------


version (Windows)
{
import std.c;

uint32_t ver;

void
main()
{
    test_mutual();

    ver = GetVersion();
    dynamic_object* obj = process_modules[IMAGE_SELF];

    call2[&D] = hook(obj, "GetVersion", &D);  assert(0x0D == GetVersion());
    call2[&E] = hook(obj, "GetVersion", &E);  assert(0x0E == GetVersion());
    unhook(obj, "GetVersion");               assert(0x0D == GetVersion());
    unhook(obj, "GetVersion");               assert(ver == GetVersion());

    call2[&D] = hook("kernel32.dll", "GetVersion", &D); assert(0x0D == GetVersion());
    call2[&E] = hook("kernel32.dll", "GetVersion", &E); assert(0x0E == GetVersion());
    unhook("kernel32.dll", "GetVersion");               assert(0x0D == GetVersion());
    unhook("kernel32.dll", "GetVersion");               assert(ver == GetVersion());
}

extern (Windows):

uint32_t GetVersion();
uint32_t function()[uint32_t function()] call2;
uint32_t D(){ assert(ver == call2[&D]()); return 0x0D; }
uint32_t E(){ assert(0x0D   == call2[&E]()); return 0x0E; }
}


