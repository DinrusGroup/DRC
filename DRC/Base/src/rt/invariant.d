/*
 * Placed into the Public Domain
 * written by Walter Bright
 * www.digitalmars.com
 */
//module rt.invariant;
import tpl.traits, sys.WinFuncs, runtime, stdrus: инфо, фм, ДАТА, ВРЕМЯ;

export extern (D)
 void _d_invariant(Object o)
{  
try
{
 ИнфОКлассе c;

    // alias КортежТипаОснова!(o.toString()) TL;
  //   скажинс(typeid(TL));	// prints: (A,I)
  /+
    if(o is null){ инфо(фм(
"
Приложение будет закрыто, так как _d_invariant получил нулевую
ссылку на неизвестный объект. (Возможно, это процедура из DLL.)
Сборка мусора и остановка рантайма будут проведены в
необходимом порядке. Приносим извинения, но в запущенном
вами приложении,либо в рантайме Динрус,
 есть какие-то несоответствия либо ошибки.

%s  %s
", ДАТА, ВРЕМЯ )); ртСтоп();} // just do null check, not invariant check

		+/
	c = o.classinfo;



    do
    {
        if (c.classInvariant !is null)
        {
            void delegate() inv;
            inv.ptr = cast(void*) o;
            inv.funcptr =  cast(void function()) c.classInvariant;
            inv();
        }
        c = c.base;
    } while (c);
	
}
	catch(Исключение и) и.выведи;
}
