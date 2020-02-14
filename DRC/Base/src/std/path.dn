module std.путь;
pragma(lib, "DinrusStd.lib");
private import stdrus, cidrus;


alias РАЗДПАП sep ;
alias АЛЬТРАЗДПАП altsep;
alias РАЗДПСТР pathsep;
alias РАЗДСТР linesep; 
alias ТЕКПАП curdir;	 
alias РОДПАП pardir; 

version (Windows) alias stdrus.сравнлюб fcmp;
version (Posix) alias std.ткст.cmp fcmp;

alias  извлекиРасш getExt;
alias  дайИмяПути getName;
alias  извлекиПапку getDirName;
alias извлекиИмяПути getBaseName;
alias  извлекиМеткуДиска getDrive;
alias  устДефРасш defaultExt;
alias  добРасш addExt;
alias  абсПуть_ли isabs;
alias  слейПути join; 
alias сравниПути fncharmatch;
alias сравниПутьОбразец fnmatch;  
alias  разверниТильду expandTilde;


//module stdext.путь;

//import std.путь;
//import std.array;
import std.string;
//import std.conv;

ткст нормализуйПап(ткст пап)
{
	if(пап.length == 0)
		return ".\\";
	пап = std.string.replace(пап, "/", "\\");
	if(пап[$-1] == '\\')
		return пап;
	return пап ~ "\\";
}

S нормализуйПуть(S)(S путь)
{
	return std.string.replace(путь, "/", "\\");
}

ткст каноническийПуть(ткст путь)
{
	return std.string.tolower(std.string.replace(путь, "/", "\\"));
}

ткст сделайИмяфАбс(ткст файл, ткст рабпап)
{
	if(!isabs(файл) && рабпап.length)
	{
		if(файл == ".")
			файл = рабпап;
		else
			файл = нормализуйПап(рабпап) ~ файл;
	}
	return файл;
}

void сделайИмяффАбсс(ткст[] файлы, ткст рабпап)
{
	foreach(ref файл; файлы)
	{
		if(!isabs(файл) && рабпап.length)
			файл = сделайИмяфАбс(файл, рабпап);
	}
}

/+
ткст удали2ТчкВПути(ткст файл)
{
	// assumes \\ used as путь separator
	for( ; файл.length >= 2; )
	{
		// remove duplicate back slashes
		auto pos = indexOf(файл[1..$], "\\\\");
		if(pos < 0)
			break;
		файл = файл[0..pos+1] ~ файл[pos + 2 .. $];
	}
	for( ; ; )
	{
		auto pos = indexOf(файл, "\\..\\");
		if(pos < 0)
			break;
		auto lpos = lastIndexOf(файл[0..pos], '\\');
		if(lpos < 0)
			break;
		файл = файл[0..lpos] ~ файл[pos + 3 .. $];
	}
	for( ; ; )
	{
		auto pos = indexOf(файл, "\\.\\");
		if(pos < 0)
			break;
		файл = файл[0..pos] ~ файл[pos + 2 .. $];
	}
	return файл;
}

ткст сделайИмяфКанонич(ткст файл, ткст рабпап)
{
	файл = сделайИмяфАбс(файл, рабпап);
	файл = нормализуйПуть(файл);
	файл = удали2ТчкВПути(файл);
	return файл;
}

ткст сделайИмяпКанонич(ткст пап, ткст рабпап)
{
	пап = сделайИмяфАбс(пап, рабпап);
	пап = нормализуйПап(пап);
	пап = удали2ТчкВПути(пап);
	return пап;
}

void сделайИмяффКаноничч(ткст[] файлы, ткст рабпап)
{
	foreach(ref файл; файлы)
		файл = сделайИмяфКанонич(файл, рабпап);
}

void сделайИмяппКаноничч(ткст[] папп, ткст рабпап)
{
	foreach(ref пап; папп)
		пап = сделайИмяпКанонич(пап, рабпап);
}

ткст имяфВКавычки(ткст имяф)
{
	if(имяф.length >= 2 && имяф[0] == '\"' && имяф[$-1] == '\"')
		return имяф;
	if(имяф.indexOf('$') >= 0 || indexOf(имяф, ' ') >= 0)
		имяф = "\"" ~ имяф ~ "\"";
	return имяф;
}

void имяффВКавычки(ткст[] файлы)
{
	foreach(ref файл; файлы)
	{
		файл = имяфВКавычки(файл);
	}
}

ткст имяфВКавычкиНормализуй(ткст имяф)
{
	return имяфВКавычки(нормализуйПуть(имяф));
}

ткст дайИмяБезРасш(ткст имяф)
{
	ткст bname = baseName(имяф);
	ткст name = stripExtension(bname);
	if(name.length == 0)
		name = bname;
	return name;
}

ткст safeFilename(ткст имяф, ткст rep = "-") // - instead of _ to not possibly be part of a module name
{
	ткст safefile = имяф;
	foreach(char ch; ":\\/")
		safefile = std.string.replace(safefile, вТкст(ch), rep);
	return safefile;
}

ткст makeRelative(ткст файл, ткст путь)
{
	if(!isabs(файл))
		return файл;
	if(!isabs(путь))
		return файл;

	файл = std.string.replace(файл, "/", "\\");
	путь = std.string.replace(путь, "/", "\\");
	if(путь[$-1] != '\\')
		путь ~= "\\";

	ткст lfile = std.string.tolower(файл);
	ткст lpath = std.string.tolower(путь);

	int posfile = 0;
	for( ; ; )
	{
		auto idxfile = indexOf(lfile, '\\');
		auto idxpath = indexOf(lpath, '\\');
		assert(idxpath >= 0);

		if(idxfile < 0 || idxfile != idxpath || lfile[0..idxfile] != lpath[0 .. idxpath])
		{
			if(posfile == 0)
				return файл;

			// путь longer than файл путь or different subdirs
			ткст res;
			while(idxpath >= 0)
			{
				res ~= "..\\";
				lpath = lpath[idxpath + 1 .. $];
				idxpath = indexOf(lpath, '\\');
			}
			return res ~ файл[posfile .. $];
		}

		lfile = lfile[idxfile + 1 .. $];
		lpath = lpath[idxpath + 1 .. $];
		posfile += idxfile + 1;

		if(lpath.length == 0)
		{
			// файл longer than путь
			return файл[posfile .. $];
		}
	}
}

unittest
{
	ткст файл = "c:\\a\\bc\\def\\ghi.d";
	ткст путь = "c:\\a\\bc\\x";
	ткст res = makeRelative(файл, путь);
	assert(res == "..\\def\\ghi.d");

	файл = "c:\\a\\bc\\def\\ghi.d";
	путь = "c:\\a\\bc\\def";
	res = makeRelative(файл, путь);
	assert(res == "ghi.d");

	файл = "c:\\a\\bc\\def\\Ghi.d";
	путь = "c:\\a\\bc\\Def\\ggg\\hhh\\iii";
	res = makeRelative(файл, путь);
	assert(res == "..\\..\\..\\Ghi.d");

	файл = "d:\\a\\bc\\Def\\ghi.d";
	путь = "c:\\a\\bc\\def\\ggg\\hhh\\iii";
	res = makeRelative(файл, путь);
	assert(res == файл);
}

ткст commonParentDir(ткст path1, ткст path2)
{
	if (path1.length == 0 || path2.length == 0)
		return null;
	ткст p1 = std.string.tolower(нормализуйПап(path1));
	ткст p2 = std.string.tolower(нормализуйПап(path2));

	while(p2.length)
	{
		if (p1.startsWith(p2))
			return path1[0 .. p2.length]; // preserve case
		ткст q2 = dirName(p2);
		q2 = нормализуйПап(q2);
		if(q2 == p2)
			return null;
		p2 = q2;
	}
	return null;
}

unittest
{
	ткст path1 = "c:\\A\\bc\\def\\ghi.d";
	ткст path2 = "c:\\a/bc\\x";
	ткст res = commonParentDir(path1, path2);
	assert(res == "c:\\A\\bc\\");
}
+/
