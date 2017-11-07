module dmd.backend.Srcpos;

struct Srcpos
{
    uint Slinnum;		// 0 means no info available
version (TX86) {
version (SPP_OR_SCPP) {
    Sfile** Sfilptr;	// file
///    #define srcpos_sfile(p)	(**(p).Sfilptr)
///    #define srcpos_name(p)	(srcpos_sfile(p).SFname)
}
version (MARS) {
    char* Sfilename;
///    #define srcpos_name(p)	((p).SFname)
}
}
version (M_UNIX) {
    short Sfilnum;		// file number
}
version (SOURCE_OFFSETS) {
    uint Sfiloff;	// byte offset
}
}