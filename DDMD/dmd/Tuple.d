module dmd.Tuple;

import dmd.common;
import dmd.ArrayTypes;
import dmd.DYNCAST;

import dmd.TObject;

class Tuple : TObject
{
	Objects objects;

	this()
	{
		register();
		objects = new Objects();
	}

	DYNCAST dyncast()
	{
		assert(false);
	}
}
