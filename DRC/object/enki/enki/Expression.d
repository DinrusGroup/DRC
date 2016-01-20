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
module enki.Expression;

private import enki.types;
private import enki.CodeGenerator;
private import enki.EnkiBackend;
private import enki.Rule;

private import std.stdio;

class Expression  : IRenderable{
	SubExpression[][] terms;
	bool areAllShort;
	bool[] isShort;
	String errorText;
	
	public this(SubExpression[][] terms){
		this.terms = terms;
		assert(terms.length > 0);
	}
	
	public this(SubExpression[] factors...){
		assert(factors.length > 0);
		this.terms ~= factors.dup;
	}

	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		// determine short expressions and error expressions
		areAllShort = true;
		String[] keyTerms;
		foreach(uint i,SubExpression[] term; terms){
			bool thisIsShort = true;
			
			auto firstShort = cast(ShortExpression)term[0];
			if(firstShort){
				if(firstShort.isDescribable){
					keyTerms ~= firstShort.getDescription();
				}
			}
			
			// test entire term for shorthand and run semantic passes
			foreach(SubExpression expr; term){
				if(!cast(ShortExpression)expr){
					thisIsShort = false;
				}
				expr.semanticPass(thisRule,root);
			}
			
			this.isShort ~= thisIsShort;
			if(!thisIsShort) areAllShort = false;
		}
		
		// build up the error expression
		errorText = "";
		foreach(i,term; keyTerms){
			if(!root.isTerminal(term)) continue;
			
			String terminalName = root.getTerminalName(term);
			if(i == 0){
				errorText ~= terminalName;
			}
			else if(i == keyTerms.length-1 && keyTerms.length > 1){
				errorText ~= " or " ~ terminalName;
			}
			else{
				errorText ~= ", " ~ terminalName;
			}
		}
		if(errorText.length > 0){
			errorText = "Expected " ~ errorText ~ ".";	
		}
	}
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		String type = null; // doesn't exist
				
		debug writefln("Expression.resolveBindingType %s",name);
		foreach(SubExpression[] term; terms){
			foreach(SubExpression expr; term){
				String exprType = expr.resolveBindingType(name,root);
				if(!type) type = exprType;
				else if(exprType && type != exprType){
					debug writefln("type %s vs type %s",type,exprType);
					throw new Exception("Cannot resolve type of binding '" ~ name ~ "' as it resolves to more than one type.");
				}
			}
		}
		return type;	
	}
	
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		Statement clearError = new Call("clearErrors");
		Statement raiseError;
		
		if(errorText.length > 0 && !fail.isEmpty){
			 raiseError = new CompositeStatement(
			 	//clearError, // experimental
			 	new Call("setError","\"" ~ errorText ~"\"")
			 );
		}
		else{
			raiseError = Statement.empty;
		}		
		
		if(areAllShort){
			String text = "";
			bool isFirstTerm = true;
			foreach(SubExpression[] term; terms){
				if(isFirstTerm){
					isFirstTerm = false;
					text ~= "(";
				}
				else{
					text ~= " || (";
				}
				bool isFirstFactor = true;
				foreach(SubExpression factor; term){
					if(isFirstFactor){
						isFirstFactor = false;
					}
					else{
						text ~= " && ";
					}
					text ~= (cast(ShortExpression)factor).renderShort();
				}
				text ~= ")";
			}
			
			
			with(generator){
				emit("{//Expression");
				indent();
					emit("uint start = position;");
					renderIfTest(text, 
						new CompositeStatement(clearError,pass), 
						new CompositeStatement(
							raiseError,
							new Literal("position = start;"), // unwind on failure of expression
							fail
						)
					);
				unindent();
				emit("}");
			}
		}
		else{
			assert(isShort.length == terms.length);
			with(generator){
				auto matchLabel = new Label("match");
				auto gotoMatch = new Goto(matchLabel);
				
				emit("{//Expression");
				indent();
					emit("uint start = position;");
					foreach(uint i,SubExpression[] term; terms){ // or grouping
						if(isShort[i]){
							String text = "";
							bool isFirstFactor = true;
							foreach(SubExpression expr; term){
								if(isFirstFactor){
									isFirstFactor = false;
								}
								else{
									text ~= " && ";
								}
								text ~= (cast(ShortExpression)expr).renderShort();
							}
							renderIfTest(text, gotoMatch, Statement.empty);
						}
						else{
							auto mismatchLabel = new Label("mismatch");
							auto gotoMismatch = new Goto(mismatchLabel);							
							foreach(SubExpression expr; term){ // and grouping
								renderFail(expr,gotoMismatch);
							}
							render(gotoMatch);							
							render(mismatchLabel);
						}						
					}
					render(raiseError);
					emit("position = start;"); // unwind on failure of expression
					render(fail);
					render(matchLabel);
					render(clearError);
					render(pass);
				unindent();
				emit("}");
			}
		}
	}
	
	public String toBNF(){
		String result = "";
		
		foreach(uint i,SubExpression[] term; terms){
			if(i != 0) result ~= "|";
			foreach(SubExpression expr; term){
				result ~= " " ~ expr.toBNF();
			}
		}
		return result;
	}
}

interface SubExpression : IRenderable{
	public void semanticPass(Rule thisRule,BaseEnkiParser root);
	public String resolveBindingType(String name,BaseEnkiParser root);
	public void render(CodeGenerator generator,Statement pass,Statement fail);
	public String toBNF();	
}

alias SubExpression[] Term;

interface ShortExpression{
	public String getDescription();
	public bool isDescribable();
	public String renderShort();
}

class Production : SubExpression, ShortExpression{
	String name;
	String desc;
	String type;
	Binding binding;
	ProductionArg[] args;
	
	public this(String name,Binding binding,ProductionArg[] args...){
		this.name = name;
		this.desc = name;
		this.binding = binding;
		this.args = args.dup;
	}
	
	public String getDescription(){
		return desc;	
	}
	
	//TODO: determine this via some semantic pass and if the production is user-defined or not.
	public bool isDescribable(){
		return true;
	}
	
	public String renderShort(){
		String result = "parse_" ~ name ~ "(";
		
		foreach(uint i,arg; args){
			if(i == 0){
				result ~= arg.toString();
			}
			else{
				result ~= "," ~ arg.toString();
			}
		}
	
		if(binding){
			result ~= ")" ~ binding.postAssignExpr();
		}
		else{
			result ~= ").success";
		}
		
		return result;
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		type = root.getTypeForRule(name);
		
		//TODO: match each arg up to the rule predicate params, and determine each type
		
		foreach(arg; args){
			BindingProductionArg bindingArg = cast(BindingProductionArg)arg;
			if(bindingArg){
				bindingArg.semanticPass(thisRule,root);
			}
		}
		if(binding) binding.semanticPass(thisRule,root);
	}
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		debug writefln("Production.resolveBindingType (%s) %s",this.name,name);
		if(binding && binding.name == name){
			debug writefln("--match %s ",type);
			return type;
		}
		return null;
	}

	public void render(CodeGenerator generator,Statement pass,Statement fail){
		generator.renderIfTest(renderShort(), pass, fail);
	}
	
	public String toBNF(){
		String result = name;
		if(args.length > 0){
			result ~= "!(";
			foreach(uint i,arg; args){
				if(i == 0){
					result ~= arg.toBNF();
				}
				else{
					result ~= "," ~ arg.toBNF();
				}
			}
			result ~= ")";
		}
		if(binding) result ~= binding.toBNF();
		return result;
	}
}

abstract class ProductionArg{
	public String toString();
	public String toBNF();
}

class StringProductionArg : ProductionArg{
	String value;
	public this(String value){
		this.value = value;
	}
	
	public String toString(){
	//TODO: use a smart cast here...?
		return "\"" ~ value ~ "\"";
	}
	
	public String toBNF(){
		return toString();
	}
}

class BindingProductionArg : ProductionArg{
	String name;
	String type;
	
	public this(String name){
		this.name = name;
	}

	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		thisRule.resolveBinding(name);
		type = thisRule.resolveBindingType(name,root);	
	}
	
	public String toString(){
	//TODO: use a smart cast here...?
		return "bind_" ~ name;
	}
	
	public String toBNF(){
		return name;
	}
}

class GroupExpr : SubExpression{
	Expression expr;
	Binding binding;
	
	public this(Expression expr,Binding binding){
		this.expr = expr;
		this.binding = binding;
	}
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		String type = null; // doesn't exist
				
		debug writefln("GroupExpr.resolveBindingType");
		String exprType = null;
		if(binding && binding.name == name){
			exprType = "String";
		}
		type = expr.resolveBindingType(name,root);
		
		if(!type) type = exprType;
		else if(exprType && type != exprType){
			debug writefln("type %s vs type %s",type,exprType);
			throw new Exception("Cannot resolve type of binding '" ~ name ~ "' as it resolves to more than one type.");
		}
		
		return type;		
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		expr.semanticPass(thisRule,root);
		if(binding) binding.semanticPass(thisRule,root);
	}	

	public void render(CodeGenerator generator,Statement pass,Statement fail){
		if(binding){
			with(generator){
				emit("{//GroupExpr");
				indent();
					emit("uint start = position;");
					render(expr,pass,fail);
					emit(binding.assignExpr("String","sliceData(start,position)")~";");				
				unindent();
				emit("}");
			}
		}
		else{
			generator.render(expr,pass,fail);
		}
	}
	
	public String toBNF(){
		if(binding) return "(" ~ expr.toBNF() ~ ")" ~ binding.toBNF() ~ " ";
		 return "(" ~ expr.toBNF() ~ ") ";
	}	
}

class OptionalExpr : SubExpression{
	Expression expr;
	Binding binding;
	
	public this(Expression expr,Binding binding){
		this.expr = expr;
		this.binding = binding;
	}

	public String resolveBindingType(String name,BaseEnkiParser root){
		String type = null; // doesn't exist
				
		debug writefln("OptionalExpr.resolveBindingType");
		String exprType = null;
		if(binding && binding.name == name){
			exprType = "String";
		}
		type = expr.resolveBindingType(name,root);
		
		if(!type) type = exprType;
		else if(exprType && type != exprType){
			debug writefln("type %s vs type %s",type,exprType);
			throw new Exception("Cannot resolve type of binding '" ~ name ~ "' as it resolves to more than one type.");
		}
		
		return type;			
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		expr.semanticPass(thisRule,root);
		if(binding) binding.semanticPass(thisRule,root);
	}	
	
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		with(generator){
			emit("{//OptionalExpr");
			indent();
				if(binding)	emit("uint start = position;");
				
				render(expr);
				
				if(binding) emit(binding.assignExpr("String","sliceData(start,position)")~";");				
			unindent();
			emit("}");
		}		
	}
	
	public String toBNF(){
		if(binding) return "[" ~ expr.toBNF() ~ "]" ~ binding.toBNF()~ " ";
		 return "[" ~ expr.toBNF() ~ "] ";
	}		
}

class ZeroOrMoreExpr : SubExpression{
	Expression expr;
	Binding binding;
	Expression term;
	
	public this(Expression expr,Binding binding,Expression term){
		this.expr = expr;
		this.binding = binding;
		this.term = term;
		
		//if(!this.term){
		//	this.term = new Expression(new Production("eoi",null));
		//}
	}
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		debug writefln("ZeroOrMoreExpr.resolveBindingType");
		String type = null;
		String exprType = null;
				
		if(binding && binding.name == name){
			type = "String";
		}
		exprType = expr.resolveBindingType(name,root);
		
		if(!type) type = exprType;
		else if(exprType && type != exprType){
			debug writefln("type %s vs type %s",type,exprType);
			throw new Exception("Cannot resolve type of binding '" ~ name ~ "' as it resolves to more than one type.");
		}
		
		if(term){
			exprType = term.resolveBindingType(name,root);
			
			if(!type) type = exprType;
			else if(exprType && type != exprType){
				debug writefln("type %s vs type %s",type,exprType);
				throw new Exception("Cannot resolve type of binding '" ~ name ~ "' as it resolves to more than one type.");
			}
		}

		return type;		
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		expr.semanticPass(thisRule,root);
		if(binding) binding.semanticPass(thisRule,root);
		if(term) term.semanticPass(thisRule,root);
	}		
	 
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		auto loopStart = new Label("loop");
		auto loopEnd = new Label("loopend");
		auto gotoLoop = new Goto(loopStart);
		auto gotoLoopEnd = new Goto(loopEnd);

		Statement raiseTermError;
		if(term && term.errorText.length > 0){
			raiseTermError = new Call("setError","\"" ~ term.errorText ~ "\"");
		}
		else{
			raiseTermError = Statement.empty;
		}
		
		Statement exprFail = fail;
		if(!term){
			exprFail = gotoLoopEnd; 
		}
		
		with(generator){						
			emit("{//ZeroOrMoreExpr"); 
			indent();
				if(term) emit("uint start = position;");
				emit("uint termPos;");
				render(loopStart);
	
				emit("termPos = position;");
				if(term){
					renderPass(term,gotoLoopEnd);
					/*emit("if(termPos != start && termPos == position){");
						indent();
						render(raiseTermError);
						render(fail);
						unindent();
					emit("}");*/
				}		
				render(expr,gotoLoop,exprFail);
				
				render(loopEnd);
				if(binding) emit(binding.assignExpr("String","sliceData(start,termPos)")~";");
				render(pass);
				emit("{}");
			unindent();
			emit("}");
		}
	}
	
	public String toBNF(){
		String result = "{" ~ expr.toBNF() ~ "}";
		if(binding) result ~= binding.toBNF();
		else result ~= " ";
		if(term) result ~= term.toBNF();
		return result;
	}		
}

class Terminal : SubExpression, ShortExpression{
	String text;
	Binding binding;
	
	public this(String text,Binding binding){
		this.text = text;
		this.binding = binding;
	}
	
	public String getDescription(){
		return "\\\"" ~ text ~ "\\\"";
	}	
	
	public bool isDescribable(){
		return false; // set to false, to reduce error noise
	}	
	
	public String renderShort(){		
		if(binding){
			return "terminal(\"" ~ text ~ "\")" ~ binding.postAssignExpr();
		}
		else{
			return "terminal(\"" ~ text ~ "\").success";
		}			
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		if(binding) binding.semanticPass(thisRule,root);
	}	
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		debug writefln("Terminal.resolveBindingType %s",text);
		if(binding && binding.name == name){
			return "String";
		}
		return null;
	}	
	
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		generator.renderIfTest(renderShort(), pass, fail);
	}
			
	public String toBNF(){
		if(binding){
			return "\"" ~ text ~ "\"" ~ binding.toBNF();
		}
		else{
			return "\"" ~ text ~ "\"";
		}
	}	
}

class Regexp : SubExpression, ShortExpression{
	String text;
	Binding binding;
	
	public this(String text,Binding binding){
		this.text = text;
		this.binding = binding;
	}
	
	public String getDescription(){
		return "`" ~ text ~ "`";
	}	
	
	public bool isDescribable(){
		return false; // set to false, to reduce error noise
	}	
	
	public String renderShort(){		
		if(binding){
			return "regexp(`" ~ text ~ "`)" ~ binding.postAssignExpr();
		}
		else{
			return "regexp(`" ~ text ~ "`).success";
		}			
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		if(binding) binding.semanticPass(thisRule,root);
	}	
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		debug writefln("Regexp.resolveBindingType %s",text);
		if(binding && binding.name == name){
			return "String";
		}
		return null;
	}	
	
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		generator.renderIfTest(renderShort(), pass, fail);
	}
			
	public String toBNF(){
		if(binding){
			return "`" ~ text ~ "`" ~ binding.toBNF();
		}
		else{
			return "`" ~ text ~ "`";
		}
	}	
}

class Substitution : SubExpression, ShortExpression{
	Binding binding;
	String bindingName;
	String type;
	
	public this(String bindingName,Binding binding){
		this.bindingName = bindingName;
		this.binding = binding;
	}
	
	public String getDescription(){
		return "";
	}	
	
	public bool isDescribable(){
		return false; // set to false, to reduce error noise
	}	
	
	public String renderShort(){
		//TODO: use a smart cast here from the binding to a string
		if(binding){
			return "terminal(convert!(String," ~ type ~ ")(bind_" ~ bindingName ~ "))" ~ binding.postAssignExpr();
		}
		else{
			return "terminal(convert!(String," ~ type ~ ")(bind_" ~ bindingName ~ ")).success";
		}			
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		thisRule.resolveBinding(bindingName);
		this.type = thisRule.resolveBindingType(bindingName,root);
		
		if(binding) binding.semanticPass(thisRule,root);
	}	
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		debug writefln("Terminal.resolveBindingType %s",bindingName);
		if(binding && binding.name == name){
			return "String";
		}
		return null;
	}	
	
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		generator.renderIfTest(renderShort(), pass, fail);
	}
			
	public String toBNF(){
		if(binding){
			return "." ~ bindingName ~ binding.toBNF();
		}
		else{
			return "." ~ bindingName;
		}
	}	
}

class Negate : SubExpression{
	SubExpression expr;
	
	public this(SubExpression expr){
		this.expr = expr;
	}

	public String resolveBindingType(String name,BaseEnkiParser root){
		return expr.resolveBindingType(name,root);			
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		expr.semanticPass(thisRule,root);
	}	
	
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		auto matchLabel = new Label("match");
		auto gotoMatch = new Goto(matchLabel);
		auto mismatchLabel = new Label("mismatch");
		auto gotoMismatch = new Goto(mismatchLabel);
		
		with(generator){
			emit("{//Negate");
			indent();
				render(expr,gotoMatch,gotoMismatch);
								
				render(matchLabel);
				render(fail);
				
				render(mismatchLabel);
				render(pass);
			unindent();
			emit("}");
		}		
	}
	
	public String toBNF(){
		 return "!" ~ expr.toBNF();
	}		
}

class Test : SubExpression{
	SubExpression expr;
	
	public this(SubExpression expr){
		this.expr = expr;
	}

	public String resolveBindingType(String name,BaseEnkiParser root){
		return expr.resolveBindingType(name,root);			
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		expr.semanticPass(thisRule,root);
	}	
	
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		auto matchLabel = new Label("match");
		auto gotoMatch = new Goto(matchLabel);
		auto mismatchLabel = new Label("mismatch");
		auto gotoMismatch = new Goto(mismatchLabel);
		
		with(generator){
			emit("{//Test");
			indent();
				emit("uint start = position;");
				render(expr,gotoMatch,gotoMismatch);
				
				render(mismatchLabel);
				render(fail);
								
				render(matchLabel);
				emit("position = start;");
				render(pass);

			unindent();
			emit("}");
		}		
	}
	
	public String toBNF(){
		 return "/" ~ expr.toBNF();
	}		
}


class LiteralExpr: SubExpression{
	Binding binding;
	String literalName;
	ProductionArg[] args;
	
	public this(String literalName,Binding binding,ProductionArg[] args...){
		this.literalName = literalName;
		this.binding = binding;
		this.args = args.dup;
	}
	
	public String getDescription(){
		return "";
	}	
	
	public bool isDescribable(){
		return false; // set to false, to reduce error noise
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){		
		//TODO: match each arg up to the rule predicate params, and determine each type
		foreach(arg; args){
			BindingProductionArg bindingArg = cast(BindingProductionArg)arg;
			if(bindingArg){
				bindingArg.semanticPass(thisRule,root);
			}
		}
		if(binding) binding.semanticPass(thisRule,root);
	}
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		debug writefln("LiteralExpr.resolveBindingType %s",literalName);
		// cannot resolve binding type 
		return null;
	}	
	
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		String result = this.literalName;
		
		if(args.length > 0){
			result ~= "(";		
			foreach(uint i,arg; args){
				if(i == 0){
					result ~= arg.toString();
				}
				else{
					result ~= "," ~ arg.toString();
				}
			}
			result ~= ")";
		}
		if(binding){
			result = binding.blindAssignExpr(result);
		}
				
		generator.emit(result ~ ";");
	}
			
	public String toBNF(){
		String result = "@" ~ literalName;
		if(args.length > 0){
			result ~= "!(";
			foreach(uint i,arg; args){
				if(i == 0){
					result ~= arg.toBNF();
				}
				else{
					result ~= "," ~ arg.toBNF();
				}
			}
			result ~= ")";
		}
		if(binding) result ~= binding.toBNF();
		return result;		
	}	
}

class CustomTerminal : SubExpression, ShortExpression{
	String name;
	Binding binding;
	
	public this(String name,Binding binding){
		this.name = name;
		this.binding = binding;
	}
	
	public String getDescription(){
		return "\\\"" ~ name ~ "\\\"";
	}	
	
	public bool isDescribable(){
		return false; // set to false, to reduce error noise
	}	
	
	public String renderShort(){		
		if(binding){
			return "terminal(" ~ name ~ ")" ~ binding.postAssignExpr();
		}
		else{
			return "terminal(" ~ name ~ ").success";
		}			
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		if(binding) binding.semanticPass(thisRule,root);
	}	
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		debug writefln("Terminal.resolveBindingType %s",name);
		if(binding && binding.name == name){
			return "String";
		}
		return null;
	}	
	
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		generator.renderIfTest(renderShort(), pass, fail);
	}
			
	public String toBNF(){
		if(binding){
			return "&" ~ name ~ binding.toBNF();
		}
		else{
			return "&" ~ name;
		}
	}	
}

class Binding{
	bool isConcat;
	String name;
	String type;
	
	public this(bool isConcat,String name){
		this.isConcat = isConcat;
		this.name = name;
	}
	
	public String assignExpr(String type,String rvalue){
		if(isConcat){
			return "smartAssignCat!(" ~ this.type ~ "," ~ type ~ ")(bind_" ~ name ~ "," ~ rvalue ~ ")";
		}
		else{
			return "smartAssign!(" ~ this.type ~ "," ~ type ~ ")(bind_" ~ name ~ "," ~ rvalue ~ ")";
		}
	}
	
	public String blindAssignExpr(String rvalue){
		if(isConcat){
			return "smartAssignCat(bind_" ~ name ~ "," ~ rvalue ~ ")";
		}
		else{
			return "smartAssign(bind_" ~ name ~ "," ~ rvalue ~ ")";
		}
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		thisRule.resolveBinding(name); // ensure that the binding is declared
		type = thisRule.resolveBindingType(name,root); // find the type
	}
	
	public String postAssignExpr(){
		if(isConcat){
			return ".assignCat!(" ~ type ~ ")(bind_" ~ name ~ ")";
		}
		else{
			return ".assign!(" ~ type ~ ")(bind_" ~ name ~ ")";
		}
	}
	
	public String toBNF(){
		String result = ":";
		if(isConcat) result ~= "~";
		result ~= name ~ " ";
		return result;
	}		
}