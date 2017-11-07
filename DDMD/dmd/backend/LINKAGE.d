module dmd.backend.LINKAGE;

/* Linkage type		*/
enum LINKAGE
{
    LINK_C,			/* C style				*/
    LINK_CPP,			/* C++ style				*/
    LINK_PASCAL,		/* Pascal style				*/
    LINK_FORTRAN,
    LINK_SYSCALL,
    LINK_STDCALL,
    LINK_D,			// D code
    LINK_MAXDIM			/* array dimension			*/
}