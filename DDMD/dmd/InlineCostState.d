module dmd.InlineCostState;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.Expression;

struct InlineCostState
{
    int nested;
    int hasthis;
    int hdrscan;    // !=0 if inline scan for 'header' content
    FuncDeclaration fd;
}

const int COST_MAX = 250;

int arrayInlineCost(InlineCostState* ics, Expressions arguments)
{
	int cost = 0;

    if (arguments)
    {
		foreach (e; arguments)
		{   
			if (e)
				cost += e.inlineCost(ics);
		}
    }
    return cost;
}