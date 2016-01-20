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
module enki.types;

private import std.string;
private import std.conv;

alias char[] String;

// implicitly converable
template convert(V,U : V){
	U convert(V value){
		return value; 	
	}
}

// conversion to string
template convert(V,U:String){
	U convert(V value){
		static if(is(V == struct) || is(V == class)){
			return value.toString();
		}
		else{
			return std.string.toString(value);
		}
	}
}

// conversion from string
template convert(V:String,U){
	U convert(V value){
		static if(is(U == int)){
			return std.conv.toInt(value);
		}
		else static if(is(U == int)){
			return std.conv.toUint(value);
		}		
		else static if(is(U == long)){
			return std.conv.toLong(value);
		}		
		else static if(is(U == ulong)){
			return std.conv.toUlong(value);
		}		
		else static if(is(U == short)){
			return std.conv.toShort(value);
		}		
		else static if(is(U == ushort)){
			return std.conv.toUshort(value);
		}		
		else static if(is(U == byte)){
			return std.conv.toByte(value);
		}		
		else static if(is(U == ubyte)){
			return std.conv.toUbyte(value);
		}	
		else static if(is(U == float)){
			return std.conv.toFloat(value);
		}
		else static if(is(U == double)){
			return std.conv.toDouble(value);
		}
		else static if(is(U == real)){
			return std.conv.toReal(value);
		}
		else static if(is(U == bool)){
			return (value != null && value.length > 0);
		}
		else static if(is(U == char)){
			static assert(false);
		}		
		else{
			// last ditch effort
			return cast(U)value;
		}
	}
}

template convert(V,U : U[]){
	U convert(V value){
		return cast(U)value;
	}
}

// else
template convert(V,U){
	U convert(V value){
		static if(is(U : V)){
			return value;
		}
		else{
			return cast(U)value;
		}
	}
}

template smartAssignCat(U,V){
	void smartAssignCat(inout U u,V v){
		u = convert!(V,U)(v);
	}	
}

template smartAssignCat(U : U[],V){
	void smartAssignCat(inout U[] u,V v){
		u ~= convert!(V,U[])(v);
	}	
}

template smartAssign(U,V){
	void smartAssign(inout U u,V v){
		u = convert!(V,U)(v);
	}	
}

template smartAssign(U : U[],V){
	void smartAssign(inout U[] u,V v){
		static if(is(V : U[])){
			u = convert!(V,U[])(v);
		}
		else{
			u.length = 1;
			u[0] = convert!(V,U[])(v);
		}
	}	
}

// template tuple type to help with parsing
struct ResultT(T){
	T result;
	bool success;
	
	alias T Type;
	
	public static ResultT!(T) opCall(T result){ 
		ResultT!(T) _this;
		_this.result = result; 
		_this.success = true;
		return _this;
	}
	
	public static ResultT!(T) opCall(T result,bool success){ 
		ResultT!(T) _this;
		_this.result = result; 
		_this.success = success;
		return _this;
	}
			
	public static ResultT!(T) opCall(){ 
		ResultT!(T) _this;
		_this.success = false;
		return _this;
	}	
	
	template assignCat(V){
		public bool assignCat(inout V value){
			if(this.success) smartAssignCat!(V,Type)(value,this.result);
			return this.success;
		}
	}
	
	template assign(V){
		public bool assign(inout V value){
			if(this.success) smartAssign!(V,Type)(value,this.result);;
			return this.success;
		}
	}	
}

