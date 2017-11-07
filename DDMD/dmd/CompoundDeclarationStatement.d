module dmd.CompoundDeclarationStatement;

import dmd.common;
import dmd.CompoundStatement;
import dmd.Loc;
import dmd.TOK;
import dmd.ArrayTypes;
import dmd.VarDeclaration;
import dmd.AssignExp;
import dmd.ExpInitializer;
import dmd.Declaration;
import dmd.StorageClassDeclaration;
import dmd.DeclarationStatement;
import dmd.DeclarationExp;
import dmd.Statement;
import dmd.OutBuffer;
import dmd.HdrGenState;

import dmd.DDMDExtensions;

class CompoundDeclarationStatement : CompoundStatement
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Statements s)
	{
		register();
		super(loc, s);
		///statements = s;
	}

    override Statement syntaxCopy()
	{
		Statements a = new Statements();
		a.setDim(statements.dim);
		for (size_t i = 0; i < statements.dim; i++)
		{
			Statement s = statements[i];
			if (s)
				s = s.syntaxCopy();
			a[i] = s;
		}
		CompoundDeclarationStatement cs = new CompoundDeclarationStatement(loc, a);
		return cs;
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		int nwritten = 0;
		foreach (Statement s; statements)
		{
			if (s)
			{
				DeclarationStatement ds = s.isDeclarationStatement();
				assert(ds);
				DeclarationExp de = cast(DeclarationExp)ds.exp;
				assert(de.op == TOKdeclaration);
				Declaration d = de.declaration.isDeclaration();
				assert(d);
				VarDeclaration v = d.isVarDeclaration();
				if (v)
				{
					/* This essentially copies the part of VarDeclaration.toCBuffer()
					 * that does not print the type.
					 * Should refactor this.
					 */
					if (nwritten)
					{
						buf.writeByte(',');
						buf.writestring(v.ident.toChars());
					}
					else
					{
						StorageClassDeclaration.stcToCBuffer(buf, v.storage_class);
						if (v.type)
							v.type.toCBuffer(buf, v.ident, hgs);
						else
							buf.writestring(v.ident.toChars());
					}

					if (v.init)
					{
						buf.writestring(" = ");
///version (DMDV2) {
						ExpInitializer ie = v.init.isExpInitializer();
						if (ie && (ie.exp.op == TOKconstruct || ie.exp.op == TOKblit))
							(cast(AssignExp)ie.exp).e2.toCBuffer(buf, hgs);
						else
///}
							v.init.toCBuffer(buf, hgs);
					}
				}
				else
					d.toCBuffer(buf, hgs);
				nwritten++;
			}
		}
		buf.writeByte(';');
		if (!hgs.FLinit.init)
			buf.writenl();
	}
}
