module dmd.BaseClass;

import dmd.common;
import dmd.Type;
import dmd.PROT;
import dmd.ClassDeclaration;
import dmd.Array;
import dmd.TY;
import dmd.TypeFunction;
import dmd.Dsymbol;
import dmd.FuncDeclaration;
import dmd.ArrayTypes;
import dmd.Util;

import core.stdc.stdlib;
import core.stdc.string;

import core.memory;

import dmd.TObject;

import dmd.DDMDExtensions;

class BaseClass : TObject
{
	mixin insertMemberExtension!(typeof(this));

    Type type;				// (before semantic processing)
    PROT protection;		// protection for the base interface

    ClassDeclaration base;
    int offset;				// 'this' pointer offset
    Array vtbl;				// for interfaces: Array of FuncDeclaration's
					// making up the vtbl[]

    //int baseInterfaces_dim;
    BaseClass[] baseInterfaces;		// if BaseClass is an interface, these
					// are a copy of the InterfaceDeclaration::interfaces

    this()
	{
		register();

		vtbl = new Array();
	}

    this(Type type, PROT protection)
	{
		register();

		//printf("BaseClass(this = %p, '%s')\n", this, type->toChars());
		this.type = type;
		this.protection = protection;

		vtbl = new Array();
	}

	/****************************************
	 * Fill in vtbl[] for base class based on member functions of class cd.
	 * Input:
	 *	vtbl		if !=null, fill it in
	 *	newinstance	!=0 means all entries must be filled in by members
	 *			of cd, not members of any base classes of cd.
	 * Returns:
	 *	true if any entries were filled in by members of cd (not exclusively
	 *	by base classes)
	 */
    bool fillVtbl(ClassDeclaration cd, Array vtbl, int newinstance)
	{
		ClassDeclaration id = base;
		int j;
		bool result = false;

		//printf("BaseClass.fillVtbl(this='%s', cd='%s')\n", base.toChars(), cd.toChars());
		if (vtbl)
			vtbl.setDim(base.vtbl.dim);

		// first entry is ClassInfo reference
		for (j = base.vtblOffset(); j < base.vtbl.dim; j++)
		{
			FuncDeclaration ifd = (cast(Dsymbol)base.vtbl.data[j]).isFuncDeclaration();
			FuncDeclaration fd;
			TypeFunction tf;

			//printf("        vtbl[%d] is '%s'\n", j, ifd ? ifd.toChars() : "null");

			assert(ifd);
			// Find corresponding function in this class
			tf = (ifd.type.ty == Tfunction) ? cast(TypeFunction)(ifd.type) : null;
			fd = cd.findFunc(ifd.ident, tf);
			if (fd && !fd.isAbstract())
			{
				//printf("            found\n");
				// Check that calling conventions match
				if (fd.linkage != ifd.linkage)
					fd.error("linkage doesn't match interface function");

				// Check that it is current
				if (newinstance &&
					fd.toParent() != cd &&
					ifd.toParent() == base
				)
					cd.error("interface function %s.%s is not implemented",
					id.toChars(), ifd.ident.toChars());

				if (fd.toParent() == cd)
					result = true;
			}
			else
			{
				//printf("            not found\n");
				// BUG: should mark this class as abstract?
				if (!cd.isAbstract())
					cd.error("interface function %s.%s isn't implemented", id.toChars(), ifd.ident.toChars());
				fd = null;
			}
			if (vtbl)
				vtbl.data[j] = cast(void*)fd;
		}

		return result;
	}

    void copyBaseInterfaces(BaseClasses vtblInterfaces)
	{
		//printf("+copyBaseInterfaces(), %s\n", base.toChars());
	//    if (baseInterfaces_dim)
	//	return;

		baseInterfaces.length = base.interfaces_dim;

		//printf("%s.copyBaseInterfaces()\n", base.toChars());
		for (int i = 0; i < baseInterfaces.length; i++)
		{
			BaseClass b2 = base.interfaces[i];
			assert(b2.vtbl.dim == 0);	// should not be filled yet

			BaseClass b = cloneThis(b2);
			baseInterfaces[i] = b;

			if (i)				// single inheritance is i==0
				vtblInterfaces.push(b);	// only need for M.I.
			b.copyBaseInterfaces(vtblInterfaces);
		}
		//printf("-copyBaseInterfaces\n");
	}
}
