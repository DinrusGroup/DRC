/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.internal.dynamic_object : represents a .DLL or .SO
*/

module kong.internal.dynamic_object;
import kong.internal.image_interface;
import kong.internal.stdlib;

version (Windows)      public import kong.win32.DSO;
else version (linux)   public import kong.linux.DSO;
else                   static assert(0);

static const string IMAGE_SELF   = "<IMAGE>";
static const string IMAGE_KERNEL = "<KERNEL>";

struct dynamic_object
{
    void *address;  // Mapped address
    string name;    // Full path to object.

    image_interface image;

    void
    print()
    {
        .print!("%08x : %-40.40s")(address, name);
    }
}
