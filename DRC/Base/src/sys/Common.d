module sys.Common;

version (Win32)
        {
       // public import sys.win32.UserGdi;
        public  import sys.WinTypes, sys.WinConsts, sys.WinIfaces, sys.WinStructs,
         sys.WinFuncs;
		public import exception;
		//pragma(lib,"DinrusTango.lib");
        }
/+
version (linux)
        {
        public import sys.linux.linux;
        alias sys.linux.linux posix;
        }

version (darwin)
        {
        public import sys.darwin.darwin;
        alias sys.darwin.darwin posix;
        }
version (freebsd)
        {
        public import sys.freebsd.freebsd;
        alias sys.freebsd.freebsd posix;
        }
version (solaris)
        {
        public import sys.solaris.solaris;
        alias sys.solaris.solaris posix;
        }

        +/

/*******************************************************************************

        Stuff for sysErrorMsg(), kindly provопрed by Regan Heath.

*******************************************************************************/

version (Win32)
        {

        }
else
version (Posix)
        {
        private import cidrus;
        }
else
   {
   pragma (msg, "Неподдерживаемая среда; не декларирован ни Win32, ни Posix");
   static assert(0);
   }

   
