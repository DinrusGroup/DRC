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
module enki.EnkiBackend;

private import enki.types;
private import enki.BaseParser;
private import enki.CodeGenerator;
private import enki.Expression;
private import enki.Directive;
private import enki.Rule;

debug private import std.stdio;

interface SyntaxLine{
	public void semanticPass(BaseEnkiParser root);
	public String toBNF();
}

struct UserProduction{
	String returnType;
	String name;
	String description;
	bool isTerminal;
		
	static UserProduction opCall(String returnType,String name,String description=null,bool isTerminal=true){
		UserProduction _this;
		_this.returnType = returnType;
		_this.name = name;
		_this.description = description ? description : name;
		_this.isTerminal = isTerminal;
		return _this;
	}
}

class BaseEnkiParser : BaseParser{
	SyntaxLine[] lines;
	Rule[String] rules;
	String[] imports;
	String baseclass;
	String classname;
	String moduleName;
	String startProduction;
	UserProduction[] userProductions;

	public this(){
		this.startProduction = "Syntax";
		this.baseclass = "BaseParser";
		this.classname = "Parser";
	}
	
	public bool createSyntax(SyntaxLine[] lines){
		this.lines = lines;
		return true;
	}
	
	public void add(BaseEnkiParser other){
		debug writefln("Aggregating included rules - %d total",other.rules.length);
		foreach(name,rule; other.rules){
			debug writefln("\t%s included",name);
			this.rules[name] = rule;
		}
		
		debug writefln("Aggregating included lines - %d total",other.lines.length);
		this.lines ~= other.lines;		
	}
	
	public void setImport(String imp){
		imports ~= imp;
	}
	
	public void setBaseClass(String name){
		baseclass = name;
	}
	
	public void setClassname(String name){
		classname = name;
	}
	
	public void setModulename(String name){
		moduleName = name;
	}
	
	public void defineUserProduction(String returnType,String name,String description){
		userProductions ~= UserProduction(returnType,name,description);
	}
	
	public void setStartProduction(String prod){
		startProduction = prod;
	}
	
	public void aliasRule(String ruleName,String aliasName){
		if(ruleName in rules){
			rules[aliasName] = rules[ruleName];
		}
		else{
			throw new Exception("Cannot alias '" ~ aliasName ~ "'. Rule '" ~ ruleName ~ "' is not defined.");
		}
	}
	
	public void addRule(String name,Rule rule){
		if(name in rules) throw new Exception("Rule '" ~ name ~ "' is already defined.");
		rules[name] = rule;
	}
	
	public String getTypeForRule(String name){
		String type;
		foreach(uProd; userProductions){
			if(uProd.name == name){
				type = uProd.returnType;
				break;
			}
		}
		if(!type){
			if(!(name in rules)){
				throw new Exception("Cannot find rule '" ~ name ~ "'.");
			}
			type = rules[name].getType(this);
		}
		return type;
	}
	
	public bool isTerminal(String name){
		foreach(uProd; userProductions){
			if(uProd.name == name){
				return uProd.isTerminal;
			}
		}
		return true;
	}
	
	public String getTerminalName(String terminalName){
		String name;
		foreach(uProd; userProductions){
			if(uProd.name == terminalName){
				name = uProd.description;
			}
		}
		if(!name) name = terminalName;
		return name;
	}
	
	public void semanticPass(){
		// first pass - gather all production names
		foreach(line; lines){
			Rule rule = cast(Rule)line;
			if(rule){
				this.rules[rule.name] = rule;
			}
		}
		
		// resolve all lines
		foreach(line; lines){		
			line.semanticPass(this);
		}
	}
		
	String render(){
		auto CodeGenerator generator = new CodeGenerator();
		with(generator){
			emit("//auto-generated parser");
			if(moduleName){
				emit("module " ~ moduleName ~ ";");
			}
			emit("debug private import std.stdio;");
			foreach(imp; imports){
				emit("private import " ~ imp ~ ";");
			}
			emit("");
			if(baseclass){
				emit("class " ~ classname ~ " : " ~ baseclass ~ "{");
			}
			else{
				emit("class " ~ classname ~ "{");				
			}
			emit("");
			
			foreach(line; lines){
				auto renderable = cast(IRenderable)line;
				if(renderable){
					render(renderable);
				}
			}
			
			emit("}");
		}	
		return generator.toString();
	}
	
	public String toBNF(){
		String result = "";
		foreach(line; lines){
			result ~= line.toBNF();
		}
		return result;
	}
}

class Comment : SyntaxLine{
	String text;
	public this(String text){
		this.text = text;
	}
	
	public void semanticPass(BaseEnkiParser root){
		//do nothing
	}	
	
	public String toBNF(){
		return "# " ~ text ~ "\n";
	}
}