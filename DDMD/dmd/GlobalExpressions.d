module dmd.GlobalExpressions;

import dmd.common;
import dmd.Expression;
import dmd.Loc;
import dmd.TOK;

__gshared Expression EXP_CANT_INTERPRET;
__gshared Expression EXP_CONTINUE_INTERPRET;
__gshared Expression EXP_BREAK_INTERPRET;
__gshared Expression EXP_GOTO_INTERPRET;
__gshared Expression EXP_VOID_INTERPRET;

void initGlobalExpressions()
{
	EXP_CANT_INTERPRET = new Expression(Loc(0), TOK.init, 0);
	EXP_CONTINUE_INTERPRET = new Expression(Loc(0), TOK.init, 0);
	EXP_BREAK_INTERPRET = new Expression(Loc(0), TOK.init, 0);
	EXP_GOTO_INTERPRET = new Expression(Loc(0), TOK.init, 0);
	EXP_VOID_INTERPRET = new Expression(Loc(0), TOK.init, 0);
}