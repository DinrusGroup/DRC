module dmd.Escape;

struct Escape
{
    const(char)*[256] strings;

    static const(char)* escapeChar(uint c)
	{
		assert(false);
	}
}