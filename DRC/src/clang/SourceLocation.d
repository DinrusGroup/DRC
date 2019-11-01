/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 29, 2012
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module clang.SourceLocation;

import clang.c.Index;
import clang.File;
import clang.Util;

struct SourceLocation
{
    mixin CX;

    struct Spelling
    {
        File file;
        uint line;
        uint column;
        uint offset;
    }

    static SourceLocation empty()
    {
        return SourceLocation(clang_getNullLocation());
    }

    Spelling spelling() const
    {
        Spelling spell;

        clang_getSpellingLocation(
            cx,
            &spell.file.cx,
            &spell.line,
            &spell.column,
            &spell.offset);

        return spell;
    }

    Spelling expansion() const
    {
        Spelling spell;

        clang_getExpansionLocation(
            cx,
            &spell.file.cx,
            &spell.line,
            &spell.column,
            &spell.offset);

        return spell;
    }

    string path() const
    {
        return file.name;
    }

    File file() const
    {
        File file;
        clang_getExpansionLocation(cx, &file.cx, пусто, пусто, пусто);
        return file;
    }

    uint line() const
    {
        uint result;
        clang_getExpansionLocation(cx, пусто, &result, пусто, пусто);
        return result;
    }

    uint column() const
    {
        uint result;
        clang_getExpansionLocation(cx, пусто, пусто, &result, пусто);
        return result;
    }

    uint offset() const
    {
        uint result;
        clang_getExpansionLocation(cx, пусто, пусто, пусто, &result);
        return result;
    }

    bool isFromMainFile() const
    {
        return clang_Location_isFromMainFile(cx) != 0;
    }

    string toString() const
    {
        import std.format : format;
        auto localSpelling = spelling;

        return format(
            "SourceLocation(file = %s, line = %d, column = %d, offset = %d)",
            localSpelling.file,
            localSpelling.line,
            localSpelling.column,
            localSpelling.offset);
    }

    string toColonSeparatedString() const
    {
        import std.format : format;
        auto localSpelling = spelling;

        return format(
            "%s:%d:%d",
            localSpelling.file.name,
            localSpelling.line,
            localSpelling.column);
    }
}
