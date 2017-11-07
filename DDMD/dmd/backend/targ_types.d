module dmd.backend.targ_types;

/***************************
 * Target machine data types as they appear on the host.
 */

alias char	 targ_char;
alias ubyte	 targ_uchar;
alias byte	 targ_schar;
alias short	 targ_short;
alias ushort targ_ushort;
alias long	 targ_long;
alias ulong	 targ_ulong;
alias long 	 targ_llong;
alias ulong	 targ_ullong;
alias float	 targ_float;
alias double targ_double;
alias real   targ_ldouble;
alias int 	 targ_int;
alias uint   targ_uns;
alias size_t targ_size_t;
alias ptrdiff_t targ_ptrdiff_t;

alias cfloat Complex_f;
alias cdouble Complex_d;
alias creal Complex_ld;

extern(C) extern __gshared targ_size_t localsize;
extern(C) extern __gshared targ_size_t Toff;
extern(C) extern __gshared targ_size_t Poff;
extern(C) extern __gshared targ_size_t Aoff;
extern(C) extern __gshared targ_size_t Poffset;
extern(C) extern __gshared targ_size_t funcoffset;
extern(C) extern __gshared targ_size_t framehandleroffset;
extern(C) extern __gshared targ_size_t Aoffset;
extern(C) extern __gshared targ_size_t Toffset;
extern(C) extern __gshared targ_size_t EEoffset;