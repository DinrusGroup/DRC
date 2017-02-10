/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.hook_interface : ...
*/
module kong.internal.hook_interface;
import kong.internal.stdlib;
import kong.process;

T enforce(T)(T value, hook_exception.ERROR err = hook_exception.ERROR.INTERNAL)
{
    if (value)
        throw new hook_exception(err);

    return value;
}

class hook_exception : Exception
{
    enum ERROR { NOTFOUND = 0, PARSE = 1, ACCESS = 2, INTERNAL = 3 }

    static const string[4] messages =
    [ "Hook not found", "Invalid instruction encountered", "Memory protected", "Internal failure" ];

    ERROR error_code;

    this(ERROR code)
    {
        error_code = code;
        super(messages[code]);
    }
}

interface hook_chain
{
    // update hook. push previous hook onto queue.
    void* push(void*);

    /*
     * pop last hook and update the active hook.
     * return false when queue reaches 0.
     */
    bool pop();

    // returns the original function (or a callable stub for it)
    void* original_function();
}


void
force_access(void *ptr, kong.process.memory_region.ACCESS mode)
{
    memory_region* mem = ptr in process_map;

    if (mem == пусто)
        throw new hook_exception(hook_exception.ERROR.ACCESS);

    if ((mem.access & mode) != mode)
        return mem.access_set(mem.access|mode);

    return;
}


