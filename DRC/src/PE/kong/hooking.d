/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.hooking : code-overwrite,PLT|GOT,IAT hooks.
*/
module kong.hooking;
import kong.internal.stdlib;
import kong.internal.hook_interface;
import kong.process;


version (linux)         import kong.ELF.hook_api;
else version (Windows)  import kong.PE.hook_api;
else static assert(0);
version (X86)           import kong.IA32.hook_code;
else static assert(0);


private hook_chain[string]  hook_table;



private
void*
hook_x(T...)(string index, T x)
{
    //P (callback, target, handle<optional>)
    //P (callback, symbol, obj)

    static assert(x.length >= 2);

    hook_chain* hook = index in hook_table;
    hook_chain  h;

    if (!hook)
    {
        static if (is(typeof(x[1]) == string) && is(typeof(x[2]) == dynamic_object*))
             h = new apihook_chain(x);
        else h = new codehook_chain(x);

        hook_table[index] = h;
        return h.original_function();
    }

    // else push onto existing chain
    return hook.push(x[0]);
}

private
void
unhook_x(string index)
{
    hook_chain* hook = index in hook_table;

    enforce(!hook, hook_exception.ERROR.NOTFOUND);

    if (hook.pop() == 0)
        hook_table.remove(index);
}



//─ hook IAT/PLT.GOT ─

T
hook(T)(dynamic_object* obj, string sym, T cb)
{
    enforce(!obj, hook_exception.ERROR.NOTFOUND);
    return cast(T) hook_x(AK(obj, sym), cb, sym, obj);
}

void
unhook(dynamic_object* obj, string sym)
{
    enforce(!obj, hook_exception.ERROR.NOTFOUND);
    unhook_x(AK(obj, sym));
}

//─ (code-overwrite) known address ─

T hook(T)(T A, T B)
    { return cast(T) hook_x(BK(A), B, A); }

void unhook(void* A)
    { unhook_x(BK(A)); }


//─ (code-overwrite) unknown library address ─

T hook(T)(string so, string sym, T cb)
    { return cast(T) hook_x(CK(so, sym), cb, sym, so); }

void unhook(string so, string sym)
    { unhook_x(CK(so, sym)); }


// hash table keygen
private string AK(dynamic_object* obj, string sym)
    { return obj.name ~ sym; }

private string BK(T)(T addr)
    { return toString(cast(uintptr_t)addr); }

private string CK(string so, string sym)
    { return "LD:" ~ so ~ sym; }

