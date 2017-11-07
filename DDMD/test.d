import std.stdio;
import std.utf;
import std.file;
import std.path;
import std.algorithm;
import std.string;
import std.process;
import core.stdc.ctype;
import std.c.windows.windows;

string compiler = "dmd";

class Test
{
	enum EXTRA_SOURCES = "EXTRA_SOURCES";
	enum COMPILE_SEPARATELY = "COMPILE_SEPARATELY";
	enum PERMUTE_ARGS = "PERMUTE_ARGS";
	enum REQUIRED_ARGS = "REQUIRED_ARGS";
	enum POST_SCRIPT = "POST_SCRIPT";
	enum EXECUTE_ARGS = "EXECUTE_ARGS";
	
	this(string path, string outputDir)
	{
		this.outputDir = outputDir;
		this.baseDir = dirname(path);
		
		this.baseName = getBaseName(path);
		this.name = getName(baseName);
		
		this.fileNames ~= baseName;
		
		auto file = File(path);
		while (true) {
			auto line = file.readln();
			if (!line.startsWith("// ")) {
				break;
			}
			
			line = trim(line[3..$]);
			if (line.startsWith(EXTRA_SOURCES)) {
				fileNames ~= split(line[EXTRA_SOURCES.length + 2..$], " ");
			} else if (line.startsWith(COMPILE_SEPARATELY)) {
				compileSeparately = true;
			} else if (line.startsWith(EXECUTE_ARGS)) {
				executeArgs = line[EXECUTE_ARGS.length + 2..$];
			} else if (line.startsWith(PERMUTE_ARGS)) {
				// ignore for now
			} else if (line.startsWith(REQUIRED_ARGS)) {
				requiredArgs = line[REQUIRED_ARGS.length + 2..$];
			} else if (line.startsWith(POST_SCRIPT)) {
				// ignore for now
			} else {
				continue;
			}
		}
	}
	
	private string prefix()
	{
		return std.string.format(compiler ~ " -od%s -I%s %s", outputDir, baseDir, requiredArgs);
	}
	
	private string csuffix(string fileName)
	{
		// output to console
		return ""; //std.string.format(" > %s\\%s.clog", outputDir, getBaseName(fileName));
	}
	
	private string lsuffix(string fileName)
	{
		return std.string.format(" > %s\\%s.llog", outputDir, getBaseName(fileName));
	}
	
	private string output()
	{
		return std.string.format(" -of%s\\%s.exe", outputDir, name);
	}
	
	private void execute(string command)
	{
		system(command);
	}
	
	void compile()
	{
		if (compileSeparately) {
			string link_command = compiler ~ output();
			foreach (fileName; fileNames) {
				string compile_command = prefix();
				
				compile_command ~= std.string.format(" %s\\%s -c", baseDir, fileName);
				compile_command ~= csuffix(fileName);
				
				execute(compile_command);
				link_command ~= std.string.format(" %s\\%s.obj", outputDir, getName(getBaseName(fileName)));
			}
			
			link_command ~= lsuffix(baseName);
			
			execute(link_command);			
		} else {
			string compile_command = prefix();
			foreach (fileName; fileNames) {
				compile_command ~= std.string.format(" %s\\%s", baseDir, fileName);
			}
			
			compile_command ~= output();
			compile_command ~= csuffix(baseName);
			
			execute(compile_command);
		}
	}
	
	private string[] fileNames;
	
	private string name;
	private string baseName;
	private string outputDir;
	private string baseDir;
	private string requiredArgs;
	private string executeArgs;
	
	private bool compileSeparately = false;
}

class RunnableTest : Test
{
	this(string path, string outputDir)
	{
		super(path, outputDir);
	}
	
	void run()
	{
		string run_command = std.string.format("%s\\%s.exe %s > %s\\%s.exe.rlog", outputDir, name, executeArgs, outputDir, name);
		execute(run_command);
	}
}

int main(string[] args)
{
	auto runnable_tests = wildcard("runnable/*.d"/*, "runnable/*.html", "runnable/*.sh"*/);
	auto runnable_test_results = map!q{"result/" ~ a ~ ".out"}(runnable_tests);

	auto outputDir = "result";
	
	if (args.length >= 2) {
		compiler = args[1];
	} else {
		// compiler = "dmd"; // value by default
	}

	foreach (fileName; runnable_tests) {
		//fileName = "runnable\\a18.d";
		writeln("testing ", fileName);
		auto test = new RunnableTest(fileName, outputDir);
		test.compile();
//		test.run();
//		break;
	}
	
	return 0;
}

string[] wildcard(string[] paths...)
{
	string[] fileNames;
	
	foreach (path; paths) {
		filter(path, (string fileName) { fileNames ~= fileName; return true; });
	}
	
	return fileNames;
}

string trimLeft(string s)
{
	for (int i = 0; i < s.length; ++i) {
		if (!isspace(s[i])) {
			return s[i..$];
		}
	}
	
	return null;
}

string trimRight(string s)
{
	for (int i = s.length - 1; i >= 0; --i) {
		if (!isspace(s[i])) {
			return s[0..i + 1];
		}
	}
	
	return null;
}

string trim(string s)
{
	return trimLeft(trimRight(s));
}

version(Windows) void filter(string pattern, bool delegate(string fileName) callback)
{
	WIN32_FIND_DATAW fileinfo;

	auto h = FindFirstFileW(std.utf.toUTF16z(pattern), &fileinfo);
	if (h == INVALID_HANDLE_VALUE)
		return;

	auto path = dirname(pattern);

	do
	{
		// Skip "." and ".."
		auto name = fileinfo.cFileName.ptr;
		if (name[0] == '.' && (name[1] == 0 || name[1] == '.'))
			continue;

		size_t clength = std.string.wcslen(fileinfo.cFileName.ptr);
        auto fileName = std.path.join(path, std.utf.toUTF8(fileinfo.cFileName[0 .. clength]));
		
		if (!callback(fileName)) {
			break;
		}
	} while (FindNextFileW(h, &fileinfo) != FALSE);
	
	FindClose(h);
}

string getBaseName(string fullname, string extension = null)
{
    auto i = fullname.length;
    for (; i > 0; i--)
    {
        version(Windows)
        {
            if (fullname[i - 1] == ':' || fullname[i - 1] == '\\' || fullname[i - 1] == '/')
                break;
        }
        else version(Posix)
        {
            if (fullname[i - 1] == '/')
                break;
        }
        else
        {
            static assert(0);
        }
    }
    return chomp(fullname[i .. fullname.length],
            extension.length ? extension : "");
}