module dmd.TFLAGS;

enum TFLAGS
{
	TFLAGSintegral	= 1,
	TFLAGSfloating	= 2,
	TFLAGSunsigned	= 4,
	TFLAGSreal		= 8,
	TFLAGSimaginary = 0x10,
	TFLAGScomplex	= 0x20,
}