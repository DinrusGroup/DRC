// Written in The D Programming Language
/// Script to build DDMD
import std.file;
import std.getopt;
import std.path;
import std.process;
import std.stdio;
import std.string: replace, format;
import std.zip;

enum dmdVersionDefault = "2.040";
enum dmdArchiveBaseURL = "http://ftp.digitalmars.com/";
enum dmd = "dmd";

version(Windows)
{
	enum scriptName = "build.bat";
	enum osSubDir   = "windows";
	enum configFile = "sc.ini";
	enum execExt    = ".exe";
	enum dmdLib = "dmd.lib";
}
else
{
	version (OSX)
		enum osSubDir   = "osx";

	else version (linux)
		enum osSubDir   = "linux";

	enum scriptName = "./build.sh";
	enum configFile = "dmd.conf";
	enum execExt    = "";
	enum dmdLib = "libdmd.a";
}

string dmdVersion;
string dmdPackage;
string dmdArchive;
string dmBase="";
bool shouldDownload;

void doCopy(string from, string to)
{
	from = normFilePath(from);
	to   = normFilePath(to);
	
	writefln(`copy "%s" "%s"`, from, to);
	copy(from, to);
}

void doChDir(string dir)
{
	dir = normDirPath(dir);
	
	writefln(`chdir "%s"`, dir);
	chdir(dir);
}

int doSystem(string cmd)
{
	writeln(cmd);
	stdout.flush();
	return system(cmd);
}

void copyRecurse(string from, string to)
{
	from = normDirPath(from)[0..$-1];
	to   = normDirPath(to)[0..$-1];
	version(Windows)
		doSystem(`xcopy "%s" "%s" /E /I /Y /Q`.format(from, to));
	else
		doSystem(`cp '%s' '%s' -r`.format(from, to));
}

void copyAndPatch(string from, string to, void delegate(ref string) patcher)
{
	auto data = cast(string)read(from);
	patcher(data);
	std.file.write(to, data);
}

/// makePath("C:\foo\bar\dir") will create "C:\foo\bar\dir" if it doesn't already exist.
/// makePath("C:\foo\bar\dir\") will create "C:\foo\bar\dir" if it doesn't already exist.
void makePath(string dir)
{
	dir = normDirPath(dir)[0..$-1];
	if(!exists(dir))
		mkdirRecurse(dir);
}

/// makePathTo("C:\foo\bar\file.txt") will create "C:\foo\bar\" if it doesn't already exist.
/// makePathTo("C:\foo\bar\dir\") will create "C:\foo\bar\" if it doesn't already exist.
void makePathTo(string file)
{
	file = normFilePath(file);
	auto dir = dirName(file);
	makePath(dir);
}

/// Ensure trailing slash and OS-correct path separators
string normDirPath(string str)
{
	str = normPathSep(str);
	if(str.length > 0 && str[$-1] != dirSeparator[0])
		str ~= dirSeparator;
	
	return str;
}

/// Ensure no trailing slash and OS-correct path separators
string normFilePath(string str)
{
	str = normPathSep(str);
	if(str.length > 0 && str[$-1] == dirSeparator[0])
		str = str[0..$-1];
	
	return str;
}

/// Ensure OS-correct path separators
string normPathSep(string str)
{
	version(Windows)
		str = str.replace("/", "\\");
	else
		str = str.replace("\\", "/");
	
	return str;
}

unittest
{
	version(Windows)
	{
		assert(normDirPath ("C:\\a/b\\c/d"  ) == "C:\\a\\b\\c\\d\\");
		assert(normDirPath ("C:\\a/b\\c/d\\") == "C:\\a\\b\\c\\d\\");
		assert(normDirPath ("C:\\a/b\\c/d/" ) == "C:\\a\\b\\c\\d\\");
		assert(normFilePath("C:\\a/b\\c/d"  ) == "C:\\a\\b\\c\\d"  );
		assert(normFilePath("C:\\a/b\\c/d\\") == "C:\\a\\b\\c\\d"  );
	}
	else
	{
		assert(normDirPath ("\\a/b\\c/d"  ) == "/a/b/c/d/");
		assert(normDirPath ("\\a/b\\c/d\\") == "/a/b/c/d/");
		assert(normDirPath ("\\a/b\\c/d/" ) == "/a/b/c/d/");
		assert(normFilePath("\\a/b\\c/d"  ) == "/a/b/c/d" );
		assert(normFilePath("\\a/b\\c/d\\") == "/a/b/c/d" );
	}
}

bool initialSetup()
{
	writeln("Running initial setup...");
	
	makePath("bin");
	
	// Download dmd zip
	if(!exists(dmdArchive) && shouldDownload)
		doSystem("wget "~dmdArchiveBaseURL~dmdArchive);

	// Extract dmd zip
	writeln("Extracting dmd archive...");
	if(exists("dmd2"))
		rmdirRecurse("dmd2");
	auto zip = new ZipArchive(std.file.read(dmdArchive));
	foreach(member; zip.directory)
	{
		makePathTo(member.name);
		std.file.write(member.name, zip.expand(member));
	}
	
	// Make mars2.c with 'main' hidden
	doChDir("dmd2/src/dmd");
	copyAndPatch("mars.c", "mars2.c", (ref string data) {
		data = data.replace("int main(int argc, char *argv[])", "int HIDE_main(int argc, char *argv[])");
	});
	
	copyAndPatch("util.c", "util.c", (ref string data) {
		data = data.replace("void util_assert(char *file,int line)", "void HIDE_util_assert(char *file,int line)");
	});

	// Apply patch
	doChDir("../../..");
	doChDir("dmd2");
	doSystem("patch -p1 --binary < " ~ normFilePath("../dmdpatch.patch"));
	
	// Setup makefile for dmd.lib
	doChDir("..");
	doChDir("dmd2/src/dmd");
	version(Windows)
		enum makefile = "win32.mak";
	else
	{
		version (linux)
			enum makefile = "linux_lib.mak";

		else version (OSX)
			enum makefile = "osx_lib.mak";

		doCopy("../../../"~makefile, makefile);
	}

	version(Windows)
	copyAndPatch(makefile, makefile, (ref string data) {
		if(dmBase == "")
		{
			data = data.replace("\nCC=$(SCROOT)\\bin\\dmc", "\nCC=dmc");
			data = data.replace("\nLIB=$(SCROOT)\\bin\\lib", "\nLIB=lib");
		}
		else
			data = data.replace("\nD=", "\nD="~dmBase);
	});

	
	// Build dmd.lib
	version(Windows)
		doSystem("make deblib -f"~makefile);
	else
		doSystem("make -f"~makefile);
	doCopy(dmdLib, "../../../" ~ dmdLib);
	
	// Copy and patch config file
	doChDir("../../..");
	copyAndPatch(
		normFilePath("dmd2/"~osSubDir~"/bin/"~configFile),
		normFilePath("bin/"~configFile),
		(ref string data) {
			data = data.replace(normDirPath("../.."), normDirPath("../dmd2"));
			data = data.replace(normDirPath("../lib")[0 .. $ - 1], normDirPath("../dmd2/"~osSubDir~"/lib")[0 .. $ - 1]);
		}
	);

	// Copy linker
	version (Windows)
		doCopy("dmd2/"~osSubDir~"/bin/link"~execExt, "bin/link"~execExt);

	return true;
}

int main(string[] args)
{
	endOfOptions = "";
	bool help;
	bool shouldSetup;
	bool debugOnly;
	bool releaseOnly;
	dmdVersion = dmdVersionDefault;
	getopt(
		args,
		std.getopt.config.caseSensitive,
		"setup",      &shouldSetup,
		"debug|d",    &debugOnly,
		"release|r",  &releaseOnly,
		"ver",        &dmdVersion,
		"download",   &shouldDownload,
		"dmbase",     &dmBase,
		"help|h|H|?", &help
	);
	
	dmdPackage = "dmd."~dmdVersion;
	dmdArchive = dmdPackage~".zip";

	auto helpMsg = 
`This script will compile DDMD

Note that this script must be run from the main DDMD directory.

Also, make sure you have GNU patch installed and current versions
of DMC and DMD (D2) on the PATH. (DMC is only needed on Windows.)

Usage:
    `~scriptName~` [options...]
	
    --help,-h,-H,-?  Display this help message
    --debug,-d       Only build debug version
    --release,-r     Only build release version
    --ver={ver}      Base DDMD off specific DMD version (default: `~dmdVersionDefault~`)
    --setup          Run initial setup
    --download       If running initial setup and the dmd zip doesn't exist,
                     use wget to download it
    --dmbase={path}  Path to directory containing 'dm' for building dmd.lib
                     (Optional if --setup is used, otherwise ignored)
`;

	// Assume the user meant they wanted both.
	if(debugOnly && releaseOnly)
	{
		debugOnly = releaseOnly = false;
	}
	
	if(
		help ||
		( shouldSetup && !exists(dmdArchive) && !shouldDownload    ) ||
		( shouldSetup && exists(dmdArchive) && !isFile(dmdArchive) )
	)
	{
		write(helpMsg);
		return 1;
	}
	
	if( !shouldSetup && (!exists(dmdLib) || !isFile(dmdLib)) )
	{
		auto needSetupMsg = 
`'`~dmdLib~`' has not been built so you need to run the initial setup:

If you have GNU wget installed, just run:
  `~scriptName~` --setup --download

If you don't have wget, download a copy of `~dmdArchive~` to this
directory. It can be obtained from:
  `~dmdArchiveBaseURL~dmdArchive~`
Then run:
  `~scriptName~` --setup

For a full list of options, run:
  `~scriptName~` --help
`;

		write(needSetupMsg);
		return 1;
	}

	if(shouldSetup)
	{
		if(!initialSetup())
			return 1;
	}
	
	int ret=0;
	version(Windows)
	{
		system("cls");
		if(ret == 0) ret = doSystem(r"dmc.exe bridge\bridge.cpp -c");
		if(!releaseOnly) if(ret == 0) ret = doSystem(dmd ~ r" -debug -g @commands.txt");
		if(!debugOnly)   if(ret == 0) ret = doSystem(dmd ~ r" -release -O -inline @commands.txt");
	}
	else
	{
		version (linux)
			auto commands = "@commands.linux.txt";

		else version (OSX)
			auto commands = "@commands.osx.txt";

		if(ret == 0) ret = doSystem("g++ -m32 -c bridge/bridge.cpp -obridge.o");
		if(!releaseOnly) if(ret == 0) ret = doSystem(dmd ~ " -debug -gc " ~ commands);
		if(!debugOnly)   if(ret == 0) ret = doSystem(dmd ~ " -release -O -inline " ~ commands);
	}
	
	return ret;
}
