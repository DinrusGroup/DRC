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
module enki.CodeGenerator;

private import enki.types;

private import std.string;

interface IRenderable{
	public void render(CodeGenerator generator,Statement passterm,Statement failterm);
}

abstract class Statement : IRenderable{
	static EmptyStatement empty;
	static this(){
		empty = new EmptyStatement();
	}
	
	public bool opCast(){
		return this != empty;
	}
	
	public bool isEmpty(){
		return false;
	}
}

class EmptyStatement : Statement{
	public this(){
	}
	
	public void render(CodeGenerator generator,Statement passterm,Statement failterm){
	}
	
	public bool isEmpty(){
		return true;
	}	
}

class Label: Statement{
	static uint counter = 0;
	String name;
	
	public this(String name){
		counter++;
		this.name = name ~ std.string.toString(counter); 
	}
	
	public void render(CodeGenerator generator,Statement passterm,Statement failterm){
		generator.emit(name ~ ":");
	}
}

class Literal: Statement{
	String text;
	public this(String text){
		this.text = text;
	}
		
	public void render(CodeGenerator generator,Statement passterm,Statement failterm){
		generator.emit(text);
	}
}

class Goto: Statement{
	Label label;
	
	public this(Label label){
		this.label = label;
	}
	
	public void render(CodeGenerator generator,Statement passterm,Statement failterm){
		generator.emit("goto " ~ label.name ~ ";");
	}
}

class Call: Statement{
	String name;
	String[] args;
	
	public this(String name,String[] args...){
		this.name = name;
		this.args = args;
	}
	
	public void render(CodeGenerator generator,Statement passterm,Statement failterm){
		String signature = name ~ "(";
		
		foreach(uint i,String arg; args){
			if(i == 0){
				signature ~= arg;
			}
			else{
				signature ~= "," ~ arg;
			}
		}
		generator.emit(signature ~= ");");
	}
}

class CompositeStatement : Statement{
	Statement[] statements;
		
	public this(Statement[] statements...){
		foreach(stmt; statements){
			if(stmt.isEmpty) continue;
			this.statements ~= stmt;
		}
	}
	
	public void render(CodeGenerator generator,Statement passterm,Statement failterm){
		foreach(statement; statements){
			generator.render(statement,passterm,failterm);
		}
	}
	
	public bool isEmpty(){
		return statements.length == 0;
	}		
}


class CodeGenerator{
	uint counter;
	String tabs;
	String code;
	
	public this(){
		counter = 0;
		tabs = "";
	}
	
	public void indent(){
		tabs = tabs ~ "\t";
	}
	
	public void unindent(){
		tabs = tabs[0..$-1];
	}
	
	public String getUniqueLabel(String label){
		counter++;
		return label ~ std.string.toString(counter);
	}
	
	public void emit(String text){
		code ~= tabs ~ text ~ "\n";
	}
	
	public void render(IRenderable renderable){
		if(cast(Label)renderable){
			unindent();
			renderable.render(this,Statement.empty,Statement.empty);
			indent();
		}
		else{
			renderable.render(this,Statement.empty,Statement.empty);
		}
	}	
	
	public void render(IRenderable renderable,Statement passterm,Statement failterm){
		renderable.render(this,passterm,failterm);
	}
	
	public void renderFail(IRenderable renderable,Statement failterm){
		renderable.render(this,Statement.empty,failterm);
	}	
	
	public void renderPass(IRenderable renderable,Statement passterm){
		renderable.render(this,passterm,Statement.empty);
	}
	
	public void renderIfTest(String test,Statement pass,Statement fail){
		if(pass.isEmpty && fail.isEmpty){
			emit(test ~ ";");
		}
		else if(pass.isEmpty){
			emit("if(!(" ~ test ~ ")){");
				indent();
				render(fail);
				unindent();						
			emit("}");			
		}
		else if(fail.isEmpty){
			emit("if(" ~ test ~ "){");
				indent();
				render(pass);
				unindent();						
			emit("}");
		}
		else{
			emit("if(" ~ test ~ "){");
				indent();
				render(pass);
				unindent();
			emit("}else{");
				indent();
				render(fail);
				unindent();
			emit("}");
		}		
	}
	
	public String toString(){
		return code;
	}
}
