module dmd.backend.mTYman;

enum mTYman {
	mTYman_c = 1,	// C mangling
	mTYman_cpp = 2,	// C++ mangling
	mTYman_pas = 3,	// Pascal mangling
	mTYman_for = 4,	// FORTRAN mangling
	mTYman_sys = 5,	// _syscall mangling
	mTYman_std = 6,	// _stdcall mangling
	mTYman_d = 7,	// D mangling
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(mTYman));