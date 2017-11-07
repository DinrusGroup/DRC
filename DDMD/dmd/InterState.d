module dmd.InterState;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Statement;

import dmd.TObject;

class InterState : TObject
{
	this()
	{
		register();
		vars = new Dsymbols();
	}
	
    InterState caller;		// calling function's InterState
    FuncDeclaration fd;	// function being interpreted
    Dsymbols vars;		// variables used in this function
    Statement start;		// if !=NULL, start execution at this statement
    Statement gotoTarget;	// target of EXP_GOTO_INTERPRET result
    Expression localThis;	// value of 'this', or NULL if none
}