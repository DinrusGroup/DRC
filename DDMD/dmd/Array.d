module dmd.Array;

import dmd.common;
import core.memory;

import std.exception;
import core.stdc.string;
import core.stdc.stdlib;

import dmd.TObject;

class Array : TObject
{
	uint dim = 0;
    uint allocdim = 0;
    void** data = null;

    ~this()
	{
		///mem.free(data);
	}
	
    void mark()
	{
		///unsigned u;
		///mem.mark(data);
		///for (u = 0; u < dim; u++)
		///mem.mark(data[u]);	// BUG: what if arrays of Object's?
	}
	
    override string toString()
	{
		char *p;

		///char **buf = cast(char**)alloca(dim * (char*).sizeof);
		scope string[] buf = new string[dim];
		uint len = 2;
		for (uint u = 0; u < dim; u++) {
			buf[u] = (cast(Object)data[u]).toString();
			len += buf[u].length + 1;
		}

		char* str = cast(char*)GC.malloc(len);

		str[0] = '[';
		p = str + 1;

		for (uint u = 0; u < dim; u++)
		{
			if (u != 0) {
				*p++ = ',';
			}
			uint length = buf[u].length;
			p[0..length] = buf[u][];

			p += length;
		}

		*p++ = ']';
		*p = 0;

		return assumeUnique(str[0..len]);
	}

    final void reserve(uint nentries)
	{
		//printf("Array::reserve: size = %d, offset = %d, nbytes = %d\n", size, offset, nbytes);
		if (allocdim - dim < nentries) {
			allocdim = dim + nentries;
			
			auto newData = cast(void**)GC.malloc(allocdim * (*data).sizeof);
			memcpy(newData, data, dim * (*data).sizeof);
//			GC.free(data);
			data = newData;
			
			//data = cast(void**)GC.realloc(data, allocdim * (*data).sizeof);
		}
	}
	
    final void setDim(uint newdim)
	{
		if (dim < newdim) {
			reserve(newdim - dim);
		}

		dim = newdim;
	}
	
    final void fixDim()
	{
		if (dim != allocdim)
		{
			data = cast(void**)GC.realloc(data, dim * (*data).sizeof);
			allocdim = dim;
		}
	}
	
    final void push(void* ptr)
	{
		reserve(1);
		data[dim++] = ptr;
	}

    final void* pop()
	{
		return data[--dim];
	}
	
    final void shift(void* ptr)
	{
		reserve(1);
		memmove(data + 1, data, dim * (*data).sizeof);
		data[0] = ptr;
		dim++;
	}
	
    final void insert(uint index, void* ptr)
	{
		reserve(1);
		memmove(data + index + 1, data + index, (dim - index) * (*data).sizeof);
		data[index] = ptr;
		dim++;
	}
	
    final void insert(uint index, Array a)
	{
		if (a !is null) {
			uint d = a.dim;
			reserve(d);

			if (dim != index) {
				memmove(data + index + d, data + index, (dim - index) * (*data).sizeof);
			}

			memcpy(data + index, a.data, d * (*data).sizeof);
			dim += d;
		}
	}
	
	/***********************************
	 * Append array a to this array.
	 */
    final void append(Array a)
	{
		insert(dim, a);
	}

    final void remove(uint i)
	{
		memmove(data + i, data + i + 1, (dim - i) * (*data).sizeof);
		dim--;
	}
	
    final void zero()
	{
		memset(data, 0, dim * (*data).sizeof);
	}

    final void* tos()
	{
		return dim ? data[dim - 1] : null;
	}

	private static extern (C) int Array_sort_compare(const(void*) x, const(void*) y)
	{
		Object ox = *cast(Object *)x;
		Object oy = *cast(Object *)y;

		return ox.opCmp(oy);
	}

    final void sort()
	{
		if (dim) {
			qsort(cast(void*)data, dim, Object.sizeof, &Array_sort_compare);
		}
	}
	
	final Array copyTo(Array a)
	{
		a.setDim(dim);
		memcpy(a.data, data, dim * (*data).sizeof);

		return a;
	}

    final Array copy()
	{
		return copyTo(new Array());
	}
}

class Vector(T) : TObject
{
public:
    @property final size_t dim()
    {
        return _dim;
    }

    @property final void dim(size_t newDim)
    {
        _dim = newDim;
    }
	
    @property final size_t length() const
    {
        return _dim;
    }
/* Doesn't work due to compiler BUG
    @property final size_t opDollar() const
    {
        return _dim;
    }    
*/
/* 
	// Use [] for accessing members instead
	// or ptr() to get the pointer to the first element
    @property T *data()
    {
        return _data;
    }
*/
    @property T *ptr()
    {
        return _data;
    }
	
    @property final size_t allocdim()
    {
        return _allocdim;
    }
    
    ref T opIndex(size_t index)
    {
        return _data[index];
    }
    
    void opIndexAssign(T value, size_t index)
    {
        _data[index] = value;
    }
    
    final T pop()
    {        
        T v = _data[--_dim];
//        _data[dim] = T.init;
        return v;
    }
    
    final void push(T elem)
    {
        reserve(1);
        _data[_dim++] = elem;
    }
    
	final void zero()
	{
		memset(_data, 0, dim * T.sizeof);
		// TODO fix to assign T.init
	}
	
    final void reserve(size_t nentries)
	{
        //printf("Array::reserve: size = %d, offset = %d, nbytes = %d\n", size, offset, nbytes);
        if (allocdim - dim < nentries) {
            _allocdim = dim + nentries;
            _data = cast(T*)GC.realloc(_data, allocdim * T.sizeof);
        }
	}
    
    final void shift(T ptr)
    {
        reserve(1);
        memmove(_data + 1, _data, _dim * T.sizeof);
        _data[0] = ptr;
        _dim++;
    }

    final Vector!T copy()
	{
		return copyTo(new Vector!T());
	}

	final Vector!T copyTo(Vector!T a)
	{
		a.setDim(dim);
		memcpy(a._data, _data, dim * T.sizeof);
        // TODO call postblits
		return a;
	}
    
    final void setDim(size_t newdim)
	{
		if (dim < newdim) {
			reserve(newdim - dim);
		}

		_dim = newdim;
        // TODO if newdim < dim set memory to T.init
	}
    
    int opApply(scope int delegate(ref T) dg)
    {
        int result = 0;

	    for (size_t i = 0; i < _dim; i++)
	    {
    	    result = dg(_data[i]);
	        if (result)
		        break;
	    }
	    return result;
    }

    int opApply(scope int delegate(ref size_t key, ref T value) dg)
    {
        int result = 0;
        for (size_t i = 0; i < _dim; i++)
        {
            result = dg(i, _data[i]);
            if(result)
                break;
        }
        return result;
    }
    
    final void append(Vector!T a)
	{
		insert(dim, a);
	}
    
    final void remove(size_t i)
	{
		memmove(_data + i, _data + i + 1, (_dim - i) * T.sizeof);
//		_data[dim-1] = T.init;
        _dim--;
	}

    final void insert(uint index, T ptr)
	{
		reserve(1);
		memmove(_data + index + 1, _data + index, (_dim - index) * T.sizeof);
		_data[index] = ptr;
		_dim++;
	}
    
    final void insert(size_t index, Vector!T a)
	{
		if (a !is null) {
			uint d = a.dim;
			reserve(d);

			if (dim != index) {
				memmove(_data + index + d, _data + index, (dim - index) * T.sizeof);
			}

			memcpy(_data + index, a._data, d * T.sizeof);
			_dim += d;
		}
	}
private:
    T* _data = null;
    size_t _dim = 0;
    size_t _allocdim = 0;
}