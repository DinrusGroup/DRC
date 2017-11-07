module dmd.HdrGenState;

struct HdrGenState
{
    int hdrgen;		// 1 if generating header file
    int ddoc;		// 1 if generating Ddoc file
    int console;	// 1 if writing to console
    int tpltMember;
    int inCallExp;
    int inPtrExp;
    int inSlcExp;
    int inDotExp;
    int inBinExp;
    int inArrExp;
    int emitInst;
    
	struct FLinit_
    {
        int init;
        int decl;
    }
	
	FLinit_ FLinit;
}