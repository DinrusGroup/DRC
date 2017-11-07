module dmd.FuncLiteralDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.TOK;
import dmd.Loc;
import dmd.Type;
import dmd.ForeachStatement;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.STC;
import dmd.Lexer;

import dmd.DDMDExtensions;

class FuncLiteralDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    TOK tok;			// TOKfunction or TOKdelegate

    this(Loc loc, Loc endloc, Type type, TOK tok, ForeachStatement fes)
	{
		register();
		super(loc, endloc, null, STC.STCundefined, type);
		
		string id;

		if (fes)
			id = "__foreachbody";
		else if (tok == TOK.TOKdelegate)
			id = "__dgliteral";
		else
			id = "__funcliteral";

		this.ident = Lexer.uniqueId(id);
		this.tok = tok;
		this.fes = fes;

		//printf("FuncLiteralDeclaration() id = '%s', type = '%s'\n", this->ident->toChars(), type->toChars());
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
    	buf.writestring(kind());
        buf.writeByte(' ');
        type.toCBuffer(buf, null, hgs);
        bodyToCBuffer(buf, hgs);
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		FuncLiteralDeclaration f;

		//printf("FuncLiteralDeclaration.syntaxCopy('%s')\n", toChars());
		if (s)
			f = cast(FuncLiteralDeclaration)s;
		else
		{	
			f = new FuncLiteralDeclaration(loc, endloc, type.syntaxCopy(), tok, fes);
			f.ident = ident;		// keep old identifier
		}
		FuncDeclaration.syntaxCopy(f);
		return f;
	}
	
    override bool isNested()
	{
		//printf("FuncLiteralDeclaration::isNested() '%s'\n", toChars());
		return (tok == TOK.TOKdelegate);
	}
	
    override bool isVirtual()
	{
		return false;
	}

    override FuncLiteralDeclaration isFuncLiteralDeclaration() { return this; }

    override string kind()
	{
		return (tok == TOKdelegate) ? "delegate" : "function";
	}
}
