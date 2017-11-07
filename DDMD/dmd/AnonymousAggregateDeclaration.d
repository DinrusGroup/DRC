module dmd.AnonymousAggregateDeclaration;

import dmd.common;
import dmd.AggregateDeclaration;
import dmd.Loc;

import dmd.DDMDExtensions;

class AnonymousAggregateDeclaration : AggregateDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this()
    {
		register();
		super(Loc(0), null);
    }

    AnonymousAggregateDeclaration isAnonymousAggregateDeclaration() { return this; }
}