module dmd.StringTable;

import dmd.common;
import dmd.StringValue;
import dmd.StringEntry;
import dmd.Dchar;

import core.stdc.stdlib;
import core.stdc.string;

import core.memory;

import std.stdio;

struct StringTable
{
	Object[string] table;
/*
	~this()
	{
		foreach (k, v; table) {
			delete v;
		}
	}
*/
	Object* lookup(string s)
	{
		return s in table;
	}

	Object* insert(string s)
	{
		auto value = s in table;
		if (value !is null) {
			return null;
		}

		table[s] = null;

		return s in table;
	}

	Object* update(string s)
	{
		auto value = s in table;
		if (value !is null) {
			return value;
		}

		table[s] = null;

        return s in table;
	}

    /*
	StringValue* lookup(string s)
	{
		if (auto p = s in table) {
			return *p;
		}

		return null;
	}

	StringValue* insert(string s)
	{
		if (auto p = s in table) {
			return null;
		}

		auto value = new StringValue();
		value.lstring.string_ = s;
		table[s] = value;

		return value;
	}

	StringValue* update(string s)
	{
		if (auto p = s in table) {
			return *p;
		}

		auto value = new StringValue();
		value.lstring.string_ = s;
		table[s] = value;

		return value;
	}
	*/

	/*
    void** table;
    uint count;
    uint tabledim;

    this(uint size = 37)
	{
		register();
		table = cast(void**)GC.calloc(size * (void*).sizeof);
		memset(table, 0, size * (void*).sizeof);
		tabledim = size;
		count = 0;
	}

    ~this()
	{
		/// TODO: is it *really* needed?
		// Zero out dangling pointers to help garbage collector.
		// Should zero out StringEntry's too.
		///for (uint i = 0; i < count; i++) {
		///	table[i] = null;
		///}

		///free(table);
		//table = null;
	}

    StringValue* lookup(immutable(dchar_t)[] s)
	{
		StringEntry* se = *search(s);
		if (se !is null)
			return &se.value;
		else
			return null;
	}

    StringValue* insert(immutable(dchar_t)[] s)
	{
		StringEntry** pse = search(s);
		StringEntry* se = *pse;
		if (se !is null)
			return null;		// error: already in table
		else
		{
			se = new StringEntry(s);
			*pse = se;
			++count;
		}

		return &se.value;
	}

	void insertCopy(StringEntry* proto)
	{
		StringEntry** pse = search(proto.value.lstring.string_);
		StringEntry* se = *pse;
		if (se is null)
		{
			se = new StringEntry(proto);
			*pse = se;
			++count;
		}
	}

    StringValue* update(immutable(dchar_t)[] s)
	{
		StringEntry** pse = search(s);
		StringEntry* se = *pse;
		if (se is null)			// not in table: so create new entry
		{
			se = new StringEntry(s);
			*pse = se;
			++count;
		}
		return &se.value;
	}

	void copyTo(StringTable stringTable)
	{
		for (int u = 0; u < tabledim; ++u) {
			StringEntry** se = cast(StringEntry**)&table[u];
			copyNode(*se, stringTable);
		}
	}

private:
	void copyNode(StringEntry* node, StringTable stringTable)
	{
		if (node is null) {
			return;
		}

		copyNode(node.left, stringTable);
		stringTable.insertCopy(node);
		copyNode(node.right, stringTable);
	}

    StringEntry** search(immutable(dchar_t)[] s)
	{
		int cmp;

		//printf("StringTable::search(%p,%d)\n",s,len);
		hash_t hash = Dchar.calcHash(s.ptr, s.length);
		uint u = hash % tabledim;
		StringEntry** se = cast(StringEntry**)&table[u];
		//printf("\thash = %d, u = %d\n",hash,u);
		while (*se)
		{
			cmp = (*se).hash - hash;
			if (cmp == 0)
			{
				cmp = (*se).value.lstring.len() - s.length;
				if (cmp == 0)
				{
					cmp = Dchar.memcmp(s.ptr, (*se).value.lstring.toDchars().ptr, s.length);
					if (cmp == 0)
						break;
				}
			}
			if (cmp < 0)
				se = &(*se).left;
			else
				se = &(*se).right;
		}

		//printf("\treturn %p, %p\n",se, (*se));
		return se;
	}
	*/
}
