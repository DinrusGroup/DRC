module dmd.Complex;

struct Complex(T)
{
	T re;
	T im;
	
	public static const Complex zero = Complex(0, 0);
}