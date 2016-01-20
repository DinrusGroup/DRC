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
module enki.BaseParser;
/**
	Runtime parser engine.
	
	Include this with your generated enki output.
*/

private import enki.types;
private import enki.IParser;

private import std.string;
private import std.stdio;
private import std.regexp;

alias ResultT!(bool) ResultBool;
alias ResultT!(String) ResultString;

abstract class BaseParser: IParser{
	struct ErrorData{
		uint pos;
		String text;
	}
	
	private String data;
	private uint pos;
	private ErrorData[] errors;
	
	public this(){		
	}
	
	public void initalize(String input){
		data = input;
		pos = 0;
	}
	
	protected uint position(){
		return this.pos;
	}
	
	protected void position(uint  newPos){
		this.pos = newPos;
	}
	
	protected String sliceData(uint start,uint end){
		return data[start..end];
	}
	
	/** conversion helpers **/
	
	protected String hexToChar(String hexValue){
		return "\\x" ~ hexValue;
	}
		
	/** error handling **/
	protected void setError(char[] text){
		debug writefln("[%d] Error: %s",pos,text);
		ErrorData data;
		data.pos = pos;
		data.text = text;		
		errors ~= data;
	}
	
	protected void setError(char[] text,int pos){
		ErrorData data;
		data.pos = pos;
		data.text = text;
		errors ~= data;
	}
	
	protected void clearErrors(){
		errors = (ErrorData[]).init;
	}
	
	public String getErrorReport(){
		String result = "";
		foreach(ErrorData err; errors){
			uint line=1;
			uint startOfLine = 0;
			for(uint i=0; i<err.pos; i++){
				if(data[i] == '\n'){
					startOfLine = i;
					line++;
				}
			}
			result ~= std.string.format("(%d,%d) %s\n",line,err.pos-startOfLine+1,err.text);
		}
		return result;
	}
	
	public bool hasErrors(){
		return errors.length > 0;
	}
	
	/** rudimentary parsers **/	
	
	public ResultString terminal(String str){
		uint start = pos;
		//writefln("match: %s %d (%d) %d",str,position,data[pos],data.length);
		if(position >= data.length || str.length > data.length - pos || data[pos..pos+str.length] != str){
			setError("Expected '" ~ str ~ "'");
			return ResultString();
		}
		pos += str.length;
		return ResultString(data[start..pos]);
	}
	
	public ResultString regexp(String str){
		if (auto m = std.regexp.search(data[pos..$],str))
		{
			if(m.pre.length == 0){
				auto result = m.match(0);
				pos += result.length;
				return ResultString(result);
			}
		}
		return ResultString();
	}
	
	public ResultBool parse_eoi(){
		if(pos >= data.length){
			setError("Expected end-of-input");
			return ResultBool(true);
		}
		return ResultBool();
	}


	public ResultString parse_letter(){
		if(pos >= data.length ||
			!((data[pos] >= 'a' && data[pos] <= 'z') ||
			(data[pos] >= 'A' && data[pos] <= 'Z'))){
			setError("Expected letter");
			return ResultString();
		}
		pos++;
		return ResultString(data[pos-1..pos]);
	}
	
	public ResultString parse_digit(){
		if(pos >= data.length || (!(data[pos] >= '0' && data[pos] <= '9'))){
			setError("Expected digit");
			return ResultString();
		}
		pos++;
		return ResultString(data[pos-1..pos]);
	}
	
	public ResultString parse_hexdigit(){
		if(pos >= data.length || 
			!((data[pos] >= '0' && data[pos] <= '9') ||
			(data[pos] >= 'a' && data[pos] <= 'f') ||
			(data[pos] >= 'A' && data[pos] <= 'F'))){			
			setError("Expected hex digit");
			return ResultString();
		}
		pos++;
		return ResultString(data[pos-1..pos]);
	}
	
	public ResultString parse_any(){
		if(pos >= data.length){
			setError("Unexpected end-of-input");
			return ResultString();
	 	}
		pos++;
		return ResultString(data[pos-1..pos]);
	}
	
	public ResultString parse_newline(){
		uint start = pos;
		if(pos < data.length){	
			if(data[pos] == '\r'){
				pos++;
			}
			if(data[pos] == '\n'){
				pos++;
				return ResultString(data[start..pos]);
			}
		}
		setError("Expected newline");
		return ResultString();
	}
	
	public ResultBool parse_eol(){
		if(pos >= data.length){
			return ResultBool(true);
		}
		
		uint start = pos;
		if(position < data.length){	
			if(data[pos] == '\r'){
				pos++;
			}
			if(data[pos] == '\n'){
				pos++;
				return ResultBool(true);
			}
		}
		setError("Expected end-of-line");
		return  ResultBool();
	}
	
	public ResultString parse_ws(){
		uint start = position;
		while(pos < data.length){
			switch(data[pos]){
			case '\n':
			case '\r':
			case '\t':
			case '\v':
			case '\f':
			case ' ':
				pos++;
				break;
			default:
				goto done;
			}			
		}
		done:
		return ResultString(data[start..pos]); // always a success
	}
	
	public ResultString parse_sp(){
		uint start = position;
		while(pos < data.length){
			switch(data[pos]){
			case '\n':
			case '\r':
			case '\t':
			case '\v':
			case '\f':
			case ' ':
				pos++;
				break;
			default:
				goto done;
			}			
		}
	done:
		if(start == pos) return ResultString();
		return ResultString(data[start..pos]);
	}
	
	public ResultBool parse_err(){
		throw new Exception(getErrorReport());
		return ResultBool(false);
	}
}