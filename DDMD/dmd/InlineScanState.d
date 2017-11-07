module dmd.InlineScanState;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.ExpInitializer;
import dmd.Dsymbol;
import dmd.InlineScanState;
import dmd.TupleDeclaration;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.TypeStruct;
import dmd.StructDeclaration;
import dmd.Array;
import dmd.Expression;
import dmd.DsymbolExp;
import dmd.TOK;
import dmd.TY;

struct InlineScanState
{
    FuncDeclaration fd;	// function being scanned
}

void scanVar(Dsymbol s, InlineScanState* iss)
{
    VarDeclaration vd = s.isVarDeclaration();
    if (vd)
    {
		TupleDeclaration td = vd.toAlias().isTupleDeclaration();
		if (td)
		{
			for (size_t i = 0; i < td.objects.dim; i++)
			{   
				auto se = cast(DsymbolExp)td.objects[i];
				assert(se.op == TOKdsymbol);
				scanVar(se.s, iss);
			}
		}
		else
		{
			// Scan initializer (vd.init)
			if (vd.init)
			{
				ExpInitializer ie = vd.init.isExpInitializer();

				if (ie)
				{
		version (DMDV2) {
					if (vd.type)
					{	
						Type tb = vd.type.toBasetype();
						if (tb.ty == Tstruct)
						{   
							StructDeclaration sd = (cast(TypeStruct)tb).sym;
							if (sd.cpctor)
							{
								/* The problem here is that if the initializer is a
								 * function call that returns a struct S with a cpctor:
								 *   S s = foo();
								 * the postblit is done by the return statement in foo()
								 * in s2ir.c, the intermediate code generator.
								 * But, if foo() is inlined and now the code looks like:
								 *   S s = x;
								 * the postblit is not there, because such assignments
								 * are rewritten as s.cpctor(&x) by the front end.
								 * So, the inlining won't get the postblit called.
								 * Work around by not inlining these cases.
								 * A proper fix would be to move all the postblit
								 * additions to the front end.
								 */
								return;
							}
						}
					}
		}
					ie.exp = ie.exp.inlineScan(iss);
				}
			}
		}
    }
}

void arrayInlineScan(InlineScanState* iss, Expressions arguments)
{
    if (arguments)
    {
		foreach (ref Expression e; arguments)
		{   
			if (e)
			{
				e = e.inlineScan(iss);
			}
		}
    }
}