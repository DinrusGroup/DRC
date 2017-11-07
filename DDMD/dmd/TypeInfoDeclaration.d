module dmd.TypeInfoDeclaration;

import dmd.common;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.Dsymbol;
import dmd.Module;
import dmd.Scope;
import dmd.Loc;
import dmd.STC;
import dmd.Global;
import dmd.OutBuffer;
import dmd.PROT;
import dmd.LINK;

import dmd.backend.Symbol;
import dmd.backend.dt_t;
import dmd.backend.DT;
import dmd.backend.SC;
import dmd.backend.FL;
import dmd.backend.glue;
import dmd.backend.Util;
import dmd.backend.TYPE;

import core.stdc.stdio;

import dmd.DDMDExtensions;

class TypeInfoDeclaration : VarDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	Type tinfo;

	this(Type tinfo, int internal)
	{
		register();
		super(Loc(0), global.typeinfo.type, tinfo.getTypeInfoIdent(internal), null);
		this.tinfo = tinfo;
		storage_class = STC.STCstatic | STC.STCgshared;
		protection = PROT.PROTpublic;
		linkage = LINK.LINKc;
	}

	override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);		  // should never be produced by syntax
		return null;
	}

	override void semantic(Scope sc)
	{
		assert(linkage == LINKc);
	}

	override void emitComment(Scope sc)
	{
	}

	override Symbol* toSymbol()
	{
		//printf("TypeInfoDeclaration::toSymbol(%s), linkage = %d\n", toChars(), linkage);
		return VarDeclaration.toSymbol();
	}

	override void toJsonBuffer(OutBuffer buf)
	{
	}

	override void toObjFile(int multiobj)			// compile to .obj file
	{
		Symbol* s;
		uint sz;
		Dsymbol parent;

		//printf("TypeInfoDeclaration.toObjFile(%p '%s') protection %d\n", this, toChars(), protection);

		if (multiobj)
		{
			obj_append(this);
			return;
		}

		s = toSymbol();
		sz = cast(uint)type.size();

		parent = this.toParent();
		s.Sclass = SC.SCcomdat;
		s.Sfl = FL.FLdata;

		toDt(&s.Sdt);

		dt_optimize(s.Sdt);

		// See if we can convert a comdat to a comdef,
		// which saves on exe file space.
		if (s.Sclass == SC.SCcomdat &&
			s.Sdt.dt == DT.DT_azeros &&
			s.Sdt.DTnext == null)
		{
			s.Sclass = SC.SCglobal;
			s.Sdt.dt = DT.DT_common;
		}

version (ELFOBJ_OR_MACHOBJ) { ///ELFOBJ || MACHOBJ // Burton
		if (s.Sdt && s.Sdt.dt == DT_azeros && s.Sdt.DTnext == null)
			s.Sseg = Segment.UDATA;
		else
			s.Sseg = Segment.DATA;
}
		outdata(s);
		if (isExport())
			obj_export(s,0);
	}

	void toDt(dt_t** pdt)
	{
		assert(false);
	}
}
