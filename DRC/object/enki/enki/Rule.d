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
module enki.Rule;

private import enki.types;
private import enki.EnkiBackend;
private import enki.Expression;
private import enki.CodeGenerator;

private import std.stdio;

class Rule : SyntaxLine, IRenderable{
	String name;
	RulePredicate pred;
	Expression expr;
	RuleDecl decl;
	String lhs;
	String type;
	bool semanticDone;
	Param[String] params;
		
	public this(String name,RulePredicate pred,Expression expr,RuleDecl decl=null){
		this.name = name;
		this.pred = pred;
		this.expr = expr;
		this.decl = decl;
		
		if(!pred){
			this.pred = new DefaultPredicate();
		}
		if(!decl){
			this.decl = new RuleDecl();
		}
	}
	
	public void semanticPass(BaseEnkiParser root){
		try{
			if(semanticDone) return;
			semanticDone = true;
			
			expr.semanticPass(this,root);
			pred.semanticPass(this,root);
			decl.semanticPass(this,root);
			
			foreach(param; params){
				param.semanticPass(this,root);
			}
			
			type = pred.getType(this,root);
		}
		catch(Exception e){
			throw new Exception("during semantic pass of Rule '" ~ name ~ "'\n" ~ e.toString());			
		}
	}
		
	public String getType(BaseEnkiParser root){
		if(!semanticDone) semanticPass(root);
		if(type) return type;
		
		type = pred.getType(this,root);
		
		return type;
	}
	
	public String resolveBindingType(String name,BaseEnkiParser root){
		debug writefln("%s Rule.resolveBindingType %s",this.name,name);
		String type = decl.resolveBindingType(name);
		if(!type) type = pred.resolveBindingType(name);
		if(!type) type = expr.resolveBindingType(name,root);
		
		//resolve using params
		if(!type) foreach(param; params){
			if(param.name == name && param.realType != null){
				type = param.realType;
				break;
			}
		}

		
		return type;
	}
		
	public void resolveBinding(String name){
		if(pred.resolveBinding(name)) return;
		if(decl.resolveBinding(name)) return;
		
		this.params[name] = new Param(name);
		
		//throw new Exception("Binding '" ~ name ~ "' is not declared.");
	}	
			
	public void render(CodeGenerator generator,Statement pass,Statement fail){
		auto matchLabel = new Label("match");
		auto gotoMatch = new Goto(matchLabel);
		auto mismatchLabel = new Label("mismatch");
		auto gotoMismatch = new Goto(mismatchLabel);
		
		with(generator){
			indent();
				emit("/*");
				emit(this.toBNF());
				emit("*/");
				
				emit("public ResultT!(" ~ type ~ ") parse_" ~ name ~ "(" ~ decl.renderDeclaration() ~ "){");
				indent();
					emit("debug writefln(\"parse_" ~ name ~ "()\");");
					emit("uint start = position;");
					pred.renderDeclarations(generator,decl.params);
					emit("");
					foreach(param; params){
						emit(param.toString() ~ ";");
					}
					emit("");
					render(expr,gotoMatch,gotoMismatch);
					
					render(matchLabel);
					emit("debug writefln(\"parse_" ~ name ~ "() PASS\");");
					pred.renderPass(generator);
					
					render(mismatchLabel);
					emit("position = start;");
					pred.renderFail(generator);
								
				unindent();
				emit("}");
			unindent();
			emit("");
		}
	}
	
	public String toBNF(){		
		String result = "\n" ~ name ~ decl.toBNF() ~ "\n";
		if(!(cast(DefaultPredicate)pred)) result ~= "\t= " ~ pred.toBNF() ~ "\n";
		result ~= "\t::= " ~ expr.toBNF() ~ ";\n";
		return result;
	}
	
}

class RuleDecl{
	Param[String] params;
	
	public this(Param[] params...){
		foreach(param; params){
			this.params[param.name] = param;
		}
	}
	
	public String renderDeclaration(){
		String result = "";
		bool first = true;
		foreach(param; params){
			if(first){
				result ~= "inout " ~ param.toString();
				first = false;
			}
			else{
				result ~= ",inout " ~ param.toString();
			}
		}
		return result;
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		foreach(param; params){
			param.semanticPass(thisRule,root);
		}
	}		
	
	public bool resolveBinding(String name){
		foreach(param; params){
			if(param.name == name) return true;
		}
		return false;
	}
	
	public String resolveBindingType(String name){
		foreach(param; params){
			if(param.name == name) return param.realType;
		}
		return null;
	}	
	
	public String toBNF(){
		if(params.length == 0) return "";
		String result = "(";
		bool first = true;
		foreach(param; params){
			if(first){
				result ~= param.toBNF();
				first = false;
			}
			else{
				result ~= "," ~ param.toBNF();
			}
		}
		result ~= ")";
		return result;
	}
}

abstract class RulePredicate{
	public void renderDeclarations(CodeGenerator generator,Param[String] ruleParams);
	public void renderPass(CodeGenerator generator);
	public void renderFail(CodeGenerator generator);
	public void semanticPass(Rule thisRule,BaseEnkiParser root);
	public bool resolveBinding(String name);
	public String resolveBindingType(String name);
	public String getType(Rule thisRule,BaseEnkiParser root);
	public String toBNF();
}

class DefaultPredicate : RulePredicate{
	public this(){
	}
	
	public void renderDeclarations(CodeGenerator generator,Param[String] ruleParams){
		generator.emit("//no declarations");
	}
	
	public void renderPass(CodeGenerator generator){
		generator.emit("return ResultT!(bool)(true);");
	}
	
	public void renderFail(CodeGenerator generator){
		generator.emit("return ResultT!(bool)(false);");
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		//do nothing
	}
	
	public bool resolveBinding(String name){
		return false;
	}
	
	public String resolveBindingType(String name){
		return null;
	}
	
	public String getType(Rule thisRule,BaseEnkiParser root){
		return "bool";
	}
	
	public String toBNF(){
		return "";
	}
}

class ClassPredicate : RulePredicate{
	Param[] params;
	String type;
	
	public this(String type,Param[] params...){
		this.type = type;
		this.params = params.dup;
	}
	
	public void renderDeclarations(CodeGenerator generator,Param[String] ruleParams){
		foreach(uint i,param; params){
			if(param.name in ruleParams) continue;
			generator.emit(param.toString() ~ ";");
		}
	}
	
	public void renderPass(CodeGenerator generator){
		String args = "";
		foreach(uint i,param; params){
			if(i==0){
				args ~= param.getName();
			}
			else{
				args ~= "," ~ param.getName();
			}
		}
		generator.emit("ResultT!(" ~ type ~ ") passed = ResultT!(" ~ type ~ ")(new " ~ type ~ "(" ~ args ~ "));");
		generator.emit("return passed;");
	}
	
	public void renderFail(CodeGenerator generator){
		generator.emit("ResultT!(" ~ type ~ ") failed = ResultT!(" ~ type ~ ")();");
		generator.emit("return failed;");
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		foreach(param; params){
			param.semanticPass(thisRule,root);
		}
	}		
	
	public bool resolveBinding(String name){
		foreach(param; params){
			if(param.name == name) return true;
		}
		return false;
	}
	
	public String resolveBindingType(String name){
		foreach(param; params){
			if(param.name == name) return param.realType;
		}
		return null;
	}	
	
	public String getType(Rule thisRule,BaseEnkiParser root){
		return type;
	}
	
	public String toBNF(){
		String result = "new " ~ type ~ "(";
		foreach(uint i,param; params){
			if(i==0){
				result ~= param.toBNF();
			}
			else{
				result ~= "," ~ param.toBNF();
			}
		}
		result ~= ")";
		return result;
	}
}
	
class FunctionPredicate : RulePredicate{
	Param[] params;
	Param decl;
	
	public this(Param decl,Param[] params...){
		this.decl = decl;
		this.params = params.dup;
	}
	
	public void renderDeclarations(CodeGenerator generator,Param[String] ruleParams){
		foreach(uint i,param; params){
			if(!(param.name in ruleParams)){
				generator.emit(param.toString() ~ ";");
			}
		}
	}
	
	public void renderPass(CodeGenerator generator){
		String args = "";
		foreach(uint i,param; params){
			if(i==0){
				args ~= param.getName();
			}
			else{
				args ~= "," ~ param.getName();
			}
		}
		if(decl.type == "void"){
			generator.emit(decl.name ~ "(" ~ args ~ ");");
			generator.emit("return ResultT!(String)(sliceData(start,position));");
		}
		else{
			generator.emit("auto value = " ~ decl.name ~ "(" ~ args ~ ");");
			generator.emit("return ResultT!(" ~ decl.realType ~ ")(value);");
		}
	}
	
	public void renderFail(CodeGenerator generator){
		if(decl.type == "void"){
			generator.emit("return ResultT!(String)();");
		}
		else{
			generator.emit("return ResultT!(" ~ decl.realType ~ ")();");
		}
	}	
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		//decl.semanticPass(thisRule,root); // not needed
		
		foreach(param; params){
			param.semanticPass(thisRule,root);
		}
	}	
		
	public bool resolveBinding(String name){
		foreach(param; params){
			if(param.name == name) return true;
		}
		return false;
	}
		
	public String resolveBindingType(String name){
		foreach(param; params){
			if(param.name == name){
				return param.realType;
			}
		}
		return null;
	}		
	
	public String getType(Rule thisRule,BaseEnkiParser root){
		if(decl.type == "void"){
			return "String";
		}
		else{
			return decl.getType(thisRule,root);
		}
	}
	
	public String toBNF(){
		String result = decl.toBNF() ~ "(";
		foreach(uint i,param; params){
			if(i==0){
				result ~= param.toBNF();
			}
			else{
				result ~= "," ~ param.toBNF();
			}
		}
		result ~= ")";
		return result;
	}	
}

class BindingPredicate : RulePredicate{
	Param decl;
	
	public this(Param decl){
		this.decl = decl;
	}
	
	public void renderDeclarations(CodeGenerator generator,Param[String] ruleParams){
		if(!(decl.name in ruleParams)){
			generator.emit(decl.toString() ~ ";");
		}
	}
	
	public void renderPass(CodeGenerator generator){
		generator.emit("return ResultT!(" ~ decl.realType ~ ")(" ~ decl.getName() ~ ");");
	}
	
	public void renderFail(CodeGenerator generator){
		generator.emit("return ResultT!(" ~ decl.realType ~ ")();");
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		decl.semanticPass(thisRule,root); 
	}	
	
	public bool resolveBinding(String name){
		return decl.name == name;
	}
	
	public String resolveBindingType(String name){
		if(decl.name == name) return decl.realType;
		return null;
	}		
	
	public String getType(Rule thisRule,BaseEnkiParser root){
		return decl.getType(thisRule,root);
	}
	
	public String toBNF(){
		return decl.toBNF();
	}		
}

class Param{
	public bool isArray;
	public String type;
	public String name;
	public String realType;
	
	public this(bool isArray,String type,String name){
		this.isArray = isArray;
		this.type = type;
		this.name = name;
		this.realType = type;
		if(this.isArray) this.realType ~= "[]";
	}
	
	public this(String name){
		this.name = name;
		this.type = null;
	}
	
	public String getName(){
		return "bind_" ~ name;
	}
	
	public void semanticPass(Rule thisRule,BaseEnkiParser root){
		getType(thisRule,root);
	}
	
	public String getType(Rule thisRule,BaseEnkiParser root){
		if(realType) return realType;
		
		debug writefln("resolve type");
		type = thisRule.resolveBindingType(name,root);
		if(!type) throw new Exception("Cannot resolve type of binding '" ~ this.name ~ "'");
		realType = type;
		
		//debug writefln("param: %s resolved to %s",this.name,realType);
		return realType;
	}
	
	public String toString(){
		String result = "";
		result ~= type;
		if(isArray) result ~= "[]";
		result ~= " bind_" ~ name;
		
		return result;
	}
	
	public String toBNF(){
		String result = "";
		result ~= type;
		if(isArray) result ~= "[]";
		result ~= " " ~ name;
		
		return result;
	}		
}