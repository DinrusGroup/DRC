module dmd.PragmaDeclaration;

import dmd.common;
import dmd.ArrayTypes;
import dmd.AttribDeclaration;
import dmd.Loc;
import dmd.Identifier;
import dmd.StringExp;
import dmd.TOK;
import dmd.WANT;
import dmd.Global;
import dmd.Id;
import dmd.Array;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.FuncDeclaration;

import dmd.backend.Util;
import dmd.backend.Symbol;

import core.stdc.stdlib : malloc;

import dmd.DDMDExtensions;

class PragmaDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    Expressions args;		// array of Expression's

    this(Loc loc, Identifier ident, Expressions args, Dsymbols decl)
	{
		register();
		super(decl);
		this.loc = loc;
		this.ident = ident;
		this.args = args;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("PragmaDeclaration.syntaxCopy(%s)\n", toChars());
		PragmaDeclaration pd;

		assert(!s);
		pd = new PragmaDeclaration(loc, ident, Expression.arraySyntaxCopy(args), Dsymbol.arraySyntaxCopy(decl));
		return pd;
	}
	
    override void semantic(Scope sc)
	{
		// Should be merged with PragmaStatement

		//printf("\tPragmaDeclaration.semantic '%s'\n",toChars());
		if (ident == Id.msg)
		{
			if (args)
			{
				foreach (e; args)
				{
					e = e.semantic(sc);
					e = e.optimize(WANTvalue | WANTinterpret);
					if (e.op == TOKstring)
					{
						auto se = cast(StringExp)e;
						writef("%s", se.toChars()[1..$-2]); // strip the '"'s, TODO: change to original?: /*se.len, cast(char*)se.string_*/
					}
					else
						writef(e.toChars());
				}
				writef("\n");
			}
			goto Lnodecl;
		}
		else if (ident == Id.lib)
		{
			if (!args || args.dim != 1)
				error("string expected for library name");
			else
			{
				auto e = args[0];

				e = e.semantic(sc);
				e = e.optimize(WANTvalue | WANTinterpret);
				args[0] = e;
				if (e.op != TOKstring)
					error("string expected for library name, not '%s'", e.toChars());
				else if (global.params.verbose)
				{
					StringExp se = cast(StringExp)e;
					writef("library   %.*s\n", cast(int)se.len, cast(char*)se.string_);
				}
			}
			goto Lnodecl;
		}
///	version (IN_GCC) {
///		else if (ident == Id.GNU_asm)
///		{
///		if (! args || args.dim != 2)
///			error("identifier and string expected for asm name");
///		else
///		{
///			Expression *e;
///			Declaration *d = null;
///			StringExp *s = null;
///
///			e = (Expression *)args.data[0];
///			e = e.semantic(sc);
///			if (e.op == TOKvar)
///			{
///			d = ((VarExp *)e).var;
///			if (! d.isFuncDeclaration() && ! d.isVarDeclaration())
///				d = null;
///			}
///			if (!d)
///			error("first argument of GNU_asm must be a function or variable declaration");
///
///			e = (Expression *)args.data[1];
///			e = e.semantic(sc);
///			e = e.optimize(WANTvalue);
///			if (e.op == TOKstring && ((StringExp *)e).sz == 1)
///			s = ((StringExp *)e);
///			else
///			error("second argument of GNU_asm must be a char string");
///
///			if (d && s)
///			d.c_ident = Lexer.idPool((char*) s.string);
///		}
///		goto Lnodecl;
///		}
///	}
///version(DMDV2) {
		else if (ident == Id.startaddress)
		{
			if (!args || args.dim != 1)
				error("function name expected for start address");
			else
			{
				auto e = args[0];
				e = e.semantic(sc);
				e = e.optimize(WANTvalue | WANTinterpret);
				args[0] = e;
				Dsymbol sa = getDsymbol(e);
				if (!sa || !sa.isFuncDeclaration())
					error("function name expected for start address, not '%s'", e.toChars());
			}
			goto Lnodecl;
		}
///}
///	version (TARGET_NET) {
///		else if (ident == Lexer.idPool("assembly"))
///		{
///		}
///	} // TARGET_NET
		else if (global.params.ignoreUnsupportedPragmas)
		{
			if (global.params.verbose)
			{
				/* Print unrecognized pragmas
				 */
				writef("pragma    %s", ident.toChars());
				if (args)
				{
					foreach (size_t i, Expression e; args)
					{
						e = e.semantic(sc);
						e = e.optimize(WANTvalue | WANTinterpret);
						if (i == 0)
							writef(" (");
						else
							writef(",");
						writef("%s", e.toChars());
					}
					if (args.dim)
						writef(")");
				}
				writef("\n");
			}
			goto Lnodecl;
		}
		else
			error("unrecognized pragma(%s)", ident.toChars());

		if (decl)
		{
			foreach(Dsymbol s; decl)
				s.semantic(sc);
		}
		return;

	Lnodecl:
		if (decl)
			error("pragma is missing closing ';'");
	}
	
    override void setScope(Scope sc)
	{
version (TARGET_NET) {
    if (ident == Lexer.idPool("assembly"))
    {
        if (!args || args.dim != 1)
        {
            error("pragma has invalid number of arguments");
        }
        else
        {
            Expression e = cast(Expression)args.data[0];
            e = e.semantic(sc);
            e = e.optimize(WANTvalue | WANTinterpret);
            args.data[0] = cast(void*)e;
            if (e.op != TOKstring)
            {
                error("string expected, not '%s'", e.toChars());
            }
            PragmaScope pragma_ = new PragmaScope(this, sc.parent, cast(StringExp)e);

            assert(sc);
            pragma_.setScope(sc);

            //add to module members
            assert(sc.module_);
            assert(sc.module_.members);
            sc.module_.members.push(cast(void*)pragma_);
        }
    }
}
	}
	
    override bool oneMember(Dsymbol* ps)
	{
		*ps = null;
		return true;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
	
    override string kind()
	{
		assert(false);
	}
	
    override void toObjFile(int multiobj)			// compile to .obj file
	{
		if (ident == Id.lib)
		{
			assert(args && args.dim == 1);

			auto e = args[0];

			assert(e.op == TOKstring);

			auto se = cast(StringExp)e;
			char* name = cast(char*)malloc(se.len + 1);
			memcpy(name, se.string_, se.len);
			name[se.len] = 0;
		version (OMFOBJ) {
			/* The OMF format allows library names to be inserted
			 * into the object file. The linker will then automatically
			 * search that library, too.
			 */
			obj_includelib(name);
		} else version (ELFOBJ_OR_MACHOBJ) {
			/* The format does not allow embedded library names,
			 * so instead append the library name to the list to be passed
			 * to the linker.
			 */
			global.params.libfiles.push(cast(void*) name);
		} else {
			error("pragma lib not supported");
		}
		}
///	version (DMDV2) {
		else if (ident == Id.startaddress)
		{
			assert(args && args.dim == 1);
			auto e = args[0];
			Dsymbol sa = getDsymbol(e);
			FuncDeclaration f = sa.isFuncDeclaration();
			assert(f);
			Symbol* s = f.toSymbol();
			obj_startaddress(s);
		}
///	}
		AttribDeclaration.toObjFile(multiobj);
	}
}
