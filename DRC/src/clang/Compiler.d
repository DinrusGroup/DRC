module clang.Compiler;

//*V-tas: import std.path;
//*V-tas: import std.typetuple : staticMap;
import stdrus;

import clang.c.Index;

struct Compiler
{
    private
    {
        version (Windows)
            static auto root = `C:\`;

        else
            const root = "/";

        string virtualPath_;

        static template toInternalHeader (string file)
        {
            static auto toInternalHeader = InternalHeader(file, import(file));
        }

        static struct InternalHeader
        {
            string filename;
            string content;
        }

        static auto internalHeaders = [
            staticMap!(
                toInternalHeader,
                "__stddef_max_align_t.h",
                "float.h",
                "limits.h",
                "stdarg.h",
                "stdbool.h",
                "stddef.h"
            )
        ];
    }

    string[] extraIncludePaths ()
    {
        return [virtualPath];
    }

    string[] extraIncludeFlags ()
    {
       //*V-tas: import std.algorithm;
       //*V-tas: import std.array;
		/*V-tas:
        return extraIncludePaths.map!(x => "-I" ~ x).array;
		*/
    }

    CXUnsavedFile[] extraHeaders ()
    {
      //*V-tas:  import std.algorithm : map;
      //*V-tas:  import std.array;
      //*V-tas:  import std.string : toStringz;
/*V-tas:
        return internalHeaders.map!((e) {
            auto path = buildPath(virtualPath, e.filename);
            return CXUnsavedFile(path.toStringz, e.content.ptr, cast(uint)e.content.length);
        }).array();
		*/
    }

private:

    string virtualPath ()
    {
      //*V-tas:  import std.random;
      //*V-tas:  import std.conv;

        if (virtualPath_.length)
            return virtualPath_;

        //return virtualPath_ = buildPath(root, uniform(1, 10_000_000).to!string);
		return virtualPath_ = buildPath(root, stdrus.вТкст(uniform(1, 10_000_000)));
    }
}

string[] internalIncludeFlags()
{
    //*V-tas:import std.algorithm;
    //*V-tas:import std.array;

//    return Compiler.init.extraIncludePaths.map!(path => "-I" ~ path).array();
}

CXUnsavedFile[] internalHeaders()
{
    return Compiler.init.extraHeaders();
}
