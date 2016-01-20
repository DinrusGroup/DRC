/// Author: Aziz Köksal
/// License: GPL3

// Impossible static circular reference.
const x = y;
const y = x;

// Impossible static circular reference.
struct A
{ const цел a = B.b; }
struct B
{ const цел b = A.a; }

struct C
{
  const x = C.x;
}