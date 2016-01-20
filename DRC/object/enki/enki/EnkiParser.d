//auto-generated parser
module enki.EnkiParser;
debug private import std.stdio;
private import enki.types;
private import enki.EnkiBackend;
private import enki.Rule;
private import enki.Expression;
private import enki.Directive;

class EnkiParser : BaseEnkiParser{

/+
    Copyright (c) 2006 Eric Anderton

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following
    conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.
+/
	/*
	
Syntax
	= bool createSyntax(SyntaxLine[] lines)
	::=  ws { ( Rule:~lines | Comment:~lines | Directive:~lines )  ws}  eoi;

	*/
	public ResultT!(bool) parse_Syntax(){
		debug writefln("parse_Syntax()");
		uint start = position;
		SyntaxLine[] bind_lines;
		
		
		{//Expression
			uint start = position;
			if(!(parse_ws().success)){
				goto mismatch4;
			}
			{//ZeroOrMoreExpr
				uint start = position;
				uint termPos;
			loop5:
				termPos = position;
				{//Expression
					uint start = position;
					if((parse_eoi().success)){
						clearErrors();
						goto loopend6;
					}else{
						position = start;
					}
				}
				{//Expression
					uint start = position;
					{//Expression
						uint start = position;
						if((parse_Rule().assignCat!(SyntaxLine[])(bind_lines)) || (parse_Comment().assignCat!(SyntaxLine[])(bind_lines)) || (parse_Directive().assignCat!(SyntaxLine[])(bind_lines))){
							clearErrors();
						}else{
							setError("Expected Rule, Comment or Directive.");
							position = start;
							goto mismatch8;
						}
					}
					if(!(parse_ws().success)){
						goto mismatch8;
					}
					goto match7;
				mismatch8:
					position = start;
					goto mismatch4;
				match7:
					clearErrors();
					goto loop5;
				}
			loopend6:
				{}
			}
			goto match3;
		mismatch4:
			setError("Expected Whitespace.");
			position = start;
			goto mismatch2;
		match3:
			clearErrors();
			goto match1;
		}
	match1:
		debug writefln("parse_Syntax() PASS");
		auto value = createSyntax(bind_lines);
		return ResultT!(bool)(value);
	mismatch2:
		position = start;
		return ResultT!(bool)();
	}

	/*
	
Rule
	= new Rule(String name,RulePredicate pred,Expression expr,RuleDecl decl)
	::=  ws Identifier:name  ws [ RuleDecl:decl  ws]  [ RulePredicate:pred ]  ws "::=" ws Expression:expr  ws ";";

	*/
	public ResultT!(Rule) parse_Rule(){
		debug writefln("parse_Rule()");
		uint start = position;
		String bind_name;
		RulePredicate bind_pred;
		Expression bind_expr;
		RuleDecl bind_decl;
		
		
		{//Expression
			uint start = position;
			if(!(parse_ws().success)){
				goto mismatch12;
			}
			if(!(parse_Identifier().assign!(String)(bind_name))){
				goto mismatch12;
			}
			if(!(parse_ws().success)){
				goto mismatch12;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_RuleDecl().assign!(RuleDecl)(bind_decl) && parse_ws().success)){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_RulePredicate().assign!(RulePredicate)(bind_pred))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			if(!(parse_ws().success)){
				goto mismatch12;
			}
			if(!(terminal("::=").success)){
				goto mismatch12;
			}
			if(!(parse_ws().success)){
				goto mismatch12;
			}
			if(!(parse_Expression().assign!(Expression)(bind_expr))){
				goto mismatch12;
			}
			if(!(parse_ws().success)){
				goto mismatch12;
			}
			if(!(terminal(";").success)){
				goto mismatch12;
			}
			goto match11;
		mismatch12:
			setError("Expected Whitespace.");
			position = start;
			goto mismatch10;
		match11:
			clearErrors();
			goto match9;
		}
	match9:
		debug writefln("parse_Rule() PASS");
		ResultT!(Rule) passed = ResultT!(Rule)(new Rule(bind_name,bind_pred,bind_expr,bind_decl));
		return passed;
	mismatch10:
		position = start;
		ResultT!(Rule) failed = ResultT!(Rule)();
		return failed;
	}

	/*
	
RuleDecl
	= new RuleDecl(Param[] params)
	::=  ParamsExpr:params ;

	*/
	public ResultT!(RuleDecl) parse_RuleDecl(){
		debug writefln("parse_RuleDecl()");
		uint start = position;
		Param[] bind_params;
		
		
		{//Expression
			uint start = position;
			if((parse_ParamsExpr().assign!(Param[])(bind_params))){
				clearErrors();
				goto match13;
			}else{
				setError("Expected ParamsExpr.");
				position = start;
				goto mismatch14;
			}
		}
	match13:
		debug writefln("parse_RuleDecl() PASS");
		ResultT!(RuleDecl) passed = ResultT!(RuleDecl)(new RuleDecl(bind_params));
		return passed;
	mismatch14:
		position = start;
		ResultT!(RuleDecl) failed = ResultT!(RuleDecl)();
		return failed;
	}

	/*
	
RulePredicate
	= RulePredicate pred
	::=  "=" ws ( ClassPredicate:pred | FunctionPredicate:pred | BindingPredicate:pred ) ;

	*/
	public ResultT!(RulePredicate) parse_RulePredicate(){
		debug writefln("parse_RulePredicate()");
		uint start = position;
		RulePredicate bind_pred;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("=").success)){
				goto mismatch18;
			}
			if(!(parse_ws().success)){
				goto mismatch18;
			}
			{//Expression
				uint start = position;
				if((parse_ClassPredicate().assign!(RulePredicate)(bind_pred)) || (parse_FunctionPredicate().assign!(RulePredicate)(bind_pred)) || (parse_BindingPredicate().assign!(RulePredicate)(bind_pred))){
					clearErrors();
				}else{
					setError("Expected ClassPredicate, FunctionPredicate or BindingPredicate.");
					position = start;
					goto mismatch18;
				}
			}
			goto match17;
		mismatch18:
			position = start;
			goto mismatch16;
		match17:
			clearErrors();
			goto match15;
		}
	match15:
		debug writefln("parse_RulePredicate() PASS");
		return ResultT!(RulePredicate)(bind_pred);
	mismatch16:
		position = start;
		return ResultT!(RulePredicate)();
	}

	/*
	
ClassPredicate
	= new ClassPredicate(String name,Param[] params)
	::=  "new" ws Identifier:name  ws ParamsExpr:params ;

	*/
	public ResultT!(ClassPredicate) parse_ClassPredicate(){
		debug writefln("parse_ClassPredicate()");
		uint start = position;
		String bind_name;
		Param[] bind_params;
		
		
		{//Expression
			uint start = position;
			if((terminal("new").success && parse_ws().success && parse_Identifier().assign!(String)(bind_name) && parse_ws().success && parse_ParamsExpr().assign!(Param[])(bind_params))){
				clearErrors();
				goto match19;
			}else{
				position = start;
				goto mismatch20;
			}
		}
	match19:
		debug writefln("parse_ClassPredicate() PASS");
		ResultT!(ClassPredicate) passed = ResultT!(ClassPredicate)(new ClassPredicate(bind_name,bind_params));
		return passed;
	mismatch20:
		position = start;
		ResultT!(ClassPredicate) failed = ResultT!(ClassPredicate)();
		return failed;
	}

	/*
	
FunctionPredicate
	= new FunctionPredicate(Param decl,Param[] params)
	::=  ExplicitParam:decl  ws ParamsExpr:params ;

	*/
	public ResultT!(FunctionPredicate) parse_FunctionPredicate(){
		debug writefln("parse_FunctionPredicate()");
		uint start = position;
		Param bind_decl;
		Param[] bind_params;
		
		
		{//Expression
			uint start = position;
			if((parse_ExplicitParam().assign!(Param)(bind_decl) && parse_ws().success && parse_ParamsExpr().assign!(Param[])(bind_params))){
				clearErrors();
				goto match21;
			}else{
				setError("Expected ExplicitParam.");
				position = start;
				goto mismatch22;
			}
		}
	match21:
		debug writefln("parse_FunctionPredicate() PASS");
		ResultT!(FunctionPredicate) passed = ResultT!(FunctionPredicate)(new FunctionPredicate(bind_decl,bind_params));
		return passed;
	mismatch22:
		position = start;
		ResultT!(FunctionPredicate) failed = ResultT!(FunctionPredicate)();
		return failed;
	}

	/*
	
BindingPredicate
	= new BindingPredicate(Param param)
	::=  Param:param ;

	*/
	public ResultT!(BindingPredicate) parse_BindingPredicate(){
		debug writefln("parse_BindingPredicate()");
		uint start = position;
		Param bind_param;
		
		
		{//Expression
			uint start = position;
			if((parse_Param().assign!(Param)(bind_param))){
				clearErrors();
				goto match23;
			}else{
				setError("Expected Param.");
				position = start;
				goto mismatch24;
			}
		}
	match23:
		debug writefln("parse_BindingPredicate() PASS");
		ResultT!(BindingPredicate) passed = ResultT!(BindingPredicate)(new BindingPredicate(bind_param));
		return passed;
	mismatch24:
		position = start;
		ResultT!(BindingPredicate) failed = ResultT!(BindingPredicate)();
		return failed;
	}

	/*
	
ParamsExpr
	= Param[] params
	::=  "(" ws [ Param:~params  ws { "," ws Param:~params  ws} ]  ")";

	*/
	public ResultT!(Param[]) parse_ParamsExpr(){
		debug writefln("parse_ParamsExpr()");
		uint start = position;
		Param[] bind_params;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("(").success)){
				goto mismatch28;
			}
			if(!(parse_ws().success)){
				goto mismatch28;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if(!(parse_Param().assignCat!(Param[])(bind_params))){
						goto mismatch30;
					}
					if(!(parse_ws().success)){
						goto mismatch30;
					}
					{//ZeroOrMoreExpr
						uint termPos;
					loop31:
						termPos = position;
						{//Expression
							uint start = position;
							if((terminal(",").success && parse_ws().success && parse_Param().assignCat!(Param[])(bind_params) && parse_ws().success)){
								clearErrors();
								goto loop31;
							}else{
								position = start;
								goto loopend32;
							}
						}
					loopend32:
						{}
					}
					goto match29;
				mismatch30:
					position = start;
				match29:
					clearErrors();
				}
			}
			if(!(terminal(")").success)){
				goto mismatch28;
			}
			goto match27;
		mismatch28:
			position = start;
			goto mismatch26;
		match27:
			clearErrors();
			goto match25;
		}
	match25:
		debug writefln("parse_ParamsExpr() PASS");
		return ResultT!(Param[])(bind_params);
	mismatch26:
		position = start;
		return ResultT!(Param[])();
	}

	/*
	
Param
	= Param param
	::=  ExplicitParam:param | WeakParam:param ;

	*/
	public ResultT!(Param) parse_Param(){
		debug writefln("parse_Param()");
		uint start = position;
		Param bind_param;
		
		
		{//Expression
			uint start = position;
			if((parse_ExplicitParam().assign!(Param)(bind_param)) || (parse_WeakParam().assign!(Param)(bind_param))){
				clearErrors();
				goto match33;
			}else{
				setError("Expected ExplicitParam or WeakParam.");
				position = start;
				goto mismatch34;
			}
		}
	match33:
		debug writefln("parse_Param() PASS");
		return ResultT!(Param)(bind_param);
	mismatch34:
		position = start;
		return ResultT!(Param)();
	}

	/*
	
WeakParam
	= new Param(String name)
	::=  Identifier:name ;

	*/
	public ResultT!(Param) parse_WeakParam(){
		debug writefln("parse_WeakParam()");
		uint start = position;
		String bind_name;
		
		
		{//Expression
			uint start = position;
			if((parse_Identifier().assign!(String)(bind_name))){
				clearErrors();
				goto match35;
			}else{
				setError("Expected Identifier.");
				position = start;
				goto mismatch36;
			}
		}
	match35:
		debug writefln("parse_WeakParam() PASS");
		ResultT!(Param) passed = ResultT!(Param)(new Param(bind_name));
		return passed;
	mismatch36:
		position = start;
		ResultT!(Param) failed = ResultT!(Param)();
		return failed;
	}

	/*
	
ExplicitParam
	= new Param(bool isArray,String type,String name)
	::=  Identifier:type  ws [ "[]":isArray  ws]  Identifier:name ;

	*/
	public ResultT!(Param) parse_ExplicitParam(){
		debug writefln("parse_ExplicitParam()");
		uint start = position;
		bool bind_isArray;
		String bind_type;
		String bind_name;
		
		
		{//Expression
			uint start = position;
			if(!(parse_Identifier().assign!(String)(bind_type))){
				goto mismatch40;
			}
			if(!(parse_ws().success)){
				goto mismatch40;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((terminal("[]").assign!(bool)(bind_isArray) && parse_ws().success)){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			if(!(parse_Identifier().assign!(String)(bind_name))){
				goto mismatch40;
			}
			goto match39;
		mismatch40:
			setError("Expected Identifier.");
			position = start;
			goto mismatch38;
		match39:
			clearErrors();
			goto match37;
		}
	match37:
		debug writefln("parse_ExplicitParam() PASS");
		ResultT!(Param) passed = ResultT!(Param)(new Param(bind_isArray,bind_type,bind_name));
		return passed;
	mismatch38:
		position = start;
		ResultT!(Param) failed = ResultT!(Param)();
		return failed;
	}

	/*
	
Expression
	= new Expression(Term[] terms)
	::=  Term:~terms  ws { "|" ws Term:~terms  ws} ;

	*/
	public ResultT!(Expression) parse_Expression(){
		debug writefln("parse_Expression()");
		uint start = position;
		Term[] bind_terms;
		
		
		{//Expression
			uint start = position;
			if(!(parse_Term().assignCat!(Term[])(bind_terms))){
				goto mismatch44;
			}
			if(!(parse_ws().success)){
				goto mismatch44;
			}
			{//ZeroOrMoreExpr
				uint termPos;
			loop45:
				termPos = position;
				{//Expression
					uint start = position;
					if((terminal("|").success && parse_ws().success && parse_Term().assignCat!(Term[])(bind_terms) && parse_ws().success)){
						clearErrors();
						goto loop45;
					}else{
						position = start;
						goto loopend46;
					}
				}
			loopend46:
				{}
			}
			goto match43;
		mismatch44:
			setError("Expected Term.");
			position = start;
			goto mismatch42;
		match43:
			clearErrors();
			goto match41;
		}
	match41:
		debug writefln("parse_Expression() PASS");
		ResultT!(Expression) passed = ResultT!(Expression)(new Expression(bind_terms));
		return passed;
	mismatch42:
		position = start;
		ResultT!(Expression) failed = ResultT!(Expression)();
		return failed;
	}

	/*
	
Term
	= SubExpression[] factors
	::=  SubExpression:~factors  ws { SubExpression:~factors  ws} ;

	*/
	public ResultT!(SubExpression[]) parse_Term(){
		debug writefln("parse_Term()");
		uint start = position;
		SubExpression[] bind_factors;
		
		
		{//Expression
			uint start = position;
			if(!(parse_SubExpression().assignCat!(SubExpression[])(bind_factors))){
				goto mismatch50;
			}
			if(!(parse_ws().success)){
				goto mismatch50;
			}
			{//ZeroOrMoreExpr
				uint termPos;
			loop51:
				termPos = position;
				{//Expression
					uint start = position;
					if((parse_SubExpression().assignCat!(SubExpression[])(bind_factors) && parse_ws().success)){
						clearErrors();
						goto loop51;
					}else{
						setError("Expected SubExpression.");
						position = start;
						goto loopend52;
					}
				}
			loopend52:
				{}
			}
			goto match49;
		mismatch50:
			setError("Expected SubExpression.");
			position = start;
			goto mismatch48;
		match49:
			clearErrors();
			goto match47;
		}
	match47:
		debug writefln("parse_Term() PASS");
		return ResultT!(SubExpression[])(bind_factors);
	mismatch48:
		position = start;
		return ResultT!(SubExpression[])();
	}

	/*
	
SubExpression
	= SubExpression expr
	::=  Production:expr | Substitution:expr | Terminal:expr | Regexp:expr | GroupExpr:expr | OptionalExpr:expr | ZeroOrMoreExpr:expr | NegateExpr:expr | TestExpr:expr | LiteralExpr:expr | CustomTerminal:expr ;

	*/
	public ResultT!(SubExpression) parse_SubExpression(){
		debug writefln("parse_SubExpression()");
		uint start = position;
		SubExpression bind_expr;
		
		
		{//Expression
			uint start = position;
			if((parse_Production().assign!(SubExpression)(bind_expr)) || (parse_Substitution().assign!(SubExpression)(bind_expr)) || (parse_Terminal().assign!(SubExpression)(bind_expr)) || (parse_Regexp().assign!(SubExpression)(bind_expr)) || (parse_GroupExpr().assign!(SubExpression)(bind_expr)) || (parse_OptionalExpr().assign!(SubExpression)(bind_expr)) || (parse_ZeroOrMoreExpr().assign!(SubExpression)(bind_expr)) || (parse_NegateExpr().assign!(SubExpression)(bind_expr)) || (parse_TestExpr().assign!(SubExpression)(bind_expr)) || (parse_LiteralExpr().assign!(SubExpression)(bind_expr)) || (parse_CustomTerminal().assign!(SubExpression)(bind_expr))){
				clearErrors();
				goto match53;
			}else{
				setError("Expected Production, Substitution, Terminal, Regexp, GroupExpr, OptionalExpr, ZeroOrMoreExpr, NegateExpr, TestExpr, LiteralExpr or CustomTerminal.");
				position = start;
				goto mismatch54;
			}
		}
	match53:
		debug writefln("parse_SubExpression() PASS");
		return ResultT!(SubExpression)(bind_expr);
	mismatch54:
		position = start;
		return ResultT!(SubExpression)();
	}

	/*
	
Production
	= new Production(String name,Binding binding,ProductionArg[] args)
	::=  Identifier:name  ws [ "!(" ws ProductionArg:~args  { ws "," ws ProductionArg:~args }  ")"]  [ Binding:binding ] ;

	*/
	public ResultT!(Production) parse_Production(){
		debug writefln("parse_Production()");
		uint start = position;
		String bind_name;
		Binding bind_binding;
		ProductionArg[] bind_args;
		
		
		{//Expression
			uint start = position;
			if(!(parse_Identifier().assign!(String)(bind_name))){
				goto mismatch58;
			}
			if(!(parse_ws().success)){
				goto mismatch58;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if(!(terminal("!(").success)){
						goto mismatch60;
					}
					if(!(parse_ws().success)){
						goto mismatch60;
					}
					if(!(parse_ProductionArg().assignCat!(ProductionArg[])(bind_args))){
						goto mismatch60;
					}
					{//ZeroOrMoreExpr
						uint start = position;
						uint termPos;
					loop61:
						termPos = position;
						{//Expression
							uint start = position;
							if((terminal(")").success)){
								clearErrors();
								goto loopend62;
							}else{
								position = start;
							}
						}
						{//Expression
							uint start = position;
							if((parse_ws().success && terminal(",").success && parse_ws().success && parse_ProductionArg().assignCat!(ProductionArg[])(bind_args))){
								clearErrors();
								goto loop61;
							}else{
								setError("Expected Whitespace.");
								position = start;
								goto mismatch60;
							}
						}
					loopend62:
						{}
					}
					goto match59;
				mismatch60:
					position = start;
				match59:
					clearErrors();
				}
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Binding().assign!(Binding)(bind_binding))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			goto match57;
		mismatch58:
			setError("Expected Identifier.");
			position = start;
			goto mismatch56;
		match57:
			clearErrors();
			goto match55;
		}
	match55:
		debug writefln("parse_Production() PASS");
		ResultT!(Production) passed = ResultT!(Production)(new Production(bind_name,bind_binding,bind_args));
		return passed;
	mismatch56:
		position = start;
		ResultT!(Production) failed = ResultT!(Production)();
		return failed;
	}

	/*
	
ProductionArg
	= ProductionArg arg
	::=  StringProductionArg:arg | BindingProductionArg:arg ;

	*/
	public ResultT!(ProductionArg) parse_ProductionArg(){
		debug writefln("parse_ProductionArg()");
		uint start = position;
		ProductionArg bind_arg;
		
		
		{//Expression
			uint start = position;
			if((parse_StringProductionArg().assign!(ProductionArg)(bind_arg)) || (parse_BindingProductionArg().assign!(ProductionArg)(bind_arg))){
				clearErrors();
				goto match63;
			}else{
				setError("Expected StringProductionArg or BindingProductionArg.");
				position = start;
				goto mismatch64;
			}
		}
	match63:
		debug writefln("parse_ProductionArg() PASS");
		return ResultT!(ProductionArg)(bind_arg);
	mismatch64:
		position = start;
		return ResultT!(ProductionArg)();
	}

	/*
	
StringProductionArg
	= new StringProductionArg(String value)
	::=  String:value ;

	*/
	public ResultT!(StringProductionArg) parse_StringProductionArg(){
		debug writefln("parse_StringProductionArg()");
		uint start = position;
		String bind_value;
		
		
		{//Expression
			uint start = position;
			if((parse_String().assign!(String)(bind_value))){
				clearErrors();
				goto match65;
			}else{
				setError("Expected String.");
				position = start;
				goto mismatch66;
			}
		}
	match65:
		debug writefln("parse_StringProductionArg() PASS");
		ResultT!(StringProductionArg) passed = ResultT!(StringProductionArg)(new StringProductionArg(bind_value));
		return passed;
	mismatch66:
		position = start;
		ResultT!(StringProductionArg) failed = ResultT!(StringProductionArg)();
		return failed;
	}

	/*
	
BindingProductionArg
	= new BindingProductionArg(String value)
	::=  Identifier:value ;

	*/
	public ResultT!(BindingProductionArg) parse_BindingProductionArg(){
		debug writefln("parse_BindingProductionArg()");
		uint start = position;
		String bind_value;
		
		
		{//Expression
			uint start = position;
			if((parse_Identifier().assign!(String)(bind_value))){
				clearErrors();
				goto match67;
			}else{
				setError("Expected Identifier.");
				position = start;
				goto mismatch68;
			}
		}
	match67:
		debug writefln("parse_BindingProductionArg() PASS");
		ResultT!(BindingProductionArg) passed = ResultT!(BindingProductionArg)(new BindingProductionArg(bind_value));
		return passed;
	mismatch68:
		position = start;
		ResultT!(BindingProductionArg) failed = ResultT!(BindingProductionArg)();
		return failed;
	}

	/*
	
Substitution
	= new Substitution(String name,Binding binding)
	::=  "." Identifier:name  ws [ Binding:binding ] ;

	*/
	public ResultT!(Substitution) parse_Substitution(){
		debug writefln("parse_Substitution()");
		uint start = position;
		String bind_name;
		Binding bind_binding;
		
		
		{//Expression
			uint start = position;
			if(!(terminal(".").success)){
				goto mismatch72;
			}
			if(!(parse_Identifier().assign!(String)(bind_name))){
				goto mismatch72;
			}
			if(!(parse_ws().success)){
				goto mismatch72;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Binding().assign!(Binding)(bind_binding))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			goto match71;
		mismatch72:
			position = start;
			goto mismatch70;
		match71:
			clearErrors();
			goto match69;
		}
	match69:
		debug writefln("parse_Substitution() PASS");
		ResultT!(Substitution) passed = ResultT!(Substitution)(new Substitution(bind_name,bind_binding));
		return passed;
	mismatch70:
		position = start;
		ResultT!(Substitution) failed = ResultT!(Substitution)();
		return failed;
	}

	/*
	
GroupExpr
	= new GroupExpr(Expression expr,Binding binding)
	::=  "(" ws Expression:expr  ws ")" ws [ Binding:binding ] ;

	*/
	public ResultT!(GroupExpr) parse_GroupExpr(){
		debug writefln("parse_GroupExpr()");
		uint start = position;
		Expression bind_expr;
		Binding bind_binding;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("(").success)){
				goto mismatch76;
			}
			if(!(parse_ws().success)){
				goto mismatch76;
			}
			if(!(parse_Expression().assign!(Expression)(bind_expr))){
				goto mismatch76;
			}
			if(!(parse_ws().success)){
				goto mismatch76;
			}
			if(!(terminal(")").success)){
				goto mismatch76;
			}
			if(!(parse_ws().success)){
				goto mismatch76;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Binding().assign!(Binding)(bind_binding))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			goto match75;
		mismatch76:
			position = start;
			goto mismatch74;
		match75:
			clearErrors();
			goto match73;
		}
	match73:
		debug writefln("parse_GroupExpr() PASS");
		ResultT!(GroupExpr) passed = ResultT!(GroupExpr)(new GroupExpr(bind_expr,bind_binding));
		return passed;
	mismatch74:
		position = start;
		ResultT!(GroupExpr) failed = ResultT!(GroupExpr)();
		return failed;
	}

	/*
	
OptionalExpr
	= new OptionalExpr(Expression expr,Binding binding)
	::=  "[" ws Expression:expr  ws "]" ws [ Binding:binding ] ;

	*/
	public ResultT!(OptionalExpr) parse_OptionalExpr(){
		debug writefln("parse_OptionalExpr()");
		uint start = position;
		Expression bind_expr;
		Binding bind_binding;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("[").success)){
				goto mismatch80;
			}
			if(!(parse_ws().success)){
				goto mismatch80;
			}
			if(!(parse_Expression().assign!(Expression)(bind_expr))){
				goto mismatch80;
			}
			if(!(parse_ws().success)){
				goto mismatch80;
			}
			if(!(terminal("]").success)){
				goto mismatch80;
			}
			if(!(parse_ws().success)){
				goto mismatch80;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Binding().assign!(Binding)(bind_binding))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			goto match79;
		mismatch80:
			position = start;
			goto mismatch78;
		match79:
			clearErrors();
			goto match77;
		}
	match77:
		debug writefln("parse_OptionalExpr() PASS");
		ResultT!(OptionalExpr) passed = ResultT!(OptionalExpr)(new OptionalExpr(bind_expr,bind_binding));
		return passed;
	mismatch78:
		position = start;
		ResultT!(OptionalExpr) failed = ResultT!(OptionalExpr)();
		return failed;
	}

	/*
	
ZeroOrMoreExpr
	= new ZeroOrMoreExpr(Expression expr,Binding binding,Expression term)
	::=  "{" ws Expression:expr  ws "}" ws [ Binding:binding  ws]  [ Expression:term ] ;

	*/
	public ResultT!(ZeroOrMoreExpr) parse_ZeroOrMoreExpr(){
		debug writefln("parse_ZeroOrMoreExpr()");
		uint start = position;
		Expression bind_expr;
		Binding bind_binding;
		Expression bind_term;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("{").success)){
				goto mismatch84;
			}
			if(!(parse_ws().success)){
				goto mismatch84;
			}
			if(!(parse_Expression().assign!(Expression)(bind_expr))){
				goto mismatch84;
			}
			if(!(parse_ws().success)){
				goto mismatch84;
			}
			if(!(terminal("}").success)){
				goto mismatch84;
			}
			if(!(parse_ws().success)){
				goto mismatch84;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Binding().assign!(Binding)(bind_binding) && parse_ws().success)){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Expression().assign!(Expression)(bind_term))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			goto match83;
		mismatch84:
			position = start;
			goto mismatch82;
		match83:
			clearErrors();
			goto match81;
		}
	match81:
		debug writefln("parse_ZeroOrMoreExpr() PASS");
		ResultT!(ZeroOrMoreExpr) passed = ResultT!(ZeroOrMoreExpr)(new ZeroOrMoreExpr(bind_expr,bind_binding,bind_term));
		return passed;
	mismatch82:
		position = start;
		ResultT!(ZeroOrMoreExpr) failed = ResultT!(ZeroOrMoreExpr)();
		return failed;
	}

	/*
	
Terminal
	= new Terminal(String text,Binding binding)
	::=  ( String:text | HexChar:text )  ws [ Binding:binding ] ;

	*/
	public ResultT!(Terminal) parse_Terminal(){
		debug writefln("parse_Terminal()");
		uint start = position;
		String bind_text;
		Binding bind_binding;
		
		
		{//Expression
			uint start = position;
			{//Expression
				uint start = position;
				if((parse_String().assign!(String)(bind_text)) || (parse_HexChar().assign!(String)(bind_text))){
					clearErrors();
				}else{
					setError("Expected String or HexChar.");
					position = start;
					goto mismatch88;
				}
			}
			if(!(parse_ws().success)){
				goto mismatch88;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Binding().assign!(Binding)(bind_binding))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			goto match87;
		mismatch88:
			position = start;
			goto mismatch86;
		match87:
			clearErrors();
			goto match85;
		}
	match85:
		debug writefln("parse_Terminal() PASS");
		ResultT!(Terminal) passed = ResultT!(Terminal)(new Terminal(bind_text,bind_binding));
		return passed;
	mismatch86:
		position = start;
		ResultT!(Terminal) failed = ResultT!(Terminal)();
		return failed;
	}

	/*
	
Regexp
	= new Regexp(String text,Binding binding)
	::=  ( "r" String:text | "`" { any}:text  "`")  ws [ Binding:binding ] ;

	*/
	public ResultT!(Regexp) parse_Regexp(){
		debug writefln("parse_Regexp()");
		uint start = position;
		String bind_text;
		Binding bind_binding;
		
		
		{//Expression
			uint start = position;
			{//Expression
				uint start = position;
				if(terminal("r").success && parse_String().assign!(String)(bind_text)){
					goto match93;
				}
				if(!(terminal("`").success)){
					goto mismatch94;
				}
				{//ZeroOrMoreExpr
					uint start = position;
					uint termPos;
				loop95:
					termPos = position;
					{//Expression
						uint start = position;
						if((terminal("`").success)){
							clearErrors();
							goto loopend96;
						}else{
							position = start;
						}
					}
					{//Expression
						uint start = position;
						if((parse_any().success)){
							clearErrors();
							goto loop95;
						}else{
							setError("Expected any.");
							position = start;
							goto mismatch94;
						}
					}
				loopend96:
					smartAssign!(String,String)(bind_text,sliceData(start,termPos));
					{}
				}
				goto match93;
			mismatch94:
				position = start;
				goto mismatch92;
			match93:
				clearErrors();
			}
			if(!(parse_ws().success)){
				goto mismatch92;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Binding().assign!(Binding)(bind_binding))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			goto match91;
		mismatch92:
			position = start;
			goto mismatch90;
		match91:
			clearErrors();
			goto match89;
		}
	match89:
		debug writefln("parse_Regexp() PASS");
		ResultT!(Regexp) passed = ResultT!(Regexp)(new Regexp(bind_text,bind_binding));
		return passed;
	mismatch90:
		position = start;
		ResultT!(Regexp) failed = ResultT!(Regexp)();
		return failed;
	}

	/*
	
NegateExpr
	= new Negate(SubExpression expr)
	::=  "!" ws SubExpression:expr ;

	*/
	public ResultT!(Negate) parse_NegateExpr(){
		debug writefln("parse_NegateExpr()");
		uint start = position;
		SubExpression bind_expr;
		
		
		{//Expression
			uint start = position;
			if((terminal("!").success && parse_ws().success && parse_SubExpression().assign!(SubExpression)(bind_expr))){
				clearErrors();
				goto match97;
			}else{
				position = start;
				goto mismatch98;
			}
		}
	match97:
		debug writefln("parse_NegateExpr() PASS");
		ResultT!(Negate) passed = ResultT!(Negate)(new Negate(bind_expr));
		return passed;
	mismatch98:
		position = start;
		ResultT!(Negate) failed = ResultT!(Negate)();
		return failed;
	}

	/*
	
TestExpr
	= new Test(SubExpression expr)
	::=  "/" ws SubExpression:expr ;

	*/
	public ResultT!(Test) parse_TestExpr(){
		debug writefln("parse_TestExpr()");
		uint start = position;
		SubExpression bind_expr;
		
		
		{//Expression
			uint start = position;
			if((terminal("/").success && parse_ws().success && parse_SubExpression().assign!(SubExpression)(bind_expr))){
				clearErrors();
				goto match99;
			}else{
				position = start;
				goto mismatch100;
			}
		}
	match99:
		debug writefln("parse_TestExpr() PASS");
		ResultT!(Test) passed = ResultT!(Test)(new Test(bind_expr));
		return passed;
	mismatch100:
		position = start;
		ResultT!(Test) failed = ResultT!(Test)();
		return failed;
	}

	/*
	
LiteralExpr
	= new LiteralExpr(String name,Binding binding,ProductionArg[] args)
	::=  "@" Identifier:name  ws [ "!(" ws ProductionArg:~args  { ws "," ws ProductionArg:~args }  ")"]  [ Binding:binding ] ;

	*/
	public ResultT!(LiteralExpr) parse_LiteralExpr(){
		debug writefln("parse_LiteralExpr()");
		uint start = position;
		String bind_name;
		Binding bind_binding;
		ProductionArg[] bind_args;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("@").success)){
				goto mismatch104;
			}
			if(!(parse_Identifier().assign!(String)(bind_name))){
				goto mismatch104;
			}
			if(!(parse_ws().success)){
				goto mismatch104;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if(!(terminal("!(").success)){
						goto mismatch106;
					}
					if(!(parse_ws().success)){
						goto mismatch106;
					}
					if(!(parse_ProductionArg().assignCat!(ProductionArg[])(bind_args))){
						goto mismatch106;
					}
					{//ZeroOrMoreExpr
						uint start = position;
						uint termPos;
					loop107:
						termPos = position;
						{//Expression
							uint start = position;
							if((terminal(")").success)){
								clearErrors();
								goto loopend108;
							}else{
								position = start;
							}
						}
						{//Expression
							uint start = position;
							if((parse_ws().success && terminal(",").success && parse_ws().success && parse_ProductionArg().assignCat!(ProductionArg[])(bind_args))){
								clearErrors();
								goto loop107;
							}else{
								setError("Expected Whitespace.");
								position = start;
								goto mismatch106;
							}
						}
					loopend108:
						{}
					}
					goto match105;
				mismatch106:
					position = start;
				match105:
					clearErrors();
				}
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Binding().assign!(Binding)(bind_binding))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			goto match103;
		mismatch104:
			position = start;
			goto mismatch102;
		match103:
			clearErrors();
			goto match101;
		}
	match101:
		debug writefln("parse_LiteralExpr() PASS");
		ResultT!(LiteralExpr) passed = ResultT!(LiteralExpr)(new LiteralExpr(bind_name,bind_binding,bind_args));
		return passed;
	mismatch102:
		position = start;
		ResultT!(LiteralExpr) failed = ResultT!(LiteralExpr)();
		return failed;
	}

	/*
	
CustomTerminal
	= new CustomTerminal(String name,Binding binding)
	::=  "&" Identifier:name  ws [ Binding:binding ] ;

	*/
	public ResultT!(CustomTerminal) parse_CustomTerminal(){
		debug writefln("parse_CustomTerminal()");
		uint start = position;
		String bind_name;
		Binding bind_binding;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("&").success)){
				goto mismatch112;
			}
			if(!(parse_Identifier().assign!(String)(bind_name))){
				goto mismatch112;
			}
			if(!(parse_ws().success)){
				goto mismatch112;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((parse_Binding().assign!(Binding)(bind_binding))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			goto match111;
		mismatch112:
			position = start;
			goto mismatch110;
		match111:
			clearErrors();
			goto match109;
		}
	match109:
		debug writefln("parse_CustomTerminal() PASS");
		ResultT!(CustomTerminal) passed = ResultT!(CustomTerminal)(new CustomTerminal(bind_name,bind_binding));
		return passed;
	mismatch110:
		position = start;
		ResultT!(CustomTerminal) failed = ResultT!(CustomTerminal)();
		return failed;
	}

	/*
	
Binding
	= new Binding(bool isConcat,String name)
	::=  ":" ws [ "~"]:isConcat   ws Identifier:name ;

	*/
	public ResultT!(Binding) parse_Binding(){
		debug writefln("parse_Binding()");
		uint start = position;
		bool bind_isConcat;
		String bind_name;
		
		
		{//Expression
			uint start = position;
			if(!(terminal(":").success)){
				goto mismatch116;
			}
			if(!(parse_ws().success)){
				goto mismatch116;
			}
			{//OptionalExpr
				uint start = position;
				{//Expression
					uint start = position;
					if((terminal("~").success)){
						clearErrors();
					}else{
						position = start;
					}
				}
				smartAssign!(bool,String)(bind_isConcat,sliceData(start,position));
			}
			if(!(parse_ws().success)){
				goto mismatch116;
			}
			if(!(parse_Identifier().assign!(String)(bind_name))){
				goto mismatch116;
			}
			goto match115;
		mismatch116:
			position = start;
			goto mismatch114;
		match115:
			clearErrors();
			goto match113;
		}
	match113:
		debug writefln("parse_Binding() PASS");
		ResultT!(Binding) passed = ResultT!(Binding)(new Binding(bind_isConcat,bind_name));
		return passed;
	mismatch114:
		position = start;
		ResultT!(Binding) failed = ResultT!(Binding)();
		return failed;
	}

	/*
	
Identifier
	= String value
	::=  ( IdentifierStartChar { IdentifierChar} ):value  ;

	*/
	public ResultT!(String) parse_Identifier(){
		debug writefln("parse_Identifier()");
		uint start = position;
		String bind_value;
		
		
		{//Expression
			uint start = position;
			{//GroupExpr
				uint start = position;
				{//Expression
					uint start = position;
					if(!(parse_IdentifierStartChar().success)){
						goto mismatch122;
					}
					{//ZeroOrMoreExpr
						uint termPos;
					loop123:
						termPos = position;
						{//Expression
							uint start = position;
							if((parse_IdentifierChar().success)){
								clearErrors();
								goto loop123;
							}else{
								setError("Expected IdentifierChar.");
								position = start;
								goto loopend124;
							}
						}
					loopend124:
						{}
					}
					goto match121;
				mismatch122:
					setError("Expected IdentifierStartChar.");
					position = start;
					goto mismatch120;
				match121:
					clearErrors();
				}
				smartAssign!(String,String)(bind_value,sliceData(start,position));
			}
			goto match119;
		mismatch120:
			position = start;
			goto mismatch118;
		match119:
			clearErrors();
			goto match117;
		}
	match117:
		debug writefln("parse_Identifier() PASS");
		return ResultT!(String)(bind_value);
	mismatch118:
		position = start;
		return ResultT!(String)();
	}

	/*
	
IdentifierStartChar
	= String text
	::=  ( letter| "_"):text  ;

	*/
	public ResultT!(String) parse_IdentifierStartChar(){
		debug writefln("parse_IdentifierStartChar()");
		uint start = position;
		String bind_text;
		
		
		{//Expression
			uint start = position;
			{//GroupExpr
				uint start = position;
				{//Expression
					uint start = position;
					if((parse_letter().success) || (terminal("_").success)){
						clearErrors();
					}else{
						setError("Expected Letter.");
						position = start;
						goto mismatch128;
					}
				}
				smartAssign!(String,String)(bind_text,sliceData(start,position));
			}
			goto match127;
		mismatch128:
			position = start;
			goto mismatch126;
		match127:
			clearErrors();
			goto match125;
		}
	match125:
		debug writefln("parse_IdentifierStartChar() PASS");
		return ResultT!(String)(bind_text);
	mismatch126:
		position = start;
		return ResultT!(String)();
	}

	/*
	
IdentifierChar
	= String text
	::=  ( letter| digit| "_"| "."):text  ;

	*/
	public ResultT!(String) parse_IdentifierChar(){
		debug writefln("parse_IdentifierChar()");
		uint start = position;
		String bind_text;
		
		
		{//Expression
			uint start = position;
			{//GroupExpr
				uint start = position;
				{//Expression
					uint start = position;
					if((parse_letter().success) || (parse_digit().success) || (terminal("_").success) || (terminal(".").success)){
						clearErrors();
					}else{
						setError("Expected Letter or Digit.");
						position = start;
						goto mismatch132;
					}
				}
				smartAssign!(String,String)(bind_text,sliceData(start,position));
			}
			goto match131;
		mismatch132:
			position = start;
			goto mismatch130;
		match131:
			clearErrors();
			goto match129;
		}
	match129:
		debug writefln("parse_IdentifierChar() PASS");
		return ResultT!(String)(bind_text);
	mismatch130:
		position = start;
		return ResultT!(String)();
	}

	/*
	
String
	= String text
	::=  "\"" { AnyChar}:text  "\"";

	*/
	public ResultT!(String) parse_String(){
		debug writefln("parse_String()");
		uint start = position;
		String bind_text;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("\"").success)){
				goto mismatch136;
			}
			{//ZeroOrMoreExpr
				uint start = position;
				uint termPos;
			loop137:
				termPos = position;
				{//Expression
					uint start = position;
					if((terminal("\"").success)){
						clearErrors();
						goto loopend138;
					}else{
						position = start;
					}
				}
				{//Expression
					uint start = position;
					if((parse_AnyChar().success)){
						clearErrors();
						goto loop137;
					}else{
						setError("Expected AnyChar.");
						position = start;
						goto mismatch136;
					}
				}
			loopend138:
				smartAssign!(String,String)(bind_text,sliceData(start,termPos));
				{}
			}
			goto match135;
		mismatch136:
			position = start;
			goto mismatch134;
		match135:
			clearErrors();
			goto match133;
		}
	match133:
		debug writefln("parse_String() PASS");
		return ResultT!(String)(bind_text);
	mismatch134:
		position = start;
		return ResultT!(String)();
	}

	/*
	
HexChar
	= String hexToChar(String text)
	::=  "#" ( hexdigit hexdigit):text  ;

	*/
	public ResultT!(String) parse_HexChar(){
		debug writefln("parse_HexChar()");
		uint start = position;
		String bind_text;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("#").success)){
				goto mismatch142;
			}
			{//GroupExpr
				uint start = position;
				{//Expression
					uint start = position;
					if((parse_hexdigit().success && parse_hexdigit().success)){
						clearErrors();
					}else{
						setError("Expected Hexdigit.");
						position = start;
						goto mismatch142;
					}
				}
				smartAssign!(String,String)(bind_text,sliceData(start,position));
			}
			goto match141;
		mismatch142:
			position = start;
			goto mismatch140;
		match141:
			clearErrors();
			goto match139;
		}
	match139:
		debug writefln("parse_HexChar() PASS");
		auto value = hexToChar(bind_text);
		return ResultT!(String)(value);
	mismatch140:
		position = start;
		return ResultT!(String)();
	}

	/*
	
AnyChar
	= String value
	::=  [ "\\":~value ]  any:~value ;

	*/
	public ResultT!(String) parse_AnyChar(){
		debug writefln("parse_AnyChar()");
		uint start = position;
		String bind_value;
		
		
		{//Expression
			uint start = position;
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((terminal("\\").assignCat!(String)(bind_value))){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			if(!(parse_any().assignCat!(String)(bind_value))){
				goto mismatch146;
			}
			goto match145;
		mismatch146:
			position = start;
			goto mismatch144;
		match145:
			clearErrors();
			goto match143;
		}
	match143:
		debug writefln("parse_AnyChar() PASS");
		return ResultT!(String)(bind_value);
	mismatch144:
		position = start;
		return ResultT!(String)();
	}

	/*
	
Comment
	= new Comment(String text)
	::=  "#" { any}:text  eol;

	*/
	public ResultT!(Comment) parse_Comment(){
		debug writefln("parse_Comment()");
		uint start = position;
		String bind_text;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("#").success)){
				goto mismatch150;
			}
			{//ZeroOrMoreExpr
				uint start = position;
				uint termPos;
			loop151:
				termPos = position;
				{//Expression
					uint start = position;
					if((parse_eol().success)){
						clearErrors();
						goto loopend152;
					}else{
						position = start;
					}
				}
				{//Expression
					uint start = position;
					if((parse_any().success)){
						clearErrors();
						goto loop151;
					}else{
						setError("Expected any.");
						position = start;
						goto mismatch150;
					}
				}
			loopend152:
				smartAssign!(String,String)(bind_text,sliceData(start,termPos));
				{}
			}
			goto match149;
		mismatch150:
			position = start;
			goto mismatch148;
		match149:
			clearErrors();
			goto match147;
		}
	match147:
		debug writefln("parse_Comment() PASS");
		ResultT!(Comment) passed = ResultT!(Comment)(new Comment(bind_text));
		return passed;
	mismatch148:
		position = start;
		ResultT!(Comment) failed = ResultT!(Comment)();
		return failed;
	}

	/*
	
Directive
	= Directive dir
	::=  "." ( ImportDirective:~dir | BaseClassDirective:~dir | ClassnameDirective:~dir | DefineDirective:~dir | StartDirective:~dir | IncludeDirective:~dir | AliasDirective:~dir | ModuleDirective:~dir | CodeDirective:~dir ) ;

	*/
	public ResultT!(Directive) parse_Directive(){
		debug writefln("parse_Directive()");
		uint start = position;
		Directive bind_dir;
		
		
		{//Expression
			uint start = position;
			if(!(terminal(".").success)){
				goto mismatch156;
			}
			{//Expression
				uint start = position;
				if((parse_ImportDirective().assignCat!(Directive)(bind_dir)) || (parse_BaseClassDirective().assignCat!(Directive)(bind_dir)) || (parse_ClassnameDirective().assignCat!(Directive)(bind_dir)) || (parse_DefineDirective().assignCat!(Directive)(bind_dir)) || (parse_StartDirective().assignCat!(Directive)(bind_dir)) || (parse_IncludeDirective().assignCat!(Directive)(bind_dir)) || (parse_AliasDirective().assignCat!(Directive)(bind_dir)) || (parse_ModuleDirective().assignCat!(Directive)(bind_dir)) || (parse_CodeDirective().assignCat!(Directive)(bind_dir))){
					clearErrors();
				}else{
					setError("Expected ImportDirective, BaseClassDirective, ClassnameDirective, DefineDirective, StartDirective, IncludeDirective, AliasDirective, ModuleDirective or CodeDirective.");
					position = start;
					goto mismatch156;
				}
			}
			goto match155;
		mismatch156:
			position = start;
			goto mismatch154;
		match155:
			clearErrors();
			goto match153;
		}
	match153:
		debug writefln("parse_Directive() PASS");
		return ResultT!(Directive)(bind_dir);
	mismatch154:
		position = start;
		return ResultT!(Directive)();
	}

	/*
	
ImportDirective
	= new ImportDirective(String imp)
	::=  "import" ws "(" ws DirectiveArg:imp  ws ")" ws ";";

	*/
	public ResultT!(ImportDirective) parse_ImportDirective(){
		debug writefln("parse_ImportDirective()");
		uint start = position;
		String bind_imp;
		
		
		{//Expression
			uint start = position;
			if((terminal("import").success && parse_ws().success && terminal("(").success && parse_ws().success && parse_DirectiveArg().assign!(String)(bind_imp) && parse_ws().success && terminal(")").success && parse_ws().success && terminal(";").success)){
				clearErrors();
				goto match157;
			}else{
				position = start;
				goto mismatch158;
			}
		}
	match157:
		debug writefln("parse_ImportDirective() PASS");
		ResultT!(ImportDirective) passed = ResultT!(ImportDirective)(new ImportDirective(bind_imp));
		return passed;
	mismatch158:
		position = start;
		ResultT!(ImportDirective) failed = ResultT!(ImportDirective)();
		return failed;
	}

	/*
	
BaseClassDirective
	= new BaseClassDirective(String name)
	::=  "baseclass" ws "(" ws DirectiveArg:name  ws ")" ws ";";

	*/
	public ResultT!(BaseClassDirective) parse_BaseClassDirective(){
		debug writefln("parse_BaseClassDirective()");
		uint start = position;
		String bind_name;
		
		
		{//Expression
			uint start = position;
			if((terminal("baseclass").success && parse_ws().success && terminal("(").success && parse_ws().success && parse_DirectiveArg().assign!(String)(bind_name) && parse_ws().success && terminal(")").success && parse_ws().success && terminal(";").success)){
				clearErrors();
				goto match159;
			}else{
				position = start;
				goto mismatch160;
			}
		}
	match159:
		debug writefln("parse_BaseClassDirective() PASS");
		ResultT!(BaseClassDirective) passed = ResultT!(BaseClassDirective)(new BaseClassDirective(bind_name));
		return passed;
	mismatch160:
		position = start;
		ResultT!(BaseClassDirective) failed = ResultT!(BaseClassDirective)();
		return failed;
	}

	/*
	
ClassnameDirective
	= new ClassnameDirective(String name)
	::=  "classname" ws "(" ws DirectiveArg:name  ws ")" ws ";";

	*/
	public ResultT!(ClassnameDirective) parse_ClassnameDirective(){
		debug writefln("parse_ClassnameDirective()");
		uint start = position;
		String bind_name;
		
		
		{//Expression
			uint start = position;
			if((terminal("classname").success && parse_ws().success && terminal("(").success && parse_ws().success && parse_DirectiveArg().assign!(String)(bind_name) && parse_ws().success && terminal(")").success && parse_ws().success && terminal(";").success)){
				clearErrors();
				goto match161;
			}else{
				position = start;
				goto mismatch162;
			}
		}
	match161:
		debug writefln("parse_ClassnameDirective() PASS");
		ResultT!(ClassnameDirective) passed = ResultT!(ClassnameDirective)(new ClassnameDirective(bind_name));
		return passed;
	mismatch162:
		position = start;
		ResultT!(ClassnameDirective) failed = ResultT!(ClassnameDirective)();
		return failed;
	}

	/*
	
DefineDirective
	= new DefineDirective(String returnType,String name,bool isTerminal,String description)
	::=  "define" ws "(" ws DirectiveArg:returnType  ws "," ws DirectiveArg:name  ws "," ws DirectiveArg:isTerminal  ws [ "," ws DirectiveArg:description  ws]  ")" ws ";";

	*/
	public ResultT!(DefineDirective) parse_DefineDirective(){
		debug writefln("parse_DefineDirective()");
		uint start = position;
		String bind_returnType;
		String bind_name;
		bool bind_isTerminal;
		String bind_description;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("define").success)){
				goto mismatch166;
			}
			if(!(parse_ws().success)){
				goto mismatch166;
			}
			if(!(terminal("(").success)){
				goto mismatch166;
			}
			if(!(parse_ws().success)){
				goto mismatch166;
			}
			if(!(parse_DirectiveArg().assign!(String)(bind_returnType))){
				goto mismatch166;
			}
			if(!(parse_ws().success)){
				goto mismatch166;
			}
			if(!(terminal(",").success)){
				goto mismatch166;
			}
			if(!(parse_ws().success)){
				goto mismatch166;
			}
			if(!(parse_DirectiveArg().assign!(String)(bind_name))){
				goto mismatch166;
			}
			if(!(parse_ws().success)){
				goto mismatch166;
			}
			if(!(terminal(",").success)){
				goto mismatch166;
			}
			if(!(parse_ws().success)){
				goto mismatch166;
			}
			if(!(parse_DirectiveArg().assign!(bool)(bind_isTerminal))){
				goto mismatch166;
			}
			if(!(parse_ws().success)){
				goto mismatch166;
			}
			{//OptionalExpr
				{//Expression
					uint start = position;
					if((terminal(",").success && parse_ws().success && parse_DirectiveArg().assign!(String)(bind_description) && parse_ws().success)){
						clearErrors();
					}else{
						position = start;
					}
				}
			}
			if(!(terminal(")").success)){
				goto mismatch166;
			}
			if(!(parse_ws().success)){
				goto mismatch166;
			}
			if(!(terminal(";").success)){
				goto mismatch166;
			}
			goto match165;
		mismatch166:
			position = start;
			goto mismatch164;
		match165:
			clearErrors();
			goto match163;
		}
	match163:
		debug writefln("parse_DefineDirective() PASS");
		ResultT!(DefineDirective) passed = ResultT!(DefineDirective)(new DefineDirective(bind_returnType,bind_name,bind_isTerminal,bind_description));
		return passed;
	mismatch164:
		position = start;
		ResultT!(DefineDirective) failed = ResultT!(DefineDirective)();
		return failed;
	}

	/*
	
StartDirective
	= new StartDirective(String production)
	::=  "start" ws "(" ws DirectiveArg:production  ws ")" ws ";";

	*/
	public ResultT!(StartDirective) parse_StartDirective(){
		debug writefln("parse_StartDirective()");
		uint start = position;
		String bind_production;
		
		
		{//Expression
			uint start = position;
			if((terminal("start").success && parse_ws().success && terminal("(").success && parse_ws().success && parse_DirectiveArg().assign!(String)(bind_production) && parse_ws().success && terminal(")").success && parse_ws().success && terminal(";").success)){
				clearErrors();
				goto match167;
			}else{
				position = start;
				goto mismatch168;
			}
		}
	match167:
		debug writefln("parse_StartDirective() PASS");
		ResultT!(StartDirective) passed = ResultT!(StartDirective)(new StartDirective(bind_production));
		return passed;
	mismatch168:
		position = start;
		ResultT!(StartDirective) failed = ResultT!(StartDirective)();
		return failed;
	}

	/*
	
IncludeDirective
	= new IncludeDirective(String filename)
	::=  "include" ws "(" ws String:filename  ws ")" ws ";";

	*/
	public ResultT!(IncludeDirective) parse_IncludeDirective(){
		debug writefln("parse_IncludeDirective()");
		uint start = position;
		String bind_filename;
		
		
		{//Expression
			uint start = position;
			if((terminal("include").success && parse_ws().success && terminal("(").success && parse_ws().success && parse_String().assign!(String)(bind_filename) && parse_ws().success && terminal(")").success && parse_ws().success && terminal(";").success)){
				clearErrors();
				goto match169;
			}else{
				position = start;
				goto mismatch170;
			}
		}
	match169:
		debug writefln("parse_IncludeDirective() PASS");
		ResultT!(IncludeDirective) passed = ResultT!(IncludeDirective)(new IncludeDirective(bind_filename));
		return passed;
	mismatch170:
		position = start;
		ResultT!(IncludeDirective) failed = ResultT!(IncludeDirective)();
		return failed;
	}

	/*
	
AliasDirective
	= new AliasDirective(String rule,String ruleAlias)
	::=  "alias" ws "(" ws DirectiveArg:rule  ws "," ws DirectiveArg:ruleAlias  ws ")" ws ";";

	*/
	public ResultT!(AliasDirective) parse_AliasDirective(){
		debug writefln("parse_AliasDirective()");
		uint start = position;
		String bind_rule;
		String bind_ruleAlias;
		
		
		{//Expression
			uint start = position;
			if((terminal("alias").success && parse_ws().success && terminal("(").success && parse_ws().success && parse_DirectiveArg().assign!(String)(bind_rule) && parse_ws().success && terminal(",").success && parse_ws().success && parse_DirectiveArg().assign!(String)(bind_ruleAlias) && parse_ws().success && terminal(")").success && parse_ws().success && terminal(";").success)){
				clearErrors();
				goto match171;
			}else{
				position = start;
				goto mismatch172;
			}
		}
	match171:
		debug writefln("parse_AliasDirective() PASS");
		ResultT!(AliasDirective) passed = ResultT!(AliasDirective)(new AliasDirective(bind_rule,bind_ruleAlias));
		return passed;
	mismatch172:
		position = start;
		ResultT!(AliasDirective) failed = ResultT!(AliasDirective)();
		return failed;
	}

	/*
	
ModuleDirective
	= new ModuleDirective(String moduleName)
	::=  "module" ws "(" ws DirectiveArg:moduleName  ws ")" ws ";";

	*/
	public ResultT!(ModuleDirective) parse_ModuleDirective(){
		debug writefln("parse_ModuleDirective()");
		uint start = position;
		String bind_moduleName;
		
		
		{//Expression
			uint start = position;
			if((terminal("module").success && parse_ws().success && terminal("(").success && parse_ws().success && parse_DirectiveArg().assign!(String)(bind_moduleName) && parse_ws().success && terminal(")").success && parse_ws().success && terminal(";").success)){
				clearErrors();
				goto match173;
			}else{
				position = start;
				goto mismatch174;
			}
		}
	match173:
		debug writefln("parse_ModuleDirective() PASS");
		ResultT!(ModuleDirective) passed = ResultT!(ModuleDirective)(new ModuleDirective(bind_moduleName));
		return passed;
	mismatch174:
		position = start;
		ResultT!(ModuleDirective) failed = ResultT!(ModuleDirective)();
		return failed;
	}

	/*
	
CodeDirective
	= new CodeDirective(String code)
	::=  "code" ws "{{{" { any}:code  "}}}";

	*/
	public ResultT!(CodeDirective) parse_CodeDirective(){
		debug writefln("parse_CodeDirective()");
		uint start = position;
		String bind_code;
		
		
		{//Expression
			uint start = position;
			if(!(terminal("code").success)){
				goto mismatch178;
			}
			if(!(parse_ws().success)){
				goto mismatch178;
			}
			if(!(terminal("{{{").success)){
				goto mismatch178;
			}
			{//ZeroOrMoreExpr
				uint start = position;
				uint termPos;
			loop179:
				termPos = position;
				{//Expression
					uint start = position;
					if((terminal("}}}").success)){
						clearErrors();
						goto loopend180;
					}else{
						position = start;
					}
				}
				{//Expression
					uint start = position;
					if((parse_any().success)){
						clearErrors();
						goto loop179;
					}else{
						setError("Expected any.");
						position = start;
						goto mismatch178;
					}
				}
			loopend180:
				smartAssign!(String,String)(bind_code,sliceData(start,termPos));
				{}
			}
			goto match177;
		mismatch178:
			position = start;
			goto mismatch176;
		match177:
			clearErrors();
			goto match175;
		}
	match175:
		debug writefln("parse_CodeDirective() PASS");
		ResultT!(CodeDirective) passed = ResultT!(CodeDirective)(new CodeDirective(bind_code));
		return passed;
	mismatch176:
		position = start;
		ResultT!(CodeDirective) failed = ResultT!(CodeDirective)();
		return failed;
	}

	/*
	
DirectiveArg
	= String arg
	::=  Identifier:arg | String:arg ;

	*/
	public ResultT!(String) parse_DirectiveArg(){
		debug writefln("parse_DirectiveArg()");
		uint start = position;
		String bind_arg;
		
		
		{//Expression
			uint start = position;
			if((parse_Identifier().assign!(String)(bind_arg)) || (parse_String().assign!(String)(bind_arg))){
				clearErrors();
				goto match181;
			}else{
				setError("Expected Identifier or String.");
				position = start;
				goto mismatch182;
			}
		}
	match181:
		debug writefln("parse_DirectiveArg() PASS");
		return ResultT!(String)(bind_arg);
	mismatch182:
		position = start;
		return ResultT!(String)();
	}

}
