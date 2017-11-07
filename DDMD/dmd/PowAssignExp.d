module dmd.PowAssignExp;

import dmd.BinExp;
import dmd.Scope;
import dmd.Loc;
import dmd.Identifier;
import dmd.Expression;
import dmd.TOK;
import dmd.STC;
import dmd.PowExp;
import dmd.AssignExp;
import dmd.Lexer;
import dmd.VarDeclaration;
import dmd.ExpInitializer;
import dmd.DeclarationExp;
import dmd.VarExp;
import dmd.CommaExp;
import dmd.ErrorExp;
import dmd.Id;

import dmd.DDMDExtensions;

// Only a reduced subset of operations for now.
class PowAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
    {
		register();
        super(loc, TOK.TOKpowass, PowAssignExp.sizeof, e1, e2);
    }
    
    override Expression semantic(Scope sc)
    {
        Expression e;

        if (type)
	    return this;

        BinExp.semantic(sc);
        e2 = resolveProperties(sc, e2);

        e = op_overload(sc);
        if (e)
	        return e;

        e1 = e1.modifiableLvalue(sc, e1);
        assert(e1.type && e2.type);

        if ( (e1.type.isintegral() || e1.type.isfloating()) &&
	     (e2.type.isintegral() || e2.type.isfloating()))
        {
	        if (e1.op == TOKvar)
	        {   // Rewrite: e1 = e1 ^^ e2
	            e = new PowExp(loc, e1.syntaxCopy(), e2);
	            e = new AssignExp(loc, e1, e);
	        }
	        else
	        {   // Rewrite: ref tmp = e1; tmp = tmp ^^ e2
	            Identifier id = Lexer.uniqueId("__powtmp");
	            auto v = new VarDeclaration(e1.loc, e1.type, id, new ExpInitializer(loc, e1));
	            v.storage_class |= STC.STCref | STC.STCforeach;
	            Expression de = new DeclarationExp(e1.loc, v);
	            VarExp ve = new VarExp(e1.loc, v);
	            e = new PowExp(loc, ve, e2);
	            e = new AssignExp(loc, new VarExp(e1.loc, v), e);
	            e = new CommaExp(loc, de, e);
	        }
	        e = e.semantic(sc);
	        return e;
        }
        error("%s ^^= %s is not supported", e1.type.toChars(), e2.type.toChars() );
        return new ErrorExp();
    }
    
    // For operator overloading
    override Identifier opId()
    {
        return Id.powass;
    }
};