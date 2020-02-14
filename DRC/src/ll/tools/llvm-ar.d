module llvmAr;
import cidrus, ll.Target;

extern (C){
int ЛЛВхоФункцАр(in ткст0* argv);
int ЛЛВхоФункцРанлиб(ткст0* args);
int ЛЛОбщВхоФункцЛЛАр( char **args);
ткст[] дайАргиКС();
}

цел main(ткст[]) 
{
ЛЛНициализуйВсеИнфОЦели();
ЛЛНициализуйВсеЦелевыеМК();
ЛЛНициализуйВсеАсмПарсеры();

ткст[] арги = дайАргиКС();

if (strncmp(cast(char*)арги[1], cast(char*)"ar", 1))
{
	auto марги =  cast(ткст0*) арги[1..арги.length];
	return ЛЛВхоФункцАр( марги);
}
else if (strncmp(cast(char*) арги[1],cast(char*)"ranlib", 1))
{
	auto марги =cast(ткст0*)  арги[1..арги.length];
	return ЛЛВхоФункцРанлиб(марги);
}
}
