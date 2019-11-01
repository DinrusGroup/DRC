/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 29, 2012
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module clang.Type;

import std.bitmanip;

import clang.c.Index;
import clang.Cursor;
import clang.Util;

struct Type
{
    static assert(Type.init.kind == CXTypeKind.invalid);

    mixin CX;

    private Type* pointee_;
    private Type* canonical_;

    mixin(bitfields!(
        bool, "isConst", 1,
        bool, "isVolatile", 1,
        bool, "isClang", 1,
        uint, "", 5));

    string spelling = "";

    this (CXType cx)
    {
        this.cx = cx;
        spelling = Cursor(clang_getTypeDeclaration(cx)).spelling;
        isConst = clang_isConstQualifiedType(cx) == 1;
        isClang = true;
    }

    this (CXTypeKind kind, string spelling)
    {
        cx.kind = kind;
        this.spelling = spelling;
    }

    static Type makePointer(Type pointee)
    {
        Type result = Type(CXTypeKind.pointer, "");
        result.pointee_ = new Type();
        *result.pointee_ = pointee;
        return result;
    }

    static Type makeTypedef(string spelling, Type canonical)
    {
        Type result = Type(CXTypeKind.typedef_, spelling);
        result.canonical_ = new Type();
        *result.canonical_ = canonical;
        return result;
    }

    bool isAnonymous ()
    {
        return spelling == "";
    }

    Type underlying ()
    {
        return declaration.underlyingType;
    }

    bool isArray ()
    {
        return
            kind == CXTypeKind.constantArray ||
            kind == CXTypeKind.incompleteArray ||
            kind == CXTypeKind.variableArray ||
            kind == CXTypeKind.dependentSizedArray;
    }

    /**
     * Removes array and pointer modifiers from the type.
     */
    Type undecorated()
    {
        if (isArray)
            return array.elementType.undecorated;
        else if (kind == CXTypeKind.pointer && !pointee.isFunctionType)
            return pointee.undecorated;
        else
            return this;
    }

    bool isDecorated()
    {
        return isArray || (kind == CXTypeKind.pointer && !pointee.isFunctionType);
    }

    bool isEnum ()
    {
        return kind == CXTypeKind.enum_;
    }

    bool isExposed ()
    {
        return kind != CXTypeKind.unexposed;
    }

    bool isFunctionType ()
    {
        return canonical.kind == CXTypeKind.functionProto;
    }

    bool isFunctionPointerType ()
    {
        return kind == CXTypeKind.pointer && pointee.isFunctionType;
    }

    bool isObjCIdType ()
    {
        return isTypedef &&
            canonical.kind == CXTypeKind.objCObjectPointer &&
            spelling == "id";
    }

    bool isObjCClassType ()
    {
        return isTypedef &&
            canonical.kind == CXTypeKind.objCObjectPointer &&
            spelling == "Class";
    }

    bool isObjCSelType ()
    {
        with(CXTypeKind)
            if (isTypedef)
            {
                auto c = canonical;
                return c.kind == pointer &&
                    c.pointee.kind == objCSel;
            }

            else
                return false;
    }

    bool isObjCBuiltinType ()
    {
        return isObjCIdType || isObjCClassType || isObjCSelType;
    }

    bool isPointer ()
    {
        return kind == CXTypeKind.pointer;
    }

    bool isTypedef ()
    {
        return kind == CXTypeKind.typedef_;
    }

    bool isValid ()
    {
        return kind != CXTypeKind.invalid;
    }

    bool isWideCharType ()
    {
        return kind == CXTypeKind.wChar;
    }

    Type canonical()
    {
        if (canonical_)
        {
            return *canonical_;
        }
        else
        {
            if (isClang)
                return Type(clang_getCanonicalType(cx));
            else
                return Type.init;
        }
    }

    Type pointee()
    {
        if (pointee_)
        {
            return *pointee_;
        }
        else
        {
            if (isClang)
                return Type(clang_getPointeeType(cx));
            else
                return Type.init;
        }
    }

    Type element()
    {
        return Type(clang_getElementType(cx));
    }

    Type named()
    {
        if (isClang)
            return Type(clang_Type_getNamedType(cx));
        else
            return Type.init;
    }

    Cursor declaration ()
    {
        if (isClang)
            return Cursor(clang_getTypeDeclaration(cx));
        else
            return Cursor.empty;
    }

    FuncType func ()
    {
        return FuncType(this);
    }

    ArrayType array ()
    {
        return ArrayType(this);
    }

    size_t sizeOf()
    {
        if (isClang)
        {
            auto result = clang_Type_getSizeOf(cx);

            if (result < 0)
                throwTypeLayoutError(cast(CXTypeLayoutError) result, spelling);

            return cast(size_t) result;
        }
        else
        {
            throw new TypeLayoutErrorUnknown(spelling);
        }
    }

    string toString() const
    {
        import std.format: format;
        return format("Type(kind = %s, spelling = %s, isConst = %s)", kind, spelling, isConst);
    }

    string toString()
    {
        import std.format : format;
        return format("Type(kind = %s, spelling = %s)", kind, spelling);
    }
}

struct FuncType
{
    Type type;
    alias type this;

    Type resultType ()
    {
        auto r = clang_getResultType(type.cx);
        return Type(r);
    }

    Arguments arguments ()
    {
        return Arguments(this);
    }

    bool isVariadic ()
    {
        return clang_isFunctionTypeVariadic(type.cx) == 1;
    }
}

struct ArrayType
{
    Type type;
    alias type this;

    this (Type type)
    {
        assert(type.isArray);
        this.type = type;
    }

    Type elementType ()
    {
        auto r = clang_getArrayElementType(cx);
        return Type(r);
    }

    long size ()
    {
        return clang_getArraySize(cx);
    }

    size_t numDimensions ()
    {
        size_t result = 1;
        auto subtype = elementType();

        while (subtype.isArray)
        {
            ++result;
            subtype = subtype.array.elementType();
        }

        return result;
    }
}

struct Arguments
{
    FuncType type;

    uint length ()
    {
        return clang_getNumArgTypes(type.type.cx);
    }

    Type opIndex (uint i)
    {
        auto r = clang_getArgType(type.type.cx, i);
        return Type(r);
    }

    int opApply (int delegate (ref Type) dg)
    {
        foreach (i ; 0 .. length)
        {
            auto type = this[i];

            if (auto result = dg(type))
                return result;
        }

        return 0;
    }
}

bool isIntegral (CXTypeKind kind)
{
    with (CXTypeKind)
        switch (kind)
        {
            case bool_:
            case charU:
            case uChar:
            case char16:
            case char32:
            case uShort:
            case uInt:
            case uLong:
            case uLongLong:
            case uInt128:
            case charS:
            case sChar:
            case wChar:
            case short_:
            case int_:
            case long_:
            case longLong:
            case int128:
                return true;

            default:
                return false;
        }
}

bool isUnsigned (CXTypeKind kind)
{
    with (CXTypeKind)
        switch (kind)
        {
            case charU: return true;
            case uChar: return true;
            case uShort: return true;
            case uInt: return true;
            case uLong: return true;
            case uLongLong: return true;
            case uInt128: return true;

            default: return false;
        }
}

class TypeLayoutError : object.Exception
{
    this (string message, string file = __FILE__, size_t line = __LINE__)
    {
        super(message, file, line);
    }
}

class TypeLayoutErrorUnknown : TypeLayoutError
{
    this (string spelling, string file = __FILE__, size_t line = __LINE__)
    {
        super("The layout of the type is unknown: '" ~ spelling ~ "'.");
    }
}

class TypeLayoutErrorInvalid : TypeLayoutError
{
    this (string spelling, string file = __FILE__, size_t line = __LINE__)
    {
        super("The type is of invalid kind.");
    }
}

class TypeLayoutErrorIncomplete : TypeLayoutError
{
    this (string spelling, string file = __FILE__, size_t line = __LINE__)
    {
        super("The type '" ~ spelling ~ "' is an incomplete type.");
    }
}

class TypeLayoutErrorDependent : TypeLayoutError
{
    this (string spelling, string file = __FILE__, size_t line = __LINE__)
    {
        super("The type `" ~ spelling ~ "` is a dependent type.");
    }
}

class TypeLayoutErrorNotConstantSize : TypeLayoutError
{
    this (string spelling, string file = __FILE__, size_t line = __LINE__)
    {
        super("The type '" ~ spelling ~ "'is not a constant size type.");
    }
}

class TypeLayoutErrorInvalidFieldName : TypeLayoutError
{
    this (string spelling, string file = __FILE__, size_t line = __LINE__)
    {
        super("The field name '" ~ spelling ~ "' is not valid for this record.");
    }
}

void throwTypeLayoutError(
    CXTypeLayoutError layout,
    string spelling,
    string file = __FILE__,
    size_t line = __LINE__)
{
    final switch (layout)
    {
        case CXTypeLayoutError.invalid:
            throw new TypeLayoutErrorInvalid(spelling, file, line);
        case CXTypeLayoutError.incomplete:
            throw new TypeLayoutErrorIncomplete(spelling, file, line);
        case CXTypeLayoutError.dependent:
            throw new TypeLayoutErrorDependent(spelling, file, line);
        case CXTypeLayoutError.notConstantSize:
            throw new TypeLayoutErrorNotConstantSize(spelling, file, line);
        case CXTypeLayoutError.invalidFieldName:
            throw new TypeLayoutErrorInvalidFieldName(spelling, file, line);
    }
}
