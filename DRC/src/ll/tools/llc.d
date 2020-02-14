module llc;
import common;

extern (C) int ЛЛВхоФункцЛЛКомпилятора(inout char** argv);
extern(C) ткст[] дайАргиКС();

цел main(ткст[] арги)
{
auto арги_ = дайАргиКС();
	if(арги_.length == 2)
	{
		арги_ ~= "--help";
	}
auto ксарги = cast(char**) арги_;
return ЛЛВхоФункцЛЛКомпилятора(ксарги);
}
