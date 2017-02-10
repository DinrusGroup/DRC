/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.internal.image_reflect : frontend to txtgen.
*/

module kong.internal.image_reflect;

private import kong.internal.reflect_txtgen;

template reflect(t...)
{
    const char[] reflect = __body__(t[0], __types__(t[1]), __table__(t[1], [t[2..$]]));
}
