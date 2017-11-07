/**
 Common interfaces for the debugging package.

 Authors:
	Jeremie Pelletier
*/
module dbg.Debug;

interface IExecutableImage {
	uint codeOffset() const;

	ISymbolicDebugInfo debugInfo();
}

interface ISymbolicDebugInfo {
	SymbolInfo ResolveSymbol(size_t rva) const;
	FileLineInfo ResolveFileLine(size_t rva) const;
}

struct SymbolInfo {
	string	name;
	uint	offset;
}

struct FileLineInfo {
	string	file;
	uint	line;
}

void SystemException()
{
	throw new Exception("SystemException");
}