/**
 *	
 */
module dmd.PASS;

/* State of symbol in winding its way through the passes of the compiler
 */
enum PASS
{
    PASSinit,           // initial state
    PASSsemantic,       // semantic() started
    PASSsemanticdone,   // semantic() done
    PASSsemantic2,      // semantic2() run
    PASSsemantic3,      // semantic3() started
    PASSsemantic3done,  // semantic3() done
    PASSobj,            // toObjFile() run
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(PASS));