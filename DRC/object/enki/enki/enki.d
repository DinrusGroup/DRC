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
module enki.enki;

private import enki.EnkiBackend;
private import enki.EnkiParser;
private import enki.enki_bn;

private import utils.ArgParser;

private import std.stdio;
private import std.file;

char[] helpText = 
`Enki - Frontend Parser Generator - V1.0 Build %d
Copyright(c) 2006 Eric Anderton

Creates a parser class based on annotated EBNF input.
The default ouput filename is "parser.d".

Usage:
  enki <source ebnf file> { -switch }
  
  -f<file>  Specify output filename 
  -b<file>  Specify output ebnf filename
  -t        Test Mode
  
The -b option is used primarily as a sanity check of
enki's internal workings.  The generated output is
re-created from the internal parse tree after the input
file is consumed.

The <file> params to follow -f and -b may be omitted if
-t is specified.
`;

void main(char[][] args){
	if(args.length == 1){
		writefln(helpText,auto_build_number);
		return 0;
	}
	
	char[] inputFilename;
	char[] outputFilename;
	char[] ebnfFilename;
	bool testMode = false;
	
	outputFilename = "parser.d";
	
	// configure the arg parser
	ArgParser argParser = new ArgParser(delegate uint(char[] value,uint ordinal){
		if(ordinal > 0) throw new Exception("Invalid argument '" ~ value ~ "'");
		inputFilename = value;
		return value.length;
	});
	
	argParser.bind("-", "f",delegate uint(char[] value){
		outputFilename = value;
		return value.length;
	});
	
	argParser.bind("-", "b",delegate uint(char[] value){
		ebnfFilename = value;
		return value.length;
	});
	
	argParser.bind("-", "t",delegate uint(char[] value){
		testMode = true;
		return value.length;
	});	

	// parse and resolve arguments	
	argParser.parse(args[1..$]);
	
	if(!inputFilename){
		throw new Exception("No filename specified.");
	}
	
	if(!isfile(inputFilename)){
		throw new Exception("File '" ~ inputFilename ~ "' doesn't exist.");
	}
	
	if(!testMode){
		if(outputFilename && outputFilename == ""){
			throw new Exception("Ouptut filename not specified - filename expected after '-f'.");
		}
		
		if(ebnfFilename && ebnfFilename == ""){
			throw new Exception("Ouptut BNF filename not specified - filename expected after '-b'.");
		}
	}

	// run the Enki Parser
	auto parser = new EnkiParser();
	parser.initalize(cast(char[])std.file.read(inputFilename));
	auto result = parser.parse_Syntax();
	
	if(result.success){
		parser.semanticPass();
		
		if(testMode){
			writefln("Parser:\n %s",parser.render());
		}
		else{
			std.file.write(outputFilename,parser.render());
		}
		
		if(ebnfFilename){
			if(testMode){
				writefln("\nBNF:\n %s",parser.toBNF());
			}
			else{
				std.file.write(ebnfFilename,parser.toBNF());
			}
		}
	}
	else{
		writefln("\nErrors:\n%s",parser.getErrorReport());	
	}
}