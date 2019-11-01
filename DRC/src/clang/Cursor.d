/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 1, 2012
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module clang.Cursor;

import std.array : appender, Appender;
import std.conv : to;
import std.string;

import clang.c.Index;
import clang.Index;
import clang.File;
import clang.SourceLocation;
import clang.SourceRange;
import clang.Token;
import clang.TranslationUnit;
import clang.Type;
import clang.Util;
import clang.Visitor;

struct Cursor
{
    mixin CX;

    private static CXCursorKind[string] predefined;

    static this()
    {
        predefined = queryPredefined();
    }

    static Cursor empty ()
    {
        auto r = clang_getNullCursor();
        return Cursor(r);
    }

    string spelling () 
    {
        return toD(clang_getCursorSpelling(cx));
    }

    CXCursorKind kind () 
    {
        return clang_getCursorKind(cx);
    }

    bool isPreprocessor () 
    {
        CXCursorKind kind = clang_getCursorKind(cx);
        return CXCursorKind.firstPreprocessing <= kind &&
            kind <= CXCursorKind.lastPreprocessing;
    }

    SourceLocation location () 
    {
        return SourceLocation(clang_getCursorLocation(cx));
    }

    File file () 
    {
        return location.file;
    }

    string path () 
    {
        return file.name;
    }

    Token[] tokens() 
    {
        CXTranslationUnit translUnit = clang_Cursor_getTranslationUnit(cx);

        return TranslationUnit.tokenize(translUnit, extent);
    }

    SourceRange extent() 
    {
        return SourceRange(clang_getCursorExtent(cx));
    }

    Type type () 
    {
        auto r = clang_getCursorType(cx);
        return Type(r);
    }

    Type underlyingType() 
    {
        return Type(clang_getTypedefDeclUnderlyingType(cx));
    }

    Cursor underlyingCursor() 
    {
        foreach (child; all)
        {
            if (child.kind == CXCursorKind.typeRef)
                return child.referenced;

            if (child.isDeclaration &&
                child.kind != CXCursorKind.parmDecl)
            {
                return child;
            }
        }

        return empty;
    }

    bool isDeclaration ()
    {
        return clang_isDeclaration(cx.kind) != 0;
    }

    DeclarationVisitor declarations ()
    {
        return DeclarationVisitor(cx);
    }

    ObjcCursor objc ()
    {
        return ObjcCursor(this);
    }

    FunctionCursor func ()
    {
        return FunctionCursor(this);
    }

    EnumCursor enum_ ()
    {
        return EnumCursor(this);
    }

    bool isValid ()
    {
        return !clang_isInvalid(cx.kind);
    }

    bool isEmpty ()
    {
        return clang_Cursor_isNull(cx) != 0;
    }

    Visitor all () 
    {
        return Visitor(this);
    }

    InOrderVisitor allInOrder () 
    {
        return InOrderVisitor(this);
    }

    private Cursor[] childrenImpl(T)(bool ignorePredefined) 
    {
        import std.array : appender;

        Cursor[] result;
        auto app = appender(result);

        if (ignorePredefined && isTranslationUnit)
        {
            foreach (cursor, _; T(this))
            {
                if (!cursor.isPredefined)
                    app.put(cursor);
            }
        }
        else
        {
            foreach (cursor, _; T(this))
                app.put(cursor);
        }

        return app.data;
    }

    Cursor[] children(bool ignorePredefined = false) 
    {
        return childrenImpl!Visitor(ignorePredefined);
    }

    Cursor[] childrenInOrder(bool ignorePredefined = false) 
    {
        return childrenImpl!InOrderVisitor(ignorePredefined);
    }

    Cursor child() 
    {
        foreach (child; all)
            return child;

        return Cursor.empty;
    }

    Cursor findChild(CXCursorKind kind) 
    {
        foreach (child; all)
        {
            if (child.kind == kind)
                return child;
        }

        return Cursor.empty();
    }

    Cursor[] filterChildren(CXCursorKind kind)
    {
        import std.array;

        auto result = Appender!(Cursor[])();

        foreach (child; all)
        {
            if (child.kind == kind)
                result.put(child);
        }

        return result.data();
    }

    Cursor[] filterChildren(CXCursorKind[] kinds ...)
    {
        import std.array;

        auto result = Appender!(Cursor[])();

        foreach (child; all)
        {
            foreach (kind; kinds)
            {
                if (child.kind == kind)
                {
                    result.put(child);
                    break;
                }
            }
        }

        return result.data();
    }

    Cursor semanticParent() 
    {
        return Cursor(clang_getCursorSemanticParent(cast(CXCursor) cx));
    }

    Cursor lexicalParent() 
    {
        return Cursor(clang_getCursorLexicalParent(cast(CXCursor) cx));
    }

    CXLanguageKind language ()
    {
        return clang_getCursorLanguage(cx);
    }

    equals_t opEquals (in Cursor cursor) 
    {
        return clang_equalCursors(cast(CXCursor) cursor.cx, cast(CXCursor) cx) != 0;
    }

    hash_t toHash () 
    {
        return clang_hashCursor(cast(CXCursor) cx);
    }

    bool isDefinition () 
    {
        return clang_isCursorDefinition(cast(CXCursor) cx) != 0;
    }

    bool isTranslationUnit() 
    {
        return clang_isTranslationUnit(kind) != 0;
    }

    File includedFile()
    {
        return File(clang_getIncludedFile(cx));
    }

    string includedPath ()
    {
        auto file = clang_getIncludedFile(cx);
        return toD(clang_getFileName(file));
    }

    private static CXCursorKind[string] queryPredefined()
    {
        CXCursorKind[string] result;

        Index index = Index(false, false);
        TranslationUnit unit = TranslationUnit.parseString(
            index,
            "",
            []);

        foreach (cursor; unit.cursor.children)
            result[cursor.spelling] = cursor.kind;

        auto version_ = clangVersion();

        if (version_.major == 3 && version_.minor == 7)
            result["__int64"] = CXCursorKind.macroDefinition;

        return result;
    }

    bool isPredefined() 
    {
        auto xkind = spelling in predefined;
        return xkind !is пусто && *xkind == kind;
    }

    TranslationUnit translationUnit ()
    {
        return TranslationUnit(clang_Cursor_getTranslationUnit(cx));
    }

    Cursor definition () 
    {
        return Cursor(clang_getCursorDefinition(cast(CXCursor) cx));
    }

    Cursor referenced () 
    {
        return Cursor(clang_getCursorReferenced(cast(CXCursor) cx));
    }

    Cursor canonical () 
    {
        return Cursor(clang_getCanonicalCursor(cast(CXCursor) cx));
    }

    int bitFieldWidth() 
    {
        return clang_getFieldDeclBitWidth(cast(CXCursor) cx);
    }

    bool isBitField() 
    {
        return clang_Cursor_isBitField(cast(CXCursor) cx) != 0;
    }

    Cursor opCast(T)() /*const if (is(T == Cursor)) */
	in {assert(is(T == Cursor));}
    {
        return this;
    }

    bool opCast(T)() /* if (is(T == bool))*/
	in {assert(is(T == bool));}
    {
        return !isEmpty && isValid;
    }

    void dumpAST(ref Appender!string result, size_t indent, File* file)
    {
        import std.format;
        import std.array : replicate;
        import std.algorithm.comparison : min;

        string stripPrefix(string x)
        {
             string prefix = "";
             size_t prefixSize = prefix.length;
            return x.startsWith(prefix) ? x[prefixSize..$] : x;
        }

        string prettyTokens(Token[] tokens, size_t limit = 5)
        {
            string prettyToken(Token token)
            {
                 string prefix = "CXToken_";
                 size_t prefixSize = prefix.length;
                auto x = toString(token.kind);
                return format(
                    "%s \"%s\"",
                    x.startsWith(prefix) ? x[prefixSize .. $] : x,
                    token.spelling);
            }

            auto result = appender!string("[");

            if (tokens.length != 0)
            {
                result.put(prettyToken(tokens[0]));

                foreach (Token token; tokens[1..min($, limit)])
                {
                    result.put(", ");
                    result.put(prettyToken(token));
                }
            }

            if (tokens.length > limit)
                result.put(", ..]");
            else
                result.put("]");

            return result.data;
        }

         size_t step = 4;

        result.put(" ".replicate(indent));
        formattedWrite(
            result,
            "%s \"%s\" [%d..%d] %s\n",
            stripPrefix(to!string(kind)),
            spelling,
            extent.start.offset,
            extent.end.offset,
            prettyTokens(tokens));

        if (file)
        {
            foreach (cursor, _; allInOrder)
            {
                if (!cursor.isPredefined() && cursor.file == *file)
                    cursor.dumpAST(result, indent + step);
            }
        }
        else
        {
            foreach (cursor, _; allInOrder)
            {
                if (!cursor.isPredefined())
                    cursor.dumpAST(result, indent + step);
            }
        }
    }

    void dumpAST(ref Appender!string result, size_t indent)
    {
        dumpAST(result, indent, пусто);
    }

    string dumpAST()
    {
        auto result = appender!string();
        dumpAST(result, 0);
        return result.data;
    }

    string toString()
    {
        import std.format : format;
        return format("Cursor(kind = %s, spelling = %s)", kind, spelling);
    }
}

struct ObjcCursor
{
    Cursor cursor;
    alias cursor this;

    ObjCInstanceMethodVisitor instanceMethods ()
    {
        return ObjCInstanceMethodVisitor(cursor);
    }

    ObjCClassMethodVisitor classMethods ()
    {
        return ObjCClassMethodVisitor(cursor);
    }

    ObjCPropertyVisitor properties ()
    {
        return ObjCPropertyVisitor(cursor);
    }

    Cursor superClass ()
    {
        foreach (cursor, parent ; TypedVisitor!(CXCursorKind.objCSuperClassRef)(cursor))
            return cursor;

        return Cursor.empty;
    }

    ObjCProtocolVisitor protocols ()
    {
        return ObjCProtocolVisitor(cursor);
    }

    Cursor category ()
    {
        assert(cursor.kind == CXCursorKind.objCCategoryDecl);

        foreach (c, _ ; TypedVisitor!(CXCursorKind.objCClassRef)(cursor))
            return c;

        assert(0, "This cursor does not have a class reference.");
    }
}

struct FunctionCursor
{
    Cursor cursor;
    alias cursor this;

    Type resultType ()
    {
        auto r = clang_getCursorResultType(cx);
        return Type(r);
    }

    bool isVariadic ()
    {
        return type.func.isVariadic;
    }

    ParamVisitor parameters ()
    {
        return ParamVisitor(cx);
    }
}

struct ParamCursor
{
    Cursor cursor;
    alias cursor this;
}

struct EnumCursor
{
    Cursor cursor;
    alias cursor this;

    string value ()
    {
        //return type.kind.isUnsigned ? unsignedValue.toString : signedValue.toString;
        return signedValue.to!string;
    }

    long signedValue ()
    {
        return clang_getEnumConstantDeclValue(cx);
    }

    ulong unsignedValue ()
    {
        return clang_getEnumConstantDeclUnsignedValue(cx);
    }
}
