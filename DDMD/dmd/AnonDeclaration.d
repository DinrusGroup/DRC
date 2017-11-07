module dmd.AnonDeclaration;

import dmd.common;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.Array;
import dmd.AttribDeclaration;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.AggregateDeclaration;
import dmd.AnonymousAggregateDeclaration;
import dmd.STC;
import dmd.Module;
import dmd.VarDeclaration;
import dmd.Global;

import dmd.DDMDExtensions;

class AnonDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	int isunion;
	int sem = 0;			// 1 if successful semantic()

	this(Loc loc, int isunion, Dsymbols decl)
	{
		register();
		super(decl);
		this.loc = loc;
		this.isunion = isunion;
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		AnonDeclaration ad;

		assert(!s);
		ad = new AnonDeclaration(loc, isunion, Dsymbol.arraySyntaxCopy(decl));
		return ad;
	}

	override void semantic(Scope sc)
	{
		//printf("\tAnonDeclaration::semantic %s %p\n", isunion ? "union" : "struct", this);

		Scope scx = null;
		if (scope_)
		{   
			sc = scope_;
			scx = scope_;
			scope_ = null;
		}
		
	    uint dprogress_save = global.dprogress;

		assert(sc.parent);

		Dsymbol parent = sc.parent.pastMixin();
		AggregateDeclaration ad = parent.isAggregateDeclaration();

		if (!ad || (!ad.isStructDeclaration() && !ad.isClassDeclaration()))
		{
			error("can only be a part of an aggregate");
			return;
		}

		if (decl)
		{
			AnonymousAggregateDeclaration aad = new AnonymousAggregateDeclaration();
			int adisunion;

			if (sc.anonAgg)
			{   
				ad = sc.anonAgg;
				adisunion = sc.inunion;
			}
			else
				adisunion = ad.isUnionDeclaration() !is null;

		//	printf("\tsc.anonAgg = %p\n", sc.anonAgg);
		//	printf("\tad  = %p\n", ad);
		//	printf("\taad = %p\n", &aad);

			sc = sc.push();
			sc.anonAgg = aad;
			sc.stc &= ~(STCauto | STCscope | STCstatic | STCtls | STCgshared);
			sc.inunion = isunion;
			sc.offset = 0;
			sc.flags = cast(SCOPE)0;
			aad.structalign = sc.structalign;
			aad.parent = ad;

			foreach(Dsymbol s; decl)
			{
				s.semantic(sc);
				if (isunion)
					sc.offset = 0;
				if (aad.sizeok == 2)
					break;
			}
			sc = sc.pop();

			// If failed due to forward references, unwind and try again later
			if (aad.sizeok == 2)
			{
				ad.sizeok = 2;
				//printf("\tsetting ad.sizeok %p to 2\n", ad);
				if (!sc.anonAgg)
				{
					scope_ = scx ? scx : sc.clone();
					scope_.setNoFree();
					scope_.module_.addDeferredSemantic(this);
				}
				global.dprogress = dprogress_save;
				//printf("\tforward reference %p\n", this);
				return;
			}
			if (sem == 0)
			{   
				global.dprogress++;
				sem = 1;
				//printf("\tcompleted %p\n", this);
			}
			else {
				//printf("\talready completed %p\n", this);
			}

			// 0 sized structs are set to 1 byte
			if (aad.structsize == 0)
			{
				aad.structsize = 1;
				aad.alignsize = 1;
			}

			// Align size of anonymous aggregate
		//printf("aad.structalign = %d, aad.alignsize = %d, sc.offset = %d\n", aad.structalign, aad.alignsize, sc.offset);
			ad.alignmember(aad.structalign, aad.alignsize, &sc.offset);
			//ad.structsize = sc.offset;
		//printf("sc.offset = %d\n", sc.offset);

			// Add members of aad to ad
			//printf("\tadding members of aad to '%s'\n", ad.toChars());
			for (uint i = 0; i < aad.fields.dim; i++)
			{
				auto v = aad.fields[i];

				v.offset += sc.offset;
				ad.fields.push(v);
			}

			// Add size of aad to ad
			if (adisunion)
			{
				if (aad.structsize > ad.structsize)
				ad.structsize = aad.structsize;
				sc.offset = 0;
			}
			else
			{
				ad.structsize = sc.offset + aad.structsize;
				sc.offset = ad.structsize;
			}

			if (ad.alignsize < aad.alignsize)
				ad.alignsize = aad.alignsize;
		}
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

	override string kind()
	{
		assert(false);
	}
}

