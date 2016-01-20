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
module enki.Directive;

private import enki.types;
private import enki.EnkiBackend;
private import enki.CodeGenerator;

debug private import std.stdio;

abstract class Directive : SyntaxLine, IRenderable{
	public void semanticPass(BaseEnkiParser root){
		//do nothing
	}
	
	public String toBNF(){
		// do nothing
	}
	
	public String toString(){
		// do nothing
	}

	public void render(CodeGenerator generator,Statement passterm,Statement failterm){
		// do nothing
	}	
}

class ImportDirective : Directive{
	String imp;
	
	public this(String imp){
		this.imp = imp;
	}
	
	public void semanticPass(BaseEnkiParser root){
		root.setImport(imp);
	}
	
	public String toBNF(){
		return ".import(\"" ~ imp ~ "\");\n";
	}
	
	public String toString(){
		return "Import Directive";
	}
}

class BaseClassDirective : Directive{
	String name;
	
	public this(String name){
		this.name = name;
	}
	
	public void semanticPass(BaseEnkiParser root){
		root.setBaseClass(name);
	}		
	
	public String toBNF(){
		return ".baseclass(\"" ~ name ~ "\");\n";
	}
	
	public String toString(){
		return "Base Class Directive";
	}	
}

class ClassnameDirective : Directive{
	String name;
	
	public this(String name){
		this.name = name;
	}
	
	public void semanticPass(BaseEnkiParser root){
		root.setClassname(name);
	}
	
	public String toBNF(){
		return ".classname(\"" ~ name ~ "\");\n";
	}
	
	public String toString(){
		return "Classname Directive";
	}	
}

class StartDirective : Directive{
	String prod;
	
	public this(String prod){
		this.prod = prod;
	}
	
	public void semanticPass(BaseEnkiParser root){
		root.getTypeForRule(prod); // prod root to determine if this is valid
		root.setStartProduction(prod);
	}
				
	public String toBNF(){
		return ".start(\"" ~ prod ~ "\");\n";
	}
	
	public String toString(){
		return "Start Directive";
	}	
}

class DefineDirective : Directive{
	String returnType;
	String name;
	String description;
	bool isTerminal;
	
	public this(String returnType,String name,bool isTerminal,String description){
		this.name = name;
		this.returnType = returnType;
		this.isTerminal = isTerminal;
		this.description = description;
	}
	
	public void semanticPass(BaseEnkiParser root){
		root.defineUserProduction(returnType,name,description);
	}
	
	public String toBNF(){
		String terminalStr = isTerminal ? "true" : "false";
		if(description){			
			return ".define(\"" ~ returnType ~ "\",\"" ~ name ~ "\",\"" ~ terminalStr ~ "\",\"" ~ description ~ "\");\n";
		}
		else{
			return ".define(\"" ~ returnType ~ "\",\"" ~ name ~ "\",\"" ~ terminalStr ~ "\");\n";
		}
	}
	
	public String toString(){
		return "Define Directive";
	}	
}


// cannot reference the parser duing bootstrap - it doesn't exist yet
version(Bootstrap){}
else{
	private import enki.EnkiParser;
	private import std.file;
}

class IncludeDirective : Directive{
	String filename;
	
	public this(String filename){
		this.filename = filename;
	}
	
	public void semanticPass(BaseEnkiParser root){
		version(Bootstrap){
			throw new Exception("Include directive is meaningless during bootstrap phase.");
		} 
		else{
			if(!std.file.isfile(filename)){
				throw new Exception("Cannot include '" ~ filename ~ "'; file doesn't exist.");
			}
			// cannot reference the parser duing bootstrap - it doesn't exist yet
				
			auto parser = new EnkiParser();
			parser.initalize(cast(char[])std.file.read(filename));
			auto result = parser.parse_Syntax();
			
			if(result.success){
				auto syntax = result.result;
				parser.semanticPass();
				root.add(parser);
			}
			else{
				throw new Exception("In file '" ~ filename ~ "':\n" ~ parser.getErrorReport());
			}
		}		
	}
				
	public String toBNF(){
		return "#.include(\"" ~ filename ~ "\");\n";
	}
	
	public String toString(){
		return "Include Directive";
	}	
}


class AliasDirective : Directive{
	String rule;
	String ruleAlias;
		
	public this(String rule,String ruleAlias){
		this.rule = rule;
		this.ruleAlias = ruleAlias;
	}
	
	public void semanticPass(BaseEnkiParser root){
		root.aliasRule(rule,ruleAlias);
	}
	
	public String toBNF(){
		return ".alias(\"" ~ rule ~ "\",\"" ~ ruleAlias ~ "\");\n";
	}
	
	public String toString(){
		return "Alias Directive";
	}	
}

class ModuleDirective : Directive{
	String moduleName;
		
	public this(String moduleName){
		this.moduleName = moduleName;
	}
	
	public void semanticPass(BaseEnkiParser root){
		root.setModulename(moduleName);
	}
	
	public String toBNF(){
		return ".module(\"" ~ moduleName ~ "\");\n";
	}
	
	public String toString(){
		return "Module Directive";
	}	
}


class CodeDirective : Directive{
	String code;
		
	public this(String code){
		this.code = code;
	}
	
	public void semanticPass(BaseEnkiParser root){
		//do nothing
	}
	
	public String toBNF(){
		return ".code{{{" ~ code ~ "}}}\n";
	}
	
	public String toString(){
		return "Code Directive";
	}	
	
	public void render(CodeGenerator generator,Statement passterm,Statement failterm){
		generator.emit(code);
	}	
}