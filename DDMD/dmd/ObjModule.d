module dmd.ObjModule;

struct ObjModule
{
	ubyte* base;			// where are we holding it in memory
    uint length;			// in bytes
    ushort page;			// page module starts in output file
    ubyte flags;
    string name;				// module name
}

enum MFgentheadr = 1;	// generate THEADR record
enum MFtheadr = 2;	// module name comes from THEADR record