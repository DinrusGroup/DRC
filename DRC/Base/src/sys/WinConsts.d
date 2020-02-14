/**
Модуль перечней и констант WIN API для языка Динрус.
Разработчик Виталий Кулич.

Список названий перечней констант:

ПТипЗКД, ПМайлСлот, ППраваДоступа, ПТипТокена, ПТипБид, ПУровеньИмперсонацииБезопасности, ПТокен, КЛАСС_ИНФОРМАЦИИ_ТОКЕНА, ПСтд, ПШирСим, ПСжатие, ПРежимКонсоли, ППозКурсора, ППозПотока, ПРеестр, ПКлючРег, ПФайл, ПСовмИспФайла, ПРежимФайла, ПРежСоздФайла, ПФлагКУДоп, ППриоритетНити, ППроцесс, ПРежим_Адресации, ПИдЧП, ПКомРез, ПОшибка, ПЗагрФлаг, ПОкПерерис, ПФичаБезопмаса, ПТипВарианта, ПВинСокОш, ПТипСок, ППротокол, ПОпцияСокета, ПСемействоАдресов, ПЭкстрЗакрытиеСокета, ПФлагиСокета, ПИнАдр, ПИницКо, ПИмИнфо, АИ, ПСисМетрика, ПАтрыИнфосим, ПТипСоб, ПТипСобМыши, ПСостКнопкиМыши, ПСостКлУпр, ПСтильПера, ПЗвук, ППамять, ПФлагСооб, ПВиртКл, ППрокр, ПВидОкна, ПЦветУпрЭлта, ПСтильКласса, ПСлотПочты, ПСооб, ПФорматСооб, ПЯзык, ППодъяз, ПКодСтр, ПКонтекст, ПОкСооб, ПФлагСоздПроц, ПКонтекстВып, ППолитикаИсключений, ПДиспачФлаг, ПСредство, ПВар, ПАспектЦУ, ТИМЕД, ПВидТипа, ПКонвВызова, ПВидФунк, ПВидВызова, ПВидПерем, ПФлагТипа, ПФлагФунк, ПФлагиПерем, ПВидДескр, ПВидСистемы, ПВидРег, ПВидИзм,
*/

module sys.WinConsts;
import sys.WinStructs, sys.WinFuncs;
//public import sys.uuid;
import cidrus;




template ДелайСКод(бцел sev, бцел fac, бцел код) {
  const ДелайСКод = ((sev << 31) | (fac << 16) | код);
}

extern(Windows):


const цел СОКОШИБ = -1;//SOCKET_ERROR
const бцел РАЗМНАБ_УД = 64;//FD_SETSIZE
const СОКЕТ НЕВЕРНСОК = cast(СОКЕТ)~0;//INVALID_SOCKET
alias НЕВЕРНСОК НЕВЕРНЫЙ_СОКЕТ;


const цел ДЛИНА_ВСАОПИСАНИЯ = 256; 

const цел ДЛИНА_ВСАСИС_СТАТУСА = 128;

const цел МАСКА_ВВПАРАМ =  0x7F; //MASK_IOPARM
const цел ВВК_ВХО =        cast(цел)0x80000000; //IOC_IN
const цел ВВФСБВВ =       cast(цел)(ВВК_ВХО | ((бцел.sizeof & МАСКА_ВВПАРАМ) << 16) | (102 << 8) | 126);//FIONBIO (Функция ВВ для Блокирования/Разблокирования Сетевого Ввода-Вывода)


const   ук НЕВЕРНХЭНДЛ    = cast(ук)-1; //INVALID_HANDLE_VALUE
const  бцел НЕВЕРНФУКНАБОРА  = cast(бцел)-1;//INVALID_SET_FILE_POINTER
const  бцел НЕВЕРНРАЗМФАЙЛА         = cast(бцел)0xFFFFFFFF;//INVALID_FILE_SIZE
const бцел НЕВЕРНФАЙЛАТРЫ = cast(бцел) -1;//INVALID_FILE_ATTRIBUTES
const ббайт ОТРИЦ_ДЕСЯТОК = 0x80;
const бцел	МАКС_ПУТЬ 			= 260;
const т_мера МАКС_ИСКЛ_ПАРАМЫ = 15;//EXCEPTION_MAXIMUM_PARAMETERS
const бцел ИСКЛ_НЕПРОДОЛЖИТЕЛЬНОЕ    =  1;// EXCEPTION_NONCONTINUABLE
const ЛУИД СИСТЛУИД = { квадрЧасть:999 };//SYSTEM_LUID
/+
// These are not documented on MSDN
const THREAD_BASE_PRIORITY_LOWRT =  15;
const THREAD_BASE_PRIORITY_MAX   =   2;
const THREAD_BASE_PRIORITY_MIN   =  -2;
const THREAD_BASE_PRIORITY_IDLE  = -15;
+/

const ббайт //ЗКДЗАГ.флагиЗкд

	НАСЛЕДОВАТЬ_ОБЪЕКТ_ЗКД         = 0x01,
	НАСЛЕДОВАТЬ_КОНТЕЙНЕР_ЗКД      = 0x02,
	НЕ_ПРИМЕНЯТЬ_НАСЛЕДОВАНИЕ_ЗКД   = 0x04,
	НАСЛЕДОВАТЬ_ТОЛЬКО_ЗКД           = 0x08,
	УНАСЛЕДОВАННАЯ_ЗКД              = 0x10,
	РАБОЧИЕ_ФЛАГИ_НАСЛЕДОВАНИЯ        = 0x1F,
	ФЛАГ_УДАЧНОГО_ДОСТУПА_ЗКД = 0x40,
	ФЛАГ_НЕУДАЧНОГО_ДОСТУПА_ЗКД     = 0x80;
	
enum ПТипЗКД: ббайт //ЗКДЗАГ.типЗкд
 {
	ДоступОткрыт,//ACCESS_ALLOWED_ACE_TYPE,
	ДоступЗакрыт,//ACCESS_DENIED_ACE_TYPE,
	СистАудит,//SYSTEM_AUDIT_ACE_TYPE,
	СистТревога//SYSTEM_ALARM_ACE_TYPE
}

// ЗКД_ОБЪЕКТ_ЗАКРЫТ и др.
const бцел
	ЗКД_ЕСТЬ_ТИП_ОБЪЕКТА           = 0x00000001,
	ЗКД_ЕСТЬ_УНАСЛЕДОВАННЫЙ_ТИП_ОБЪЕКТА = 0x00000002;
	
// Формат Маски Доступа
const МАСКА_ДОСТУПА
	УДАЛИТЬ                   = 0x00010000,
	ЧИТАТЬ_КОНТРОЛЬ             = 0x00020000,
	ЗАПИСАТЬ_ДКД                = 0x00040000,
	ЗАПИСАТЬ_ВЛАДЕЛЬЦА              = 0x00080000,
	СИНХРОНИЗИРОВАТЬ              = 0x00100000,
	ДОСТУП_С_СИСТЕМНОЙ_БЕЗОПАСНОСТЬЮ   = 0x01000000,
	МАКСИМАЛЬНО_ДОПУСТИМЫЙ          = 0x02000000,
	ГЕНЕРНОЕ_ЧТЕНИЕ             = 0x80000000,
	ГЕНЕРНАЯ_ЗАПИСЬ            = 0x40000000,
	ГЕНЕРНОЕ_ВЫПОЛНЕНИЕ         = 0x20000000,
	ГЕНЕРНОЕ_ВСЁ              = 0x10000000,
	ТРЕБУЮТСЯСП = 0x000F0000,
	СПЧ     = 0x00020000,
	СПЗ    = 0x00020000,
	СПВ  = 0x00020000,
	СП_ВСЕ      = 0x001F0000,
	ОП_ВСЕ      = 0x0000FFFF;
	
// Не документировано в MSDN
const МАСКА_ДОСТУПА
	ВЫПОЛНЕНИЕ_ВВ_ОПРОС_СОСТОЯНИЯ  = 1,
	ВЫПОЛНЕНИЕ_ВВ_ИЗМЕНЕНИЕ_СОСТОЯНИЯ = 2,
	ВЫПОЛНЕНИЕ_ВВ_ЛЮБОЙ_ДОСТУП   = ТРЕБУЮТСЯСП | СИНХРОНИЗИРОВАТЬ | 3;
// MinGW:в конце ntifs.h
	
const т_мера ДЛИНА_ИСТОКА_ТОКЕНА = 8;
const т_мера МИН_ДЛИНА_ДЕСКРИПТОРА_БЕЗОПАСНОСТИ = 20;

enum ПМайлСлот
{
	БезСообщ   = -1,
	ЖдатьНавсегда = -1,
}

const МАСКА_ДОСТУПА
	ПРОЦЕСС_ЗАВЕРШИТЬ         = 0x0001,
	ПРОЦЕСС_СОЗДАТЬ_НИТЬ     = 0x0002,
	ПРОЦЕСС_УСТАНОВИТЬ_ИДСЕССИИ     = 0x0004,
	ПРОЦЕСС_ОПЕРАЦИЯ_ВП      = 0x0008,
	ПРОЦЕСС_ЧТЕНИЕ_ВП           = 0x0010,
	ПРОЦЕСС_ЗАПИСЬ_ВП          = 0x0020,
	ПРОЦЕС_ДУБ_ХЭНДЛ        = 0x0040,
	ПРОЦЕСС_СОЗДАТЬ_ПРОЦЕСС    = 0x0080,
	ПРОЦЕСС_УСТАНОВИТЬ_КВОТУ         = 0x0100,
	ПРОЦЕСС_УСТАНОВИТЬ_ИНФОРМАЦИЮ   = 0x0200,
	ПРОЦЕСС_ЗАПРОСИТЬ_ИНФОРМАЦИЮ = 0x0400,
	ПРОЦЕСС_ЛЮБОЙ_ДОСТУП        = ТРЕБУЮТСЯСП | СИНХРОНИЗИРОВАТЬ | 0x0FFF;

const МАСКА_ДОСТУПА
	НИТЬ_ЗАВЕРШИТЬ            = 0x0001,
	НИТЬ_ЗАМОРОЗ_РАЗМОРОЗ       = 0x0002,
	НИТЬ_ВЗЯТЬ_КОНТЕКСТ          = 0x0008,
	НИТЬ_УСТАНОВИТЬ_КОНТЕКСТ          = 0x0010,
	НИТЬ_УСТАНОВИТЬ_ИНФУ      = 0x0020,
	НИТЬ_ЗАПРОСИТЬ_ИНФУ    = 0x0040,
	НИТЬ_УСТАНОВИТЬ_ТОКЕН_НИТИ     = 0x0080,
	НИТЬ_ИМПЕРСОНИРОВАТЬ          = 0x0100,
	НИТЬ_ПРЯМАЯ_ИМПЕРСОНАЦИЯ = 0x0200,
	НИТЬ_ЛЮБОЙ_ДОСТУП           = ТРЕБУЮТСЯСП|СИНХРОНИЗИРОВАТЬ|0x3FF;

// MinGW: also in ddk/windamigos.dk.h
const бцел
	ДУБЛИРОВАТЬ_ЗАКР_ИСТОК    = 1,
	ДУБЛИРОВАТЬ_ДОСТУП     = 2,
	ДУБЛИРОВАТЬ_АТРИБУТЫ = 4;

const МАСКА_ДОСТУПА
	МУТАНТ_ОПРОС_СОСТОЯНИЯ = 1,
	МУТАНТ_ЛЮБОЙ_ДОСТУП =  ТРЕБУЮТСЯСП | СИНХРОНИЗИРОВАТЬ | МУТАНТ_ОПРОС_СОСТОЯНИЯ;

const МАСКА_ДОСТУПА
	ТАЙМЕР_ОПРОС_СОСТОЯНИЯ  = 1,
	ТАЙМЕР_ИЗМЕНЕНИЕ_СОСТОЯНИЯ = 2,
	ТАЙМЕР_ЛЮБОЙ_ДОСТУП   = ТРЕБУЮТСЯСП | СИНХРОНИЗИРОВАТЬ| ТАЙМЕР_ОПРОС_СОСТОЯНИЯ
	                     | ТАЙМЕР_ИЗМЕНЕНИЕ_СОСТОЯНИЯ;
						 
const БИДИДЕНТАВТОРИТ
	НИЧЕЙ_БИД        = {[5: 0]},
	ОБЩИЙ_БИД       = {[5: 1]},
	МЕСТНЫЙ_БИД       = {[5: 2]},
	БИД_СОЗДАТЕЛЯ     = {[5: 3]},
	НЕ_УНИК_БИД      = {[5: 4]},
	НТ_БИД              = {[5: 5]},
	ОБЯЗАТ_БИД = {[5: 6]};//SECURITY_MANDATORY_LABEL_AUTHORITY
	
const бцел
	НИЧЕЙ_РИД                   =  0,
	ОБЩИЙ_РИД                  =  0,
	МЕСТНЫЙ_РИД                  =  0,
	РИД_ВЛАДЕЛЕЦ_СОЗДАТЕЛЬ          =  0,
	РИД_СОЗДАТЕЛЬ_ГРУППА          =  1,
	РИД_ДОЗВОН                 =  1,
	РИД_СЕТЬ                =  2,
	БАТЧ_РИД                  =  3,
	ИНТЕРАКТИВНЫЙ_РИД            =  4,
	РИД_ЛОГИН_ИДЫ              =  5,
	РИД_СЛУЖБА                =  6,
	РИД_ЛОК_СИСТЕМА           = 18,
	РИД_ВСТРОЕННЫЙ_ДОМЕН         = 32,
	РИД_ПРИНЦИПАЛ         = 10,
	РИД_СОЗДАТЕЛЬ_ВЛАДЕЛЕЦ_СЕРВЕР   =  2,
	РИД_СОЗДАТЕЛЬ_ГРУППА_СЕРВЕР   =  3,
	ЧИСЛО_РИД_ЛОГИН_ИДОВ        =  3,
	РИД_АНОНИМНЫЙ_ЛОГИН        =  7,
	РИД_ПРОКСИ                  =  8,
	РИД_КОНТРОЛЁРЫ_ПРЕДПРИЯТИЯ =  9,
	РИД_ЛОГИН_СЕРВЕР           = РИД_КОНТРОЛЁРЫ_ПРЕДПРИЯТИЯ,
	РИД_АВТОРИЗОВАННЫЙ_ПОЛЬЗОВАТЕЛЬ     = 11,
	РИД_ОГРАНИЧЕННЫЙ_КОД        = 12,
	РИД_НТ_НЕ_УНИК          = 21,
	РИД_РЕВИЗИЯ                        =  1;
/+
enum : бцел {
	DOMAIN_USER_RID_ADMIN        = 0x01F4,
	DOMAIN_USER_RID_GUEST        = 0x01F5,
	DOMAIN_GROUP_RID_ADMINS      = 0x0200,
	DOMAIN_GROUP_RID_USERS       = 0x0201,
	DOMAIN_ALIAS_RID_ADMINS      = 0x0220,
	DOMAIN_ALIAS_RID_USERS       = 0x0221,
	DOMAIN_ALIAS_RID_GUESTS      = 0x0222,
	DOMAIN_ALIAS_RID_POWER_USERS = 0x0223,
	DOMAIN_ALIAS_RID_ACCOUNT_OPS = 0x0224,
	DOMAIN_ALIAS_RID_SYSTEM_OPS  = 0x0225,
	DOMAIN_ALIAS_RID_PRINT_OPS   = 0x0226,
	DOMAIN_ALIAS_RID_BACKUP_OPS  = 0x0227,
	DOMAIN_ALIAS_RID_REPLICATOR  = 0x0228
}

enum : бкрат {
	SECURITY_MANDATORY_UNTRUSTED_RID         = 0,
	SECURITY_MANDATORY_LOW_RID               = 0x1000,
	SECURITY_MANDATORY_MEDIUM_RID            = 0x2000,
	SECURITY_MANDATORY_HIGH_RID              = 0x3000,
	SECURITY_MANDATORY_SYSTEM_RID            = 0x4000,
	SECURITY_MANDATORY_PROTECTED_PROCESS_RID = 0x5000,
	SECURITY_MANDATORY_MAXIMUM_USER_RID      = SECURITY_MANDATORY_SYSTEM_RID
}

const TCHAR[]
	SE_CREATE_TOKEN_NAME           = "SeCreateTokenPrivilege",
	SE_ASSIGNPRIMARYTOKEN_NAME     = "SeAssignPrimaryTokenPrivilege",
	SE_LOCK_MEMORY_NAME            = "SeLockMemoryPrivilege",
	SE_INCREASE_QUOTA_NAME         = "SeIncreaseQuotaPrivilege",
	SE_UNSOLICITED_INPUT_NAME      = "SeUnsolicitedInputPrivilege",
	SE_MACHINE_ACCOUNT_NAME        = "SeMachineAccountPrivilege",
	SE_TCB_NAME                    = "SeTcbPrivilege",
	SE_SECURITY_NAME               = "SeSecurityPrivilege",
	SE_TAKE_OWNERSHIP_NAME         = "SeTakeOwnershipPrivilege",
	SE_LOAD_DRIVER_NAME            = "SeLoadDriverPrivilege",
	SE_SYSTEM_PROFILE_NAME         = "SeSystemProfilePrivilege",
	SE_SYSTEMTIME_NAME             = "SeSystemtimePrivilege",
	SE_PROF_SINGLE_PROCESS_NAME    = "SeProfileSingleProcessPrivilege",
	SE_INC_BASE_PRIORITY_NAME      = "SeIncreaseBasePriorityPrivilege",
	SE_CREATE_PAGEFILE_NAME        = "SeCreatePagefilePrivilege",
	SE_CREATE_PERMANENT_NAME       = "SeCreatePermanentPrivilege",
	SE_BACKUP_NAME                 = "SeBackupPrivilege",
	SE_RESTORE_NAME                = "SeRestorePrivilege",
	SE_SHUTDOWN_NAME               = "SeShutdownPrivilege",
	SE_DEBUG_NAME                  = "SeDebugPrivilege",
	SE_AUDIT_NAME                  = "SeAuditPrivilege",
	SE_SYSTEM_ENVIRONMENT_NAME     = "SeSystemEnvironmentPrivilege",
	SE_CHANGE_NOTIFY_NAME          = "SeChangeNotifyPrivilege",
	SE_REMOTE_SHUTDOWN_NAME        = "SeRemoteShutdownPrivilege",
	SE_CREATE_GLOBAL_NAME          = "SeCreateGlobalPrivilege",
	SE_UNDOCK_NAME                 = "SeUndockPrivilege",
	SE_MANAGE_VOLUME_NAME          = "SeManageVolumePrivilege",
	SE_IMPERSONATE_NAME            = "SeImpersonatePrivilege",
	SE_ENABLE_DELEGATION_NAME      = "SeEnableDelegationPrivilege",
	SE_SYNC_AGENT_NAME             = "SeSyncAgentPrivilege",
	SE_TRUSTED_CREDMAN_ACCESS_NAME = "SeTrustedCredManAccessPrivilege",
	SE_RELABEL_NAME                = "SeRelabelPrivilege",
	SE_INCREASE_WORKING_SET_NAME   = "SeIncreaseWorkingSetPrivilege",
	SE_TIME_ZONE_NAME              = "SeTimeZonePrivilege",
	SE_CREATE_SYMBOLIC_LINK_NAME   = "SeCreateSymbolicLinkPrivilege";

const DWORD
	SE_GROUP_MANDATORY          = 0x00000001,
	SE_GROUP_ENABLED_BY_DEFAULT = 0x00000002,
	SE_GROUP_ENABLED            = 0x00000004,
	SE_GROUP_OWNER              = 0x00000008,
	SE_GROUP_USE_FOR_DENY_ONLY  = 0x00000010,
	SE_GROUP_INTEGRITY          = 0x00000020,
	SE_GROUP_INTEGRITY_ENABLED  = 0x00000040,
	SE_GROUP_RESOURCE           = 0x20000000,
	SE_GROUP_LOGON_ID           = 0xC0000000;
	
	
const WORD LANG_SYSTEM_DEFAULT = (SUBLANG_SYS_DEFAULT << 10) | LANG_NEUTRAL;
const WORD LANG_USER_DEFAULT   = (SUBLANG_DEFAULT << 10) | LANG_NEUTRAL;
const DWORD LOCALE_NEUTRAL     = (SORT_DEFAULT << 16)
                                 | (SUBLANG_NEUTRAL << 10) | LANG_NEUTRAL;

// ---
enum : BYTE {
	ACL_REVISION    = 2,
	ACL_REVISION_DS = 4
}

// These are not documented on MSDN
enum : BYTE {
	ACL_REVISION1    = 1,
	ACL_REVISION2,
	ACL_REVISION3,
	ACL_REVISION4 // = 4
}

const BYTE
	MIN_ACL_REVISION = 2,
	MAX_ACL_REVISION = 4;

/+
// These aren't necessary for D.
const MINCHAR=0x80;
const MAXCHAR=0x7f;
const MINSHORT=0x8000;
const MAXSHORT=0x7fff;
const MINLONG=0x80000000;
const MAXLONG=0x7fffffff;
const MAXBYTE=0xff;
const MAXWORD=0xffff;
const MAXDWORD=0xffffffff;
+/

// SYSTEM_INFO.dwProcessorType
enum : DWORD {
	PROCESSOR_INTEL_386     =   386,
	PROCESSOR_INTEL_486     =   486,
	PROCESSOR_INTEL_PENTIUM =   586,
	PROCESSOR_MIPS_R4000    =  4000,
	PROCESSOR_ALPHA_21064   = 21064,
	PROCESSOR_INTEL_IA64    =  2200
}

// SYSTEM_INFO.wProcessorArchitecture
enum : WORD {
	PROCESSOR_ARCHITECTURE_INTEL,
	PROCESSOR_ARCHITECTURE_MIPS,
	PROCESSOR_ARCHITECTURE_ALPHA,
	PROCESSOR_ARCHITECTURE_PPC,
	PROCESSOR_ARCHITECTURE_SHX,
	PROCESSOR_ARCHITECTURE_ARM,
	PROCESSOR_ARCHITECTURE_IA64,
	PROCESSOR_ARCHITECTURE_ALPHA64,
	PROCESSOR_ARCHITECTURE_MSIL,
	PROCESSOR_ARCHITECTURE_AMD64,
	PROCESSOR_ARCHITECTURE_IA32_ON_WIN64, // = 10
	PROCESSOR_ARCHITECTURE_UNKNOWN = 0xFFFF
}

// IsProcessorFeaturePresent()
enum : DWORD {
	PF_FLOATING_POINT_PRECISION_ERRATA,
	PF_FLOATING_POINT_EMULATED,
	PF_COMPARE_EXCHANGE_DOUBLE,
	PF_MMX_INSTRUCTIONS_AVAILABLE,
	PF_PPC_MOVEMEM_64BIT_OK,
	PF_ALPHA_BYTE_INSTRUCTIONS,
	PF_XMMI_INSTRUCTIONS_AVAILABLE,
	PF_3DNOW_INSTRUCTIONS_AVAILABLE,
	PF_RDTSC_INSTRUCTION_AVAILABLE,
	PF_PAE_ENABLED,
	PF_XMMI64_INSTRUCTIONS_AVAILABLE
}


const DWORD
	HEAP_NO_SERIALIZE             = 0x01,
	HEAP_GROWABLE                 = 0x02,
	HEAP_GENERATE_EXCEPTIONS      = 0x04,
	HEAP_ZERO_MEMORY              = 0x08,
	HEAP_REALLOC_IN_PLACE_ONLY    = 0x10,
	HEAP_TAIL_CHECKING_ENABLED    = 0x20,
	HEAP_FREE_CHECKING_ENABLED    = 0x40,
	HEAP_DISABLE_COALESCE_ON_FREE = 0x80;

// These are not documented on MSDN
const HEAP_CREATE_ALIGN_16       = 0;
const HEAP_CREATE_ENABLE_TRACING = 0x020000;
const HEAP_MAXIMUM_TAG           = 0x000FFF;
const HEAP_PSEUDO_TAG_FLAG       = 0x008000;
const HEAP_TAG_ШИФТ             = 16;
// ???
//MACRO #define HEAP_MAKE_TAG_FLAGS(b,o) ((DWORD)((b)+(o)<<16)))

const ACCESS_MASK
	KEY_QUERY_VALUE        = 0x000001,
	KEY_SET_VALUE          = 0x000002,
	KEY_CREATE_SUB_KEY     = 0x000004,
	KEY_ENUMERATE_SUB_KEYS = 0x000008,
	KEY_NOTIFY             = 0x000010,
	KEY_CREATE_LINK        = 0x000020,
	KEY_WRITE              = 0x020006,
	KEY_EXECUTE            = 0x020019,
	KEY_READ               = 0x020019,
	KEY_ALL_ACCESS         = 0x0F003F;

static if (WINVER >= 0x502) {
	const ACCESS_MASK
		KEY_WOW64_64KEY    = 0x000100,
		KEY_WOW64_32KEY    = 0x000200;
}

const DWORD
	REG_WHOLE_HIVE_VOLATILE = 1,
	REG_REFRESH_HIVE        = 2,
	REG_NO_LAZY_FLUSH       = 4;

const DWORD
	REG_OPTION_RESERVED       =  0,
	REG_OPTION_NON_VOLATILE   =  0,
	REG_OPTION_VOLATILE       =  1,
	REG_OPTION_CREATE_LINK    =  2,
	REG_OPTION_BACKUP_RESTORE =  4,
	REG_OPTION_OPEN_LINK      =  8,
	REG_LEGAL_OPTION          = 15;

const SECURITY_INFORMATION
	OWNER_SECURITY_INFORMATION            = 0x00000001,
	GROUP_SECURITY_INFORMATION            = 0x00000002,
	DACL_SECURITY_INFORMATION             = 0x00000004,
	SACL_SECURITY_INFORMATION             = 0x00000008,
	LABEL_SECURITY_INFORMATION            = 0x00000010,
	UNPROTECTED_SACL_SECURITY_INFORMATION = 0x10000000,
	UNPROTECTED_DACL_SECURITY_INFORMATION = 0x20000000,
	PROTECTED_SACL_SECURITY_INFORMATION   = 0x40000000,
	PROTECTED_DACL_SECURITY_INFORMATION   = 0x80000000;

const DWORD MAXIMUM_PROCESSORS = 32;

// VirtualAlloc(), etc
// -------------------

enum : DWORD {
	PAGE_NOACCESS          = 0x0001,
	PAGE_READONLY          = 0x0002,
	PAGE_READWRITE         = 0x0004,
	PAGE_WRITECOPY         = 0x0008,
	PAGE_EXECUTE           = 0x0010,
	PAGE_EXECUTE_READ      = 0x0020,
	PAGE_EXECUTE_READWRITE = 0x0040,
	PAGE_EXECUTE_WRITECOPY = 0x0080,
	PAGE_GUARD             = 0x0100,
	PAGE_NOCACHE           = 0x0200
}

enum : DWORD {
	MEM_COMMIT      = 0x00001000,
	MEM_RESERVE     = 0x00002000,
	MEM_DECOMMIT    = 0x00004000,
	MEM_RELEASE     = 0x00008000,
	MEM_FREE        = 0x00010000,
	MEM_PRIVATE     = 0x00020000,
	MEM_MAPPED      = 0x00040000,
	MEM_RESET       = 0x00080000,
	MEM_TOP_DOWN    = 0x00100000,
	MEM_WRITE_WATCH = 0x00200000, // MinGW (???): 98/Me
	MEM_PHYSICAL    = 0x00400000,
	MEM_4MB_PAGES   = 0x80000000
}

// MinGW: also in ddk/ntifs.h
// CreateFileMapping()
const DWORD
	SEC_BASED     = 0x00200000,
	SEC_NO_CHANGE = 0x00400000,
	SEC_FILE      = 0x00800000,
	SEC_IMAGE     = 0x01000000,
	SEC_VLM       = 0x02000000,
	SEC_RESERVE   = 0x04000000,
	SEC_COMMIT    = 0x08000000,
	SEC_NOCACHE   = 0x10000000,
	MEM_IMAGE     = SEC_IMAGE;
// MinGW: end ntifs.h

// ???
const ACCESS_MASK
	SECTION_QUERY       = 0x000001,
	SECTION_MAP_WRITE   = 0x000002,
	SECTION_MAP_READ    = 0x000004,
	SECTION_MAP_EXECUTE = 0x000008,
	SECTION_EXTEND_SIZE = 0x000010,
	SECTION_ALL_ACCESS  = 0x0F001F;

// These are not documented on MSDN
const MESSAGE_RESOURCE_UNICODE = 1;
const RTL_CRITSECT_TYPE        = 0;
const RTL_RESOURCE_TYPE        = 1;

// COFF file format
// ----------------

// IMAGE_FILE_HEADER.Characteristics
const WORD
	IMAGE_FILE_RELOCS_STRIPPED         = 0x0001,
	IMAGE_FILE_EXECUTABLE_IMAGE        = 0x0002,
	IMAGE_FILE_LINE_NUMS_STRIPPED      = 0x0004,
	IMAGE_FILE_LOCAL_SYMS_STRIPPED     = 0x0008,
	IMAGE_FILE_AGGRESIVE_WS_TRIM       = 0x0010,
	IMAGE_FILE_LARGE_ADDRESS_AWARE     = 0x0020,
	IMAGE_FILE_BYTES_REVERSED_LO       = 0x0080,
	IMAGE_FILE_32BIT_MACHINE           = 0x0100,
	IMAGE_FILE_DEBUG_STRIPPED          = 0x0200,
	IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP = 0x0400,
	IMAGE_FILE_NET_RUN_FROM_SWAP       = 0x0800,
	IMAGE_FILE_SYSTEM                  = 0x1000,
	IMAGE_FILE_DLL                     = 0x2000,
	IMAGE_FILE_UP_SYSTEM_ONLY          = 0x4000,
	IMAGE_FILE_BYTES_REVERSED_HI       = 0x8000;
+/
// IMAGE_FILE_HEADER.Machine
enum ПФОбрМашина: бкрат {
	Неизвестно   = 0x0000,
	I386      = 0x014C,
	R3000     = 0x0162,
	R4000     = 0x0166,
	R10000    = 0x0168,
	WCEMIPSV2 = 0x0169,
	ALPHA     = 0x0184,
	SH3       = 0x01A2,
	SH3DSP    = 0x01A3,
	SH4       = 0x01A6,
	SH5       = 0x01A8,
	ARM       = 0x01C0,
	THUMB     = 0x01C2,
	AM33      = 0x01D3,
	POWERPC   = 0x01F0,
	POWERPCFP = 0x01F1,
	IA64      = 0x0200,
	MIPS16    = 0x0266,
	MIPSFPU   = 0x0366,
	MIPSFPU16 = 0x0466,
	EBC       = 0x0EBC,
	AMD64     = 0x8664,
	M32R      = 0x9041
}
/+
// ???
enum  {
	IMAGE_DOS_SIGNATURE    = 0x5A4D,
	IMAGE_OS2_SIGNATURE    = 0x454E,
	IMAGE_OS2_SIGNATURE_LE = 0x454C,
	IMAGE_VXD_SIGNATURE    = 0x454C,
	IMAGE_NT_SIGNATURE     = 0x4550
}

// IMAGE_OPTIONAL_HEADER.Magic
enum : WORD {
	IMAGE_NT_OPTIONAL_HDR32_MAGIC = 0x010B,
	IMAGE_ROM_OPTIONAL_HDR_MAGIC  = 0x0107,
	IMAGE_NT_OPTIONAL_HDR64_MAGIC = 0x020B
}

// IMAGE_OPTIONAL_HEADER.Subsystem
enum : WORD {
	IMAGE_SUBSYSTEM_UNKNOWN                  =  0,
	IMAGE_SUBSYSTEM_NATIVE,
	IMAGE_SUBSYSTEM_WINDOWS_GUI,
	IMAGE_SUBSYSTEM_WINDOWS_CUI,          // =  3
	IMAGE_SUBSYSTEM_OS2_CUI                  =  5,
	IMAGE_SUBSYSTEM_POSIX_CUI                =  7,
	IMAGE_SUBSYSTEM_NATIVE_WINDOWS,
	IMAGE_SUBSYSTEM_WINDOWS_CE_GUI,
	IMAGE_SUBSYSTEM_EFI_APPLICATION,
	IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER,
	IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER,
	IMAGE_SUBSYSTEM_EFI_ROM,
	IMAGE_SUBSYSTEM_XBOX,                 // = 14
	IMAGE_SUBSYSTEM_WINDOWS_BOOT_APPLICATION = 16
}

// IMAGE_OPTIONAL_HEADER.DllCharacteristics
const WORD
	IMAGE_DLL_CHARACTERISTICS_DYNAMIC_BASE         = 0x0040,
	IMAGE_DLL_CHARACTERISTICS_FORCE_INTEGRITY      = 0x0080,
	IMAGE_DLL_CHARACTERISTICS_NX_COMPAT            = 0x0100,
	IMAGE_DLLCHARACTERISTICS_NO_ISOLATION          = 0x0200,
	IMAGE_DLLCHARACTERISTICS_NO_SEH	               = 0x0400,
	IMAGE_DLLCHARACTERISTICS_NO_BIND               = 0x0800,
	IMAGE_DLLCHARACTERISTICS_WDM_DRIVER            = 0x2000,
	IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE = 0x8000;

// ???
const IMAGE_SEPARATE_DEBUG_SIGNATURE = 0x4944;
+/

/// точность адресов, выводимых функцией трассировки
enum ППрецАдра{
    ВсеВозвр=0,
    ВерхТочно=1,
    ВсеТочно=3
}

enum ПРазмОбраза: т_мера
{
	ЧлоПапЗап =  16,
	РазмОпцЗагРом =  56,
	РазмСтдОпцЗаг =  28,
	РазмОпцЗагНт  = 224,
	РазмКратИмени          =   8,
	РазмЗагСекц      =  40,
	РазмСимвола              =  18,
	РазмДопСимвола          =  18,
	РазмРелок          =  10,
	РазмРелокОвы     =   8,
	РазмНомСтр          =   6,
	РазмЗагЧленаАрх  =  60,
	РазмРФПОДанных                 =  16
}

enum ПОпцСимвола
{
ЛюбРег  =  1,
UNDNAME           =  2,
ИзменённыеЗагрузки    =  4,
БезСиПлюсПлюс            =  8,
ГрузитьСтроки        = 16,
OMAP_FIND_NEAREST = 32
}

 enum ПТипЗагКодВью : цел
 {
            Нет,
            ДОС,
            НТ,
            Отлад
  }

/+
PIMAGE_SECTION_HEADER IMAGE_FIRST_SECTION(PIMAGE_NT_HEADERS h) {
	return cast(PIMAGE_SECTION_HEADER)
		(&h.OptionalHeader + h.FileHeader.SizeOfOptionalHeader);
}

// ImageDirectoryEntryToDataEx()
enum : USHORT {
	IMAGE_DIRECTORY_ENTRY_EXPORT             =  0,
	IMAGE_DIRECTORY_ENTRY_IMPORT,
	IMAGE_DIRECTORY_ENTRY_RESOURCE,
	IMAGE_DIRECTORY_ENTRY_EXCEPTION,
	IMAGE_DIRECTORY_ENTRY_SECURITY,
	IMAGE_DIRECTORY_ENTRY_BASERELOC,
	IMAGE_DIRECTORY_ENTRY_DEBUG,
	IMAGE_DIRECTORY_ENTRY_COPYRIGHT,      // =  7
	IMAGE_DIRECTORY_ENTRY_ARCHITECTURE       =  7,
	IMAGE_DIRECTORY_ENTRY_GLOBALPTR,
	IMAGE_DIRECTORY_ENTRY_TLS,
	IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG,
	IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT,
	IMAGE_DIRECTORY_ENTRY_IAT,
	IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT,
	IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR, // = 14
}

// IMAGE_SECTION_HEADER.Characteristics
const DWORD
	IMAGE_SCN_TYPE_REG               = 0x00000000,
	IMAGE_SCN_TYPE_DSECT             = 0x00000001,
	IMAGE_SCN_TYPE_NOLOAD            = 0x00000002,
	IMAGE_SCN_TYPE_GROUP             = 0x00000004,
	IMAGE_SCN_TYPE_NO_PAD            = 0x00000008,
	IMAGE_SCN_TYPE_COPY              = 0x00000010,
	IMAGE_SCN_CNT_CODE               = 0x00000020,
	IMAGE_SCN_CNT_INITIALIZED_DATA   = 0x00000040,
	IMAGE_SCN_CNT_UNINITIALIZED_DATA = 0x00000080,
	IMAGE_SCN_LNK_OTHER              = 0x00000100,
	IMAGE_SCN_LNK_INFO               = 0x00000200,
	IMAGE_SCN_TYPE_OVER              = 0x00000400,
	IMAGE_SCN_LNK_REMOVE             = 0x00000800,
	IMAGE_SCN_LNK_COMDAT             = 0x00001000,
	IMAGE_SCN_MEM_FARDATA            = 0x00008000,
	IMAGE_SCN_GPREL                  = 0x00008000,
	IMAGE_SCN_MEM_PURGEABLE          = 0x00020000,
	IMAGE_SCN_MEM_16BIT              = 0x00020000,
	IMAGE_SCN_MEM_LOCKED             = 0x00040000,
	IMAGE_SCN_MEM_PRELOAD            = 0x00080000,
	IMAGE_SCN_ALIGN_1BYTES           = 0x00100000,
	IMAGE_SCN_ALIGN_2BYTES           = 0x00200000,
	IMAGE_SCN_ALIGN_4BYTES           = 0x00300000,
	IMAGE_SCN_ALIGN_8BYTES           = 0x00400000,
	IMAGE_SCN_ALIGN_16BYTES          = 0x00500000,
	IMAGE_SCN_ALIGN_32BYTES          = 0x00600000,
	IMAGE_SCN_ALIGN_64BYTES          = 0x00700000,
	IMAGE_SCN_ALIGN_128BYTES         = 0x00800000,
	IMAGE_SCN_ALIGN_256BYTES         = 0x00900000,
	IMAGE_SCN_ALIGN_512BYTES         = 0x00A00000,
	IMAGE_SCN_ALIGN_1024BYTES        = 0x00B00000,
	IMAGE_SCN_ALIGN_2048BYTES        = 0x00C00000,
	IMAGE_SCN_ALIGN_4096BYTES        = 0x00D00000,
	IMAGE_SCN_ALIGN_8192BYTES        = 0x00E00000,
	IMAGE_SCN_LNK_NRELOC_OVFL        = 0x01000000,
	IMAGE_SCN_MEM_DISCARDABLE        = 0x02000000,
	IMAGE_SCN_MEM_NOT_CACHED         = 0x04000000,
	IMAGE_SCN_MEM_NOT_PAGED          = 0x08000000,
	IMAGE_SCN_MEM_SHARED             = 0x10000000,
	IMAGE_SCN_MEM_EXECUTE            = 0x20000000,
	IMAGE_SCN_MEM_READ               = 0x40000000,
	IMAGE_SCN_MEM_WRITE              = 0x80000000;

/*	The following constants are mostlydocumented at
 *	http://download.microsoft.com/download/1/6/1/161ba512-40e2-4cc9-843a-923143f3456c/pecoff.doc
 *	but don't seem to be defined in the HTML docs.
 */
enum : SHORT {
	IMAGE_SYM_UNDEFINED =  0,
	IMAGE_SYM_ABSOLUTE  = -1,
	IMAGE_SYM_DEBUG     = -2
}

enum : ubyte {
	IMAGE_SYM_TYPE_NULL,
	IMAGE_SYM_TYPE_VOID,
	IMAGE_SYM_TYPE_CHAR,
	IMAGE_SYM_TYPE_SHORT,
	IMAGE_SYM_TYPE_INT,
	IMAGE_SYM_TYPE_LONG,
	IMAGE_SYM_TYPE_FLOAT,
	IMAGE_SYM_TYPE_DOUBLE,
	IMAGE_SYM_TYPE_STRUCT,
	IMAGE_SYM_TYPE_UNION,
	IMAGE_SYM_TYPE_ENUM,
	IMAGE_SYM_TYPE_MOE,
	IMAGE_SYM_TYPE_BYTE,
	IMAGE_SYM_TYPE_WORD,
	IMAGE_SYM_TYPE_UINT,
	IMAGE_SYM_TYPE_DWORD // = 15
}
const IMAGE_SYM_TYPE_PCODE = 32768; // ???

enum : ubyte {
	IMAGE_SYM_DTYPE_NULL,
	IMAGE_SYM_DTYPE_POINTER,
	IMAGE_SYM_DTYPE_FUNCTION,
	IMAGE_SYM_DTYPE_ARRAY
}

enum : BYTE {
	IMAGE_SYM_CLASS_END_OF_FUNCTION  = 0xFF,
	IMAGE_SYM_CLASS_NULL             =   0,
	IMAGE_SYM_CLASS_AUTOMATIC,
	IMAGE_SYM_CLASS_EXTERNAL,
	IMAGE_SYM_CLASS_STATIC,
	IMAGE_SYM_CLASS_REGISTER,
	IMAGE_SYM_CLASS_EXTERNAL_DEF,
	IMAGE_SYM_CLASS_LABEL,
	IMAGE_SYM_CLASS_UNDEFINED_LABEL,
	IMAGE_SYM_CLASS_MEMBER_OF_STRUCT,
	IMAGE_SYM_CLASS_ARGUMENT,
	IMAGE_SYM_CLASS_STRUCT_TAG,
	IMAGE_SYM_CLASS_MEMBER_OF_UNION,
	IMAGE_SYM_CLASS_UNION_TAG,
	IMAGE_SYM_CLASS_TYPE_DEFINITION,
	IMAGE_SYM_CLASS_UNDEFINED_STATIC,
	IMAGE_SYM_CLASS_ENUM_TAG,
	IMAGE_SYM_CLASS_MEMBER_OF_ENUM,
	IMAGE_SYM_CLASS_REGISTER_PARAM,
	IMAGE_SYM_CLASS_BIT_FIELD,    // =  18
	IMAGE_SYM_CLASS_FAR_EXTERNAL     =  68,
	IMAGE_SYM_CLASS_BLOCK            = 100,
	IMAGE_SYM_CLASS_FUNCTION,
	IMAGE_SYM_CLASS_END_OF_STRUCT,
	IMAGE_SYM_CLASS_FILE,
	IMAGE_SYM_CLASS_SECTION,
	IMAGE_SYM_CLASS_WEAK_EXTERNAL,// = 105
	IMAGE_SYM_CLASS_CLR_TOKEN        = 107
}

enum : BYTE {
	IMAGE_COMDAT_SELECT_NODUPLICATES = 1,
	IMAGE_COMDAT_SELECT_ANY,
	IMAGE_COMDAT_SELECT_SAME_SIZE,
	IMAGE_COMDAT_SELECT_EXACT_MATCH,
	IMAGE_COMDAT_SELECT_ASSOCIATIVE,
	IMAGE_COMDAT_SELECT_LARGEST,
	IMAGE_COMDAT_SELECT_NEWEST    // = 7
}

enum : DWORD {
	IMAGE_WEAK_EXTERN_SEARCH_NOLIBRARY = 1,
	IMAGE_WEAK_EXTERN_SEARCH_LIBRARY,
	IMAGE_WEAK_EXTERN_SEARCH_ALIAS
}

enum : WORD {
	IMAGE_REL_I386_ABSOLUTE       = 0x0000,
	IMAGE_REL_I386_DIR16          = 0x0001,
	IMAGE_REL_I386_REL16          = 0x0002,
	IMAGE_REL_I386_DIR32          = 0x0006,
	IMAGE_REL_I386_DIR32NB        = 0x0007,
	IMAGE_REL_I386_SEG12          = 0x0009,
	IMAGE_REL_I386_SECTION        = 0x000A,
	IMAGE_REL_I386_SECREL         = 0x000B,
	IMAGE_REL_I386_TOKEN          = 0x000C,
	IMAGE_REL_I386_SECREL7        = 0x000D,
	IMAGE_REL_I386_REL32          = 0x0014
}

enum : WORD {
	IMAGE_REL_AMD64_ABSOLUTE      = 0x0000,
	IMAGE_REL_AMD64_ADDR64        = 0x0001,
	IMAGE_REL_AMD64_ADDR32        = 0x0002,
	IMAGE_REL_AMD64_ADDR32NB      = 0x0003,
	IMAGE_REL_AMD64_REL32         = 0x0004,
	IMAGE_REL_AMD64_REL32_1       = 0x0005,
	IMAGE_REL_AMD64_REL32_2       = 0x0006,
	IMAGE_REL_AMD64_REL32_3       = 0x0007,
	IMAGE_REL_AMD64_REL32_4       = 0x0008,
	IMAGE_REL_AMD64_REL32_5       = 0x0009,
	IMAGE_REL_AMD64_SECTION       = 0x000A,
	IMAGE_REL_AMD64_SECREL        = 0x000B,
	IMAGE_REL_AMD64_SECREL7       = 0x000C,
	IMAGE_REL_AMD64_TOKEN         = 0x000D,
	IMAGE_REL_AMD64_SREL32        = 0x000E,
	IMAGE_REL_AMD64_PAIR          = 0x000F,
	IMAGE_REL_AMD64_SSPAN32       = 0x0010
}

enum : WORD {
	IMAGE_REL_IA64_ABSOLUTE       = 0x0000,
	IMAGE_REL_IA64_IMM14          = 0x0001,
	IMAGE_REL_IA64_IMM22          = 0x0002,
	IMAGE_REL_IA64_IMM64          = 0x0003,
	IMAGE_REL_IA64_DIR32          = 0x0004,
	IMAGE_REL_IA64_DIR64          = 0x0005,
	IMAGE_REL_IA64_PCREL21B       = 0x0006,
	IMAGE_REL_IA64_PCREL21M       = 0x0007,
	IMAGE_REL_IA64_PCREL21F       = 0x0008,
	IMAGE_REL_IA64_GPREL22        = 0x0009,
	IMAGE_REL_IA64_LTOFF22        = 0x000A,
	IMAGE_REL_IA64_SECTION        = 0x000B,
	IMAGE_REL_IA64_SECREL22       = 0x000C,
	IMAGE_REL_IA64_SECREL64I      = 0x000D,
	IMAGE_REL_IA64_SECREL32       = 0x000E,
	IMAGE_REL_IA64_DIR32NB        = 0x0010,
	IMAGE_REL_IA64_SREL14         = 0x0011,
	IMAGE_REL_IA64_SREL22         = 0x0012,
	IMAGE_REL_IA64_SREL32         = 0x0013,
	IMAGE_REL_IA64_UREL32         = 0x0014,
	IMAGE_REL_IA64_PCREL60X       = 0x0015,
	IMAGE_REL_IA64_PCREL60B       = 0x0016,
	IMAGE_REL_IA64_PCREL60F       = 0x0017,
	IMAGE_REL_IA64_PCREL60I       = 0x0018,
	IMAGE_REL_IA64_PCREL60M       = 0x0019,
	IMAGE_REL_IA64_IMMGPREL64     = 0x001A,
	IMAGE_REL_IA64_TOKEN          = 0x001B,
	IMAGE_REL_IA64_GPREL32        = 0x001C,
	IMAGE_REL_IA64_ADDEND         = 0x001F
}

enum : WORD {
	IMAGE_REL_SH3_ABSOLUTE        = 0x0000,
	IMAGE_REL_SH3_DIRECT16        = 0x0001,
	IMAGE_REL_SH3_DIRECT32        = 0x0002,
	IMAGE_REL_SH3_DIRECT8         = 0x0003,
	IMAGE_REL_SH3_DIRECT8_WORD    = 0x0004,
	IMAGE_REL_SH3_DIRECT8_LONG    = 0x0005,
	IMAGE_REL_SH3_DIRECT4         = 0x0006,
	IMAGE_REL_SH3_DIRECT4_WORD    = 0x0007,
	IMAGE_REL_SH3_DIRECT4_LONG    = 0x0008,
	IMAGE_REL_SH3_PCREL8_WORD     = 0x0009,
	IMAGE_REL_SH3_PCREL8_LONG     = 0x000A,
	IMAGE_REL_SH3_PCREL12_WORD    = 0x000B,
	IMAGE_REL_SH3_STARTOF_SECTION = 0x000C,
	IMAGE_REL_SH3_SIZEOF_SECTION  = 0x000D,
	IMAGE_REL_SH3_SECTION         = 0x000E,
	IMAGE_REL_SH3_SECREL          = 0x000F,
	IMAGE_REL_SH3_DIRECT32_NB     = 0x0010,
	IMAGE_REL_SH3_GPREL4_LONG     = 0x0011,
	IMAGE_REL_SH3_TOKEN           = 0x0012,
	IMAGE_REL_SHM_PCRELPT         = 0x0013,
	IMAGE_REL_SHM_REFLO           = 0x0014,
	IMAGE_REL_SHM_REFHALF         = 0x0015,
	IMAGE_REL_SHM_RELLO           = 0x0016,
	IMAGE_REL_SHM_RELHALF         = 0x0017,
	IMAGE_REL_SHM_PAIR            = 0x0018,
	IMAGE_REL_SHM_NOMODE          = 0x8000
}

enum : WORD {
	IMAGE_REL_M32R_ABSOLUTE       = 0x0000,
	IMAGE_REL_M32R_ADDR32         = 0x0001,
	IMAGE_REL_M32R_ADDR32NB       = 0x0002,
	IMAGE_REL_M32R_ADDR24         = 0x0003,
	IMAGE_REL_M32R_GPREL16        = 0x0004,
	IMAGE_REL_M32R_PCREL24        = 0x0005,
	IMAGE_REL_M32R_PCREL16        = 0x0006,
	IMAGE_REL_M32R_PCREL8         = 0x0007,
	IMAGE_REL_M32R_REFHALF        = 0x0008,
	IMAGE_REL_M32R_REFHI          = 0x0009,
	IMAGE_REL_M32R_REFLO          = 0x000A,
	IMAGE_REL_M32R_PAIR           = 0x000B,
	IMAGE_REL_M32R_SECTION        = 0x000C,
	IMAGE_REL_M32R_SECREL         = 0x000D,
	IMAGE_REL_M32R_TOKEN          = 0x000E
}

enum : WORD {
	IMAGE_REL_MIPS_ABSOLUTE       = 0x0000,
	IMAGE_REL_MIPS_REFHALF        = 0x0001,
	IMAGE_REL_MIPS_REFWORD        = 0x0002,
	IMAGE_REL_MIPS_JMPADDR        = 0x0003,
	IMAGE_REL_MIPS_REFHI          = 0x0004,
	IMAGE_REL_MIPS_REFLO          = 0x0005,
	IMAGE_REL_MIPS_GPREL          = 0x0006,
	IMAGE_REL_MIPS_LITERAL        = 0x0007,
	IMAGE_REL_MIPS_SECTION        = 0x000A,
	IMAGE_REL_MIPS_SECREL         = 0x000B,
	IMAGE_REL_MIPS_SECRELLO       = 0x000C,
	IMAGE_REL_MIPS_SECRELHI       = 0x000D,
	IMAGE_REL_MIPS_JMPADDR16      = 0x0010,
	IMAGE_REL_MIPS_REFWORDNB      = 0x0022,
	IMAGE_REL_MIPS_PAIR           = 0x0025
}


enum : WORD {
	IMAGE_REL_ALPHA_ABSOLUTE,
	IMAGE_REL_ALPHA_REFLONG,
	IMAGE_REL_ALPHA_REFQUAD,
	IMAGE_REL_ALPHA_GPREL32,
	IMAGE_REL_ALPHA_LITERAL,
	IMAGE_REL_ALPHA_LITUSE,
	IMAGE_REL_ALPHA_GPDISP,
	IMAGE_REL_ALPHA_BRADDR,
	IMAGE_REL_ALPHA_HINT,
	IMAGE_REL_ALPHA_INLINE_REFLONG,
	IMAGE_REL_ALPHA_REFHI,
	IMAGE_REL_ALPHA_REFLO,
	IMAGE_REL_ALPHA_PAIR,
	IMAGE_REL_ALPHA_MATCH,
	IMAGE_REL_ALPHA_SECTION,
	IMAGE_REL_ALPHA_SECREL,
	IMAGE_REL_ALPHA_REFLONGNB,
	IMAGE_REL_ALPHA_SECRELLO,
	IMAGE_REL_ALPHA_SECRELHI // = 18
}

enum : WORD {
	IMAGE_REL_PPC_ABSOLUTE,
	IMAGE_REL_PPC_ADDR64,
	IMAGE_REL_PPC_ADDR32,
	IMAGE_REL_PPC_ADDR24,
	IMAGE_REL_PPC_ADDR16,
	IMAGE_REL_PPC_ADDR14,
	IMAGE_REL_PPC_REL24,
	IMAGE_REL_PPC_REL14,
	IMAGE_REL_PPC_TOCREL16,
	IMAGE_REL_PPC_TOCREL14,
	IMAGE_REL_PPC_ADDR32NB,
	IMAGE_REL_PPC_SECREL,
	IMAGE_REL_PPC_SECTION,
	IMAGE_REL_PPC_IFGLUE,
	IMAGE_REL_PPC_IMGLUE,
	IMAGE_REL_PPC_SECREL16,
	IMAGE_REL_PPC_REFHI,
	IMAGE_REL_PPC_REFLO,
	IMAGE_REL_PPC_PAIR // = 18
}

// ???
const IMAGE_REL_PPC_TYPEMASK = 0x00FF;
const IMAGE_REL_PPC_NEG      = 0x0100;
const IMAGE_REL_PPC_BRTAKEN  = 0x0200;
const IMAGE_REL_PPC_BRNTAKEN = 0x0400;
const IMAGE_REL_PPC_TOCDEFN  = 0x0800;

enum {
	IMAGE_REL_BASED_ABSOLUTE,
	IMAGE_REL_BASED_HIGH,
	IMAGE_REL_BASED_LOW,
	IMAGE_REL_BASED_HIGHLOW,
	IMAGE_REL_BASED_HIGHADJ,
	IMAGE_REL_BASED_MIPS_JMPADDR
}
// End of constants documented in pecoff.doc

const size_t IMAGE_ARCHIVE_START_SIZE = 8;

const TCHAR[]
	IMAGE_ARCHIVE_START            = "!<arch>\n",
	IMAGE_ARCHIVE_END              = "`\n",
	IMAGE_ARCHIVE_PAD              = "\n",
	IMAGE_ARCHIVE_LINKER_MEMBER    = "/               ",
	IMAGE_ARCHIVE_LONGNAMES_MEMBER = "//              ";

const IMAGE_ORDINAL_FLAG32 = 0x80000000;

ulong IMAGE_ORDINAL64(ulong Ordinal) { return Ordinal & 0xFFFF; }
uint IMAGE_ORDINAL32(uint Ordinal)   { return Ordinal & 0xFFFF; }

bool IMAGE_SNAP_BY_ORDINAL32(uint Ordinal) {
	return (Ordinal & IMAGE_ORDINAL_FLAG32) != 0;
}

const ulong IMAGE_ORDINAL_FLAG64 = 0x8000000000000000;

bool IMAGE_SNAP_BY_ORDINAL64(ulong Ordinal) {
	return (Ordinal & IMAGE_ORDINAL_FLAG64) != 0;
}

// ???
const IMAGE_RESOURCE_NAME_IS_STRING    = 0x80000000;
const IMAGE_RESOURCE_DATA_IS_DIRECTORY = 0x80000000;

enum : DWORD {
	IMAGE_DEBUG_TYPE_UNKNOWN,
	IMAGE_DEBUG_TYPE_COFF,
	IMAGE_DEBUG_TYPE_CODEVIEW,
	IMAGE_DEBUG_TYPE_FPO,
	IMAGE_DEBUG_TYPE_MISC,
	IMAGE_DEBUG_TYPE_EXCEPTION,
	IMAGE_DEBUG_TYPE_FIXUP,
	IMAGE_DEBUG_TYPE_OMAP_TO_SRC,
	IMAGE_DEBUG_TYPE_OMAP_FROM_SRC,
	IMAGE_DEBUG_TYPE_BORLAND // = 9
}

enum : ubyte {
	FRAME_FPO,
	FRAME_TRAP,
	FRAME_TSS,
	FRAME_NONFPO
}

// ???
const IMAGE_DEBUG_MISC_EXENAME = 1;

// ???
const N_BTMASK = 0x000F;
const N_TMASK  = 0x0030;
const N_TMASK1 = 0x00C0;
const N_TMASK2 = 0x00F0;
const N_BTSHFT = 4;
const N_TШИФТ = 2;

const int
	IS_TEXT_UNICODE_ASCII16            = 0x0001,
	IS_TEXT_UNICODE_STATISTICS         = 0x0002,
	IS_TEXT_UNICODE_CONTROLS           = 0x0004,
	IS_TEXT_UNICODE_SIGNATURE          = 0x0008,
	IS_TEXT_UNICODE_REVERSE_ASCII16    = 0x0010,
	IS_TEXT_UNICODE_REVERSE_STATISTICS = 0x0020,
	IS_TEXT_UNICODE_REVERSE_CONTROLS   = 0x0040,
	IS_TEXT_UNICODE_REVERSE_SIGNATURE  = 0x0080,
	IS_TEXT_UNICODE_ILLEGAL_CHARS      = 0x0100,
	IS_TEXT_UNICODE_ODD_LENGTH         = 0x0200,
	IS_TEXT_UNICODE_NULL_BYTES         = 0x1000,
	IS_TEXT_UNICODE_UNICODE_MASK       = 0x000F,
	IS_TEXT_UNICODE_REVERSE_MASK       = 0x00F0,
	IS_TEXT_UNICODE_NOT_UNICODE_MASK   = 0x0F00,
	IS_TEXT_UNICODE_NOT_ASCII_MASK     = 0xF000;

const DWORD
	SERVICE_KERNEL_DRIVER       = 0x0001,
	SERVICE_FILE_SYSTEM_DRIVER  = 0x0002,
	SERVICE_ADAPTER             = 0x0004,
	SERVICE_RECOGNIZER_DRIVER   = 0x0008,
	SERVICE_WIN32_OWN_PROCESS   = 0x0010,
	SERVICE_WIN32_SHARE_PROCESS = 0x0020,
	SERVICE_INTERACTIVE_PROCESS = 0x0100,
	SERVICE_DRIVER              = 0x000B,
	SERVICE_WIN32               = 0x0030,
	SERVICE_TYPE_ALL            = 0x013F;

enum : DWORD {
	SERVICE_BOOT_START   = 0,
	SERVICE_SYSTEM_START = 1,
	SERVICE_AUTO_START   = 2,
	SERVICE_DEMAND_START = 3,
	SERVICE_DISABLED     = 4
}

enum : DWORD {
	SERVICE_IGNORE   = 0,
	SERVICE_NORMAL   = 1,
	SERVICE_SEVERE   = 2,
	SERVICE_CRITICAL = 3
}


const uint
	SE_OWNER_DEFAULTED          = 0x0001,
	SE_GROUP_DEFAULTED          = 0x0002,
	SE_DACL_PRESENT             = 0x0004,
	SE_DACL_DEFAULTED           = 0x0008,
	SE_SACL_PRESENT             = 0x0010,
	SE_SACL_DEFAULTED           = 0x0020,
	SE_DACL_AUTO_INHERIT_REQ    = 0x0100,
	SE_SACL_AUTO_INHERIT_REQ    = 0x0200,
	SE_DACL_AUTO_INHERITED      = 0x0400,
	SE_SACL_AUTO_INHERITED      = 0x0800,
	SE_DACL_PROTECTED           = 0x1000,
	SE_SACL_PROTECTED           = 0x2000,
	SE_SELF_RELATIVE            = 0x8000;

enum SECURITY_IMPERSONATION_LEVEL {
	SecurityAnonymous,
	SecurityIdentification,
	SecurityImpersonation,
	SecurityDelegation
}
alias SECURITY_IMPERSONATION_LEVEL* PSECURITY_IMPERSONATION_LEVEL;

alias BOOLEAN SECURITY_CONTEXT_TRACKING_MODE;
alias BOOLEAN* PSECURITY_CONTEXT_TRACKING_MODE;

const size_t SECURITY_DESCRIPTOR_MIN_LENGTH = 20;

const DWORD
	SECURITY_DESCRIPTOR_REVISION  = 1,
	SECURITY_DESCRIPTOR_REVISION1 = 1;

const DWORD
	SE_PRIVILEGE_ENABLED_BY_DEFAULT = 0x00000001,
	SE_PRIVILEGE_ENABLED            = 0x00000002,
	SE_PRIVILEGE_USED_FOR_ACCESS    = 0x80000000;

const DWORD PRIVILEGE_SET_ALL_NECESSARY = 1;

const SECURITY_IMPERSONATION_LEVEL
	SECURITY_MAX_IMPERSONATION_LEVEL = SECURITY_IMPERSONATION_LEVEL.SecurityDelegation,
	DEFAULT_IMPERSONATION_LEVEL      = SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation;

const BOOLEAN
	SECURITY_DYNAMIC_TRACKING = true,
	SECURITY_STATIC_TRACKING  = false;

// also in ddk/ntifs.h
const DWORD
	TOKEN_ASSIGN_PRIMARY    = 0x0001,
	TOKEN_DUPLICATE         = 0x0002,
	TOKEN_IMPERSONATE       = 0x0004,
	TOKEN_QUERY             = 0x0008,
	TOKEN_QUERY_SOURCE      = 0x0010,
	TOKEN_ADJUST_PRIVILEGES = 0x0020,
	TOKEN_ADJUST_GROUPS     = 0x0040,
	TOKEN_ADJUST_DEFAULT    = 0x0080,

	TOKEN_ALL_ACCESS        = STANDARD_RIGHTS_REQUIRED
                              | TOKEN_ASSIGN_PRIMARY
                              | TOKEN_DUPLICATE
                              | TOKEN_IMPERSONATE
                              | TOKEN_QUERY
                              | TOKEN_QUERY_SOURCE
                              | TOKEN_ADJUST_PRIVILEGES
                              | TOKEN_ADJUST_GROUPS
                              | TOKEN_ADJUST_DEFAULT,
	TOKEN_READ              = STANDARD_RIGHTS_READ | TOKEN_QUERY,
	TOKEN_WRITE             = STANDARD_RIGHTS_WRITE
                              | TOKEN_ADJUST_PRIVILEGES
                              | TOKEN_ADJUST_GROUPS
                              | TOKEN_ADJUST_DEFAULT,
	TOKEN_EXECUTE           = STANDARD_RIGHTS_EXECUTE;

const size_t TOKEN_SOURCE_LENGTH = 8;
// end ddk/ntifs.h


enum : ULONG32 {
	VER_PLATFORM_WIN32s,
	VER_PLATFORM_WIN32_WINDOWS,
	VER_PLATFORM_WIN32_NT
}

enum : UCHAR {
	VER_NT_WORKSTATION = 1,
	VER_NT_DOMAIN_CONTROLLER,
	VER_NT_SERVER
}

const USHORT
	VER_SUITE_SMALLBUSINESS            = 0x0001,
	VER_SUITE_ENTERPRISE               = 0x0002,
	VER_SUITE_BACKOFFICE               = 0x0004,
	VER_SUITE_TERMINAL                 = 0x0010,
	VER_SUITE_SMALLBUSINESS_RESTRICTED = 0x0020,
	VER_SUITE_EMBEDDEDNT               = 0x0040,
	VER_SUITE_DATACENTER               = 0x0080,
	VER_SUITE_SINGLEUSERTS             = 0x0100,
	VER_SUITE_PERSONAL                 = 0x0200,
	VER_SUITE_BLADE                    = 0x0400,
	VER_SUITE_STORAGE_SERVER           = 0x2000,
	VER_SUITE_COMPUTE_SERVER           = 0x4000;



static if (_WIN32_WINNT_ONLY) {
	static if (_WIN32_WINNT >= 0x500) {
		const DWORD
			VER_MINORVERSION     = 0x01,
			VER_MAJORVERSION     = 0x02,
			VER_BUILDNUMBER      = 0x04,
			VER_PLATFORMID       = 0x08,
			VER_SERVICEPACKMINOR = 0x10,
			VER_SERVICEPACKMAJOR = 0x20,
			VER_SUITENAME        = 0x40,
			VER_PRODUCT_TYPE     = 0x80;

		enum : DWORD {
			VER_EQUAL = 1,
			VER_GREATER,
			VER_GREATER_EQUAL,
			VER_LESS,
			VER_LESS_EQUAL,
			VER_AND,
			VER_OR // = 7
		}
	}

	static if (_WIN32_WINNT >= 0x501) {
		enum : ULONG {
			ACTIVATION_CONTEXT_SECTION_ASSEMBLY_INFORMATION       = 1,
			ACTIVATION_CONTEXT_SECTION_DLL_REDIRECTION,
			ACTIVATION_CONTEXT_SECTION_WINDOW_CLASS_REDIRECTION,
			ACTIVATION_CONTEXT_SECTION_COM_SERVER_REDIRECTION,
			ACTIVATION_CONTEXT_SECTION_COM_INTERFACE_REDIRECTION,
			ACTIVATION_CONTEXT_SECTION_COM_TYPE_LIBRARY_REDIRECTION,
			ACTIVATION_CONTEXT_SECTION_COM_PROGID_REDIRECTION, // = 7
			ACTIVATION_CONTEXT_SECTION_CLR_SURROGATES             = 9
		}
	}
}

// Macros
BYTE BTYPE(BYTE x) { return cast(BYTE) (x & N_BTMASK); }
bool ISPTR(uint x) { return (x & N_TMASK) == (IMAGE_SYM_DTYPE_POINTER << N_BTSHFT); }
bool ISFCN(uint x) { return (x & N_TMASK) == (IMAGE_SYM_DTYPE_FUNCTION << N_BTSHFT); }
bool ISARY(uint x) { return (x & N_TMASK) == (IMAGE_SYM_DTYPE_ARRAY << N_BTSHFT); }
bool ISTAG(uint x) {
	return x == IMAGE_SYM_CLASS_STRUCT_TAG
	    || x == IMAGE_SYM_CLASS_UNION_TAG
	    || x == IMAGE_SYM_CLASS_ENUM_TAG;
}
uint INCREF(uint x) {
	return ((x & ~N_BTMASK) << N_TШИФТ) | (IMAGE_SYM_DTYPE_POINTER << N_BTSHFT)
	  | (x & N_BTMASK);
}
uint DECREF(uint x) { return ((x >>> N_TШИФТ) & ~N_BTMASK) | (x & N_BTMASK); }

const DWORD TLS_MINIMUM_AVAILABLE = 64;

const ULONG
	IO_REPARSE_TAG_RESERVED_ZERO  = 0,
	IO_REPARSE_TAG_RESERVED_ONE   = 1,
	IO_REPARSE_TAG_RESERVED_RANGE = IO_REPARSE_TAG_RESERVED_ONE,
	IO_REPARSE_TAG_SYMBOLIC_LINK  = IO_REPARSE_TAG_RESERVED_ZERO,
	IO_REPARSE_TAG_MOUNT_POINT    = 0xA0000003,
	IO_REPARSE_TAG_SYMLINK        = 0xA000000C,
	IO_REPARSE_TAG_VALID_VALUES   = 0xE000FFFF;

/*	Although these are semantically boolean, they are documented and
 *	implemented to return ULONG; this behaviour is preserved for compatibility
 */
ULONG IsReparseTagMicrosoft(ULONG x)     { return x & 0x80000000; }
ULONG IsReparseTagHighLatency(ULONG x)   { return x & 0x40000000; }
ULONG IsReparseTagNameSurrogate(ULONG x) { return x & 0x20000000; }

bool IsReparseTagValid(ULONG x) {
	return !(x & ~IO_REPARSE_TAG_VALID_VALUES) && (x > IO_REPARSE_TAG_RESERVED_RANGE);
}

// Doesn't seem to make sense, but anyway....
ULONG WT_SET_MAX_THREADPOOL_THREADS(ref ULONG Flags, ushort Limit) {
	return Flags |= Limit << 16;
}
+/
enum ППраваДоступа
{
    ГенерноеЧтение				 = 0x80000000,
    ГенернаяЗапись 			= 0x40000000,
    ГенерноеВыполнение			 = 0x20000000,
    ГенерноеВсё				 = 0x10000000,
	Удалить 					= 0x00010000,
    ЧитатьКонтроль				 = 0x00020000,
    ЗаписьДСКД					= 0x00040000,
    ЗаписьВладельца 			= 0x00080000,
    Синхронизовать				= 0x00100000,
	ТребуютсяСП					 = 0x000F0000,
    СПЧ				 			= ЧитатьКонтроль, //Стандартные Права Чтения
    СПЗ							 = ЧитатьКонтроль, //Стандартные Права Запись
    СПВ							 = ЧитатьКонтроль,//Стандартные Права Выполнения
    ВсеСП						 = 0x001F0000, //Все Стандартные Права
    ВсеОсобыеПрава			 		= 0x0000FFFF,
    СистБезопДоступа				 = 0x01000000,
    ПозволенныйМаксимум 					= 0x02000000,		
}

enum ПТипТокена 
	{
	Первичный = 1,
	Имперсонация
	}	
	
enum ПТипБид//SID_NAME_USE
	{
	Пользователь = 1,
	Группа,
	Домен,
	Псевдоним,
	ИзвестнаяГруппа,
	УдалённыйАккаунт,
	Неверный,
	Неизвестный,
	Компьютер
	}

enum ПУровеньИмперсонацииБезопасности//SECURITY_IMPERSONATION_LEVEL
 {
	Анонимный,//SecurityAnonymous,
	Идентификация,//SecurityIdentification,
	Имперсонация,//SecurityImpersonation,
	Делегация//SecurityDelegation
}

const ПУровеньИмперсонацииБезопасности
	МАКС_УРОВЕНЬ_ИМПЕРСОНАЦИИ = ПУровеньИмперсонацииБезопасности.Делегация,
	ДЕФОЛТ_УРОВЕНЬ_ИМПЕРСОНАЦИИ      = ПУровеньИмперсонацииБезопасности.Имперсонация;	

enum ПТокен: бцел
{
	ПрисвоитьПервичный    = 0x0001,
	Дублировать         = 0x0002,
	Имперсонировать       = 0x0004,
	Запросить            = 0x0008,
	ЗапроситьИсток      = 0x0010,
	НастроитьПривилегии = 0x0020,
	НастроитьГруппы     = 0x0040,
	НастроитьДефолт    = 0x0080,

	ЛюбойДоступ        = ППраваДоступа.ТребуютсяСП
                              | ПрисвоитьПервичный
                              | Дублировать
                              | Имперсонировать
                              | Запросить
                              | ЗапроситьИсток
                              | НастроитьПривилегии
                              | НастроитьГруппы
                              | НастроитьДефолт,
	Читать              = ППраваДоступа.СПЧ | Запросить,
	Писать             = ППраваДоступа.СПЗ
                              | НастроитьПривилегии
                              | НастроитьГруппы
                              | НастроитьДефолт,
	Выполнять           = ППраваДоступа.СПВ
}

enum КЛАСС_ИНФОРМАЦИИ_ТОКЕНА //TOKEN_INFORMATION_CLASS
 {
	Пользователь =1,//TokenUser = 1,
	Группы,//TokenGroups,
	Привилегии,//TokenPrivileges,
	Владелец,//TokenOwner,
	ПервичнаяГруппа,//TokenPrimaryGroup,
	ДефолтныйДскд,//TokenDefaultDacl,
	Источник,//TokenSource,
	Тип,//TokenType,
	УровеньИмперсонации,//TokenImpersonationLevel,
	Статистика,//TokenStatistics,
	ОграниченныеБиды,//TokenRestrictedSids,
	ИдСессии,//TokenSessionId,
	ГруппыИПривилегии,//TokenGroupsAndPrivileges,
	СсылкаНаСессию,//TokenSessionReference,
	Песочница,//TokenSandBoxInert,
	ПолитикаАудита,//TokenAuditPolicy,
	Оригин//TokenOrigin
}

enum ПСтд
{
    Ввод =    cast(бцел)-10,
    Вывод=   cast(бцел)-11,
    Ошибка =    cast(бцел)-12,
}

/* WideCharToMultiByte */
enum ПШирСим
{
Предкомпоновка =	(512),//предварительно преобразовать компонированные символы в предкомпонированные
ОтброситьНепробельные	= (16),// отбросить непробельные символы 
ОтдельнСимв	= (32),//по умолчанию: генерировать отдельные символы 
ДефСим	= (64),//заменять исключения дефолтными символами
}

enum : Бул
{
	ЛОЖЬ 		= 0,
    ИСТИНА 		= 1 ,
	ОТКЛ 		= 0,
    ВКЛ 		= 1 ,
	НЕТ 		= 0,
    ДА 		= 1 ,
}

enum ПСжатие: бкрат
{ // MinGW: also in ddk/ntifs.h
	БезФормата     = 0x0000,
	ДефФормат  = 0x0001,
	ФорматЛЗНТ1    = 0x0002,
	ДвижокСтандарт = 0x0000,
	ДвижокМаксимум  = 0x0100,
	ДвижокГибер    = 0x0200
}

enum ПРежимКонсоли
{
    ОбрабВвод = 0x0001,
    СтрокВвод =      0x0002,
    ЭхоВвод =      0x0004,
    ОкВвод =    0x0008,
    МышВвод =     0x0010,
    ОбрабВывод =    0x0001,
    АдаптВывод =  0x0002,
}

enum ППозПотока: бцел {
  Уст,
  Тек,
  Кон,
}


enum ПРеестр
{
//Доступ
	ЗапросЗнач = 0x0001,
	УстановЗнач = 0x0002,
	СоздатьПодключ = 0x0004,
	ПеречислитьПодключи = 0x0008,
	Уведомить = 0x0010,
	Линковать = 0x0020,
	
	Читать			 = cast(цел)((ППраваДоступа.СПЧ | ЗапросЗнач | ПеречислитьПодключи | Уведомить)   & ~ППраваДоступа.Синхронизовать),
	Писать 			= cast(цел)((ППраваДоступа.СПЗ | УстановЗнач | СоздатьПодключ) & ~ППраваДоступа.Синхронизовать),
	Выполнить 		= cast(цел)(Читать & ~ППраваДоступа.Синхронизовать),
	ЛюбойДоступ	= cast(цел)((ППраваДоступа.ВсеСП | ЗапросЗнач | УстановЗнач | СоздатьПодключ | ПеречислитьПодключи | Уведомить | Линковать) & ~ППраваДоступа.Синхронизовать),	
	
//События
	СозданНовыйКлюч =         0x00000001,   // New Registry Key created
    ОткрытСуществующийКлюч =     0x00000002,   // Existing Key opened
	
//Опции

    Резерв =         (0x00000000),   // Параметр резервируется
    Перманент =     (0x00000000),   // Ключ сохраняется и после перезагрузки системы
    Врем =         (0x00000001),   // Ключ не сохраняется после перезагрузки
    СоздСсылку =      (0x00000002),   // Созданный ключ является символьной ссылкой
    Восстанов =   (0x00000004),   // Открыть для бэкапа или восстанова
                                                    // Требуются особые права
    ОткрытьСсылку =        (0x00000008),   // Открыть символьную ссылку
    Легал = (Резерв | Перманент | Врем | СоздСсылку | Восстанов | ОткрытьСсылку),
	
//Значение, Тип

	БезЗнач = 				0,// нет значения
	Юни0 =			 1,//строка нулевого окончания Юникод
	РасшЮни	=		2,//то же
	Бин =				3,//двоичн в свободной форме
	Бцел =				4,//32-битн чис
	БцелЛитлЭнд =		4 ,//32-битн чис
	БцелБигЭнд =		5,//32-битн чис
	Лмнк =				6,//символьная ссылка (Юникод)
	МультиЮни =		7 , //Многострочник Юникод
	СписРес =		8,// список ресурсов в карте ресурсов
	РесДескр =	9 ,// список ресурсов в аппаратном описании
	СписТребРес = 10,
	Бдол =					11,
	БдолЛитлЭнд =			11,
	
}

enum ПКлючРег: бцел
{
//Название ключа
Классы =           0x80000000,
ТекПольз =           0x80000001,
ЛокМаш =          0x80000002,
Пользователи =    0x80000003,
ДанОПроизводителе = 0x80000004,
ТекстПроизводителя = 0x80000050,
ТекстНЛСПроизводителя =  0x80000060,
ТекКонф =       0x80000005,
ДинДан =              0x80000006,

}
// Следующие флаги управляют содержимым структуры КОНТЕКСТ.
enum ПКонтекст
{
	РазмерРегистров_80387 =      80,
    i386 =    0x00010000,    // this assumes that i386 and
    i486 =    0x00010000,    // i486 have identical context records
    Упр =         (i386 | 0x00000001), // SS:SP, CS:IP, FLAGS, BP
    Целое =         (i386 | 0x00000002), // AX, BX, CX, DX, SI, DI
    Сегменты =        (i386 | 0x00000004), // DS, ES, FS, GS
    ПлавЗап =  (i386 | 0x00000008), // 387 state
    ОтладРегистры = (i386 | 0x00000010), // DB 0-3,6,7
    Полный = (Упр | Целое | Сегменты),
	МаксПоддержРасш = 512
}

enum ПФайл
{
	Нач 		= 0 ,
    Тек			 = 1 ,
    Кон			= 2, 
	
//СИ = Сообщение об Изменении
    СИ_ИмяФайла		= 0x00000001,
    СИ_ИмяПапки		= 0x00000002,
	СИ_Имя         = 0x00000003,
    СИ_АтрыФайла			= 0x00000004,
    СИ_РазмФайла					= 0x00000008,
    СИ_ПоследнЗап			= 0x00000010,
    СИ_ПоследнДост			= 0x00000020,
    СИ_ДатаСозд				= 0x00000040,
	СИ__ЭА			          = 0x00000080,
    СИ_Безоп				= 0x00000100,	
	СИ_ИмяПотока  = 0x00000200,
	СИ_РазмПотока  = 0x00000400,
	СИ_ЗапПотока = 0x00000800,
	СИ_ВалиднаяМаска          = 0x00000fff,
	
//	Действие над файлом
    Добавлен						= 0x00000001,
    Удалён				= 0x00000002,
    Изменён				= 0x00000003,
    ПереименованОбратно			= 0x00000004,
    Переименован			= 0x00000005,
	ДобавленПоток = 0x00000006,
	УдалёнПоток = 0x00000007,
	ИзменёнПоток = 0x00000008,
	УдалёнСПомDELETE = 0x00000009,
	ИдНеТунеллируем = 0x00000010,
	КонфликтТунеллируемыхИдов = 0x00000011,
	
    РегчувствПоиск				= 0x00000001,
    СохраненыРегистрыИмён					= 0x00000002,
    ЮникодНаДиске							= 0x00000004,
    НеизменныеСКД								= 0x00000008,
    Сжатие								= 0x00000010,
	КвотыОбъёма              = 0x00000020,
	ПоддерживаетРедкиеФайлы      = 0x00000040,
	ПоддерживаетТочкуВосстановления    = 0x00000080,
	ПоддерживаетУдалённоеХранилище    = 0x00000100,
	ФС_ЛФН_АПИС                     = 0x00004000,
    ТомСжат									= 0x00008000,
	ПоддерживаетИдыОбъектов        = 0x00010000,
	ПоддерживаетШифрацию        = 0x00020000,
	ИменованныеПотоки              = 0x00040000,
	ТомТолькоЧтения           = 0x00080000,
	ПоследовательнаяЗаписьСразу      = 0x00100000,
	ПоддерживаетТранзакции      = 0x00200000,
	
	// MinGW: also in ddk/ntifs.h

// MinGW: end ntifs.h

//Флаги и Атрибуты	
    ПервыйПайпЭкземпляр    = 0x00080000,
	ПереписатьЧерез					= 0x80000000,
    Асинхронно					= 0x40000000,
    БезБуф						= 0x20000000,
    СлучДоступ					= 0x10000000,
    ПоследоватСкан				= 0x08000000,
    УдалитьПриЗакрытии			= 0x04000000,
    РезервнСохрСемантики		= 0x02000000,
    СемантикаПосикс				= 0x01000000,
	ТолькоЧтение				 = 0x00000001,
    Скрытый 				= 0x00000002,
    Системный			 = 0x00000004,
    Папка 				= 0x00000010,
    Архив 				= 0x00000020,
	Устройство     		 = 0x00000040,
    Нормальный			= 0x00000080,
    Временный			= 0x00000100,
	РедкийФайл         = 0x00000200,
	ТочкаВосстановления       = 0x00000400,
    Сжатый				= 0x00000800,
    Офлайн				= 0x00001000,
	НеиндексированныйКонтент = 0x00002000,
	Шифрованный           = 0x00004000,
	ВалидныеФлаги         = 0x00007fb7,
	ВалидныйНаборФлагов     = 0x000031a7,//FILE_ATTRIBUTE_VALID_SET_FLAGS
	

// MinGW: Также в ddk/windamigos.dk.h	
	СписокПапки       = 0x00000001,
	ЧитатьДанные            = 0x00000001,
	ДобавитьФайл             = 0x00000002,
	ЗаписатьДанные           = 0x00000002,
	ДобавитьПодпапку     = 0x00000004,
	ДописатьДанные          = 0x00000004,
	СоздатьПайпЭкземпляр = 0x00000004,
	Читать_ЭА              = 0x00000008,
	ЧитатьСвойства      = 0x00000008,
	Писать_ЭА             = 0x00000010,
	ПисатьСвойства     = 0x00000010,
	Выполнить              = 0x00000020,
	Траверза             = 0x00000020,
	УдалитьПасынок         = 0x00000040,
	ЧитатьАтрибуты      = 0x00000080,
	ПисатьАтрибуты     = 0x00000100,
	
	СЧ        = 0x00000001,//СовместноеЧтение
	СЗ       = 0x00000002,//СовместнаяЗапись
	СУ     = 0x00000004,//СовместноеУдаление 
	СВФ = 0x00000007,//СовместныеВалидныеФлаги
	
	// Не документировано в MSDN
    КопироватьСтруктурХран = 0x00000041,
    СтруктурХран      = 0x00000441,

   // ВФО = Валидные Флаги Опций
	ВФО          = 0x00ffffff,// FILE_VALID_OPTION_FLAGS 
	ВФОПайп     = 0x00000032,
	ВФОМайлслот = 0x00000032,
	ВФНабора            = 0x00000036,//FILE_VALID_SET_FLAGS

	Заменить           = 0x00000000,
	Открыть                = 0x00000001,
	Создать              = 0x00000002,
	Открыть_ИФ             = 0x00000003,
	ПереписатьПоверх           = 0x00000004,
	Переписать_ИФ        = 0x00000005,
	МаксимальнаяДиспозиция = 0x00000005,

	ФайлДиректория            = 0x00000001,
	ПисатьЧерез             = 0x00000002,
	ТолькоПоследовательный           = 0x00000004,
	БезПромежутБуф = 0x00000008,
	Синх_ВВ_Трев      = 0x00000010,
	Синх_ВВ_БезТрев   = 0x00000020,
	НеДиректория        = 0x00000040,
	СоздатьСоединениеДерево    = 0x00000080,
	ВыполнитьЕслиОпБлокирована      = 0x00000100,
	НеЗная_ЭА           = 0x00000200,
	ОткрытьДляВосстанова         = 0x00000400,
	СлучайныйДоступ             = 0x00000800,
	УдалитьПоЗакрытию           = 0x00001000,
	ОткрытьПоИдФайла           = 0x00002000,
	ОткрытьДляБэкапа    = 0x00004000,
	НеСжимать            = 0x00008000,
	РезервироватьОпФильтр          = 0x00100000,
	ОткрытьТчкВосстанова        = 0x00200000,
	ОткрытьБезПеревызова            = 0x00400000,
	ОткрытьДляОпросаСвобПрострва = 0x00800000,	

}

enum ПКопирФайл
{
// КопируйФайлДоп()
	РазрешаетсяРасшифрованнаяЦель = 0,
	СбойЕслиСуществует = 1,
	Рестартуемо    = 2

}
enum ПСовмИспФайла //FILE_SHARE_ХХ
{
	Чтение			 = 0x00000001,// = ПФайл.СовместноеЧтение и т.д.
    Запись			 = 0x00000002,
    Удаление  		 = 0x00000004,
	ВалидныеФлаги	 = 0x00000007
}

enum ПРежимФайла
 {
  Ввод = 1,
  Вывод = 2,
  ВыводНов = 6,
  Добавка = 10,
  
 }  
alias ПРежимФайла ПФРежим;

enum ПРежСоздФайла: бцел
{
	СоздатьНовый				= 1,
    СоздатьВсегда				= 2,
    ОткрытьСущ					= 3,
    ОткрытьВсегда				= 4,
    ОбрезатьСущ					= 5,
}	

// флаги для GetDCEx()
enum ПФлагКУДоп
{
    Окно =           0x00000001,
    Кэш =            0x00000002,
    БезСбросаАтров =     0x00000004,
    ОбрезкаОтпрысков =     0x00000008,
    ОбрезкаПасынков =     0x00000010,
    ОбрезкаРодителя =       0x00000020,
    ИсклРгн =       0x00000040,
    ПересечьРгн =     0x00000080,
    ИсклОбнов =    0x00000100,
    ПересечьОбнов =  0x00000200,
    БлокироватьОбновОкна = 0x00000400,
    Валидировать =         0x00200000,
}

enum ППриоритетНити: цел
{
    НизРеалВрем =  15,  // value тот gets a thread to LowRealtime-1
    Макс =    2,   // maximum thread base приоритет boost
    Мин =    -2,  // minimum thread base приоритет boost
    Холостая =   -15, // value тот gets a thread to idle
    Низкий =          Мин,
    НижеНормы =    (Низкий+1),
    Норма =          0,
    Высокий =         Макс,
    ВышеНормы =    (Высокий-1),
    ВозвратОшибок =    цел.max,

}

enum ППроцесс: бцел
{
ПравоУдалять = cast(бцел)0x00010000L,//Требуется для удаления объекта. 
ПравоЧитатьКонтроль  = cast(бцел)0x00020000L,//Требуется для чтения информации в дескрипторе безопасности объекта, кроме информации в SACL. Для чтения/записи SACL, требуется право доступа ACCESS_SYSTEM_SECURITY. См.права доступа к SACL. 
ПравоСинхронизовать = cast(бцел)0x00100000L, //Право использовать объект для синхронизации. Это способствует ожиданию нити до того момента, когда объект будет в сигнализируемом состоянии. 
ПравоЗаписиДАК = cast(бцел)0x00040000L,//Требуется для изменения DACL в дескрипторе безопасности объекта. 
ПравоЗаписиВладельца = cast(бцел)0x00080000L, // Требуется для изменения владельца в дескрипторе безопасности объекта. 
ВсеПраваДоступа = cast(бцел)0x1F0FFF,//Все возможные права доступа для объекта процесса. 
ПравоСоздаватьПроцесс = cast(бцел)0x0080,//Требуется для создания процесса. 
ПравоСоздаватьНить = cast(бцел)0x0002,//Требуется для создания нити. 
ПравоДублироватьХэндл = cast(бцел)0x0040,//Требуется для дубликации хэндла посредством DuplicateHandle. 
ПравоЗапроса = cast(бцел)0x0400,// Требуется для получения определённой информации о процессе, его токене, коде выхода и классе приоритета (функции OpenProcessToken, GetExitCodeProcess, GetPriorityClass и IsProcessInJob). 
ПравоКвотировать = cast(бцел)0x0100,// Требуется для установки ограничений памяти с помощью SetProcessWorkingSetSize. 
ПравоУстанавливатьИнфо =cast(бцел)0x0200,
ПравоПрерывания = cast(бцел)0x0001,// Требуется для прекращения процесса посредством TerminateProcess. 
ПравоОбрабатыватьВП  =cast(бцел)0x0008,// Требуется для проведения операций в виртуальном адресном пространстве процесса (см. VirtualProtectEx и WriteProcessMemory). 
ПравоЧитатьВП = cast(бцел)0x0010,// Требуется для чтения виртуальной памяти процесса посредством ReadProcessMemory. 
ПравоЗаписыватьВП  = cast(бцел)0x0020,// Требуется для записи памяти посредством WriteProcessMemory. 
}

enum ПРежим_Адресации
{
	РА1616,
	РА1632,
	Реальный,
	Плоский,
}
alias ПРежим_Адресации ПРежАдр;

enum ПИдЧП //Ид Часового Пояса
{
    Неизв =  0,
    Стд = 1,
   Дэйлайт = 2,
}

enum  ПКомРез {
  Да            = 0x0,
  Нет         = 0x1,

  Нереализовано       = 0x80004001,
  НеИнтерфейс   = 0x80004002,
  Ук       = 0x80004003,
  Аборт         = 0x80004004,
  Провал          = 0x80004005,

  НетДоступа  = 0x80070005,
  ВнеПамяти   = 0x8007000E,
  НевернАрг    = 0x80070057,
  Хэндл      = 0x80070006,
  НеОжидалось  =  0x8000FFFF,

}
enum ПОшибка
{
    Нет = 0,
	Успех 				= 0,
    НевернФункц 			= 1 ,
    ФайлНеНайден 			= 2,
    ПутьНеНайден			= 3 ,
    МногоОткрФайлов 			= 4,
    ДоступЗапр			= 5,
    НевернХэндл 			= 6,
	АренаЗасорена  = (7),
	НехваткаПамяти = (8),
	НеверныйБлок = (9),
	ПлохаяСреда = (10),
	ПлохойФормат = (11),
	НеверныйДоступ = (12),
	НеверныеДанные = (13),
	ВнеПамяти = (14),
	НеверныйДрайв = (15),
	ТекущаяПапка = (16),
	ДругоеУстройство = (17),
	ФайловБольшеНеОсталось = (18),
	ЗащитаОтЗаписи = (19),
	НеверныйЮнит = (20),
	НеГотов = (21),
	НеправильнаяКоманда = (22),
	ОшибкаКонтрольнойСуммы = (23),
	НевернаяДлина = (24),
	ОшибкаПеремещения = (25),
	НеДискДОС = (26),
	СекторНеНайден = (27),
	НетБумаги = (28),
	ОшибкаЗаписи = (29),
	ОшибкаЧтения = (30),
	НеудачнаяГенерация = (31),
	НевернУкНаЭкземпляр = 32,
	НарушениеБлокировки = (33),
	НеверныйДиск = (34),
	НехваткаОбщегоБуфера = (36),
	ОшибкаУкКонцаФайла = (38),
	ДискПолон = (39),
	НеПоддерживается = (50),
	REM_NOT_LIST = (51),
	ДубликатИмени = (52),
	ПлохойСетевойПуть = (53),
	СетьЗанята = (54),
	УстройстваНеСуществует = (55),
	СлишкомМногоКоманд = (56),
	ADAP_HDW_ERR = (57),
	ПлохойСетевойОтвет = (58),
	НеожиданнаяСетеваяОшибка = (59),
	ПлохойУдалённыйАдаптер = (60),
	ПереполнениеОчередиПечати = (61),
	NO_SPOOL_SPACE = (62),
	ПечатьОтменена = (63),
	СетевоеИмяУдалено = (64),
	СетевойДоступЗапрещён = (65),
	ПлохойТипУстройства = (66),
	ПлохоеСетевоеИмя = (67),
	СлишкомМногоИмён = (68),
	СлишкомМногоСессий = (69),
	ОбщИспользованиеПриостановлено = (70),
	ЗапросНеПринят = (71),
	ПеренаправлениеПриостановлено = (72),
	ФайлУжеСуществует = (80),
	НельзяВыполнить = (82),
	Ошибка_I24 = (83),
	ВнеСтруктур = (84),
	УжеПрисвоено = (85),
	НеправильныйПароль = (86),
	НеправильныйПараметр = (87),
	ОшибкаСетевойЗаписи = (88),
	НетСлотовПроцедур = (89),
	СлишкомМногоСемафоров = (100),
	EXCL_SEM_ALREADY_OWNED = (101),
	СемафорУжеУстановлен = (102),
	СлишкомМногоЗапросовКСем = (103),
	НедействительноПриПрерывании = (104),
	ВладелецСемафораИсчез = (105),
	ЛимитПользователейСемафора = (106),
	ДискИзменён = (107),
	ДрайвБлокирован = (108),
	РазорванныйПайп = (109),
	ОткрытьНеУдалось = (110),
	ПереполненБуфер = (111),
	ДискПолон2 = (112),
	ПоисковыхУказателейБольшеНет = (113),
	НеверныйУказательЦели = (114),
	НевернаяКатегория = (117),
	НеверныйСвичВерификации = (118),
	ПлохойУровеньДрайвера = (119),
	ВызовНеВыполнен = (120),
	ТаймаутСемафора = (121),
	НедостаточноБуфера   		 	 = 122,
	НеверноеИмя = (123),
	НеверныйУровень = (124),
	НетМеткиТома = (125),
	МодульНеНайден = (126),
	ПроцедураНеНайдена = (127),
	WAIT_NO_CHILDREN = (128),
	CHILD_NOT_COMPLETE = (129),
	УказательПрямогоДоступа = (130),
	ОбратноеПеремещение = (131),
	ПеремещениеПоУстройству = (132),
	IS_JOIN_TARGET = (133),
	IS_JOINED = (134),
	IS_SUBSTED = (135),
	NOT_JOINED = (136),
	NOT_SUBSTED = (137),
	JOIN_TO_JOIN = (138),
	SUBST_TO_SUBST = (139),
	JOIN_TO_SUBST = (140),
	SUBST_TO_JOIN = (141),
	ДрайвЗанят = (142),
	ТотЖеДрайв = (143),
	ПапкаНеКорень = (144),
	ПапкаНепустая = (145),
	IS_SUBST_PATH = (146),
	IS_JOIN_PATH = (147),
	ПутьЗанят = (148),
	IS_SUBST_TARGET = (149),
	ТрассировкаСистема = (150),
	НеверныйСчётСобытий = (151),
	TOO_MANY_MUXWAITERS = (152),
	НеправильныйФорматСписка = (153),
	МеткаСлишкомДлинная = (154),
	TOO_MANY_TCBS = (155),
	СигналОтвергнут = (156),
	Сброшено = (157),
	НеБлокировано = (158),
	ПлохойАдресИдНити = (159),
	ПлохиеАргументы = (160),
	ПлохоеОпределениеПути = (161),
	SIGNAL_PENDING = (162),
	ДостигнутМаксимумНитей = (164),
	БлокировкаНеУдалась = (167),
	Занято = (170),
	CANCEL_VIOLATION = (173),
	АтомныеБлокировкиНеПоддерживаются = (174),
	НеверноеЧислоСегментов = (180),
	НеверныйПорядковыйНомер = (182),
	УжеЕсть         		 = 183,
	 НеверныйНомерФлага = (186),
	 СемафорНеНайден = (187),
	 НеверныйСтартовыйСегКода = (188),
	 НеверныйСегСтэка = (189),
	 НеверныйТипМодуля = (190),
	 НевернаяСигнатураЭкзэ = (191),
	 EXE_MARKED_INVALID = (192),
	 НеверныйФорматЭкзэ = (193),
	 ITERATED_DATA_EXCEEDS_64k = (194),
	 INVALID_MINALLOCSIZE = (195),
	 DYNLINK_FROM_INVALID_RING = (196),
	 IOPL_NOT_ENABLED = (197),
	 INVALID_SEGDPL = (198),
	 AUTODATASEG_EXCEEDS_64k = (199),
	 RING2SEG_MUST_BE_MOVABLE = (200),
	 RELOC_CHAIN_XEEDS_SEGLIM = (201),
	 INFLOOP_IN_RELOC_CHAIN = (202),
	 ENVVAR_NOT_FOUND = (203),
	 СигналНеПослан = (205),
	 FILENAME_EXCED_RANGE = (206),
	 RING2_STACK_IN_USE = (207),
	 META_EXPANSION_TOO_LONG = (208),
	 НеверныйНомерСигнала = (209),
	 Нить_1_Неактивна = (210),
	 Блокировано = (212),
	 TOO_MANY_MODULES = (214),
	 NESTING_NOT_ALLOWED = (215),
	 ПлохойПайп = (230),
	 ПайпЗанят = (231),
	 ДанныхНет = (232),
	 ПайпНеПодключен = (233),
    ЛишниеДанные		 	= 234 ,
	VC_DISCONNECTED = (240),
	INVALID_EA_NAME = (254),
	EA_LIST_INCONSISTENT = (255),
    ЭлтовБольшеНет 			= 259,
	 CANNOT_COPY = (266),
	 DIRECTORY = (267),
	 EAS_DIDNT_FIT = (275),
	 EA_FILE_CORRUPT = (276),
	 EA_TABLE_FULL = (277),
	 INVALID_EA_HANDLE = (278),
	 EAS_NOT_SUPPORTED = (282),
	 NOT_OWNER = (288),
	 TOO_MANY_POSTS = (298),
	 PARTIAL_COPY = (299),
	 MR_MID_NOT_FOUND = (317),
	 НеверныйАдрес = (487),
	 АрифметическоеПереполнение = (534),
	 ПайпПодключен = (535),
	 ПайпПрослушивается = (536),
	 EA_ACCESS_DENIED = (994),
	 ОперацияПрервана = (995),
	 НеполныйВВ = (996),
	 ОжидаетсяВВ = (997),
 ДоступаНет = (998),
 ОшПерестановки = (999),
 STACK_OVERFLOW = (1001),
 INVALID_MESSAGE = (1002),
 CAN_NOT_COMPLETE = (1003),
 INVALID_FLAGS = (1004),
 UNRECOGNIZED_VOLUME = (1005),
 ФайлПовреждён = (1006),
 ПолноэкранныйРежим = (1007),
 NO_TOKEN = (1008),
 BADDB = (1009),
 BADKEY = (1010),
 CANTOPEN = (1011),
 CANTREAD = (1012),
 CANTWRITE = (1013),
 REGISTRY_RECOVERED = (1014),
 REGISTRY_CORRUPT = (1015),
 REGISTRY_IO_FAILED = (1016),
 NOT_REGISTRY_FILE = (1017),
 KEY_DELETED = (1018),
 NO_LOG_SPACE = (1019),
 KEY_HAS_CHILDREN = (1020),
 CHILD_MUST_BE_VOLATILE = (1021),
 NOTIFY_ENUM_DIR = (1022),
 DEPENDENT_SERVICES_RUNNING = (1051),
 INVALID_SERVICE_CONTROL = (1052),
 SERVICE_REQUEST_TIMEOUT = (1053),
 SERVICE_NO_THREAD = (1054),
 SERVICE_DATABASE_LOCKED = (1055),
 SERVICE_ALREADY_RUNNING = (1056),
 INVALID_SERVICE_ACCOUNT = (1057),
 SERVICE_DISABLED = (1058),
 CIRCULAR_DEPENDENCY = (1059),
 SERVICE_DOES_NOT_EXIST = (1060),
 SERVICE_CANNOT_ACCEPT_CTRL = (1061),
 SERVICE_NOT_ACTIVE = (1062),
 FAILED_SERVICE_CONTROLLER_CONNECT = (1063),
 EXCEPTION_IN_SERVICE = (1064),
 DATABASE_DOES_NOT_EXIST = (1065),
 SERVICE_SPECIFIC_ERROR = (1066),
 PROCESS_ABORTED = (1067),
 SERVICE_DEPENDENCY_FAIL = (1068),
 SERVICE_LOGON_FAILED = (1069),
 SERVICE_START_HANG = (1070),
 INVALID_SERVICE_LOCK = (1071),
 SERVICE_MARKED_FOR_DELETE = (1072),
 SERVICE_EXISTS = (1073),
 ALREADY_RUNNING_LKG = (1074),
 SERVICE_DEPENDENCY_DELETED = (1075),
 BOOT_ALREADY_ACCEPTED = (1076),
 SERVICE_NEVER_STARTED = (1077),
 DUPLICATE_SERVICE_NAME = (1078),
 END_OF_MEDIA = (1100),
 FILEMARK_DETECTED = (1101),
 BEGINNING_OF_MEDIA = (1102),
 SETMARK_DETECTED = (1103),
 NO_DATA_DETECTED = (1104),
 PARTITION_FAILURE = (1105),
 INVALID_BLOCK_LENGTH = (1106),
 DEVICE_NOT_PARTITIONED = (1107),
 UNABLE_TO_LOCK_MEDIA = (1108),
 UNABLE_TO_UNLOAD_MEDIA = (1109),
 MEDIA_CHANGED = (1110),
 BUS_RESET = (1111),
 NO_MEDIA_IN_DRIVE = (1112),
 NO_UNICODE_TRANSLATION = (1113),
 DLL_INIT_FAILED = (1114),
 SHUTDOWN_IN_PROGRESS = (1115),
 NO_SHUTDOWN_IN_PROGRESS = (1116),
 IO_DEVICE = (1117),
 SERIAL_NO_DEVICE = (1118),
 IRQ_BUSY = (1119),
 MORE_WRITES = (1120),
 COUNTER_TIMEOUT = (1121),
 FLOPPY_ID_MARK_NOT_FOUND = (1122),
 FLOPPY_WRONG_CYLINDER = (1123),
 FLOPPY_UNKNOWN_ERROR = (1124),
 FLOPPY_BAD_REGISTERS = (1125),
 DISK_RECALIBRATE_FAILED = (1126),
 DISK_OPERATION_FAILED = (1127),
 DISK_RESET_FAILED = (1128),
 EOM_OVERFLOW = (1129),
 NOT_ENOUGH_SERVER_MEMORY = (1130),
 POSSIBLE_DEADLOCK = (1131),
 MAPPED_ALIGNMENT = (1132),
 SET_POWER_STATE_VETOED = (1140),
 SET_POWER_STATE_FAILED = (1141),
 OLD_WIN_VERSION = (1150),
 APP_WRONG_OS = (1151),
 SINGLE_INSTANCE_APP = (1152),
 RMODE_APP = (1153),
 INVALID_DLL = (1154),
 NO_ASSOCIATION = (1155),
 DDE_FAIL = (1156),
 DLL_NOT_FOUND = (1157),
 BAD_USERNAME = (2202),
 NOT_CONNECTED = (2250),
 OPEN_FILES = (2401),
 ACTIVE_CONNECTIONS = (2402),
 DEVICE_IN_USE = (2404),
 BAD_DEVICE = (1200),
 CONNECTION_UNAVAIL = (1201),
 DEVICE_ALREADY_REMEMBERED = (1202),
 NO_NET_OR_BAD_PATH = (1203),
 BAD_PROVIDER = (1204),
 CANNOT_OPEN_PROFILE = (1205),
 BAD_PROFILE = (1206),
 NOT_CONTAINER = (1207),
 EXTENDED_ERROR = (1208),
 INVALID_GROUPNAME = (1209),
 INVALID_COMPUTERNAME = (1210),
 INVALID_EVENTNAME = (1211),
 INVALID_DOMAINNAME = (1212),
 INVALID_SERVICENAME = (1213),
 INVALID_NETNAME = (1214),
 INVALID_SHARENAME = (1215),
 INVALID_PASSWORDNAME = (1216),
 INVALID_MESSAGENAME = (1217),
 INVALID_MESSAGEDEST = (1218),
 SESSION_CREDENTIAL_CONFLICT = (1219),
 REMOTE_SESSION_LIMIT_EXCEEDED = (1220),
 DUP_DOMAINNAME = (1221),
 NO_NETWORK = (1222),
	Отменено               = 1223,
 USER_MAPPED_FILE = (1224),
 CONNECTION_REFUSED = (1225),
 GRACEFUL_DISCONNECT = (1226),
 ADDRESS_ALREADY_ASSOCIATED = (1227),
 ADDRESS_NOT_ASSOCIATED = (1228),
 CONNECTION_INVALID = (1229),
 CONNECTION_ACTIVE = (1230),
 NETWORK_UNREACHABLE = (1231),
 HOST_UNREACHABLE = (1232),
 PROTOCOL_UNREACHABLE = (1233),
 PORT_UNREACHABLE = (1234),
 REQUEST_ABORTED = (1235),
 CONNECTION_ABORTED = (1236),
 RETRY = (1237),
 CONNECTION_COUNT_LIMIT = (1238),
 LOGIN_TIME_RESTRICTION = (1239),
 LOGIN_WKSTA_RESTRICTION = (1240),
 INCORRECT_ADDRESS = (1241),
 ALREADY_REGISTERED = (1242),
 SERVICE_NOT_FOUND = (1243),
 NOT_AUTHENTICATED = (1244),
 NOT_LOGGED_ON = (1245),
 CONTINUE = (1246),
 ALREADY_INITIALIZED = (1247),
 NO_MORE_DEVICES = (1248),
 NOT_ALL_ASSIGNED = (1300),
 SOME_NOT_MAPPED = (1301),
 NO_QUOTAS_FOR_ACCOUNT = (1302),
 LOCAL_USER_SESSION_KEY = (1303),
 NULL_LM_PASSWORD = (1304),
 UNKNOWN_REVISION = (1305),
 REVISION_MISMATCH = (1306),
 INVALID_OWNER = (1307),
 INVALID_PRIMARY_GROUP = (1308),
 NO_IMPERSONATION_TOKEN = (1309),
 CANT_DISABLE_MANDATORY = (1310),
 NO_LOGON_SERVERS = (1311),
 NO_SUCH_LOGON_SESSION = (1312),
 NO_SUCH_PRIVILEGE = (1313),
 PRIVILEGE_NOT_HELD = (1314),
 INVALID_ACCOUNT_NAME = (1315),
 USER_EXISTS = (1316),
 NO_SUCH_USER = (1317),
 GROUP_EXISTS = (1318),
 NO_SUCH_GROUP = (1319),
 MEMBER_IN_GROUP = (1320),
 MEMBER_NOT_IN_GROUP = (1321),
 LAST_ADMIN = (1322),
 WRONG_PASSWORD = (1323),
 ILL_FORMED_PASSWORD = (1324),
 PASSWORD_RESTRICTION = (1325),
 LOGON_FAILURE = (1326),
 ACCOUNT_RESTRICTION = (1327),
 INVALID_LOGON_HOURS = (1328),
 INVALID_WORKSTATION = (1329),
 PASSWORD_EXPIRED = (1330),
 ACCOUNT_DISABLED = (1331),
 NONE_MAPPED = (1332),
 TOO_MANY_LUIDS_REQUESTED = (1333),
 LUIDS_EXHAUSTED = (1334),
 INVALID_SUB_AUTHORITY = (1335),
 INVALID_ACL = (1336),
 INVALID_SID = (1337),
 INVALID_SECURITY_DESCR = (1338),
 BAD_INHERITANCE_ACL = (1340),
 SERVER_DISABLED = (1341),
 SERVER_NOT_DISABLED = (1342),
 INVALID_ID_AUTHORITY = (1343),
 ALLOTTED_SPACE_EXCEEDED = (1344),
 INVALID_GROUP_ATTRIBUTES = (1345),
	НевернУровеньИмперсонации 		= 1346,
	 CANT_OPEN_ANONYMOUS = (1347),
 BAD_VALIDATION_CLASS = (1348),
 BAD_TOKEN_TYPE = (1349),
 NO_SECURITY_ON_OBJECT = (1350),
 CANT_ACCESS_DOMAIN_INFO = (1351),
 INVALID_SERVER_STATE = (1352),
 INVALID_DOMAIN_STATE = (1353),
 INVALID_DOMAIN_ROLE = (1354),
 NO_SUCH_DOMAIN = (1355),
 DOMAIN_EXISTS = (1356),
 DOMAIN_LIMIT_EXCEEDED = (1357),
 INTERNAL_DB_CORRUPTION = (1358),
 INTERNAL_ERROR = (1359),
 GENERIC_NOT_MAPPED = (1360),
 BAD_DESCRIPTOR_FORMAT = (1361),
 NOT_LOGON_PROCESS = (1362),
 LOGON_SESSION_EXISTS = (1363),
 NO_SUCH_PACKAGE = (1364),
 BAD_LOGON_SESSION_STATE = (1365),
 LOGON_SESSION_COLLISION = (1366),
 INVALID_LOGON_TYPE = (1367),
 CANNOT_IMPERSONATE = (1368),
 RXACT_INVALID_STATE = (1369),
 RXACT_COMMIT_FAILURE = (1370),
 SPECIAL_ACCOUNT = (1371),
 SPECIAL_GROUP = (1372),
 SPECIAL_USER = (1373),
 MEMBERS_PRIMARY_GROUP = (1374),
 TOKEN_ALREADY_IN_USE = (1375),
 NO_SUCH_ALIAS = (1376),
 MEMBER_NOT_IN_ALIAS = (1377),
 MEMBER_IN_ALIAS = (1378),
 ALIAS_EXISTS = (1379),
 LOGON_NOT_GRANTED = (1380),
 TOO_MANY_SECRETS = (1381),
 SECRET_TOO_LONG = (1382),
 INTERNAL_DB_ERROR = (1383),
 TOO_MANY___FILE___IDS = (1384),
 LOGON_TYPE_NOT_GRANTED = (1385),
 NT_CROSS_ENCRYPTION_REQUIRED = (1386),
 NO_SUCH_MEMBER = (1387),
 INVALID_MEMBER = (1388),
 TOO_MANY_SIDS = (1389),
 LM_CROSS_ENCRYPTION_REQUIRED = (1390),
 NO_INHERITANCE = (1391),
 FILE_CORRUPT = (1392),
 DISK_CORRUPT = (1393),
 NO_USER_SESSION_KEY = (1394),
 LICENSE_QUOTA_EXCEEDED = (1395),
 INVALID_WINDOW_HANDLE = (1400),
 INVALID_MENU_HANDLE = (1401),
 INVALID_CURSOR_HANDLE = (1402),
 INVALID_ACCEL_HANDLE = (1403),
 INVALID_HOOK_HANDLE = (1404),
 INVALID_DWP_HANDLE = (1405),
 TLW_WITH_WSCHILD = (1406),
 CANNOT_FIND_WND_CLASS = (1407),
 WINDOW_OF_OTHER_THREAD = (1408),
 HOTKEY_ALREADY_REGISTERED = (1409),
	КлассУжеСуществует   			 = 1410,
	КлассаНеСуществует = (1411),
 CLASS_HAS_WINDOWS = (1412),
 INVALID_INDEX = (1413),
 INVALID_ICON_HANDLE = (1414),
 PRIVATE_DIALOG_INDEX = (1415),
 LISTBOX_ID_NOT_FOUND = (1416),
 NO_WILDCARD_CHARACTERS = (1417),
 CLIPBOARD_NOT_OPEN = (1418),
 HOTKEY_NOT_REGISTERED = (1419),
 WINDOW_NOT_DIALOG = (1420),
 CONTROL_ID_NOT_FOUND = (1421),
 INVALID_COMBOBOX_MESSAGE = (1422),
 WINDOW_NOT_COMBOBOX = (1423),
 INVALID_EDIT_HEIGHT = (1424),
 DC_NOT_FOUND = (1425),
 INVALID_HOOK_FILTER = (1426),
 INVALID_FILTER_PROC = (1427),
 HOOK_NEEDS_HMOD = (1428),
 GLOBAL_ONLY_HOOK = (1429),
 JOURNAL_HOOK_SET = (1430),
 HOOK_NOT_INSTALLED = (1431),
 INVALID_LB_MESSAGE = (1432),
 SETCOUNT_ON_BAD_LB = (1433),
 LB_WITHOUT_TABSTOPS = (1434),
 DESTROY_OBJECT_OF_OTHER_THREAD = (1435),
 CHILD_WINDOW_MENU = (1436),
 NO_SYSTEM_MENU = (1437),
 INVALID_MSGBOX_STYLE = (1438),
 INVALID_SPI_VALUE = (1439),
 SCREEN_ALREADY_LOCKED = (1440),
 HWNDS_HAVE_DIFF_PARENT = (1441),
 NOT_CHILD_WINDOW = (1442),
 INVALID_GW_COMMAND = (1443),
 INVALID_THREAD_ID = (1444),
 NON_MDICHILD_WINDOW = (1445),
 POPUP_ALREADY_ACTIVE = (1446),
 NO_SCROLLBARS = (1447),
 INVALID_SCROLLBAR_RANGE = (1448),
 INVALID_SHOWWIN_COMMAND = (1449),
 NO_SYSTEM_RESOURCES = (1450),
 NONPAGED_SYSTEM_RESOURCES = (1451),
 PAGED_SYSTEM_RESOURCES = (1452),
 WORKING_SET_QUOTA = (1453),
 PAGEFILE_QUOTA = (1454),
 COMMITMENT_LIMIT = (1455),
 MENU_ITEM_NOT_FOUND = (1456),
 EVENTLOG_FILE_CORRUPT = (1500),
 EVENTLOG_CANT_START = (1501),
 LOG_FILE_FULL = (1502),
 EVENTLOG_FILE_CHANGED = (1503),
	НеверныеДанные2               = 0x80090005,
	НеверныйСигнал             = 0x80090006,
	НЛХВнеИндексов = 0xFFFFFFFF,
	СтатусНеПам =	cast(бцел)(0xc0000017L),
	СтатусНарушДоступа = cast(бцел)(0xc0000005L),
}

enum ПОшКомм: бцел
{

	ПерепВхБуф   = 0x0001,
	ПерепСимБуф  = 0x0002,
	Паритет = 0x0004,
	Фрейм    = 0x0008,
	Брейк    = 0x0010,
	БуферВыводаБылЗанят   = 0x0100,
	ТаймаутПУ     = 0x0200,
	ВводВывод      = 0x0400,
	ПУНеУказано      = 0x0800,
	НетБумаги      = 0x1000,
	РежимНеПоддерживается     = 0x8000

}

enum ПЗагрФлаг: бцел //Флаги для загрузки динамических библиотек
{
БезЗависимостей = 0x00000001,
ИгнорУрАвториз = 0x00000010,
КакФайлДанных = 0x00000002,
АльтПоиск = 0x00000008,
}

enum ПОкПерерис : бцел
{
    Инвалидируй =          0x0001,
    ВнутрРис =       0x0002,
    Сотри =               0x0004,
    Валидируй =            0x0008,
    БезВнутрРис =     0x0010,
    БезСтир =             0x0020,
    БезОпрысков =          0x0040,
    ВсеОтпрыски =         0x0080,
    ОбновиСейч =           0x0100,
    СотриСейч =            0x0200,
    Кадр =               0x0400,
    БезКадра =             0x0800,
}
//Флаги, используемые БЕЗОПМАСом (фичи)
enum  ПФичаБезопмаса: бкрат
 {
  Авто = 0x1,
  Статич = 0x2,
  Внедрён = 0x4,
  ФиксРазм = 0x10,
  Зап = 0x20,
  С_ИИД = 0x40,
  С_Вартип = 0x80,
  Бткст = 0x100,
  Неизв = 0x200,
  Диспеч = 0x400,
  Вариант = 0x800,
  Резерв = 0xF008
}

enum ПТипВарианта : бкрат //VT_xxxxxx
{
  Пустой            = 0,
  Пусто             = 1,
  Ц2               = 2,
  Ц4               = 3,
  Р4               = 4,
  Р8               = 5,
  CY               = 6,
  Дата             = 7,
  БинТекст             = 8,
  Диспетчер         = 9,
  Ошибка            = 10,
  Бул             = 11,
  ВАРИАНТ          = 12,
  Инкогнито          = 13,
  ДЕСЯТОК          = 14,
  Ц1               = 16,
  Бц1              = 17,
  Бц2              = 18,
  Бц4              = 19,
  Ц8               = 20,
  Бц8              = 21,
  Цел              = 22,
  Бцел             = 23,
  Проц             = 24,
  КомРез          = 25,
  Ук              = 26,
  БЕЗОПМАС        = 27,
  КМАССИВ           = 28,
  Пользовательский      = 29,
  Ткст0            = 30,
  Ткстш           = 31,
  ЗАПИСЬ           = 36,
  ЦелУк          = 37,
  БцелУк         = 38,
  ФВРЕМЯ         = 64,
  Блоб             = 65,
  Поток           = 66,
  Хран          = 67,
  ПоточныйОбъект  = 68,
  СохранённыйОбъект    = 69,
  БлобОбъект      = 70,
  ОбрезДанн               = 71,
  КЛСИД            = 72,
  Верспоток = 73,
  БинТекстБлоб        = 0x0fff,
  Вектор           = 0x1000,
  Массив            = 0x2000,
  ПоСсылке            = 0x4000,
  Резерв         = 0x8000
}

enum ПВинСокОш: цел
{
	Блокировано =     10035,
	Прервано =           10004,
	ХостНеНайден =  11001,
}

enum ПТипСок: цел
{
	Поток =     1,
	ДГрамма =      2,
	Необр =        3,
	НДС =        4, //Надёжно Доставленное Сообщение (RDM  - Reliably Delivered Message)
	ППП =  5, //Последовательный Поток Пакетов
}

enum ППротокол: цел
{
	СОКЕТ =  0xFFFF,		/// сокет 
	ИП =    0,//IP,	/// интернет протокол версии 4
	ИПУС =  1,//ICMP,	/// интернет протокол управляющих сообщений
	ИПГУ =  2,//IGMP,	/// интернет протокол группового управления
	ВВП =   3,//GGP,	/// "ворота" в "воротный" протокол (gateway to gateway protocol)
	ПУТ =   6,//TCP,	/// протокол управляемой трансмиссии
	УПП =   12,//PUP,	/// универсальный пакетный протокол PARC
	ППД =   17,//UDP,	/// протокол пользовательских датаграмм
	КСЕР =   22,//IDP,	/// протокол Xerox NS
	ИПВ6 =  41,//IPV6,	/// интернет протокол версии 6
	НД =    77, //ND
	Необр =   255,	//RAW
	Макс =   256,//MAX
}


enum ПОпцияСокета: цел
{
	Отладка =                0x0,///SO_DEBUG: записать отладочную инфо
	Вещание =            0x0020,	/// SO_BROADCAST: разрешить передачу широковещательных сообщений
	ПереиспАдр =            0x0004,///SO_REUSEADDR: разрешить локальное переиспользование адреса
	Заминка =               0x0080,	/// SO_LINGER: заминка при закрытии, если остались неотправленные данные
	СПДИнлайнинг =            0x0100,	///SO_OOBINLINE: получать сверхпакетные данные в пакете (band)
	ОтправБуф =               0x1001,///SO_SNDBUF: отправить размер буфера
	ПолучБуф =               0x1002,///SO_RCVBUF: получить размер буфера
	НеМаршрутизировать =            0x0010,//SO_DONTROUTE: не маршрутизировать
	Прослушивается =   0x0002,///SO_ACCEPTCONN
	БезЗаминки =  ~Заминка,///SO_DONTLINGER
	ЭксклюзивнИспАдр = ~ПереиспАдр,///SO_EXCLUSIVEADDRUSE
	Тип =         0x1008, //SO_TYPE
	Ошибка =        0x1007, //SO_ERROR
	ОставатьсяНаСвязи = 0x0008,//SO_KEEPALIVE
	ИспОбрЦикл = 0x0040, //SO_USELOOPBACK
	
	/*BSD options not supported for дайопцсок are as shown in the following table.

	SO_SNDLOWAT =     0x1003,
	SO_RCVLOWAT =     0x1004,
	SO_SNDTIMEO =     0x1005,
	SO_RCVTIMEO =     0x1006,
	
	*/
	
	// SocketOptionLevel.TCP:
	ПУТБезЗадержек =          1,	///TCP_NODELAY: отключить алгоритм Нагла для коалесцентной посылки

	ИПМультикастЦикл = 0x4,//IP_MULTICAST_LOOP
	ИПВГруппу =      0x5,	///IP_ADD_MEMBERSHIP
	ИПИзГруппы =     0x6,	///IP_DROP_MEMBERSHIP
	
	// SocketOptionLevel.IPV6:
	ИПВ6ЮникастХопс =    4,	//IPV6_UNICAST_HOPS
	ИПD6МультикастИф =    9,	//IPV6_MULTICAST_IF
	ИПВ6МультикастХопс = 10, //IPV6_MULTICAST_HOPS	
	ИПВ6МультикастЦикл =  11,	//IPV6_MULTICAST_LOOP	
	ИПВ6ВГруппу =  12,///IPV6_ADD_MEMBERSHIP = IPV6_JOIN_GROUP	
	ИПВ6ИзГруппы = 13,//IPV6_LEAVE_GROUP =     IPV6_DROP_MEMBERSHIP	
}

enum ПСемействоАдресов: цел
{
	НЕУК =		0,//AF_UNSPEC;
	ЮНИКС =       1,//AF_UNIX,	/// локальная связь
	ИНЕТ =       2,//AF_INET,	/// итернет протокол версии 4
	АЙПИЭКС =        6,//AF_IPX,	/// novell IPX
	ЭПЛТОК =  16,//AF_APPLETALK,	/// appletalk
	ИНЕТ6 =      23,//AF_INET6,	// интернет протокол версии 6;
	ИМПЛИНК = 3,//	AF_IMPLINK
	ПИЮПИ = 4, //AF_PUP
	ХАОС = 5, //AF_CHAOS
	НС = АЙПИЭКС, //AF_NS,
	ИСО = 7,//AF_ISO,
	ОСИ = ИСО, //AF_OSI
	ЭКМА = 8,//AF_ECMA
	ДАТАКИТ = 9,//AF_DATAKIT
	СИСИАЙТИТИ = 10,//AF_CCITT
	ЭСЭНЭЙ = 11,//AF_SNA
	ДИКнет = 12,//AF_DECnet
	ДЛИ =        13,
	ЛАТ =        14,
	ХАЙЛИНК =     15,
	НЕТБИОС =    17,
	ВОЙСВЬЮ =  18,
	ФАЙРФОКС =    19,
	УННОУН1 =   20,
	БАН =        21,
	АТМ =        22,
	КЛАСТЕР =    24,
	са12844 =      25,
	ИРДА =       26,
	НЕТДЕС =     28,
	
	МАКС =        29,

}

enum ПЭкстрЗакрытиеСокета: цел
{
	Приём = 0,	///SD_RECEIVE: socket receives are disallowed
	Отправка =     1,	///SD_SEND: socket sends are disallowed
	Всё =     2,	///SD_BOTH: both RECEIVE and SEND
}

enum ПФлагиСокета: цел
{
	Неук =       0,             /// флагов не указано
	СПД =        0x1,       /// сверхпакетные данные потока
	Просмотр =       0x2,      /// посмотреть входящие данные, не удаляя их из очереди, только при получении
	НеМаршрутизировать =  0x4, /// данные не следует подвергать маршрутизации; этот флаг может игнорироваться. Только для отправки.
    БезСигнала =   0x0,  /// не посылать сигнала SIGPIPE при ошибке записи в сокет, а вместо него вернуть EPIPE
}


enum ПИнАдр: бцел
{
	Любой =        0,
	ОбрЦикл =   0x7F000001,
	Вещание =  0xFFFFFFFF,
	Неук =       0xFFFFFFFF,	
}

enum ПИницКо: бцел
 {
  Многопоточно = 0x0,
  Купейно = 0x2,
  ОтключитьОле1Дде = 0x4,
  Скорость = 0x8
}

enum ПИмИнфо //NI_xxx
{
	МаксХост	= 1025,
	МаксСерв	= 32,
	БезПКДИ			= 0x01, //ПКДИ = Полностью Квалифицированное Доменное Имя
	НумерикХост	= 0x02,
	NAMEREQD		= 0x04,
	НумерикСерв	= 0x08,
	Дграмм			= 0x10
}

enum АИ: цел
{
	Пассив = 0x1,
	КанонИмя = 0x2,
	НумерикХост = 0x4,
}

enum : бцел
{
    ПОКА_АКТИВЕН = (0x103),
}
enum
{
    БУФЕР_ТЕКСТОВОГО_РЕЖИМА_КОНСОЛИ = 1,
}

enum ПСисМетрика //SM_xxxx
{
    ШирЭкрана =             0,
    ВысЭкрана =             1,
    ШирВППрокр =            2,
    ВысГПпрокр =            3,
    ВысЗага =            4,
    ШирБорд =             5,
    ВысБорд =             6,
    ШирДлгКадра =           7,
    ВысДлгКадра =           8,
    CYVTHUMB =             9,
    CXHTHUMB =             10,
    ШирПикт =               11,
    ВысПикт =               12,
    ШирКурсора =             13,
    ВысКурсора =             14,
    ВысМеню =               15,
    НирПолнЭкр =         16,
    ВысПолнЭкр =         17,
    ВысКанджиОкна =        18,
    МышьЕсть =         19,
    ВысВППрокр =            20,
    ШирГПпрокр =            21,
    Отладка =                22,
    SWAPBUTTON =           23,
    Резерв1 =            24,
    Резерв2 =            25,
    Резерв3 =            26,
    Резерв4 =            27,
    ШирМин =                28,
    ВысМин =                29,
    CXSIZE =               30,
    CYSIZE =               31,
    ШирКадра =              32,
    ВысКадра =              33,
    CXMINTRACK =           34,
    CYMINTRACK =           35,
    CXDOUBLECLK =          36,
    CYDOUBLECLK =          37,
    CXICONSPACING =        38,
    CYICONSPACING =        39,
    MENUDROPALIGNMENT =    40,
    PENWINDOWS =           41,
    DBCSENABLED =          42,
    ЧлоКнопокМыши =        43,
    ШирФиксирКадра =         ШирДлгКадра,
    ВысФмксирКадра =         ВысДлгКадра,
    CXSIZEFRAME =          ШирКадра,
    CYSIZEFRAME =          ВысКадра,
    SECURE =               44,
    CXEDGE =               45,
    CYEDGE =               46,
    CXMINSPACING =         47,
    CYMINSPACING =         48,
    CXSMICON =             49,
    CYSMICON =             50,
    CYSMCAPTION =          51,
    CXSMSIZE =             52,
    CYSMSIZE =             53,
    CXMENUSIZE =           54,
    CYMENUSIZE =           55,
    ARRANGE =              56,
    CXMINIMIZED =          57,
    CYMINIMIZED =          58,
    CXMAXTRACK =           59,
    CYMAXTRACK =           60,
    CXMAXIMIZED =          61,
    CYMAXIMIZED =          62,
    Сеть =              63,
    CLEANBOOT =            67,
    CXDRAG =               68,
    CYDRAG =               69,
    SHOWSOUNDS =           70,
    CXMENUCHECK =          71,
    CYMENUCHECK =          72,
    SLOWMACHINE =          73,
    MIDEASTENABLED =       74,
    CMETRICS =             75,
}

enum ПАтрыИнфосим
{
    СинийПП =      0x0001, // text color contains blue.
    ЗелёныйПП =     0x0002, // text color contains green.
    КрасныйПП =       0x0004, // text color contains red.
    ИнтПП = 0x0008, // text color is intensified.
    СинийЗП =      0x0010, // background color contains blue.
    ЗелёныйЗП =     0x0020, // background color contains green.
    КрасныйЗП =       0x0040, // background color contains red.
    ИнтЗП = 0x0080, // background color is intensified.
}
alias ПАтрыИнфосим ПТекстКонсоли;

//
//  EventType флаги:
//
enum ПТипСоб
{
    Клавиша =         0x0001, // Событие contains key событие record
    Мышь =       0x0002, // Событие contains mouse событие record
    РазмБуфОкна = 0x0004, // Событие contains window change событие record
    Меню = 0x0008, // Событие contains menu событие record
    Фокус = 0x0010, // событие contains focus change
}
//
// EventFlags
//

enum ПТипСобМыши
{
    Движение =   0x0001,
    Двуклик =  0x0002,
	Колесо =  0x0004,

}
//
// ButtonState флаги
//
enum ПСостКнопкиМыши
{
    НажатаПерваяСлева =    0x0001,
    НажатаСамаяПравая =        0x0002,
    НажатаВтораяСлева =    0x0004,
    НажатаТретьяСлева =    0x0008,
    НажатаЧетвёртаяСлева =    0x0010,
}

enum ПСостКлУпр
{
    НажатПравыйАльт =     0x0001, // the right alt key is pressed.
    НажатЛевыйАльт =      0x0002, // the left alt key is pressed.
    НажатПравыйКтрл =    0x0004, // the right ctrl key is pressed.
    НажатЛевыйКтрл =     0x0008, // the left ctrl key is pressed.
    НажатШифт =         0x0010, // the shift key is pressed.
    НумлокВкл =            0x0020, // the numlock light is on.
    СкроллокВкл =         0x0040, // the scrolllock light is on.
    КапслокВкл =           0x0080, // the capslock light is on.
    ENHANCED_KEY =          0x0100, // the key is enhanced.
}

enum: бцел
{
    БЕСК =              бцел.max,
    ЖДИ_ОБЪЕКТ_0 =         0,
    ЖДИ_ПОКИНУТЫЙ_0 =      0x80,
    ЖДИ_ТАЙМАУТ =          0x102,
    ЖДИ_ЗАВЕРШЕНИЕ_ВВ =    0xc0,
    ЖДИ_ПОКИНУТЫЙ =        0x80,
    ЖДИ_ПРОВАЛ =           бцел.max,
}
enum ПСтильПера //PS_xxxx
{
    Сплошной =            0,
    Штрих =             1, /* -------  */
    Пунктир =              2, /* .......  */
    ШтрихПунктир =          3, /* _._._._  */
    ШтрихПунктирПунктир =       4, /* _.._.._  */
    Никакой =             5,
    ВРамке =      6,
    СтильПользователя =        7,
    Альтернатива =        8,
    МаскаСтиля =       0x0000000F,

    PS_ENDCAP_ROUND =     0x00000000,
    PS_ENDCAP_SQUARE =    0x00000100,
    PS_ENDCAP_FLAT =      0x00000200,
    PS_ENDCAP_MASK =      0x00000F00,

    PS_JOIN_ROUND =       0x00000000,
    PS_JOIN_BEVEL =       0x00001000,
    PS_JOIN_MITER =       0x00002000,
    PS_JOIN_MASK =        0x0000F000,

    Косметический =         0x00000000,
    Геометрический =        0x00010000,
    МаскаТипа =        0x000F0000,
}

enum ПЗвук
{
    Синх =            0x0000, /* играть синхронно (дефолт) */
    Асинх =           0x0001, /* играть асинхронно */
    БезДефолта =       0x0002, /* тишина (!default), если звук не найден */
    Память =          0x0004, /* указывает на файл в памяти */
    Цикл =            0x0008, /* loop the sound until следщ sndPlaySound */
    БезОстановки =          0x0010, /* don't stop any currently playing sound */

    НеЖдать =    0x00002000, /* не ждать, есди драйвер занят */
    Алиас =       0x00010000, /* имя is a registry alias */
    ИдАлиас =  0x00110000, /* alias is a predefined ID */
    Имяф =    0x00020000, /* имя is file имя */
    Ресурс =    0x00040004, /* имя is resource имя or atom */

    Чистить =           0x0040, /* purge non-static events for task */
    Приложение =     0x0080, /* look for application specific association */


    АлиасСтарт =   0,     /* alias base */
}
/+
enum : бцел
{
    SRCCOPY =             cast(бцел)0x00CC0020, /* dest = source                   */
    SRCPAINT =            cast(бцел)0x00EE0086, /* dest = source OR dest           */
    SRCAND =              cast(бцел)0x008800C6, /* dest = source AND dest          */
    SRCINVERT =           cast(бцел)0x00660046, /* dest = source XOR dest          */
    SRCERASE =            cast(бцел)0x00440328, /* dest = source AND (NOT dest)   */
    NOTSRCCOPY =          cast(бцел)0x00330008, /* dest = (NOT source)             */
    NOTSRCERASE =         cast(бцел)0x001100A6, /* dest = (NOT src) AND (NOT dest) */
    MERGECOPY =           cast(бцел)0x00C000CA, /* dest = (source AND pattern)     */
    MERGEPAINT =          cast(бцел)0x00BB0226, /* dest = (NOT source) OR dest     */
    PATCOPY =             cast(бцел)0x00F00021, /* dest = pattern                  */
    PATPAINT =            cast(бцел)0x00FB0A09, /* dest = DPSnoo                   */
    PATINVERT =           cast(бцел)0x005A0049, /* dest = pattern XOR dest         */
    DSTINVERT =           cast(бцел)0x00550009, /* dest = (NOT dest)               */
    BLACKNESS =           cast(бцел)0x00000042, /* dest = BLACK                    */
    WHITENESS =           cast(бцел)0x00FF0062, /* dest = WHITE                    */
}
+/
enum ППамять
{
//Секции
    ЗапросСекц       = 0x0001,
    ЗаписьСекцКарт   = 0x0002,
    ЧтениеСекцКарт    = 0x0004,
    ВыполнитьСекцКарт = 0x0008,
    УвеличитьРазмСекц = 0x0010,
	Копия = ЗапросСекц,
	Запись = ЗаписьСекцКарт,
	Чтение = ЧтениеСекцКарт,
	ВыполнитьСекцКартЯвно = 0x0020,
    ВсеДоступыКСекции = cast(int)(ППраваДоступа.ТребуютсяСП|0x0001| 0x0002 | 0x0004 | 0x0008 | 0x0010),
//Страницы
    СтрНедост          = 0x01,
    СтрТолькоЧтен          = 0x02,
    СтрЗапЧтен         = 0x04,
    СтрЗапКоп         = 0x08,
    СтрВып           = 0x10,
    СтрЧтенВып      = 0x20,
    СтрЗапЧтенВып = 0x40,
    СтрЗапКопВып = 0x80,
	СтрЗапКомб = 0x400,
    СтрОхрана            = 0x100,
    СтрБезКэша          = 0x200,
	
//Секции
    СекФайл           = 0x800000,
    СекОбраз         = 0x1000000,
	СекЗащищёнОбраз =  0x2000000 ,
    СекРезерв       = 0x4000000,
    СекОтправить        = 0x8000000,
    СекБезКэша      = 0x10000000,
	СекЗапКомб = 0x40000000,     
	СекБольшиеСтр =  0x80000000,     
	СбросФлОбзЗап = 0x01, //WRITE_WATCH_FLAG_RESET
//ПАМ_
    Отправить           = 0x1000,	//mem_commit
    Резервировать          = 0x2000,//mem_reserve
	Записать = Отправить|Резервировать,
    Взять         = 0x4000,//mem_decommit
    Освободить          = 0x8000,//mem_release
    Удалить            = 0x10000, //mem_free
    Частная         = 0x20000,
    Картированная          = 0x40000,
    Сброс           = 0x80000,
    СверхуВниз       = 0x100000,
	БольшиеСтр = 0x20000000,
	Физическая = 0X400000,
	ЗапОбзор  =    0x200000,     
    Вращать =        0x800000,    
    Стр4Мб =    0x8000000,
	Образ        = СекОбраз,

//Глоб
    ГлобФиксир =	(0),
    ГлобПеремещ = 	(2),
    Гук =	(64),
    ГДескр =	(66),
	ГлобДДЕСовмест =	(8192),
	ГлобДискард =	(256),
	ГлобНижняя =	(4096),
	ГлобНесжим =	(16),
	ГлобНедискард =	(32),
	ГлобНеБанк =	(4096),
	ГлобУведоми	= (16384),
	ГлобСовмест =	(8192),
	ГлобНульИниц =	(64),
	ГлобДискардир =	(16384),
	ГлобНевернДескр =	(32768),
	ГлобСчётБлокировок =	(255),
//Лок
	Лук	= (64),
	ЛДескр	= (66),
	ЛДескрНеНуль	= (2),
	ЛукНеНуль	= (0),
	ЛокЛДескрНеНуль	= (2),
	ЛокЛукНеНуль	= (0),
	ЛокФиксир	= (0),
	ЛокПеремещ	= (2),
	ЛокНесжим	= (16),
	ЛокНедискард	= (32),
	ЛокНульИниц	= (64),
	ЛокИзмени	= (128),
	ЛокСчётБлокировок	= (255),
	ЛокДискард	= (3840),
	ЛокДискардир	= (16384),
	ЛокНевернДескр	= (32768),

//Вирт

//Куча
	КучГенИскл =	0x00000004,
	КучНеСериализ =	0x00000001,
	КучОбнулиПам	= 0x00000008,
	КучПереместТолькоНаМесте	= 0x00000010,
	КучВклВып = 0x00040000,
}

enum ПФлагСооб //PM_xxx
{
    НеУдалять =         0x0000,
    Удалить =           0x0001,
    НеБрать =          0x0002,
}

/*
 * Virtual Keys, Standard Set
 */
enum ПВиртКл //VK_xxx
{ 
    ЛевМыши =        0x01,
    ПравМыши =        0x02,
    Отмена =         0x03,
    СредМыши =        0x04, /* NOT contiguous with L & RBUTTON */

    Назад =           0x08,
    Таб =            0x09,

    Очистить =          0x0C,
    Возврат =         0x0D,
    Шифт =          0x10,
    Контрол =        0x11,
    Меню =           0x12,
    Пауза =          0x13,
    Заглавные =        0x14,
	Эскейп =         0x1B,
    Пробел =          0x20,
    Приор =          0x21,
    Следщ =           0x22,
    Конец =            0x23,
    Дом =           0x24,
    Влево =           0x25,
    Вверх =             0x26,
    Вправо =          0x27,
    Вниз =           0x28,
    Выделить =         0x29,
    Печать =          0x2A,
    Выполнить =        0x2B,
    Снэпшот =       0x2C,
    Вставить =         0x2D,
    Удалить =         0x2E,
    Помощь =           0x2F,

/* VK_0 thru VK_9 are the same as ASCII '0' thru '9' (0x30 - 0x39) */
/* VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' (0x41 - 0x5A) */

    ЛВин =           0x5B,
    ПВин =           0x5C,
    Аппс =           0x5D,

    Чис0 =        0x60,
    Чис1 =        0x61,
    Чис2 =        0x62,
    Чис3 =        0x63,
    Чис4 =        0x64,
    Чис5 =        0x65,
    Чис6 =        0x66,
    Чис7 =        0x67,
    Чис8 =        0x68,
    Чис9 =        0x69,
    Умножь =       0x6A,
    Прибавь =            0x6B,
    Разделитель =      0x6C,
    Отнять =       0x6D,
    Десяток =        0x6E,
    Делить =         0x6F,
    Ф1 =             0x70,
    Ф2 =             0x71,
    Ф3 =             0x72,
    Ф4 =             0x73,
    Ф5 =             0x74,
    Ф6 =             0x75,
    Ф7 =             0x76,
    Ф8 =             0x77,
    Ф9 =             0x78,
    Ф10 =            0x79,
    Ф11 =            0x7A,
    Ф12 =            0x7B,
    Ф13 =            0x7C,
    Ф14 =            0x7D,
    Ф15 =            0x7E,
    Ф16 =            0x7F,
    Ф17 =            0x80,
    Ф18 =            0x81,
    Ф19 =            0x82,
    Ф20 =            0x83,
    Ф21 =            0x84,
    Ф22 =            0x85,
    Ф23 =            0x86,
    Ф24 =            0x87,

    Нумлок =        0x90,
    Прокрут =         0x91,

/*
 * VK_L* & VK_R* - left and right Alt, Ctrl and Shift virtual keys.
 * Used only as parameters to GetAsyncKeyState() and GetKeyState().
 * No other API or сообщение will distinguish left and right keys in this way.
 */
    ЛШифт =         0xA0,
    ПШифт =         0xA1,
    ЛКонтрол =       0xA2,
    ПКонтрол =       0xA3,
    ЛМеню =          0xA4,
    ПМеню =          0xA5,
    ПроцессКей =     0xE5,
    Аттн =           0xF6,
    CRSEL =          0xF7,
    EXSEL =          0xF8,
    EREOF =          0xF9,
    Плей =           0xFA,
    Зум =           0xFB,
    НетИмени =         0xFC,
    PA1 =            0xFD,
    OEM_CLEAR =      0xFE,
}

/*
 * Scroll Bar Commands
 */
enum ППрокр
{ 
	СтрокВверх =           0,
	СтрокВлево =         0,
    СтрокВниз =         1,
	СтрокВправо =        1,
    СтрВверх =           2,
    СтрВлево =         2,
    СтрВниз =         3,
    СтрВправо =        3,
    SB_THUMBPOSITION =    4,
    SB_THUMBTRACK =       5,
    Вверх =              6,
    Влево =             6,
    Вниз =           7,
    Вправо =            7,
    SB_ENDSCROLL =        8,

   Гориз =             0,
   Верт =             1,
   Ктл =              2,
   Обе =             3,
}
/+
/* Stock Logical Objects */
enum
{   WHITE_BRUSH =         0,
    LTGRAY_BRUSH =        1,
    GRAY_BRUSH =          2,
    DKGRAY_BRUSH =        3,
    BLACK_BRUSH =         4,
    NULL_BRUSH =          5,
    HOLLOW_BRUSH =        NULL_BRUSH,
    WHITE_PEN =           6,
    BLACK_PEN =           7,
    NULL_PEN =            8,
    OEM_FIXED_FONT =      10,
    ANSI_FIXED_FONT =     11,
    ANSI_VAR_FONT =       12,
    SYSTEM_FONT =         13,
    DEVICE_DEFAULT_FONT = 14,
    DEFAULT_PALETTE =     15,
    SYSTEM_FIXED_FONT =   16,
    DEFAULT_GUI_FONT =    17,
    STOCK_LAST =          17,
}
+/
/*
 * ShowWindow() Commands
 */
enum ПВидОкна
{ 
    Скрыть =             0,
    ПоказатьНорм =       1,
    Норм =           1,
    ПоказатьСвёрнуто =    2,
    ПоказатьРазвёрнуто =    3,
    Развернуть =         3,
    ПоказатьНеактивно =   4,
    Показать =             5,
    Свернуть =         6,
    ПоказатьСвёрнНеактивно =  7,
    ПоказатьНА =           8,
    Восстановить =          9,
    ПоказатьДефолтно =      10,
    Макс =              10,
}

/*
 * Color Types
 */
enum ПЦветУпрЭлта
{
ОкСообУпр =         0,//CTLCOLOR_MSGBOX
ОкРедУпр =           1,//CTLCOLOR_EDIT
ОкСписокУпр =        2,//CTLCOLOR_LISTBOX
КнопкаУпр =            3,//CTLCOLOR_BTN
ДлгУпр =            4,//CTLCOLOR_DLG
ППрокрУпр =      5,//CTLCOLOR_SCROLLBAR
СтатикУпр =         6,//CTLCOLOR_STATIC
МаксУпр =            7,//CTLCOLOR_MAX

Ппрокр =         0,//
Фон =        1,//
АктивнЗаг =     2,
НеактивЗаг =   3,
Меню =              4,
Окно =            5,
ОкРамка =       6,
ТекстМеню =          7,
ТекстОкна =        8,
ТекстЗаг =       9,
АктивКайма =      10,
НеактивКайма =    11,
РабПрострПрил =      12,
Выделение =         13,
ВыделенТекст =     14,
КнопФас =           15,
КнопТень =         16,
СерыйТекст =          17,
КнопТекст =           18,
ТекстНеактивЗаг = 19,
ВыделенКноп =      20,

COLOR_3DDKSHADOW =        21,
Свет3М =           22,
Инфотекст =          23,
COLOR_INFOBK =            24,

РабСтол =       Фон,
/*COLOR_3DFACE =            COLOR_BTNFACE,
COLOR_3DSHADOW =          COLOR_BTNSHADOW,
COLOR_3DHIGHLIGHT =       COLOR_BTNHIGHLIGHT,
COLOR_3DHILIGHT =         COLOR_BTNHIGHLIGHT,
COLOR_BTNHILIGHT =        COLOR_BTNHIGHLIGHT,*/
}
/+
enum : цел
{
    CW_USEDEFAULT = cast(цел)0x80000000
}
+/
/*
 * Special value for CreateWindow, et al.
 */
 /*
const ук  HWND_DESKTOP = cast(ук)0;

const ткст0 IDI_APPLICATION =     cast(ткст0)(32512);

const ткст0 IDC_ARROW =           cast(ткст0)(32512);
const ткст0 IDC_CROSS =           cast(ткст0)(32515);

/*
 * Window Styles
 */
enum ПСтильОкна : бцел
{
    WS_OVERLAPPED =       0x00000000,
    WS_POPUP =            0x80000000,
    WS_CHILD =            0x40000000,
    WS_MINIMIZE =         0x20000000,
    WS_VISIBLE =          0x10000000,
    WS_DISABLED =         0x08000000,
    WS_CLIPSIBLINGS =     0x04000000,
    WS_CLIPCHILDREN =     0x02000000,
    WS_MAXIMIZE =         0x01000000,
    WS_CAPTION =          0x00C00000,  /* WS_BORDER | WS_DLGFRAME  */
    WS_BORDER =           0x00800000,
    WS_DLGFRAME =         0x00400000,
    WS_VSCROLL =          0x00200000,
    WS_HSCROLL =          0x00100000,
    WS_SYSMENU =          0x00080000,
    WS_THICKFRAME =       0x00040000,
    WS_GROUP =            0x00020000,
    WS_TABSTOP =          0x00010000,
    WS_MINIMIZEBOX =      0x00020000,
    WS_MAXIMIZEBOX =      0x00010000,
    WS_TILED =            WS_OVERLAPPED,
    WS_ICONIC =           WS_MINIMIZE,
    WS_SIZEBOX =          WS_THICKFRAME,
/*
 * Common Window Styles
 */
    WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED |            WS_CAPTION |  WS_SYSMENU |  WS_THICKFRAME |            WS_MINIMIZEBOX |                 WS_MAXIMIZEBOX),
    WS_TILEDWINDOW =      WS_OVERLAPPEDWINDOW,
    WS_POPUPWINDOW =      (WS_POPUP |  WS_BORDER |  WS_SYSMENU),
    WS_CHILDWINDOW =      (WS_CHILD),
}

/*
 * Стили класса CS_
 */
enum ПСтильКласса
{
    CS_VREDRAW =          0x0001,
    CS_HREDRAW =          0x0002,
    CS_KEYCVTWINDOW =     0x0004,
    CS_DBLCLKS =          0x0008,
    CS_OWNDC =            0x0020,
    CS_CLASSDC =          0x0040,
    CS_PARENTDC =         0x0080,
    CS_NOKEYCVT =         0x0100,
    CS_NOCLOSE =          0x0200,
    CS_SAVEBITS =         0x0800,
    CS_BYTEALIGNCLIENT =  0x1000,
    CS_BYTEALIGNWINDOW =  0x2000,
    CS_GLOBALCLASS =      0x4000,
    CS_IME =              0x00010000,
}

/* Опции Положения Текста */
enum ПРасположениеТекста
{
    НеОбновлятьКС =                0, //КС = кодовая страница
    ОбновлятьКС =                  1,
    Левое =                      0,
    Правое =                     2,
    Центр =                    6,
    Верх =                       0,
    Низ =                    8,
    Основание =                  24,
    ЧтениеПНЛ =                256, //ПНЛ = справа на лево
    Маска =       (Основание+Центр+ОбновлятьКС+ЧтениеПНЛ),
}
/+
enum
{
    OUT_DEFAULT_PRECIS =          0,
    OUT_STRING_PRECIS =           1,
    OUT_CHARACTER_PRECIS =        2,
    OUT_STROKE_PRECIS =           3,
    OUT_TT_PRECIS =               4,
    OUT_DEVICE_PRECIS =           5,
    OUT_RASTER_PRECIS =           6,
    OUT_TT_ONLY_PRECIS =          7,
    OUT_OUTLINE_PRECIS =          8,
    OUT_SCREEN_OUTLINE_PRECIS =   9,

    CLIP_DEFAULT_PRECIS =     0,
    CLIP_CHARACTER_PRECIS =   1,
    CLIP_STROKE_PRECIS =      2,
    CLIP_MASK =               0xf,
    CLIP_LH_ANGLES =          (1<<4),
    CLIP_TT_ALWAYS =          (2<<4),
    CLIP_EMBEDDED =           (8<<4),

    DEFAULT_QUALITY =         0,
    DRAFT_QUALITY =           1,
    PROOF_QUALITY =           2,

    NONANTIALIASED_QUALITY =  3,
    ANTIALIASED_QUALITY =     4,


    DEFAULT_PITCH =           0,
    FIXED_PITCH =             1,
    VARIABLE_PITCH =          2,

    MONO_FONT =               8,


    ANSI_CHARSET =            0,
    DEFAULT_CHARSET =         1,
    SYMBOL_CHARSET =          2,
    ШИФТJIS_CHARSET =        128,
    HANGEUL_CHARSET =         129,
    GB2312_CHARSET =          134,
    CHINESEBIG5_CHARSET =     136,
    OEM_CHARSET =             255,

    JOHAB_CHARSET =           130,
    HEBREW_CHARSET =          177,
    ARABIC_CHARSET =          178,
    GREEK_CHARSET =           161,
    TURKISH_CHARSET =         162,
    VIETNAMESE_CHARSET =      163,
    THAI_CHARSET =            222,
    EASTEUROPE_CHARSET =      238,
    RUSSIAN_CHARSET =         204,

    MAC_CHARSET =             77,
    BALTIC_CHARSET =          186,

    FS_LATIN1 =               0x00000001L,
    FS_LATIN2 =               0x00000002L,
    FS_CYRILLIC =             0x00000004L,
    FS_GREEK =                0x00000008L,
    FS_TURKISH =              0x00000010L,
    FS_HEBREW =               0x00000020L,
    FS_ARABIC =               0x00000040L,
    FS_BALTIC =               0x00000080L,
    FS_VIETNAMESE =           0x00000100L,
    FS_THAI =                 0x00010000L,
    FS_JISJAPAN =             0x00020000L,
    FS_CHINESESIMP =          0x00040000L,
    FS_WANSUNG =              0x00080000L,
    FS_CHINESETRAD =          0x00100000L,
    FS_JOHAB =                0x00200000L,
    FS_SYMBOL =               cast(цел)0x80000000L,


/* Font Families */
    FF_DONTCARE =         (0<<4), /* Don't care or don't know. */
    FF_ROMAN =            (1<<4), /* Variable stroke width, serifed. */
                                    /* Times Roman, Century Schoolbook, etc. */
    FF_SWISS =            (2<<4), /* Variable stroke width, sans-serifed. */
                                    /* Helvetica, Swiss, etc. */
    FF_MODERN =           (3<<4), /* Constant stroke width, serifed or sans-serifed. */
                                    /* Pica, Elite, Courier, etc. */
    FF_SCRIPT =           (4<<4), /* Cursive, etc. */
    FF_DECORATIVE =       (5<<4), /* Old English, etc. */

/* Font Weights */
    FW_DONTCARE =         0,
    FW_THIN =             100,
    FW_EXTRALIGHT =       200,
    FW_LIGHT =            300,
    FW_NORMAL =           400,
    FW_MEDIUM =           500,
    FW_SEMIBOLD =         600,
    FW_BOLD =             700,
    FW_EXTRABOLD =        800,
    FW_HEAVY =            900,

    FW_ULTRALIGHT =       FW_EXTRALIGHT,
    FW_REGULAR =          FW_NORMAL,
    FW_DEMIBOLD =         FW_SEMIBOLD,
    FW_ULTRABOLD =        FW_EXTRABOLD,
    FW_BLACK =            FW_HEAVY,

    PANOSE_COUNT =               10,
    PAN_FAMILYTYPE_INDEX =        0,
    PAN_SERIFSTYLE_INDEX =        1,
    PAN_WEIGHT_INDEX =            2,
    PAN_PROPORTION_INDEX =        3,
    PAN_CONTRAST_INDEX =          4,
    PAN_STROKEVARIATION_INDEX =   5,
    PAN_ARMSTYLE_INDEX =          6,
    PAN_LETTERFORM_INDEX =        7,
    PAN_MIDLINE_INDEX =           8,
    PAN_XHEIGHT_INDEX =           9,

    PAN_CULTURE_LATIN =           0,
}

enum
{
    RDW_INVALIDATE =          0x0001,
    RDW_INTERNALPAINT =       0x0002,
    RDW_ERASE =               0x0004,
    RDW_VALIDATE =            0x0008,
    RDW_NOINTERNALPAINT =     0x0010,
    RDW_NOERASE =             0x0020,
    RDW_NOCHILDREN =          0x0040,
    RDW_ALLCHILDREN =         0x0080,
    RDW_UPDATENOW =           0x0100,
    RDW_ERASENOW =            0x0200,
    RDW_FRAME =               0x0400,
    RDW_NOFRAME =             0x0800,
}

+/
enum
{
	ДЛЛ_ПРИКРЕПИ_ПРОЦЕСС	 = 1 ,
    ДЛЛ_ПРИКРЕПИ_НИТЬ 			= 2 ,
    ДЛЛ_ОТКРЕПИ_НИТЬ			 = 3,
    ДЛЛ_ОТКРЕПИ_ПРОЦЕСС			 = 0,
}

enum ПСооб
{
    Ок  =                       0x00000000,
    ОкОтмена =                 0x00000001,
    ПрервПовторИгнор =         0x00000002,
    ДаНетОтмена =              0x00000003,
    ДаНет =                    0x00000004,
    ПовторОтмена =              0x00000005,	
    Рука =                 0x00000010,
    Вопрос =             0x00000020,
    Восклиц =          0x00000030,
    Звезда =             0x00000040,	
    Юзер =                 0x00000080,
    Предупреждение =              Восклиц,
    Ошибка =                Рука,	
    Инфо =                 Звезда,
    Стоп =                Рука,	
    ДефКноп1 =               0x00000000,
    ДефКноп2 =               0x00000100,
    ДефКноп3 =               0x00000200,
	ДефКноп4 =               0x00000300,
    ПрилМодал =                0x00000000,
    СисМодал =              0x00001000,
    ЗадачМодал =                0x00002000,	
    Помощь =                     0x00004000, 	
    Нефок =                  0x00008000,
    УстПП =            0x00010000,
    РабСтол =     0x00020000,	
    Поверх =                  0x00040000,
    Правое =                    0x00080000,
    ЧтенСпрНаЛев =               0x00100000,
    МаскаТипа =                 0x0000000F,
    МаскаПикт =                 0x000000F0,
    ДефМаска =                  0x00000F00,
    РежМаска =                 0x00003000,
    РазнМаска =                 0x0000C000,	
}

enum ПФорматСооб: бцел
{
 	РазмБуф = 0x00000100,
    ИгнорВставки =  0x00000200,
    ИзТекста =     0x00000400,
    ИзМодДескра =    0x00000800,
    ИзСист =     0x00001000,
    МасАргов =  0x00002000,
    МаскаМаксШир =  0x000000FF,
}


enum ПЯзык
{
	НЕЙТРАЛЬНЫЙ                     = 0x00,
    АФРИКАНСКИЙ                  = 0x36,
    АЛБАНСКИЙ                    = 0x1c,
    АРАБСКИЙ                      = 0x01,
    БАССКИЙ                      = 0x2d,
    БЕЛАРУССКИЙ                  = 0x23,
    БОЛГАРСКИЙ                   = 0x02,
    КАТАЛАНСКИЙ                     = 0x03,
    КИТАЙСКИЙ                     = 0x04,
    ХОРВАТСКИЙ                    = 0x1a,
    ЧЕШСКИЙ                       = 0x05,
    ДАТСКИЙ                      = 0x06,
    ГОЛАНДСКИЙ                       = 0x13,
    АНГЛИЙСКИЙ                     = 0x09,
    ЭСТОНСКИЙ                    = 0x25,
    ФЕРУЗСКИЙ                    = 0x38,
    ФАРСИ                       = 0x29,
    ФИНСКИЙ                     = 0x0b,
    ФРАНЦУЗСКИЙ                      = 0x0c,
    НЕМЕЦКИЙ                      = 0x07,
    ГРЕЧЕСКИЙ                       = 0x08,
    ЕВРЕЙСКИЙ                      = 0x0d,
    ВЕНГЕРСКИЙ                   = 0x0e,
    ИСЛАНДСКИЙ                   = 0x0f,
    ИНДОНЕЗИЙСКИЙ                  = 0x21,
    ИТАЛЬЯНСКИЙ                     = 0x10,
    ЯПОНСКИЙ                    = 0x11,
    КОРЕЙСКИЙ                      = 0x12,
    ЛАТВИЙСКИЙ                    = 0x26,
    ЛИТОВСКИЙ                  = 0x27,
    НОРВЕЖСКИЙ                   = 0x14,
    ПОЛЬСКИЙ                      = 0x15,
    ПОРТУГАЛЬСКИЙ                  = 0x16,
    РУМЫНСКИЙ                    = 0x18,
    РУССКИЙ                     = 0x19,
    СЕРБСКИЙ                     = 0x1a,
    СЛОВАЦКИЙ                      = 0x1b,
    СЛОВЕНСКИЙ                   = 0x24,
    ИСПАНСКИЙ                     = 0x0a,
    ШВЕДСКИЙ                     = 0x1d,
    ТАИЛАНДСКИЙ                        = 0x1e,
    ТУРЕЦКИЙ                     = 0x1f,
    УКРАИНСКИЙ                   = 0x22,
    ВЬЕТНАМСКИЙ                  = 0x2a,
	
}

enum ППодъяз
{
    НЕЙТРАЛЬНЫЙ =                  0x00,    
    ДЕФОЛТ =                  0x01,    
    СИС_ДЕФОЛТ =              0x02,    

    АРАБСКИЙ_САУДОВСКАЯ_АРАВИЯ =      0x01,    
    АРАБСКИЙ_ИРАК =              0x02,    
    АРАБСКИЙ_ЕГИПТ =             0x03,    
    АРАБСКИЙ_ЛИВИЯ =             0x04,    
    АРАБСКИЙ_АЛЖИР =           0x05,    
    АРАБСКИЙ_МОРОККО =           0x06,    
    АРАБСКИЙ_ТУНИС =           0x07,    
    АРАБСКИЙ_ОМАН =              0x08,    
    АРАБСКИЙ_ЙЕМЕН =             0x09,    
    АРАБСКИЙ_СИРИЯ =             0x0a,    
    АРАБСКИЙ_ИОРДАНИЯ =            0x0b,    
    АРАБСКИЙ_ЛИВАН =           0x0c,    
    АРАБСКИЙ_КУВЕЙТ =            0x0d,    
    АРАБСКИЙ_ОАЭ =               0x0e,    
    АРАБСКИЙ_БАХРЕЙН =           0x0f,    
    АРАБСКИЙ_КАТАР =             0x10,    
    КИТАЙСКИЙ_ТРАДИЦИОННЫЙ =      0x01,    
    КИТАЙСКИЙ_УПРОЩЁННЫЙ =       0x02,    
    КИТАЙСКИЙ_ГОНГКОНГ =         0x03,    
    КИТАЙСКИЙ_СИНГАПУР =        0x04,    
    ГОЛАНДСКИЙ =                    0x01,    
    ГОЛАНДСКИЙ_БЕЛЬГИЙСКИЙ =            0x02,    
    АНГЛИЙСКИЙ_США =               0x01,    
    АНГЛИЙСКИЙ_ВЕЛИКОБРИТАНИЯ =               0x02,    
    АНГЛИЙСКИЙ_АВСТРАЛИЯ =              0x03,    
    АНГЛИЙСКИЙ_КАНАДА =              0x04,    
    АНГЛИЙСКИЙ_НЗЕЛАНДИЯ =               0x05,    
    АНГЛИЙСКИЙ_ИРЛАНДИЯ =             0x06,    
    АНГЛИЙСКИЙ_ЮАР =     0x07,    
    АНГЛИЙСКИЙ_ЯМАЙКА =          0x08,    
    АНГЛИЙСКИЙ_КАРИБЫ =        0x09,    
    АНГЛИЙСКИЙ_БЕЛИЗ =           0x0a,    
    АНГЛИЙСКИЙ_ТРИНИДАД =         0x0b,    
    ФРАНЦУЗСКИЙ =                   0x01,    
    ФРАНЦУЗСКИЙ_БЕЛЬГИЙСКИЙ =           0x02,    
    ФРАНЦУЗСКИЙ_КАНАДСКИЙ =          0x03,    
    ФРАНЦУЗСКИЙ_ШВЕЙЦАРСКИЙ =             0x04,    
    ФРАНЦУЗСКИЙ_ЛЮКСЕМБУРГ =        0x05,    
    НЕМЕЦКИЙ =                   0x01,    
    НЕМЕЦКИЙ_ШВЕЙЦАРСКИЙ =             0x02,    
    НЕМЕЦКИЙ_АВСТРИЙСКИЙ =          0x03,    
    НЕМЕЦКИЙ_ЛЮБСЕМБУРГ =        0x04,    
    НЕМЕЦКИЙ_ЛИХТЕНШТЕЙН =     0x05,    
    ИТАЛЬЯНСКИЙ =                  0x01,    
    ИТАЛЬЯНСКИЙ_ШВЕЙЦАРСКИЙ =            0x02,    
    КОРЕЙСКИЙ =                   0x01,    
    КОРЕЙСКИЙ_ЙОХАБ =             0x02,    
    НОРВЕЖСКИЙ_БОКМАЛ =         0x01,    
    НОРВЕЖСКИЙ_НИНОРСКИЙ =        0x02,    
    ПОРТУГАЛЬСКИЙ =               0x02,    
    ПОРТУГАЛЬСКИЙ_БРАЗИЛЬСКИЙ =     0x01,    
    СЕРБСКИЙ_ЛАТЫНЬ =            0x02,    
    СЕРБСКИЙ_КИРИЛИЦА =         0x03,    
    ИСПАНСКИЙ =                  0x01,    
    ИСПАНСКИЙ_МЕКСИКАНСКИЙ =          0x02,    
    ИСПАНСКИЙ_СОВРЕМЕННЫЙ =           0x03,    
    ИСПАНСКИЙ_ГВАТЕМАЛА =        0x04,    
    ИСПАНСКИЙ_КОСТА_РИКА =       0x05,    
    ИСПАНСКИЙ_ПАНАМА =           0x06,    
    ИСПАНСКИЙ_ДОМИНИКАНСКИЙ = 0x07,  
    ИСПАНСКИЙ_ВЕНЕСУЭЛА =        0x08,    
    ИСПАНСКИЙ_КОЛУМБИЯ =         0x09,    
    ИСПАНСКИЙ_ПЕРУ =             0x0a,    
    ИСПАНСКИЙ_АРГЕНТИНА =        0x0b,    
    ИСПАНСКИЙ_ЭКВАДОР =          0x0c,    
    ИСПАНСКИЙ_ЧИЛИ =            0x0d,    
    ИСПАНСКИЙ_УРУГВАЙ =          0x0e,    
    ИСПАНСКИЙ_ПАРАГВАЙ =         0x0f,    
    ИСПАНСКИЙ_БОЛИВИЯ =          0x10,    
    ИСПАНСКИЙ_САЛЬВАДОР =      0x11,    
    ИСПАНСКИЙ_ГОНДУРАС =         0x12,    
    ИСПАНСКИЙ_НИКАРАГУА =        0x13,    
    ИСПАНСКИЙ_ПУЭРТО_РИКО =      0x14,    
    ШВЕДСКИЙ =                  0x01,    
    ШВЕДСКИЙ_ФИНЛЯНДИЯ =          0x02,    
}

enum ПКодСтр
{
Установленная	= (1),
Поддерживаемая	= (2),
Анзи =	(0),
Макинтош	= (2),
ОЕМ	= (1),
ВинАнзи = 1004,
ВинЮникод = 1200,
УТФ8 = 65001,
}

enum
{
 	РАЗМЕР_РЕГИСТРОВ_80387 =      80,
}

enum ПОкСооб
{
    Уведоми =                       0x004E,
    ЗапросСменыЯзыкаВвода =       0x0050,
    СменаЯзыкаВвода =              0x0051,
    ТКарта =                        0x0052,
    Помощь =                         0x0053,
    ПользовательИзменён =                  0x0054,
    УведомиФормат =                 0x0055,
    ЗНШ_АНЗИ =                             1,//Запрос Нового Шрифта
    ЗНШ_ЮНИКОД =                          2,
    ЗапросНШ =                             3,
    ПерезапросНШ =                           4,
    КонтекстноеМеню =                  0x007B,
    ИзменениеСтиля =                0x007C,
    СтильИзменён =                 0x007D,
    ИзменитьВид =                0x007E,
    ДайПикт =                      0x007F,
    УстановиПикт =                      0x0080,
    СоздатьНК =                     0x0081,
    УдалитьНК =                    0x0082,
    РассчитатьРазмерНК =                   0x0083,
    ХитТестНК =                    0x0084,
    РисоватьНК =                      0x0085,
    АктивироватьНК =                   0x0086,
    ДатьКолДлг =                   0x0087,
    ДвижениеМышиНК =                  0x00A0,
    КнопкаВнизуНК =                0x00A1,
    КнопкаВверхуНК =                  0x00A2,
    ДвукликКнопкойНК =              0x00A3,
    ПравКнопкаВнизуНК =                0x00A4,
    ПравКнопкаВверхуНК =                  0x00A5,
    ДвукликПравКнопкойНК =              0x00A6,
    СрКнопкаВнизуНК =                0x00A7,
    СрКнопкаВверхуНК =                  0x00A8,
    ДвукликСрКнопкойНК =              0x00A9,
    ПерваяКлавиша =                     0x0100,
    КлавишаВнизу =                      0x0100,
    КлавишаВверху =                        0x0101,
    Симв =                         0x0102,
    ДедСимв =                     0x0103,
    СисКлавишаВнизу =                   0x0104,
    СисКлавишаВверху =                     0x0105,
    СисСимв =                      0x0106,
    СисДедСимв =                  0x0107,
    ПоследняяКлавиша =                      0x0108,
    НачалоКомпозицииИМЕ =         0x010D,
    КонецКомпозицииИМЕ =           0x010E,
    КомпозицияИМЕ =              0x010F,
    ПоследняяКлавишаИМЕ =                  0x010F,
    ИницДиалог =                   0x0110,
    Команда =                      0x0111,
    СисКоманда =                   0x0112,
    Таймер =                        0x0113,
    ГПрокрутка =                      0x0114,
    ВПрокрутка =                      0x0115,
    ИницМеню =                     0x0116,
    ИницВсплМеню =                0x0117,
    ВыборМеню =                   0x011F,
    СимвМеню =                     0x0120,
    ВходВХолостой =                    0x0121,
    CTLCOLORMSGBOX =               0x0132,
    CTLCOLOREDIT =                 0x0133,
    CTLCOLORLISTBOX =              0x0134,
    CTLCOLORBTN =                  0x0135,
    CTLCOLORDLG =                  0x0136,
    CTLCOLORSCROLLBAR =            0x0137,
    CTLCOLORSTATIC =               0x0138,	
    ПерваяМыши =                   0x0200,
    МышьДвиг =                    0x0200,
    ЛКнопкаВнизу =                  0x0201,
    ЛКнопкаВверху =                    0x0202,
    ЛКнопкаДвуклик =                0x0203,
    ПКнопкаВнизу =                  0x0204,
    ПКнопкаВверху =                    0x0205,
    ПКнопкаДвуклик =                0x0206,
    СКнопкаВнизу =                  0x0207,
    СКнопкаВверху =                    0x0208,
    СКнопкаДвуклик =                0x0209,
    ПоследняяМыши =                    0x0209,
    УведомлениеРодителя =                 0x0210,
    ЦиклМенюОкна =                 0,
    ЦиклМенюВсплыв =                  1,
    ВходВЦиклМеню =                0x0211,
    ВыходИзЦиклаМеню =                 0x0212,	
    СледщМеню =                     0x0213,	
	Пусто =                         0x0000,
    Создать =                       0x0001,
    Разрушить =                      0x0002,
    Переместить =                         0x0003,
    Размер =                         0x0005,
    Активировать =                     0x0006,	
	Сфокусировать =                     0x0007,
    Расфокусировать =                    0x0008,
    Включить =                       0x000A,
    УстановитьПерерисовку =                    0x000B,
    УстановитьТекст =                      0x000C,
    ДатьТекст =                      0x000D,
    ДатьДлинуТекста =                0x000E,
    Изобразить =                        0x000F,
    Закрыть =                        0x0010,
    ЗапросЗавершенияСессии =              0x0011,
    Выйти =                         0x0012,
    ЗапросОткрыть =                    0x0013,
    СтеретьФон =                   0x0014,
    ИзменитьСисЦвет =               0x0015,
    ЗавершитьСессию =                   0x0016,
    ПоказатьОкно =                   0x0018,
    ИзменитьВинИни =                 0x001A,
    ИзменитьНастройки =                ИзменитьВинИни,
    ИзменениеРежДев =                0x001B,
    АктивироватьПрилож =                  0x001C,
    ИзменениеШрифта =                   0x001D,
    ИзменениеВремени =                   0x001E,
    РежимОтмены =                   0x001F,
    УстановитьКурсор =                    0x0020,
    МышьАктивировать =                0x0021,
    ОтпрыскАктивировать =                0x0022,
    ОчередьСинх =                    0x0023,
    ДатьМинМаксИнфо =                0x0024,
}
/+
enum
{
    WA_INACTIVE =     0,
    WA_ACTIVE =       1,
    WA_CLICKACTIVE =  2,
}

enum
{
    ИДОК =                1,
    ИДОТМЕНА =            2,
    ИДАБОРТ =             3,
    ИДПОВТОР =             4,
    ИДИГНОР =            5,
    ИДДА =               6,
    ИДНЕТ =                7,

    ИДЗАКРЫТЬ =         8,
    ИДПОМОЩЬ =          9,



/*
 * Стили Элемента Управления Edit
 */
    СР_ЛЕВ =             0x0000,
    СР_ЦЕНТР =           0x0001,
    СР_ПРАВ =            0x0002,
    СР_МНОГОСТРОК =        0x0004,
    СР_ЗАГ =        0x0008,
    СР_ПРОП =        0x0010,
    СР_ПАРОЛЬ =         0x0020,
    СР_АВТОВПРОМОТ =      0x0040,
    СР_АВТОГПРОМОТ =      0x0080,
    СР_НЕПРЯТАТЬВЫД =        0x0100,
    СР_ПРЕОБРОЕМ =       0x0400,
    СР_ТОЛЬКОЧТЕН =         0x0800,
    СР_ТРЕБВОЗВР =       0x1000,

    СР_ЧИСЛО =           0x2000,



/*
 * Коды Уведомлений Элемента Управления Edit
 */
    УР_УСТФОК =         0x0100,
    УР_УБРАТЬФОК =        0x0200,
    УР_ИЗМЕНИТЬ =           0x0300,
    УР_ОБНОВИТЬ =           0x0400,
    УР_ОШПРОСТРВО =         0x0500,
    УР_МАКСТЕКСТ =          0x0501,
    УР_ГПРОМОТ =          0x0601,
    УР_ВПРОМОТ =          0x0602,


/* Edit control EM_SETMARGIN parameters */
    КР_ЛЕВПОЛЕ =       0x0001,
    КР_ПРАВПОЛЕ =      0x0002,
    КР_ИСПИНФОШРИФТЕ =      0xffff,




// begin_r_winuser

/*
 * Edit Control Messages
 */
    РС_ДАЙВЫБ =               0x00B0,
    РС_УСТВЫБ =               0x00B1,
    РС_ДАЙПРЯМ =              0x00B2,
    РС_УСТПРЯМ =              0x00B3,
    РС_УСТПРЯМNP =            0x00B4,
    РС_ПРКРУТ =               0x00B5,
    РС_ПРОКРУТСТРОК =           0x00B6,
    РС_КАРЕТКАПРОКР =          0x00B7,
    РС_ДАЙИЗМ =            0x00B8,
    РС_УСТИЗМ =            0x00B9,
    РС_ДАЙСЧЁТСТРОК =         0x00BA,
    РС_ИНДЕКССТР =            0x00BB,
    РС_УСТХЭНДЛ =            0x00BC,
    РС_ДАЙХЭНДЛ =            0x00BD,
    РС_GETTHUMB =             0x00BE,
    РС_ДЛИНАСТР =           0x00C1,
    РС_ЗАМЕНИВЫБ =           0x00C2,
    РС_ДАЙСТР =              0x00C4,
    РС_LIMITTEXT =            0x00C5,
    РС_CANUNDO =              0x00C6,
    РС_UNDO =                 0x00C7,
    РС_FMTLINES =             0x00C8,
    РС_LINEFROMCHAR =         0x00C9,
    РС_SETTABSTOPS =          0x00CB,
    РС_SETPASSWORDCHAR =      0x00CC,
    РС_EMPTYUNDOBUFFER =      0x00CD,
    РС_GETFIRSTVISIBLELINE =  0x00CE,
    РС_SETREADONLY =          0x00CF,
    РС_SETWORDBREAKPROC =     0x00D0,
    РС_GETWORDBREAKPROC =     0x00D1,
    РС_GETPASSWORDCHAR =      0x00D2,

    РС_SETMARGINS =           0x00D3,
    РС_GETMARGINS =           0x00D4,
    РС_SETLIMITTEXT =         РС_LIMITTEXT, /* ;win40 Name change */
    РС_GETLIMITTEXT =         0x00D5,
    РС_POSFROMCHAR =          0x00D6,
    РС_CHARFROMPOS =          0x00D7,



// end_r_winuser


/*
 * EDITWORDBREAKPROC код values
 */
    WB_LEFT =            0,
    WB_RIGHT =           1,
    WB_ISDELIMITER =     2,

// begin_r_winuser

/*
 * Button Control Styles
 */
    СК_PUSHBUTTON =       0x00000000,
    СК_DEFPUSHBUTTON =    0x00000001,
    СК_CHECKBOX =         0x00000002,
    СК_AUTOCHECKBOX =     0x00000003,
    СК_RADIOBUTTON =      0x00000004,
    СК_3STATE =           0x00000005,
    СК_AUTO3STATE =       0x00000006,
    СК_GROUPBOX =         0x00000007,
    СК_USERBUTTON =       0x00000008,
    СК_AUTORADIOBUTTON =  0x00000009,
    СК_OWNERDRAW =        0x0000000B,
    СК_LEFTTEXT =         0x00000020,

    СК_TEXT =             0x00000000,
    СК_ICON =             0x00000040,
    СК_BITMAP =           0x00000080,
    СК_LEFT =             0x00000100,
    СК_RIGHT =            0x00000200,
    СК_CENTER =           0x00000300,
    СК_TOP =              0x00000400,
    СК_BOTTOM =           0x00000800,
    СК_VCENTER =          0x00000C00,
    СК_PUSHLIKE =         0x00001000,
    СК_MULTILINE =        0x00002000,
    СК_NOTIFY =           0x00004000,
    СК_FLAT =             0x00008000,
    СК_RIGHTBUTTON =      СК_LEFTTEXT,



/*
 * Пользователь Button Notification Codes
 */
    УК_CLICKED =          0,
    УК_PAINT =            1,
    УК_HILITE =           2,
    УК_UNHILITE =         3,
    УК_DISABLE =          4,
    УК_DOUBLECLICKED =    5,

    УК_PUSHED =           УК_HILITE,
    УК_UNPUSHED =         УК_UNHILITE,
    УК_DBLCLK =           УК_DOUBLECLICKED,
    УК_SETFOCUS =         6,
    УК_KILLFOCUS =        7,

/*
 * Button Control Messages
 */
    КСО_GETCHECK =        0x00F0,
    КСО_SETCHECK =        0x00F1,
    КСО_GETSTATE =        0x00F2,
    КСО_SETSTATE =        0x00F3,
    КСО_SETSTYLE =        0x00F4,

    КСО_CLICK =           0x00F5,
    КСО_GETIMAGE =        0x00F6,
    КСО_SETIMAGE =        0x00F7,

    BST_UNCHECKED =      0x0000,
    BST_CHECKED =        0x0001,
    BST_INDETERMINATE =  0x0002,
    BST_PUSHED =         0x0004,
    BST_FOCUS =          0x0008,


/*
 * Static Control Constants
 */
    SS_LEFT =             0x00000000,
    SS_CENTER =           0x00000001,
    SS_RIGHT =            0x00000002,
    SS_ICON =             0x00000003,
    SS_BLACKRECT =        0x00000004,
    SS_GRAYRECT =         0x00000005,
    SS_WHITERECT =        0x00000006,
    SS_BLACKFRAME =       0x00000007,
    SS_GRAYFRAME =        0x00000008,
    SS_WHITEFRAME =       0x00000009,
    SS_USERITEM =         0x0000000A,
    SS_SIMPLE =           0x0000000B,
    SS_LEFTNOWORDWRAP =   0x0000000C,

    SS_OWNERDRAW =        0x0000000D,
    SS_BITMAP =           0x0000000E,
    SS_ENHMETAFILE =      0x0000000F,
    SS_ETCHEDHORZ =       0x00000010,
    SS_ETCHEDVERT =       0x00000011,
    SS_ETCHEDFRAME =      0x00000012,
    SS_TYPEMASK =         0x0000001F,

    SS_NOPREFIX =         0x00000080, /* Don't do "&" character translation */

    SS_NOTIFY =           0x00000100,
    SS_CENTERIMAGE =      0x00000200,
    SS_RIGHTJUST =        0x00000400,
    SS_REALSIZEIMAGE =    0x00000800,
    SS_SUNKEN =           0x00001000,
    SS_ENDELLIPSIS =      0x00004000,
    SS_PATHELLIPSIS =     0x00008000,
    SS_WORDELLIPSIS =     0x0000C000,
    SS_ELLIPSISMASK =     0x0000C000,


// end_r_winuser


/*
 * Static Control Mesages
 */
    STM_SETICON =         0x0170,
    STM_GETICON =         0x0171,

    STM_SETIMAGE =        0x0172,
    STM_GETIMAGE =        0x0173,
    STN_CLICKED =         0,
    STN_DBLCLK =          1,
    STN_ENABLE =          2,
    STN_DISABLE =         3,

    STM_MSGMAX =          0x0174,
	
}
+/
enum ПФлагСоздПроц: бцел
{
БезЗадачи = 0x01000000,
ВДефолтнРежимеОшибки =0x04000000,
СНовойКонсолью = 0x00000010,
ВНовойГруппе = 0x00000200,
БезОкнаКонсоли = 0x08000000,
СохраняяУровеньАвторизации = 0x02000000,
СОтдельнойДОСВМ = 0x00000800,
Заморозь = 0x00000004,
СЮникодСредой = 0x00000400,
ВРежимеОтладки = 0x00000002,
ВПолнРежимеОтладки = 0x00000001,
Открепи = 0x00000008
}

enum ПКонтекстВып : бцел {
  СерверВнутриПроцесса  = 0x1,  
  ОбработчикВнутриПроцесса = 0x2, 
  МестныйСервер      = 0x4,  
  УдалённыйСервер     = 0x10,
  Все              = СерверВнутриПроцесса | ОбработчикВнутриПроцесса | МестныйСервер | УдалённыйСервер
}

enum ППолитикаИсключений
 {
  НеВыводить = 0,
  Выводить = 1
}


enum ПДиспачФлаг : бкрат {
  ВызватьМетод   = 0x1,  
  ДатьСвойство    = 0x2,
  УстановитьСвойство    = 0x4, 
  УстановитьСсылСвойство = 0x8  
}

enum {
  SEVERITY_SUCCESS = 0,
  SEVERITY_ERROR = 1
}

enum ПСредство : бцел {
  Нет             = 0,
  УВП              = 1,
  Диспетч         = 2,
  Хранилище          = 3,
  ITF              = 4,
  Вин32            = 7,
  Виндовс          = 8,
  SSPI             = 9,
  Безопасность         = 9,
  УпрЭлт         = 10,
  Серт            = 11,
  Интернет         = 12,
  МедиаСервер      = 13,
  MSMQ             = 14,
  SETUPAPI         = 15,
  SCARD            = 16,
  КомПлюс          = 17,
  AAF              = 18,
  URT              = 19,
  ACS              = 20,
  Дисплей            = 21,
  UMI              = 22,
  SXS              = 23,
  ВиндовсКВ       = 24,
  HTTP             = 25,
  ТеневаяКопия   = 32,
  Конфигурация    = 33,
  УправлениеСостоянием = 34,
  Метапапка    = 35,
  ОбновлениеОС    = 36,
  СлужбаКаталогов = 37
}

enum : short {
  ДА_ВАРИАНТ = -1, ///  Представляет булево значение _true (-1).
  НЕТ_ВАРИАНТ = 0  /// Представляет булево значение _false (0).
}
typedef short БУЛ_ВАРИАНТ;

enum : БУЛ_ВАРИАНТ {
  ком_да = ДА_ВАРИАНТ,
  ком_нет = НЕТ_ВАРИАНТ
}
alias БУЛ_ВАРИАНТ ком_бул;

enum ПВар: бкрат {
  БезСвойстваЗнач        = 0x1,
  АльфаБул          = 0x2,
  БезПользоватПерезап     = 0x4,
  КалендарьХиджри     = 0x8,
  МестныйБул          = 0x10,
  КалендарьТаи      = 0x20,
  Грегорианский = 0x40,
  ИспользоватьНлс            = 0x80
}

enum : бцел {
  CLSCTX_INPROC_SERVER    = 0x1,
  CLSCTX_INPROC_HANDLER   = 0x2,
  CLSCTX_LOCAL_SERVER     = 0x4,
  CLSCTX_INPROC_SERVER16  = 0x8,
  CLSCTX_REMOTE_SERVER    = 0x10,
  CLSCTX_INPROC_HANDLER16 = 0x20,
  CLSCTX_INPROC           = CLSCTX_INPROC_SERVER | CLSCTX_INPROC_HANDLER,
  CLSCTX_SERVER           = CLSCTX_INPROC_SERVER | CLSCTX_LOCAL_SERVER | CLSCTX_REMOTE_SERVER,
  CLSCTX_ALL              = CLSCTX_INPROC_SERVER | CLSCTX_INPROC_HANDLER | CLSCTX_LOCAL_SERVER | CLSCTX_REMOTE_SERVER
}

enum 
{
  CLASS_E_NOAGGREGATION     = 0x80040110,
  CLASS_E_CLASSNOTAVAILABLE = 0x80040111
}

enum {
  SELFREG_E_FIRST   = ДелайСКод!(SEVERITY_ERROR, ПСредство.ITF, 0x0200),
  SELFREG_E_LAST    = ДелайСКод!(SEVERITY_ERROR, ПСредство.ITF, 0x020F),
  SELFREG_S_FIRST   = ДелайСКод!(SEVERITY_SUCCESS, ПСредство.ITF, 0x0200),
  SELFREG_S_LAST    = ДелайСКод!(SEVERITY_SUCCESS, ПСредство.ITF, 0x020F),
  SELFREG_E_TYPELIB = SELFREG_E_FIRST,
  SELFREG_E_CLASS   = SELFREG_E_FIRST + 1
}

enum : бцел {
  STGTY_STORAGE = 1,
  STGTY_STREAM = 2,
  STGTY_LOCKBYTES = 3,
  STGTY_PROPERTY = 4
}


enum : бцел {
  STATFLAG_DEFAULT,
  STATFLAG_NONAME,
  STATFLAG_NOOPEN
}

enum : бцел 
{
  STGM_DIRECT           = 0x00000000,
  STGM_TRANSACTED       = 0x00010000,
  STGM_SIMPLE           = 0x08000000,
  STGM_READ             = 0x00000000,
  STGM_WRITE            = 0x00000001,
  STGM_READWRITE        = 0x00000002,
  STGM_SHARE_DENY_NONE  = 0x00000040,
  STGM_SHARE_DENY_READ  = 0x00000030,
  STGM_SHARE_DENY_WRITE = 0x00000020,
  STGM_SHARE_EXCLUSIVE  = 0x00000010,
  STGM_CREATE           = 0x00001000,
  STGM_PRIORITY         = 0x00040000,
  STGM_CONVERT			= 0x00020000,
  STGM_FAILIFTHERE		= 0x00000000,
  STGM_NOSCRATCH        = 0x00100000,
  STGM_NOSNAPSHOT		= 0x00200000,
  STGM_DELETEONRELEASE  = 0x04000000,
  STGM_DIRECT_SWMR		= 0x00400000  
}

enum : бцел
 {
  STGFMT_STORAGE = 0,
  STGFMT_FILE = 3,
  STGFMT_ANY = 4,
  STGFMT_DOCFILE = 5
}

enum : бцел {
  BIND_MAYBOTHERUSER = 1,
  BIND_JUSTTESTEXISTENCE = 2
}

enum ПАспектЦУ : бцел //DVASPERT
 {
  Контент = 1,
  Пальчик = 2,
  Пикт = 4,
  Докпринт = 8
}

enum ТИМЕД : бцел //TYMED
{
  NULL = 0,
  HGLOBAL = 1,
  FILE = 2,
  ISTREAM = 4,
  ISTORAGE = 8,
  GDI = 16,
  MFPICT = 32,
  ENHMF = 64
}

enum {
//DV_E_****
  ОШ_УСТР_FORMATETC = 0x80040064,
  ОШ_УСТР_DVTARGETDEVICE = 0x80040065,
  ОШ_УСТР_STGMEDIUM = 0x80040066,
  ОШ_УСТР_СТАТДАННЫЕ = 0x80040067,
  ОШ_УСТР_LINDEX = 0x80040068,
  ОШ_УСТР_TYMED = 0x80040069,
  ОШ_УСТР_CLIPFORMAT = 0x8004006A,
  ОШ_УСТР_АСПЕКТЦУ = 0x8004006B
}

enum ПДрэгДроп{
  Дроп = 0x00040100,
  Отмена = 0x00040101,
  ИспользоватьДефКусоры = 0x00040102
}

enum ПДропЭффект: бцел {
  Нет = 0,
  Копия = 1,
  Перенос = 2,
  Связь = 4,
  Промот = 0x80000000
}

enum  ПОшДрэгДроп{
  НеЗарегистрирован = 0x80040100,
  УжеЗарегистрирован = 0x80040101,
  НевернУкНаОк = 0x80040102
}

enum ПДиспетч: бкрат {
  Метод         = 0x1,
  ДайСвойство    = 0x2,
  ПоместиСвойство    = 0x4,
  ПоместиСвойствоССыл = 0x8
}

enum ПИдДисп {
  Неизвестно     = -1,
  Значение       = 0,
  ПоместиСвойство = -3,
  НовПеречень     = -4,
  Оценщик    = -5,
  Конструктор = -6,
  Деструктор  = -7,
  Коллектор     = -8
}

enum ПОшДисп{
  НеизвестныйИнтерфейс = 0x80020001,
  ЧленНеНайден   = 0x80020003,
  ПарамНеНайден    = 0x80020004,
  ТипНеСовпадает    = 0x80020005,
  НеизвестноеИмя      = 0x80020006,
  НетИменованыхАргов      = 0x80020007,
  НевернТипВар       = 0x80020008,
  Исключение        = 0x80020009,
  НевернЧлоПарамов    = 0x8002000E
}

enum ПВидТипа {
  Перечень,
  Запись,
  Модуль,
  Интерфейс,
  Диспатч,
  Сокласс,
  Алиас,
  Юнион
}


enum ПФлагПарам: бкрат {
  Нет = 0x0,
  Вход = 0x1,
  Выход = 0x2,
  Лцид = 0x4,
  Возврзнач = 0x8,
  Опц = 0x10,
  ЕстьДефолт = 0x20,
  УстьКустДанные = 0x40
}

enum ПКонвВызова {
  Фастколл,
  Сидекл,
  Мспаскаль,
  Паскаль = Мспаскаль,
  Макпаскаль,
  Стдколл,
  ФПфастколл,
  Сиколл,
  Мпвсидекл,
  Мпвпаскаль
}

enum ПВидФунк {
  Вирт,
  ЧистоВирт,
  НеВирт,
  Статич,
  Диспетч
}

enum ПВидВызова {//INVOKEKIND :
  Функ = 1,	//INVOKE_FUNC
  СвойствоПолучить = 2,//INVOKE_PROPERTYGET
  СвойствоЗаписать = 4,//INVOKE_PROPERTYPUT
  ВызовСвойствПоместСсыл = 8//INVOKE_PROPERTYPUTREF
}

enum ПВидПерем {
  Персистентная,
  Статическая,
  Константа,
  Диспатч
}

enum ПФлагТипаРеал: бкрат {
  Дефолт = 0x1,
  Исток = 0x2,
  Ограниченная = 0x4,
  ДефВиртТаб = 0x8
}

enum ПФлагТипа : бкрат {
  ОбъПриложение = 0x1,
  МожетСоздать = 0x2,
  Лицензирован = 0x4,
  ПреддеклИд = 0x8,
  Скрыт = 0x10,
  УпрЭлт = 0x20,
  Дуал = 0x40,
  Нерасш = 0x80,
  ОлеАвт = 0x100,
  Ограничен = 0x200,
  Агрегируем = 0x400,
  Заменим = 0x800,
  Диспетчируем = 0x1000,
  РеверсБайнд = 0x2000,
  Прокси = 0x4000
}

enum ПФлагФунк : бкрат {
  Ограниченная = 0x1,
  Исток = 0x2,
  Привязываемая = 0x4,
  ТребИт = 0x8,
  ДисплПрив = 0x10,
  ДефПрив = 0x20,
  Скрытая = 0x40,
  ИспДайПоследнОш = 0x80,
  ДефКолЭлем = 0x100,
  ЮИДефолт = 0x200,
  НеПросматриваемая = 0x400,
  Заменяемая = 0x800,
  НепосредствПривяз = 0x1000
}

enum ПФлагиПерем : бкрат {
  ТолькоЧтен = 0x1,
  Исток = 0x2,
  Привязываемая = 0x4,
  ТребИт = 0x8,
  ДисплПрив = 0x10,
  ДефПрив = 0x20,
  Скрытая = 0x40,
  Ограниченная = 0x80,
  ДефКолЭлем = 0x100,
  ЮИДефолт = 0x200,
  НеПросматриваемая = 0x400,
  Заменяемая = 0x800,
  НепосредствПривяз = 0x1000
}

enum ПВидДескр {
  Нет,
  Функ,
  Перем,
  ТипКомп,
  КосвОбПрил
}

enum ПВидСистемы {
  Вин16,
  Вин32,
  Мак,
  Вин64
}

enum /* LIBFLAGS */ : бкрат {
  LIBFLAG_FRESTRICTED = 0x1,
  LIBFLAG_FCONTROL = 0x2,
  LIBFLAG_FHIDDEN = 0x4,
  LIBFLAG_FHASDISKIMAGE = 0x8
}

enum ПВидРег//REGKIND 
{
  Дефолт,
  Реестр,
  Нет
}

enum ПВидИзм//
 {
  ДобЧлен,
  УдЧлен,
  УстИмена,
  УстДок,
  Общ,
  Инвалидир,
  ИзмНеуд,
  Макс
}

enum ПОшТипа
{
  ЭлементНеНайден      = 0x8002802B
}

enum ПТипРис
{
  Неинициирован = -1,
  Нет = 0,
  Битмап = 1,
  Метафайл = 2,
  Иконка = 3,
  РасшМетафайл = 4
}


enum ПАктивнОбъ: бцел
 {
  Сильный,
  Слабый
}

enum : бцел 
{
  MSHLFLAGS_NORMAL = 0x0,
  MSHLFLAGS_TABLESTRONG = 0x1,
  MSHLFLAGS_TABLEWEAK = 0x2,
  MSHLFLAGS_NOPING = 0x4
}

enum : бцел 
{
  MSHCTX_LOCAL,
  MSHCTX_NOSHAREDMEM,
  MSHCTX_DIFFERENTMACHINE,
  MSHCTX_INPROC,
  MSHCTX_CROSSCTX
}

enum ПСравнСтр: цел
 {
	ПервСтрМеньше    = 1,
	СтрРавны,
	ПервСтрБольше
}

enum ПСравнВремФла: цел
 {
	ПервРаньше    = -1,
	Равны = 0,
	ПервПозже = 1
}

enum ПФлагиНормСорт: бцел
{
	ИгнорироватьРегистр     =       1,
	ИгнорироватьНепробельные =       2,
	ИгнорироватьСимолы  =       4,
	ПунктуацияКакСимволы     = 0x01000,
	ИгнорироватьКатана = 0x1,
	ИгнорироватьШирину = (131072),
}

enum ПСтатПродолжОтладки: бцел
{
	Продолжить              = 0x00010002,
	ПрерватьНить      = 0x40010003,
	ПрерватьПроцесс     = 0x40010004,
	КонтрольСи             = 0x40010005,
	КонтрольБрейк         = 0x40010008,
	ИсклНеОбрабатываемое = 0x80010001
}

enum ПЛокаль: ЛКИД {
	ПользовательскийДефолт   = 0x400,
	СистДефолт = 0x800
}

enum ПСлотПочты: бцел //функц СоздайСлотПочты ->таймаутЧтен
{
    ЖдатьВсегда = cast(бцел)-1,
    БезОтправки = cast(бцел)-1,
}

enum ТИП_ПОМЕТКИ_РЕСУРСА_ПАМЯТИ
{
НизкоПамРесурс = 0,
ВысокоПамРесурс = 1
}
alias ТИП_ПОМЕТКИ_РЕСУРСА_ПАМЯТИ ТПРП;

enum ПТейп: бцел
{
 ФиксированныеОтделы = (0),
 ИнициаторОтделов = (0x2),
 ВыбратьОтделы = (0x1),
 Файлметки = (0x1),
 ДлинныеФайлметки = (0x3),
 Устметки = (0),
 КороткиеФайлметки = (0x2),
 АбсолютноеПоложение = (0),
 ЛогическоеПоложение = (1),
 ПсевдоЛогическоеПоложение =(2),
	Перемотать =(0),
	АбсолютныйБлок =(1),
	ЛогическийБлок =(2),
	ПсевдологическийБлок = (3),
	//Пространство
	КонецДанных =(4),
	ОтносительныеБлоки =(5),
	ПространствоФайлметки =(6),
	ПоследовательныеФмки =(7),
	ПространствоУстметки =(8),
	ПоследовательныеУстметки =(9),
	//Драйв
	Фмксирован            = 0x00000001,
	Выбор           = 0x00000002,
	Инициатор        = 0x00000004,
	СтеретьКратко      = 0x00000010,
	СтеретьДлинно       = 0x00000020,
	СтеретьТолькоБоп   = 0x00000040,
	СтеретьНемедля  = 0x00000080,
	Ёмкость    = 0x00000100,
	Остаток   = 0x00000200,
	ФиксированныеБлоки      = 0x00000400,
	ПеременныеБлоки   = 0x00000800,
	ЗащитаЗаписи    = 0x00001000,
	DRIVE_EOT_WZ_SIZE      = 0x00002000,
	DRIVE_ECC              = 0x00010000,
	Сжатие      = 0x00020000,
	DRIVE_PADDING          = 0x00040000,
	DRIVE_REPORT_SMKS      = 0x00080000,
	DRIVE_GET_ABSOLUTE_BLK = 0x00100000,
	DRIVE_GET_LOGICAL_BLK  = 0x00200000,
	DRIVE_SET_EOT_WZ_SIZE  = 0x00400000,
	ВынутьНоситель      = 0x01000000,
	DRIVE_CLEAN_REQUESTS   = 0x02000000,
	DRIVE_SET_CMP_BOP_ONLY = 0x04000000,
	DRIVE_RESERVED_BIT     = 0x80000000,
	ЗагрузитьВыгрузить      = 0x80000001,
	DRIVE_TENSION          = 0x80000002,
	БлокироватьРазблокировать      = 0x80000004,
	DRIVE_REWIND_IMMEDIATE = 0x80000008,
	УстановитьРазмерБлока   = 0x80000010,
	DRIVE_LOAD_UNLD_IMMED  = 0x80000020,
	DRIVE_TENSION_IMMED    = 0x80000040,
	DRIVE_LOCK_UNLK_IMMED  = 0x80000080,
	DRIVE_SET_ECC          = 0x80000100,
	DRIVE_SET_COMPRESSION  = 0x80000200,
	DRIVE_SET_PADDING      = 0x80000400,
	DRIVE_SET_REPORT_SMKS  = 0x80000800,
	DRIVE_ABSOLUTE_BLK     = 0x80001000,
	DRIVE_ABS_BLK_IMMED    = 0x80002000,
	DRIVE_LOGICAL_BLK      = 0x80004000,
	DRIVE_LOG_BLK_IMMED    = 0x80008000,
	DRIVE_END_OF_DATA      = 0x80010000,
	DRIVE_RELATIVE_BLKS    = 0x80020000,
	DRIVE_FILEMARKS        = 0x80040000,
	DRIVE_SEQUENTIAL_FMKS  = 0x80080000,
	DRIVE_SETMARKS         = 0x80100000,
	DRIVE_SEQUENTIAL_SMKS  = 0x80200000,
	DRIVE_REVERSE_POSITION = 0x80400000,
	DRIVE_SPACE_IMMEDIATE  = 0x80800000,
	DRIVE_WRITE_SETMARKS   = 0x81000000,
	DRIVE_WRITE_FILEMARKS  = 0x82000000,
	DRIVE_WRITE_SHORT_FMKS = 0x84000000,
	DRIVE_WRITE_LONG_FMKS  = 0x88000000,
	DRIVE_WRITE_MARK_IMMED = 0x90000000,
	DRIVE_FORMAT           = 0xA0000000,
	DRIVE_FORMAT_IMMEDIATE = 0xC0000000,
	DRIVE_HIGH_FEATURES    = 0x80000000,
	ERASE_SHORT =(0),
	ERASE_LONG =(1),
	LOAD =(0),
	UNLOAD =(1),
	TENSION =(2),
	LOCK =(3),
	UNLOCK =(4),
	FORMAT =(5)
}

enum  ПТаймер: бцел
{
	ВыполнитьДефолт            = 0x00000000,
	ВыполнитьВНитиВВ         = 0x00000001,
	ВыполнитьВОжидающейНити       = 0x00000004,
	ВыполнитьРаз           = 0x00000008,
	ВыполнитьДолгФункцию       = 0x00000010,
	ВыполнитьВНитиТаймера      = 0x00000020,
	ВыполнитьВПерсистентнойНити = 0x00000080,
	ПередатьИмперсонацию    = 0x00000100
	}
	
enum ПТулхэлп32: бцел {
	СникокСпискаКучи = 0x1,
	СнимокПроцесса  = 0x2,
	СнимокНити   = 0x4,
	СнимокМодуля   = 0x8,
	СнимокВсего      = (СникокСпискаКучи|СнимокПроцесса|СнимокНити|СнимокМодуля),
	Наследовать      = 0x80000000
}


enum  ППайп: бцел {

// СоздатьИменованныйПайп()
//Режим пайпа
	РежКлиентСервер  = 1,
	РежСерверКлиент = 2,
	РежДуплекс   = 3,
	ОдинЭкземпляр = cast(бцел) ПФайл.ПервыйПайпЭкземпляр,
	ПередатьВсё = cast(бцел) ПФайл.ПереписатьЧерез,
	РежАсинх = cast(бцел) ПФайл.Асинхронно,
	ЗаписьДСКД = cast(бцел) ППраваДоступа.ЗаписьДСКД,
	ЗаписьВладельца =cast(бцел) ППраваДоступа.ЗаписьВладельца,
	СистБезопасность = cast(бцел) ППраваДоступа.СистБезопДоступа,
	
//Тип пайпа
	ТипБайт        = 0,
	ТипСооб     = 4,
	РежЧтенБайт    = 0,
	РежЧтенСооб = 2,
	Ждать             = 0,
	НеЖдать           = 1,

// ПолучитьИнфОбИменованномПайпе()
	КрайКлиента  = 0,
	КрайСервера  = 1,

  НеограниченныхЭкземпляров = 255//константа
}

enum ПАктКткс: бцел
{
// ДеактивируйАктКткс()
	СтандартнаяДеактивация = 0,
	ПринудительнаяРанняяДеактивация = 1
}

enum ПДосУстройство: бцел
{
	// ОпределиУстройствоДос()
		СыройЦелевойПуть       = 1,
		УдалитьОпределение     = 2,
		ТочноеСовпаденииИмениПриУдалении = 4
}