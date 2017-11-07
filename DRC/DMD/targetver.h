#pragma once

// Включение SDKDDKVer.h обеспечивает определение самой последней доступной платформы Windows.

// Если требуется выполнить сборку приложения для предыдущей версии Windows, включите WinSDKVer.h и
// задайте для макроса _WIN32_WINNT значение поддерживаемой платформы перед включением SDKDDKVer.h.

#define MARS 1
//#define _WINDLL 1
#define TX86 1
//#define __I86__  1
#define __VK__ 1
#define _X86_ 1
#define _WIN32 1
#define _M_I86 1
#define _M_IX86 1
#define RC_INVOKED 1

#if _MSC_VER
#include <SDKDDKVer.h>
	#define WIN32_LEAN_AND_MEAN 1
	#define _CRT_SECURE_NO_WARNINGS 1
#endif