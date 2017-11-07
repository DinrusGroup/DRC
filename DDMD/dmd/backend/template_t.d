module dmd.backend.template_t;

/***********************************
 * Special information for class templates.
 */

struct template_t
{
/+
    symlist_t     TMinstances;	// list of Symbols that are instances
    param_t	 *TMptpl;	// template-parameter-list
    struct token_t *TMbody;	// tokens making up class body
    unsigned TMsequence;	// sequence number at point of definition
    list_t TMmemberfuncs;	// templates for member functions (list of TMF's)
    list_t TMexplicit;		// list of TME's: primary member template explicit specializations
    list_t TMnestedexplicit;	// list of TMNE's: primary member template nested explicit specializations
    Symbol *TMnext;		// threaded list of template classes headed
				// up by template_class_list
    enum_TK        TMtk;	// TKstruct, TKclass or TKunion
    int		   TMflags;	// STRxxx flags

    symbol *TMprimary;		// primary class template
    symbol *TMpartial;		// next class template partial specialization
    param_t *TMptal;		// template-argument-list for partial specialization
				// (NULL for primary class template)
    list_t TMfriends;		// list of Classsym's for which any instantiated
				// classes of this template will be friends of
    list_t TMnestedfriends;	// list of TMNF's
    int TMflags2;		// !=0 means dummy template created by template_createargtab()
+/
}