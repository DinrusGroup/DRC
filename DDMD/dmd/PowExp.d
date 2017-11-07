module dmd.PowExp;

import dmd.BinExp;
import dmd.Scope;
import dmd.Loc;
import dmd.Identifier;
import dmd.Expression;
import dmd.TOK;
import dmd.Module;
import dmd.Id;
import dmd.IdentifierExp;
import dmd.DotIdExp;
import dmd.CallExp;
import dmd.ErrorExp;
import dmd.CommaExp;
import dmd.AndExp;
import dmd.CondExp;
import dmd.Global;
import dmd.IntegerExp;
import dmd.Type;
import dmd.STC;
import dmd.Lexer;
import dmd.VarDeclaration;
import dmd.ExpInitializer;
import dmd.VarExp;
import dmd.DeclarationExp;
import dmd.MulExp;
import dmd.WANT;

import dmd.DDMDExtensions;

version(DMDV2) {

class PowExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
    {
		register();
        super(loc, TOK.TOKpow, PowExp.sizeof, e1, e2);
    }
        
    override Expression semantic(Scope sc)
    {
        Expression e;

        if (type)
	        return this;

        //printf("PowExp::semantic() %s\n", toChars());
        BinExp.semanticp(sc);
        e = op_overload(sc);
        if (e)
	        return e;

        assert(e1.type && e2.type);
        if ( (e1.type.isintegral() || e1.type.isfloating()) &&
	     (e2.type.isintegral() || e2.type.isfloating()))
        {
	        // For built-in numeric types, there are several cases.
	        // TODO: backend support, especially for  e1 ^^ 2.
            
	        bool wantSqrt = false;	
        	e1 = e1.optimize(0);
	        e2 = e2.optimize(0);
	        	
	        // Replace 1 ^^ x or 1.0^^x by (x, 1)
	        if ((e1.op == TOK.TOKint64 && e1.toInteger() == 1) ||
		        (e1.op == TOK.TOKfloat64 && e1.toReal() == 1.0))
	        {
	            typeCombine(sc);
	            e = new CommaExp(loc, e2, e1);
	            e = e.semantic(sc);
	            return e;
 	        }
	        // Replace -1 ^^ x by (x&1) ? -1 : 1, where x is integral
	        if (e2.type.isintegral() && e1.op == TOKint64 && cast(long)e1.toInteger() == -1)
	        {
	            typeCombine(sc);
	            Type resultType = type;
	            e = new AndExp(loc, e2, new IntegerExp(loc, 1, e2.type));
	            e = new CondExp(loc, e, new IntegerExp(loc, -1, resultType), new IntegerExp(loc, 1, resultType));
	            e = e.semantic(sc);
	            return e;
	        }
	        // All other negative integral powers are illegal
	        if ((e1.type.isintegral()) && (e2.op == TOK.TOKint64) && cast(long)e2.toInteger() < 0)
	        {
	            error("cannot raise %s to a negative integer power. Did you mean (cast(real)%s)^^%s ?",
		        e1.type.toBasetype().toChars(), e1.toChars(), e2.toChars());
	            return new ErrorExp();
	        }
			
			// Determine if we're raising to an integer power.
			long intpow = 0;
			if (e2.op == TOKint64 && (cast(long)e2.toInteger() == 2 || cast(long)e2.toInteger() == 3))
				intpow = e2.toInteger();
			else if (e2.op == TOKfloat64 && (e2.toReal() == cast(long)(e2.toReal())))
				intpow = cast(long)(e2.toReal());
	
	        // Deal with x^^2, x^^3 immediately, since they are of practical importance.
        	if (intpow == 2 || intpow == 3)
	        {
	            typeCombine(sc);
	            // Replace x^^2 with (tmp = x, tmp*tmp)
	            // Replace x^^3 with (tmp = x, tmp*tmp*tmp) 
	            Identifier idtmp = Lexer.uniqueId("__tmp");
	            VarDeclaration tmp = new VarDeclaration(loc, e1.type.toBasetype(), idtmp, new ExpInitializer(Loc(0), e1));
	            tmp.storage_class = STC.STCctfe;
				Expression ve = new VarExp(loc, tmp);
	            Expression ae = new DeclarationExp(loc, tmp);
				/* Note that we're reusing ve. This should be ok.
				*/
	            Expression me = new MulExp(loc, ve, ve);
           	    if (intpow == 3)
					me = new MulExp(loc, me, ve);
	            e = new CommaExp(loc, ae, me);
	            e = e.semantic(sc);
	            return e;
	        }

	        if (!global.importMathChecked)
	        {
	            global.importMathChecked = true;
				auto amodules = global.amodules;
	            for (int i = 0; i < amodules.dim; i++)
	            {
                    auto mi = cast(Module)amodules.data[i];
		            //printf("\t[%d] %s\n", i, mi->toChars());
		            if (mi.ident == Id.math &&
		                mi.parent.ident == Id.std &&
		                !mi.parent.parent)
		                goto L1;
	            }
	            error("must import std.math to use ^^ operator");

	         L1: ;
	        }
 
 	        e = new IdentifierExp(loc, Id.empty);
 	        e = new DotIdExp(loc, e, Id.std);
 	        e = new DotIdExp(loc, e, Id.math);
 	        if (e2.op == TOK.TOKfloat64 && e2.toReal() == 0.5)
 	        {   // Replace e1 ^^ 0.5 with .std.math.sqrt(x)
	            typeCombine(sc);
 	            e = new CallExp(loc, new DotIdExp(loc, e, Id._sqrt), e1);
 	        }
 	        else 
	        {
	            // Replace e1 ^^ e2 with .std.math.pow(e1, e2)
	            // We don't combine the types if raising to an integer power (because
	            // integer powers are treated specially by std.math.pow).
	            if (!e2.type.isintegral())
		            typeCombine(sc);
			    // In fact, if it *could* have been an integer, make it one.
				if (e2.op == TOKfloat64 && intpow != 0)
					e2 = new IntegerExp(loc, intpow, Type.tint64);

	            e = new CallExp(loc, new DotIdExp(loc, e, Id._pow), e1, e2);	
 	        }	
 	        e = e.semantic(sc);
	        // Always constant fold integer powers of literals. This will run the interpreter
	        // on .std.math.pow
	        if ((e1.op == TOK.TOKfloat64 || e1.op == TOK.TOKint64) && (e2.op == TOK.TOKint64))
	            e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);

	        return e;
        }
        error("%s ^^ %s is not supported", e1.type.toChars(), e2.type.toChars() );
        return new ErrorExp();
    }
   

    // For operator overloading
    override Identifier opId()
    {
        return Id.pow;
    }
    
    override Identifier opId_r()
    {
        return Id.pow_r;
    }
}

}