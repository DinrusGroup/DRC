#include <llvm/PassRegistry.h>
#include <llvm/PassInfo.h>
#include <llvm/PassSupport.h>

using namespace llvm;

extern "C" {
#include "Header.h"

//////////class PassRefistry
    ///
    LLEXPORT ЛЛРеестрПроходок LLPassRegistry_ctor()
    {
        return (ЛЛРеестрПроходок) new PassRegistry();
    }

    LLEXPORT void LLPassRegistry_dtor(ЛЛРеестрПроходок self)
    {
        if (self != NULL) delete self;
    }

    /// getPassRegistry - Access the global registry object, which is
    /// automatically initialized at application launch and destroyed by
    /// llvm_shutdown.
    LLEXPORT ЛЛРеестрПроходок LLPassRegistry_getPassRegistry(ЛЛРеестрПроходок self)
    {
		return (ЛЛРеестрПроходок) unwrap(self)->getPassRegistry();
	}

    /// getPassInfo - Look up a pass' corresponding PassInfo, indexed by the pass'
    /// type identifier (&MyPass::ID).
    LLEXPORT const PassInfo* LLPassRegistry_getPassInfo(ЛЛРеестрПроходок self, const void* TI)
    {
        return unwrap(self)->getPassInfo(TI);
    }

    /// getPassInfo - Look up a pass' corresponding PassInfo, indexed by the pass'
/// argument string.
    LLEXPORT const PassInfo* LLPassRegistry_getPassInfo2(ЛЛРеестрПроходок self, StringRef Arg) {
        return unwrap(self)->getPassInfo(Arg);
    }

    /// registerPass - Register a pass (by means of its PassInfo) with the
    /// registry.  Required in order to use the pass with a PassManager.
    LLEXPORT  void LLPassRegistry_registerPass(ЛЛРеестрПроходок self, const PassInfo& PI, bool ShouldFree = false)
    {
        unwrap(self)->registerPass(PI, ShouldFree);
    }

    /// registerAnalysisGroup - Register an analysis group (or a pass implementing
    // an analysis group) with the registry.  Like registerPass, this is required
    // in order for a PassManager to be able to use this group/pass.
    LLEXPORT void LLPassRegistry_registerAnalysisGroup(ЛЛРеестрПроходок self,
        const void* InterfaceID, const void* PassID, 
        PassInfo& Registeree, bool isDefault, bool ShouldFree = false)
    {
		unwrap(self)->registerAnalysisGroup(InterfaceID, PassID, Registeree, isDefault, ShouldFree);
	}

    /// enumerateWith - Enumerate the registered passes, calling the provided
    /// PassRegistrationListener's passEnumerate() callback on each of them.
    LLEXPORT void LLPassRegistry_enumerateWith(ЛЛРеестрПроходок self, void* L)
    {
		unwrap(self)->enumerateWith((PassRegistrationListener *) L);
	}

    /// addRegistrationListener - Register the given PassRegistrationListener
    /// to receive passRegistered() callbacks whenever a new pass is registered.
    LLEXPORT void LLPassRegistry_addRegistrationListener(ЛЛРеестрПроходок self, void* L)
    {
		unwrap(self)->addRegistrationListener((PassRegistrationListener*)L);
	}

    /// removeRegistrationListener - Unregister a PassRegistrationListener so that
    /// it no longer receives passRegistered() callbacks.
    LLEXPORT void LLPassRegistry_removeRegistrationListener(ЛЛРеестрПроходок self, PassRegistrationListener* L)
    {
		unwrap(self)->removeRegistrationListener(L);
	}
/////////// end 0f class PassRefistry
}