module dmd.backend.F;

enum F
{
	Fpending = 1,	// if function has been queued for being written
	Foutput	= 2,	/* if function has been written out	*/
	Finline	= 0x10,	/* if SCinline, and function really is inline */
	Foverload = 0x20,	/* if function can be overloaded	*/
	Ftypesafe = 0x40,	/* if function name needs type appended	*/
	Fmustoutput = 0x80,	/* set for forward ref'd functions that	*/
					/* must be output			*/
	Finlinenest = 0x1000, /* used as a marker to prevent nested	*/
					/* inlines from expanding		*/
	Flinkage = 0x2000,	/* linkage is already specified		*/
	Fstatic	= 0x4000,	/* static member function (no this)	*/
	Foperator = 4,	/* if operator overload			*/
	Fcast = 8,	/* if cast overload			*/
	Fvirtual = 0x100,	/* if function is a virtual function	*/
	Fctor = 0x200,	/* if function is a constructor		*/
	Fdtor = 0x400,	/* if function is a destructor		*/
	Fnotparent = 0x800,	/* if function is down Foversym chain	*/
	Fbitcopy = 0x8000,	/* it's a simple bitcopy (op=() or X(X&)) */
	Fpure = 0x10000,	// pure function
	Finstance = 0x20000,	// function is an instance of a template
	Ffixed = 0x40000,	// ctor has had cpp_fixconstructor() run on it,
						// dtor has had cpp_fixdestructor()
	Fintro = 0x80000,	// function doesn't hide a previous virtual function
	///#if !TX86
	///Fstcstd = 0x100000,	// static constructor or static destructor
	///#endif
	Fkeeplink = 0x200000,	// don't change linkage to default
	Fnodebug = 0x400000,	// do not generate debug info for this function
	Fgen = 0x800000,	// compiler generated function
	Finvariant = 0x1000000,	// __invariant function
	Fexplicit = 0x2000000,	// explicit constructor
	Fsurrogate = 0x4000000,	// surrogate call function
}

enum F3
{
	Fvtblgen = 0x01,	// generate vtbl[] when this function is defined
	Femptyexc = 0x02,	// empty exception specification (obsolete, use Tflags & TFemptyexc)
	Fcppeh = 0x04,	// uses C++ EH
	Fdeclared = 0x10,	// already declared function Symbol
	Fmark = 0x20,	// has unbalanced OPctor's
	Fnteh = 0x08,	// uses NT Structured EH
	Fdoinline = 0x40,	// do inline walk
	Foverridden	= 0x80,	// ignore for overriding purposes
///#if TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
///    Fnowrite	= 0x100,	// SCinline should never output definition
///#else
	Fjmonitor = 0x100,	// Jupiter synchronized function
///#endif
	Fnosideeff = 0x200,	// function has no side effects
	F3badoparrow = 0x400,	// bad operator->()
	Fmain = 0x800,	// function is main() or wmain()
	Fnested	= 0x1000,	// D nested function with 'this'
	Fmember	= 0x2000,	// D member function with 'this'
	Fnotailrecursion = 0x4000,	// no tail recursion optimizations
	Ffakeeh = 0x8000,	// allocate space for NT EH context sym anyway
}