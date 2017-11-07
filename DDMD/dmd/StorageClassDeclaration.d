module dmd.StorageClassDeclaration;

import dmd.common;
import dmd.AttribDeclaration;
import dmd.Array;
import dmd.TOK;
import dmd.Token;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.STC;
import dmd.Id;
import dmd.Identifier;

import dmd.DDMDExtensions;

class StorageClassDeclaration: AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    StorageClass stc;

    this(StorageClass stc, Dsymbols decl)
	{
		register();
		super(decl);
		
		this.stc = stc;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		StorageClassDeclaration scd;

		assert(!s);
		scd = new StorageClassDeclaration(stc, Dsymbol.arraySyntaxCopy(decl));
		return scd;
	}
	
    override void setScope(Scope sc)
	{
		if (decl)
		{
			StorageClass scstc = sc.stc;

			/* These sets of storage classes are mutually exclusive,
			 * so choose the innermost or most recent one.
			 */
			if (stc & (STC.STCauto | STC.STCscope | STC.STCstatic | STC.STCextern | STC.STCmanifest))
				scstc &= ~(STC.STCauto | STC.STCscope | STC.STCstatic | STC.STCextern | STC.STCmanifest);
			if (stc & (STC.STCauto | STC.STCscope | STC.STCstatic | STC.STCtls | STC.STCmanifest | STC.STCgshared))
				scstc &= ~(STC.STCauto | STC.STCscope | STC.STCstatic | STC.STCtls | STC.STCmanifest | STC.STCgshared);
			if (stc & (STC.STCconst | STC.STCimmutable | STC.STCmanifest))
				scstc &= ~(STC.STCconst | STC.STCimmutable | STC.STCmanifest);
			if (stc & (STC.STCgshared | STC.STCshared | STC.STCtls))
				scstc &= ~(STC.STCgshared | STC.STCshared | STC.STCtls);
			if (stc & (STCsafe | STCtrusted | STCsystem))
				scstc &= ~(STCsafe | STCtrusted | STCsystem);
			scstc |= stc;

			setScopeNewSc(sc, scstc, sc.linkage, sc.protection, sc.explicitProtection, sc.structalign);
		}
	}
	
    override void semantic(Scope sc)
	{
		if (decl)
		{
			StorageClass scstc = sc.stc;

			/* These sets of storage classes are mutually exclusive,
			 * so choose the innermost or most recent one.
			 */
			if (stc & (STC.STCauto | STC.STCscope | STC.STCstatic | STC.STCextern | STC.STCmanifest))
				scstc &= ~(STC.STCauto | STC.STCscope | STC.STCstatic | STC.STCextern | STC.STCmanifest);
			if (stc & (STC.STCauto | STC.STCscope | STC.STCstatic | STC.STCtls | STC.STCmanifest | STC.STCgshared))
				scstc &= ~(STC.STCauto | STC.STCscope | STC.STCstatic | STC.STCtls | STC.STCmanifest | STC.STCgshared);
			if (stc & (STC.STCconst | STC.STCimmutable | STC.STCmanifest))
				scstc &= ~(STC.STCconst | STC.STCimmutable | STC.STCmanifest);
			if (stc & (STC.STCgshared | STC.STCshared | STC.STCtls))
				scstc &= ~(STC.STCgshared | STC.STCshared | STC.STCtls);
			if (stc & (STCsafe | STCtrusted | STCsystem))
				scstc &= ~(STCsafe | STCtrusted | STCsystem);
			scstc |= stc;

			semanticNewSc(sc, scstc, sc.linkage, sc.protection, sc.explicitProtection, sc.structalign);
		}
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    static void stcToCBuffer(OutBuffer buf, StorageClass stc)
	{
		struct SCstring
		{
			StorageClass stc;
			TOK tok;
		}

		enum SCstring[] table =
		[
			{ STCauto,         TOKauto },
			{ STCscope,        TOKscope },
			{ STCstatic,       TOKstatic },
			{ STCextern,       TOKextern },
			{ STCconst,        TOKconst },
			{ STCfinal,        TOKfinal },
			{ STCabstract,     TOKabstract },
			{ STCsynchronized, TOKsynchronized },
			{ STCdeprecated,   TOKdeprecated },
			{ STCoverride,     TOKoverride },
			{ STClazy,         TOKlazy },
			{ STCalias,        TOKalias },
			{ STCout,          TOKout },
			{ STCin,           TOKin },
///version (DMDV2) {
			{ STCimmutable,    TOKimmutable },
			{ STCshared,       TOKshared },
			{ STCnothrow,      TOKnothrow },
			{ STCpure,         TOKpure },
			{ STCref,          TOKref },
			{ STCtls,          TOKtls },
			{ STCgshared,      TOKgshared },
			{ STCproperty,     TOKat },
			{ STCsafe,         TOKat },
			{ STCtrusted,      TOKat },
			{ STCdisable,      TOKat },
///}
		];

		for (int i = 0; i < table.length; i++)
		{
			if (stc & table[i].stc)
			{
				TOK tok = table[i].tok;
				if (tok == TOKat)
				{	Identifier id;

					if (stc & STCproperty)
						id = Id.property;
					else if (stc & STCsafe)
						id = Id.safe;
					else if (stc & STCtrusted)
						id = Id.trusted;
					else if (stc & STCdisable)
						id = Id.disable;
					else
						assert(0);
					buf.writestring(id.toChars());
				}
				else
					buf.writestring(Token.toChars(tok));
				buf.writeByte(' ');
			}
		}
	}
}
