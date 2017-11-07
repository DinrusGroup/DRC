module dmd.backend.REG;

enum REG
{
	AX = 0,
	CX = 1,
	DX = 2,
	BX = 3,
	SP = 4,
	BP = 5,
	SI = 6,
	DI = 7,
	ES = 9,
	PSW = 10,
	STACK = 11,	// top of stack
	MEM = 12,	// memory
	OTHER = 13,	// other things
	ST0 = 14,	// 8087 top of stack register
	ST01 = 15,	// top two 8087 registers; for complex types

	NOREG = 100,	// no register
}