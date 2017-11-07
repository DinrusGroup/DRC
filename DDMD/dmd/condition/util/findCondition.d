module dmd.condition.util.findCondition;

import dmd.common;
import dmd.String;
import dmd.Array;
import dmd.Identifier;

bool findCondition(Vector!string ids, Identifier ident)
{
    if (ids)
    {
		for (int i = 0; i < ids.dim; i++)
		{
			string id = ids[i];

			if (id == ident.toChars()) {
				return true;
			}
		}
    }

    return false;
}