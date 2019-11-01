/**
 * Copyright: Copyright (c) 2016 Wojciech Szęszoł. All rights reserved.
 * Authors: Wojciech Szęszoł
 * Version: Initial created: Feb 14, 2016
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module clang.SourceRange;

import std.conv;
import clang.c.Index;
import clang.SourceLocation;
import clang.Util;

struct SourceRange
{
    mixin CX;

    this(CXSourceRange cx)
    {
        this.cx = cx;
    }

    static SourceRange empty()
    {
        return SourceRange(clang_getNullRange());
    }

    bool isEmpty()
    {
        return clang_Range_isNull(cx) != 0;
    }

    this(SourceLocation start, SourceLocation end)
    {
        cx = clang_getRange(start.cx, end.cx);
    }

    SourceLocation start() const
    {
        return SourceLocation(clang_getRangeStart(cx));
    }

    SourceLocation end() const
    {
        return SourceLocation(clang_getRangeEnd(cx));
    }

    bool isMultiline() const
    {
        return start.line != end.line;
    }

    string path() const
    {
        return start.path;
    }

    string toString() const
    {
        import std.format: format;
        return format("SourceRange(start = %s, end = %s)", start, end);
    }
}

bool intersects(in SourceRange a, in SourceRange b)
{
    return a.path == b.path &&
        (a.start.offset <= b.start.offset && b.start.offset < a.end.offset) ||
        (a.start.offset < b.end.offset && b.end.offset <= a.end.offset);
}

bool contains(in SourceRange a, in SourceRange b)
{
    return a.path == b.path &&
        a.start.offset <= b.start.offset && b.end.offset <= a.end.offset;
}
