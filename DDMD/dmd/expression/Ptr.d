module dmd.expression.Ptr;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.TOK;
import dmd.AddrExp;
import dmd.AddExp;
import dmd.StructLiteralExp;
import dmd.GlobalExpressions;

Expression Ptr(Type type, Expression e1)
{
    //printf("Ptr(e1 = %s)\n", e1->toChars());
    if (e1.op == TOK.TOKadd)
    {	
		AddExp ae = cast(AddExp)e1;
		if (ae.e1.op == TOK.TOKaddress && ae.e2.op == TOK.TOKint64)
		{   
			AddrExp ade = cast(AddrExp)ae.e1;
			if (ade.e1.op == TOK.TOKstructliteral)
			{	
				StructLiteralExp se = cast(StructLiteralExp)ade.e1;
				uint offset = cast(uint)ae.e2.toInteger();
				Expression e = se.getField(type, offset);
				if (!e)
					e = EXP_CANT_INTERPRET;

				return e;
			}
		}
    }

    return EXP_CANT_INTERPRET;
}

