module dmd.ILS;

enum ILS
{
    ILSuninitialized,	// not computed yet
    ILSno,		// cannot inline
    ILSyes,		// can inline
}