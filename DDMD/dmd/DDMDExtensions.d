module dmd.DDMDExtensions;

/++
If you're making a tool based off of DDMD,
you can uncomment the commented lines below, 
and change "DSuperTool" to the name of your tool.
Then, create your own module to handle
"insertMemberDSuperTool".

That will allow you to insert code into any
module or class in DDMD's AST without actually
having to modify DDMD's actual AST code.
+/

//import DSuperTool.DDMDExtension;

template insertMemberExtension(T)
{
    //mixin insertMemberDSuperTool!T;
}
