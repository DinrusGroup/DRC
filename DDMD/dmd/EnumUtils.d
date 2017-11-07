module dmd.EnumUtils;

string BringToCurrentScope(alias enumType)()
{
	string s = "";
	foreach (i, e; __traits(allMembers, enumType)) {
		s ~= "alias " ~ enumType.stringof ~ "." ~ __traits(allMembers, enumType)[i] ~ " " ~ __traits(allMembers, enumType)[i] ~ ";\n";
	}
	
	return s;
}