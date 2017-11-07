module dmd.VersionCondition;

import dmd.common;
import dmd.DVCondition;
import dmd.Loc;
import dmd.Module;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Identifier;
import dmd.Global;
import dmd.String;
import dmd.Util : error;

import std.string : startsWith;

// for findCondition
import dmd.Array;
import core.stdc.string;

import std.stdio;

import dmd.DDMDExtensions;

bool findCondition(Vector!(string) ids, Identifier ident)
{
    if (ids !is null) {
		foreach (id; ids)
		{
			if (id == ident.toChars()) {
				return true;
			}
		}
    }

    return false;
}

class VersionCondition : DVCondition
{
	mixin insertMemberExtension!(typeof(this));

    static void setGlobalLevel(uint level)
	{
		global.params.versionlevel = level;
	}

    static void checkPredefined(Loc loc, string ident)
	{
version (DMDV2)
{
		enum string[] reserved = [
			"DigitalMars", "X86", "X86_64",
			"Windows", "Win32", "Win64",
			"linux",
			/* Although Posix is predefined by D1, disallowing its
			 * redefinition breaks makefiles and older builds.
			 */
			"Posix",
			"D_NET",
			"OSX", "FreeBSD",
			"Solaris",
			"LittleEndian", "BigEndian",
			"all",
			"none",
		];
} else {
		enum string[] reserved = [
			"DigitalMars", "X86", "X86_64",
			"Windows", "Win32", "Win64",
			"linux",
			"OSX", "FreeBSD",
			"Solaris",
			"LittleEndian", "BigEndian",
			"all",
			"none",
		];
}
		foreach (reservedIdent; reserved)
		{
			if (ident == reservedIdent)
				goto Lerror;
		}

		if (ident.startsWith("D_")) {
			goto Lerror;
		}

		return;

	  Lerror:
		error(loc, "version identifier '%s' is reserved and cannot be set", ident);
	}

    static void addGlobalIdent(string ident)
	{
		checkPredefined(Loc(0), ident);
		addPredefinedGlobalIdent(ident);
	}

    static void addPredefinedGlobalIdent(string ident)
	{
		global.params.versionids.push(ident);	///
	}

    this(Module mod, uint level, Identifier ident)
	{
		register();
		super(mod, level, ident);
	}

    override final bool include(Scope sc, ScopeDsymbol s)
	{
		//printf("VersionCondition::include() level = %d, versionlevel = %d\n", level, global.params.versionlevel);
		//if (ident) printf("\tident = '%s'\n", ident->toChars());
		if (inc == 0) {
			inc = 2;
			if (ident !is null) {
				if (findCondition(mod.versionids, ident)) {
					inc = 1;
				} else if (findCondition(global.params.versionids, ident)) {
					inc = 1;
				} else {
					mod.versionidsNot.push(ident.toChars());
				}
			} else if (level <= global.params.versionlevel || level <= mod.versionlevel) {
				inc = 1;
			}
		}

		return (inc == 1);
	}

    override final void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (ident !is null) {
			buf.printf("version (%s)", ident.toChars());
		} else {
			buf.printf("version (%u)", level);
		}
	}
}
