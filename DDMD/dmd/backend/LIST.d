module dmd.backend.LIST;

import dmd.common;
import dmd.backend.Symbol;

struct LIST
{
	/* Do not access items in this struct directly, use the		*/
	/* functions designed for that purpose.				*/
	LIST* next;	/* next element in list			*/
	int count;		/* when 0, element may be deleted	*/

	union
	{
		void *ptr;	/* data pointer				*/
		int data;
	}
}

alias LIST* list_t;			/* pointer to a list entry		*/
alias list_t symlist_t;		/* pointer to a list entry		*/

extern (C++) extern {
	list_t list_prepend(list_t* plist, void* ptr);
	void slist_add(Symbol* s);
	void slist_cleanup();
}
