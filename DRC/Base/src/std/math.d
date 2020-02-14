﻿// Написано на языке программирования Динрус. Разработчик Виталий Кулич.


module std.math;

//debug=math;           // uncomment to turn on debugging эхо's

private import cidrus, exception;
private import std.string;

private import std.traits;

version(GNU){
    // GDC can't actually do inline asm.
} else version(D_InlineAsm_X86) {
    version = Naked_D_InlineAsm_X86;
} else version(LDC) {    
    import ldc.intrinsics;
    version(X86)
    {
        version = LDC_X86;
    }
}

version(DigitalMars){
    version=INLINE_YL2X;	// x87 has opcodes for these
}

private:
/*
 * The following IEEE 'real' formats are currently supported:
 * 64 bit Big-endian  'double' (eg PowerPC)
 * 128 bit Big-endian 'quadruple' (eg SPARC)
 * 64 bit Little-endian 'double' (eg x86-SSE2)
 * 80 bit Little-endian, with implied bit 'real80' (eg x87, Itanium).
 * 128 bit Little-endian 'quadruple' (not implemented on any known processor!)
 *
 * Non-IEEE 128 bit Big-endian 'doubledouble' (eg PowerPC) has partial support
 */
version(LittleEndian) {
    static assert(real.mant_dig == 53 || real.mant_dig==64
               || real.mant_dig == 113,
      "Only 64-bit, 80-bit, and 128-bit reals"
      " are supported for LittleEndian CPUs");
} else {
    static assert(real.mant_dig == 53 || real.mant_dig==106
               || real.mant_dig == 113,
    "Only 64-bit and 128-bit reals are supported for BigEndian CPUs."
    " double-double reals have partial support");
}

// Constants used for extracting the components of the representation.
// They supplement the built-in floating point properties.
template floatTraits(T) {
 // EXPMASK is a ushort маска to select the exponent portion (without sign)
 // POW2MANTDIG = pow(2, real.mant_dig) is the value such that
 //  (smallest_denormal)*POW2MANTDIG == real.min
 // EXPPOS_SHORT is the index of the exponent when represented as a ushort array.
 // SIGNPOS_BYTE is the index of the sign when represented as a ubyte array.
 static if (T.mant_dig == 24) { // float
    const ushort EXPMASK = 0x7F80;
    const ushort EXPBIAS = 0x3F00;
    const uint EXPMASK_INT = 0x7F80_0000;
    const uint MANTISSAMASK_INT = 0x007F_FFFF;
    const real POW2MANTDIG = 0x1p+24;
    version(LittleEndian) {
      const EXPPOS_SHORT = 1;
    } else {
      const EXPPOS_SHORT = 0;
    }
 } else static if (T.mant_dig == 53) { // double, or real==double
    const ushort EXPMASK = 0x7FF0;
    const ushort EXPBIAS = 0x3FE0;
    const uint EXPMASK_INT = 0x7FF0_0000;
    const uint MANTISSAMASK_INT = 0x000F_FFFF; // for the MSB only
    const real POW2MANTDIG = 0x1p+53;
    version(LittleEndian) {
      const EXPPOS_SHORT = 3;
      const SIGNPOS_BYTE = 7;
    } else {
      const EXPPOS_SHORT = 0;
      const SIGNPOS_BYTE = 0;
    }
 } else static if (T.mant_dig == 64) { // real80
    const ushort EXPMASK = 0x7FFF;
    const ushort EXPBIAS = 0x3FFE;
    const real POW2MANTDIG = 0x1p+63;
    version(LittleEndian) {
      const EXPPOS_SHORT = 4;
      const SIGNPOS_BYTE = 9;
    } else {
      const EXPPOS_SHORT = 0;
      const SIGNPOS_BYTE = 0;
    }
 } else static if (real.mant_dig == 113){ // quadruple
    const ushort EXPMASK = 0x7FFF;
    const real POW2MANTDIG = 0x1p+113;
    version(LittleEndian) {
      const EXPPOS_SHORT = 7;
      const SIGNPOS_BYTE = 15;
    } else {
      const EXPPOS_SHORT = 0;
      const SIGNPOS_BYTE = 0;
    }
 } else static if (real.mant_dig == 106) { // doubledouble
    const ushort EXPMASK = 0x7FF0;
    const real POW2MANTDIG = 0x1p+53;  // doubledouble denormals are strange
    // and the exponent byte is not unique
    version(LittleEndian) {
      const EXPPOS_SHORT = 7; // [3] is also an exp short
      const SIGNPOS_BYTE = 15;
    } else {
      const EXPPOS_SHORT = 0; // [4] is also an exp short
      const SIGNPOS_BYTE = 0;
    }
 }
}

// These apply to all floating-point types
version(LittleEndian) {
    const MANTISSA_LSB = 0;
    const MANTISSA_MSB = 1;
} else {
    const MANTISSA_LSB = 1;
    const MANTISSA_MSB = 0;
}
public:


const real E =          2.7182818284590452354L;  /** e */ // 3.32193 fldl2t 0x1.5BF0A8B1_45769535_5FF5p+1L
const real LOG2T =      0x1.a934f0979a3715fcp+1; /** $(SUB log, 2)10 */ // 1.4427 fldl2e
const real LOG2E =      0x1.71547652b82fe178p+0; /** $(SUB log, 2)e */ // 0.30103 fldlg2
const real LOG2 =       0x1.34413509f79fef32p-2; /** $(SUB log, 10)2 */
const real LOG10E =     0.43429448190325182765;  /** $(SUB log, 10)e */
const real LN2 =        0x1.62e42fefa39ef358p-1; /** ln 2 */  // 0.693147 fldln2
const real LN10 =       2.30258509299404568402;  /** ln 10 */
const real PI =         0x1.921fb54442d1846ap+1; /** $(_PI) */ // 3.14159 fldpi
const real PI_2 =       1.57079632679489661923;  /** $(PI) / 2 */
const real PI_4 =       0.78539816339744830962;  /** $(PI) / 4 */
const real M_1_PI =     0.31830988618379067154;  /** 1 / $(PI) */
const real M_2_PI =     0.63661977236758134308;  /** 2 / $(PI) */
const real M_2_SQRTPI = 1.12837916709551257390;  /** 2 / $(SQRT)$(PI) */
const real SQRT2 =      1.41421356237309504880;  /** $(SQRT)2 */
const real SQRT1_2 =    0.70710678118654752440;  /** $(SQRT)$(HALF) */

/*
        Octal versions:
        PI/64800        0.00001 45530 36176 77347 02143 15351 61441 26767
        PI/180          0.01073 72152 11224 72344 25603 54276 63351 22056
        PI/8            0.31103 75524 21026 43021 51423 06305 05600 67016
        SQRT(1/PI)      0.44067 27240 41233 33210 65616 51051 77327 77303
        2/PI            0.50574 60333 44710 40522 47741 16537 21752 32335
        PI/4            0.62207 73250 42055 06043 23046 14612 13401 56034
        SQRT(2/PI)      0.63041 05147 52066 24106 41762 63612 00272 56161

        PI              3.11037 55242 10264 30215 14230 63050 56006 70163
        LOG2            0.23210 11520 47674 77674 61076 11263 26013 37111
 */

alias abs абс;
alias conj конъюнк;
alias cos кос;
alias sin син;
alias tan тан;
alias acos арккос;
alias asin арксин;
alias atan арктан;
alias atan2 арктан2;
alias cosh гипкос;
alias sinh гипсин;
alias tanh гиптан;
alias acosh гакос;
alias asinh гасин;
alias atanh гатан;
alias rndtol окрвдол;
alias rndtonl окрвближдол;
alias sqrt квкор;
alias exp эксп;
alias expm1 экспмин1;
alias exp2 эксп2;
alias expi экспи;
alias frexp плавэксп;
alias log лог;
alias log10 лог10;
alias cbrt кубкор;
alias fabs плавабс;
alias hypot гипот;
alias ceil окркбол;
alias floor окркмен;
alias nearbyint кближцел;
alias rint оркцел;
alias lrint орпкцел;
alias round окр;
alias lround докр;
alias trunc отсекиц;
alias remainder остаток;
alias isnan нч_ли;
alias isfinite конечн_ли;
alias isnormal норм_ли;
alias issubnormal субнорм_ли;
alias isinf беск_ли;
alias isIdentical идентичн_ли;
alias signbit старшбит;
alias nan нч;
alias nextUp следкБол;
alias nextDown следкМен;
alias nextafter следпосле;
alias pow степень;
alias poly полином;

/***********************************
 * Calculates the absolute value
 *
 * For complex numbers, abs(z) = sqrt( $(POWER z.re, 2) + $(POWER z.im, 2) )
 * = hypot(z.re, z.im).
 */
real abs(real x)
{
    return fabs(x);
}

/** ditto */
long abs(long x)
{
    return x>=0 ? x : -x;
}

/** ditto */
int abs(int x)
{
    return x>=0 ? x : -x;
}

/** ditto */
real abs(creal z)
{
    return hypot(z.re, z.im);
}

/** ditto */
real abs(ireal y)
{
    return fabs(y.im);
}

unittest
{
    assert(isIdentical(abs(-0.0L), 0.0L));
    assert(isnan(abs(real.nan)));
    assert(abs(-real.infinity) == real.infinity);
    assert(abs(-3.2Li) == 3.2L);
    assert(abs(71.6Li) == 71.6L);
    assert(abs(-56) == 56);
    assert(abs(2321312L)  == 2321312L);
    assert(abs(-1+1i) == sqrt(2.0));
}

/***********************************
 * Complex conjugate
 *
 *  conj(x + iy) = x - iy
 *
 * Note that z * conj(z) = $(POWER z.re, 2) - $(POWER z.im, 2)
 * is always a real number
 */
creal conj(creal z)
{
    return z.re - z.im*1i;
}

/** ditto */
ireal conj(ireal y)
{
    return -y;
}

unittest
{
    assert(conj(7 + 3i) == 7-3i);
    ireal z = -3.2Li;
    assert(conj(z) == -z);
}

/***********************************
 * Returns cosine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH cos(x)) $(TH invalid?))
 *      $(TR $(TD $(NAN))            $(TD $(NAN)) $(TD yes)     )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(NAN)) $(TD yes)     )
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

real cos(real x);       /* intrinsic */

/***********************************
 * Returns sine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)               $(TH sin(x))      $(TH invalid?))
 *      $(TR $(TD $(NAN))          $(TD $(NAN))      $(TD yes))
 *      $(TR $(TD $(PLUSMN)0.0)    $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(PLUSMNINF))    $(TD $(NAN))      $(TD yes))
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

real sin(real x);       /* intrinsic */


/***********************************
 *  sine, complex and imaginary
 *
 *  sin(z) = sin(z.re)*cosh(z.im) + cos(z.re)*sinh(z.im)i
 *
 * If both sin(&theta;) and cos(&theta;) are required,
 * it is most efficient to use expi(&theta;).
 */
creal sin(creal z)
{
  creal cs = expi(z.re);
  return cs.im * cosh(z.im) + cs.re * sinh(z.im) * 1i;
}

/** ditto */
ireal sin(ireal y)
{
  return cosh(y.im)*1i;
}

unittest
{
  assert(sin(0.0+0.0i) == 0.0);
  assert(sin(2.0+0.0i) == sin(2.0L) );
}

/***********************************
 *  cosine, complex and imaginary
 *
 *  cos(z) = cos(z.re)*cosh(z.im) - sin(z.re)*sinh(z.im)i
 */
creal cos(creal z)
{
  creal cs = expi(z.re);
  return cs.re * cosh(z.im) - cs.im * sinh(z.im) * 1i;
}

/** ditto */
real cos(ireal y)
{
  return cosh(y.im);
}

unittest{
  assert(cos(0.0+0.0i)==1.0);
  assert(cos(1.3L+0.0i)==cos(1.3L));
  assert(cos(5.2Li)== cosh(5.2L));
}

/****************************************************************************
 * Returns tangent of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)             $(TH tan(x))       $(TH invalid?))
 *      $(TR $(TD $(NAN))        $(TD $(NAN))       $(TD yes))
 *      $(TR $(TD $(PLUSMN)0.0)  $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(PLUSMNINF))  $(TD $(NAN))       $(TD yes))
 *      )
 */

real tan(real x)
{
    version(Naked_D_InlineAsm_X86) {
    asm
    {
        fld     x[EBP]                  ; // load theta
        fxam                            ; // test for oddball values
        fstsw   AX                      ;
        sahf                            ;
        jc      trigerr                 ; // x is NAN, infinity, or empty
                                          // 387's can handle denormals
SC18:   fptan                           ;
        fstp    ST(0)                   ; // dump X, which is always 1
        fstsw   AX                      ;
        sahf                            ;
        jnp     Lret                    ; // C2 = 1 (x is out of range)

        // Do argument reduction to bring x into range
        fldpi                           ;
        fxch                            ;
SC17:   fprem1                          ;
        fstsw   AX                      ;
        sahf                            ;
        jp      SC17                    ;
        fstp    ST(1)                   ; // remove pi from stack
        jmp     SC18                    ;

trigerr:
        jnp     Lret                    ; // if theta is NAN, return theta
        fstp    ST(0)                   ; // dump theta
    }
    return real.nan;

Lret:
    ;    
    } else {
        return cidrus.танд(x);
    }
}

unittest
{
    static real vals[][2] =     // angle,tan
    [
            [   0,   0],
            [   .5,  .5463024898],
            [   1,   1.557407725],
            [   1.5, 14.10141995],
            [   2,  -2.185039863],
            [   2.5,-.7470222972],
            [   3,  -.1425465431],
            [   3.5, .3745856402],
            [   4,   1.157821282],
            [   4.5, 4.637332055],
            [   5,  -3.380515006],
            [   5.5,-.9955840522],
            [   6,  -.2910061914],
            [   6.5, .2202772003],
            [   10,  .6483608275],

            // special angles
            [   PI_4,   1],
            //[ PI_2,   real.infinity],
            [   3*PI_4, -1],
            [   PI,     0],
            [   5*PI_4, 1],
            //[ 3*PI_2, -real.infinity],
            [   7*PI_4, -1],
            [   2*PI,   0],

            // overflow
            [   real.infinity,  real.nan],
            [   real.nan,       real.nan],
            //[   1e+100,       real.nan],
    ];
    int i;

    for (i = 0; i < vals.length; i++)
    {
        real x = vals[i][0];
        real r = vals[i][1];
        real t = tan(x);

        //эхо("tan(%Lg) = %Lg, should be %Lg\n", x, t, r);
        assert(mfeq(r, t, .0000001));

        x = -x;
        r = -r;
        t = tan(x);
        //эхо("tan(%Lg) = %Lg, should be %Lg\n", x, t, r);
        assert(mfeq(r, t, .0000001));
    }
}

/***************
 * Calculates the arc cosine of x,
 * returning a value ranging from 0 to $(PI).
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)         $(TH acos(x)) $(TH invalid?))
 *      $(TR $(TD $(GT)1.0)  $(TD $(NAN))  $(TD yes))
 *      $(TR $(TD $(LT)-1.0) $(TD $(NAN))  $(TD yes))
 *      $(TR $(TD $(NAN))    $(TD $(NAN))  $(TD yes))
 *  )
 */
real acos(real x)               { return cidrus.акосд(x); }

/***************
 * Calculates the arc sine of x,
 * returning a value ranging from -$(PI)/2 to $(PI)/2.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)            $(TH asin(x))      $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0) $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(GT)1.0)     $(TD $(NAN))       $(TD yes))
 *      $(TR $(TD $(LT)-1.0)    $(TD $(NAN))       $(TD yes))
 *  )
 */
real asin(real x)               { return cidrus.асинд(x); }

/***************
 * Calculates the arc tangent of x,
 * returning a value ranging from -$(PI)/2 to $(PI)/2.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH atan(x))      $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(NAN))       $(TD yes))
 *  )
 */
real atan(real x)               { return cidrus.атанд(x); }

/***************
 * Calculates the arc tangent of y / x,
 * returning a value ranging from -$(PI) to $(PI).
 *
 *      $(TABLE_SV
 *      $(TR $(TH y)                 $(TH x)            $(TH atan(y, x)))
 *      $(TR $(TD $(NAN))            $(TD anything)     $(TD $(NAN)) )
 *      $(TR $(TD anything)          $(TD $(NAN))       $(TD $(NAN)) )
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(GT)0.0)     $(TD $(PLUSMN)0.0) )
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD +0.0)         $(TD $(PLUSMN)0.0) )
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(LT)0.0)     $(TD $(PLUSMN)$(PI)))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD -0.0)         $(TD $(PLUSMN)$(PI)))
 *      $(TR $(TD $(GT)0.0)          $(TD $(PLUSMN)0.0) $(TD $(PI)/2) )
 *      $(TR $(TD $(LT)0.0)          $(TD $(PLUSMN)0.0) $(TD -$(PI)/2) )
 *      $(TR $(TD $(GT)0.0)          $(TD $(INFIN))     $(TD $(PLUSMN)0.0) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD anything)     $(TD $(PLUSMN)$(PI)/2))
 *      $(TR $(TD $(GT)0.0)          $(TD -$(INFIN))    $(TD $(PLUSMN)$(PI)) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(INFIN))     $(TD $(PLUSMN)$(PI)/4))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD -$(INFIN))    $(TD $(PLUSMN)3$(PI)/4))
 *      )
 */
real atan2(real y, real x)      { return cidrus.атан2д(y,x); }

/***********************************
 * Calculates the hyperbolic cosine of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH cosh(x))      $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(PLUSMN)0.0) $(TD no) )
 *      )
 */
real cosh(real x)               {
    //  cosh = (exp(x)+exp(-x))/2.
    // The naive implementation works correctly. 
    real y = exp(x);
    return (y + 1.0/y) * 0.5;
}

/***********************************
 * Calculates the hyperbolic sine of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH sinh(x))           $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0)      $(TD no))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(PLUSMN)$(INFIN)) $(TD no))
 *      )
 */
real sinh(real x)
{
    //  sinh(x) =  (exp(x)-exp(-x))/2;    
    // Very large arguments could cause an overflow, but
    // the maximum value of x for which exp(x) + exp(-x)) != exp(x)
    // is x = 0.5 * (real.mant_dig) * LN2. // = 22.1807 for real80.
    if (fabs(x) > real.mant_dig * LN2) {
        return copysign(0.5 * exp(fabs(x)), x);
    }    
    real y = expm1(x);
    return 0.5 * y / (y+1) * (y+2);
}

/***********************************
 * Calculates the hyperbolic tangent of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH tanh(x))      $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0) $(TD no) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(PLUSMN)1.0) $(TD no))
 *      )
 */
real tanh(real x)
{
    //  tanh(x) = (exp(x) - exp(-x))/(exp(x)+exp(-x))
    if (fabs(x) > real.mant_dig * LN2) {
        return copysign(1, x);        
    }
    real y = expm1(2*x);
    return y / (y + 2);
}

/***********************************
 * Calculates the inverse hyperbolic cosine of x.
 *
 *  Mathematically, acosh(x) = log(x + sqrt( x*x - 1))
 *
 * $(TABLE_DOMRG
 *  $(DOMAIN 1..$(INFIN))
 *  $(RANGE  1..log(real.max), $(INFIN)) )
 *      $(TABLE_SV
 *    $(SVH  x,     acosh(x) )
 *    $(SV  $(NAN), $(NAN) )
 *    $(SV  <1,     $(NAN) )
 *    $(SV  1,      0       )
 *    $(SV  +$(INFIN),+$(INFIN))
 *  )
 */
real acosh(real x)
{
    if (x > 1/real.epsilon)
        return LN2 + log(x);
    else
        return log(x + sqrt(x*x - 1));
}

unittest
{
    assert(isnan(acosh(0.9)));
    assert(isnan(acosh(real.nan)));
    assert(acosh(1)==0.0);
    assert(acosh(real.infinity) == real.infinity);
}

/***********************************
 * Calculates the inverse hyperbolic sine of x.
 *
 *  Mathematically,
 *  ---------------
 *  asinh(x) =  log( x + sqrt( x*x + 1 )) // if x >= +0
 *  asinh(x) = -log(-x + sqrt( x*x + 1 )) // if x <= -0
 *  -------------
 *
 *    $(TABLE_SV
 *    $(SVH x,                asinh(x)       )
 *    $(SV  $(NAN),           $(NAN)         )
 *    $(SV  $(PLUSMN)0,       $(PLUSMN)0      )
 *    $(SV  $(PLUSMN)$(INFIN),$(PLUSMN)$(INFIN))
 *    )
 */
real asinh(real x)
{
    if (fabs(x) > 1 / real.epsilon) {   // beyond this point, x*x + 1 == x*x
            return copysign(LN2 + log(fabs(x)), x);
    } else {
            // sqrt(x*x + 1) ==  1 + x * x / ( 1 + sqrt(x*x + 1) )
            return copysign(log1p(fabs(x) + x*x / (1 + sqrt(x*x + 1)) ), x);
    }
}

unittest
{
    assert(isIdentical(asinh(0.0), 0.0));
    assert(isIdentical(asinh(-0.0), -0.0));
    assert(asinh(real.infinity) == real.infinity);
    assert(asinh(-real.infinity) == -real.infinity);
    assert(isnan(asinh(real.nan)));
}

/***********************************
 * Calculates the inverse hyperbolic tangent of x,
 * returning a value from ranging from -1 to 1.
 *
 * Mathematically, atanh(x) = log( (1+x)/(1-x) ) / 2
 *
 *
 * $(TABLE_DOMRG
 *  $(DOMAIN -$(INFIN)..$(INFIN))
 *  $(RANGE  -1..1) )
 * $(TABLE_SV
 *    $(SVH  x,     acosh(x) )
 *    $(SV  $(NAN), $(NAN) )
 *    $(SV  $(PLUSMN)0, $(PLUSMN)0)
 *    $(SV  -$(INFIN), -0)
 * )
 */
real atanh(real x)
{
    // log( (1+x)/(1-x) ) == log ( 1 + (2*x)/(1-x) )
    return  0.5 * log1p( 2 * x / (1 - x) );
}

unittest
{
    assert(isIdentical(atanh(0.0), 0.0));
    assert(isIdentical(atanh(-0.0),-0.0));
    assert(isnan(atanh(real.nan)));
    assert(isnan(atanh(-real.infinity)));
}

/*****************************************
 * Returns x rounded to a long value using the current rounding mode.
 * If the integer value of x is
 * greater than long.max, the результат is
 * indeterminate.
 */
long rndtol(real x);    /* intrinsic */


/*****************************************
 * Returns x rounded to a long value using the FE_TONEAREST rounding mode.
 * If the integer value of x is
 * greater than long.max, the результат is
 * indeterminate.
 */
extern  (C) real rndtonl(real x);

/***************************************
 * Compute square root of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)         $(TH sqrt(x))   $(TH invalid?))
 *      $(TR $(TD -0.0)      $(TD -0.0)      $(TD no))
 *      $(TR $(TD $(LT)0.0)  $(TD $(NAN))    $(TD yes))
 *      $(TR $(TD +$(INFIN)) $(TD +$(INFIN)) $(TD no))
 *      )
 */

float sqrt(float x);    /* intrinsic */
double sqrt(double x);  /* intrinsic */ /// ditto
real sqrt(real x);      /* intrinsic */ /// ditto

creal sqrt(creal z)
{
    creal c;
    real x,y,w,r;

    if (z == 0)
    {
        c = 0 + 0i;
    }
    else
    {
        real z_re = z.re;
        real z_im = z.im;

        x = fabs(z_re);
        y = fabs(z_im);
        if (x >= y)
        {
            r = y / x;
            w = sqrt(x) * sqrt(0.5 * (1 + sqrt(1 + r * r)));
        }
        else
        {
            r = x / y;
            w = sqrt(y) * sqrt(0.5 * (r + sqrt(1 + r * r)));
        }

        if (z_re >= 0)
        {
            c = w + (z_im / (w + w)) * 1.0i;
        }
        else
        {
            if (z_im < 0)
                w = -w;
            c = z_im / (w + w) + w * 1.0i;
        }
    }
    return c;
}

/**
 * Calculates e$(SUP x).
 *
 *  $(TABLE_SV
 *    $(TR $(TH x)             $(TH e$(SUP x)) )
 *    $(TD +$(INFIN))          $(TD +$(INFIN)) )
 *    $(TD -$(INFIN))          $(TD +0.0)      )
 *    $(TR $(TD $(NAN))        $(TD $(NAN))    )
 *  )
 */
real exp(real x) {
    version(Naked_D_InlineAsm_X86) {
   //  e^x = 2^(LOG2E*x)
   // (This is valid because the overflow & underflow limits for exp
   // and exp2 are so similar).
    return exp2(LOG2E*x);
    } else {
        return cidrus.эксп(x);        
    }    
}

/**
 * Calculates the value of the natural logarithm base (e)
 * raised to the power of x, minus 1.
 *
 * For very small x, expm1(x) is more accurate
 * than exp(x)-1.
 *
 *  $(TABLE_SV
 *    $(TR $(TH x)             $(TH e$(SUP x)-1)  )
 *    $(TR $(TD $(PLUSMN)0.0)  $(TD $(PLUSMN)0.0) )
 *    $(TD +$(INFIN))          $(TD +$(INFIN))    )
 *    $(TD -$(INFIN))          $(TD -1.0)         )
 *    $(TR $(TD $(NAN))        $(TD $(NAN))       )
 *  )
 */
real expm1(real x) 
{
    version(Naked_D_InlineAsm_X86) {
      enum { PARAMSIZE = (real.sizeof+3)&(0xFFFF_FFFC) } // always a multiple of 4
      asm {
        /*  expm1() for x87 80-bit reals, IEEE754-2008 conformant.
         * Author: Don Clugston.
         * 
         *    expm1(x) = 2^(rndint(y))* 2^(y-rndint(y)) - 1 where y = LN2*x.
         *    = 2rndy * 2ym1 + 2rndy - 1, where 2rndy = 2^(rndint(y))
         *     and 2ym1 = (2^(y-rndint(y))-1).
         *    If 2rndy  < 0.5*real.epsilon, результат is -1.
         *    Implementation is otherwise the same as for exp2()
         */
        naked;        
        fld real ptr [ESP+4] ; // x
        mov AX, [ESP+4+8]; // AX = exponent and sign
        sub ESP, 12+8; // Create scratch space on the stack 
        // [ESP,ESP+2] = scratchint
        // [ESP+4..+6, +8..+10, +10] = scratchreal
        // set scratchreal mantissa = 1.0
        mov dword ptr [ESP+8], 0;
        mov dword ptr [ESP+8+4], 0x80000000;
        and AX, 0x7FFF; // drop sign bit
        cmp AX, 0x401D; // avoid InvalidException in fist
        jae L_extreme;
        fldl2e;
        fmul ; // y = x*log2(e)       
        fist dword ptr [ESP]; // scratchint = rndint(y)
        fisub dword ptr [ESP]; // y - rndint(y)
        // and now set scratchreal exponent
        mov EAX, [ESP];
        add EAX, 0x3fff;
        jle short L_largenegative;
        cmp EAX,0x8000;
        jge short L_largepositive;
        mov [ESP+8+8],AX;        
        f2xm1; // 2^(y-rndint(y)) -1 
        fld real ptr [ESP+8] ; // 2^rndint(y)
        fmul ST(1), ST;
        fld1;
        fsubp ST(1), ST;
        fadd;        
        add ESP,12+8;        
        ret PARAMSIZE;
        
L_extreme: // Extreme exponent. X is very large positive, very
        // large negative, infinity, or NaN.
        fxam;
        fstsw AX;
        test AX, 0x0400; // NaN_or_zero, but we already know x!=0 
        jz L_was_nan;  // if x is NaN, returns x
        test AX, 0x0200;
        jnz L_largenegative;
L_largepositive:        
        // Set scratchreal = real.max. 
        // squaring it will create infinity, and set overflow flag.
        mov word  ptr [ESP+8+8], 0x7FFE;
        fstp ST(0), ST;
        fld real ptr [ESP+8];  // load scratchreal
        fmul ST(0), ST;        // square it, to create havoc!
L_was_nan:
        add ESP,12+8;
        ret PARAMSIZE;
L_largenegative:        
        fstp ST(0), ST;
        fld1;
        fchs; // return -1. Underflow flag is not set.
        add ESP,12+8;
        ret PARAMSIZE;
      }
    } else {
        return cidrus.экспм1(x);                
    }
}

/**
 * Calculates 2$(SUP x).
 *
 *  $(TABLE_SV
 *    $(TR $(TH x)             $(TH exp2(x)    )
 *    $(TD +$(INFIN))          $(TD +$(INFIN)) )
 *    $(TD -$(INFIN))          $(TD +0.0)      )
 *    $(TR $(TD $(NAN))        $(TD $(NAN))    )
 *  )
 */
real exp2(real x) 
{
    version(Naked_D_InlineAsm_X86) {
      enum { PARAMSIZE = (real.sizeof+3)&(0xFFFF_FFFC) } // always a multiple of 4
      asm {
        /*  exp2() for x87 80-bit reals, IEEE754-2008 conformant.
         * Author: Don Clugston.
         * 
         * exp2(x) = 2^(rndint(x))* 2^(y-rndint(x))
         * The trick for high performance is to avoid the fscale(28cycles on core2),
         * frndint(19 cycles), leaving f2xm1(19 cycles) as the only slow instruction.
         * 
         * We can do frndint by using fist. BUT we can't use it for huge numbers,
         * because it will set the Invalid Operation flag is overflow or NaN occurs.
         * Fortunately, whenever this happens the результат would be zero or infinity.
         * 
         * We can perform fscale by directly poking into the exponent. BUT this doesn't
         * work for the (very rare) cases where the результат is subnormal. So we fall back
         * to the slow method in that case.
         */
        naked;        
        fld real ptr [ESP+4] ; // x
        mov AX, [ESP+4+8]; // AX = exponent and sign
        sub ESP, 12+8; // Create scratch space on the stack 
        // [ESP,ESP+2] = scratchint
        // [ESP+4..+6, +8..+10, +10] = scratchreal
        // set scratchreal mantissa = 1.0
        mov dword ptr [ESP+8], 0;
        mov dword ptr [ESP+8+4], 0x80000000;
        and AX, 0x7FFF; // drop sign bit
        cmp AX, 0x401D; // avoid InvalidException in fist
        jae L_extreme;
        fist dword ptr [ESP]; // scratchint = rndint(x)
        fisub dword ptr [ESP]; // x - rndint(x)
        // and now set scratchreal exponent
        mov EAX, [ESP];
        add EAX, 0x3fff;
        jle short L_subnormal;
        cmp EAX,0x8000;
        jge short L_overflow;
        mov [ESP+8+8],AX;        
L_normal:
        f2xm1;
        fld1;
        fadd; // 2^(x-rndint(x))
        fld real ptr [ESP+8] ; // 2^rndint(x)
        add ESP,12+8;        
        fmulp ST(1), ST;
        ret PARAMSIZE;

L_subnormal:
        // Result will be subnormal.
        // In this rare case, the simple poking method doesn't work. 
        // The speed doesn't matter, so use the slow fscale method.
        fild dword ptr [ESP];  // scratchint
        fld1;
        fscale;
        fstp real ptr [ESP+8]; // scratchreal = 2^scratchint
        fstp ST(0),ST;         // drop scratchint        
        jmp L_normal;
        
L_extreme: // Extreme exponent. X is very large positive, very
        // large negative, infinity, or NaN.
        fxam;
        fstsw AX;
        test AX, 0x0400; // NaN_or_zero, but we already know x!=0 
        jz L_was_nan;  // if x is NaN, returns x
        // set scratchreal = real.min
        // squaring it will return 0, setting underflow flag
        mov word  ptr [ESP+8+8], 1;
        test AX, 0x0200;
        jnz L_waslargenegative;
L_overflow:        
        // Set scratchreal = real.max.
        // squaring it will create infinity, and set overflow flag.
        mov word  ptr [ESP+8+8], 0x7FFE;
L_waslargenegative:        
        fstp ST(0), ST;
        fld real ptr [ESP+8];  // load scratchreal
        fmul ST(0), ST;        // square it, to create havoc!
L_was_nan:
        add ESP,12+8;
        ret PARAMSIZE;
      }
    } else {
        return cidrus.эксп2(x);
    }    
}

/**
 * Calculate cos(y) + i sin(y).
 *
 * On many CPUs (such as x86), this is a very efficient operation;
 * almost twice as fast as calculating sin(y) and cos(y) separately,
 * and is the preferred method when both are required.
 */
creal expi(real y)
{
    version(D_InlineAsm_X86)
    {
        asm
        {
            fld y;
            fsincos;
            fxch ST(1), ST(0);
        }
    }
    else
    {
        return cos(y) + sin(y)*1i;
    }
}

unittest
{
    assert(expi(1.3e5L) == cos(1.3e5L) + sin(1.3e5L) * 1i);
    assert(expi(0.0L) == 1L + 0.0Li);
}

/*********************************************************************
 * Separate floating point value into significand and exponent.
 *
 * Returns:
 *      Calculate and return $(I x) and $(I exp) such that
 *      value =$(I x)*2$(SUP exp) and
 *      .5 $(LT)= |$(I x)| $(LT) 1.0
 *      
 *      $(I x) has same sign as value.
 *
 *      $(TABLE_SV
 *      $(TR $(TH value)           $(TH returns)         $(TH exp))
 *      $(TR $(TD $(PLUSMN)0.0)    $(TD $(PLUSMN)0.0)    $(TD 0))
 *      $(TR $(TD +$(INFIN))       $(TD +$(INFIN))       $(TD int.max))
 *      $(TR $(TD -$(INFIN))       $(TD -$(INFIN))       $(TD int.min))
 *      $(TR $(TD $(PLUSMN)$(NAN)) $(TD $(PLUSMN)$(NAN)) $(TD int.min))
 *      )
 */

real frexp(real value, out int exp)
{
    ushort* vu = cast(ushort*)&value;
    long* vl = cast(long*)&value;
    uint ex;
    alias floatTraits!(real) F;

    ex = vu[F.EXPPOS_SHORT] & F.EXPMASK;
  static if (real.mant_dig == 64) { // real80
    if (ex) { // If exponent is non-zero
        if (ex == F.EXPMASK) {   // infinity or NaN
            if (*vl &  0x7FFF_FFFF_FFFF_FFFF) {  // NaN
                *vl |= 0xC000_0000_0000_0000;  // convert NaNS to NaNQ
                exp = int.min;
            } else if (vu[F.EXPPOS_SHORT] & 0x8000) {   // negative infinity
                exp = int.min;
            } else {   // positive infinity
                exp = int.max;
            }
        } else {
            exp = ex - F.EXPBIAS;
            vu[F.EXPPOS_SHORT] =
                cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
        }
    } else if (!*vl) {
        // value is +-0.0
        exp = 0;
    } else {
        // denormal
        int i = -0x3FFD;
        do {
            i--;
            *vl <<= 1;
        } while (*vl > 0);
        exp = i;
        vu[F.EXPPOS_SHORT] =
            cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
    }
  } else static if (real.mant_dig == 113) { // quadruple      
        if (ex) { // If exponent is non-zero
            if (ex == F.EXPMASK) {   // infinity or NaN
                if (vl[MANTISSA_LSB] |
                    ( vl[MANTISSA_MSB] & 0x0000_FFFF_FFFF_FFFF)) {  // NaN
                    // convert NaNS to NaNQ
                    vl[MANTISSA_MSB] |= 0x0000_8000_0000_0000;
                    exp = int.min;
                } else if (vu[F.EXPPOS_SHORT] & 0x8000) {   // negative infinity
                    exp = int.min;
                } else {   // positive infinity
                    exp = int.max;
                }
            } else {
                exp = ex - F.EXPBIAS;
                vu[F.EXPPOS_SHORT] =
                   cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
            }
        } else if ((vl[MANTISSA_LSB] 
                  |(vl[MANTISSA_MSB] & 0x0000_FFFF_FFFF_FFFF)) == 0) {
            // value is +-0.0
            exp = 0;
    } else {
        // denormal
        value *= F.POW2MANTDIG;
        ex = vu[F.EXPPOS_SHORT] & F.EXPMASK;
        exp = ex - F.EXPBIAS - 113;
        vu[F.EXPPOS_SHORT] = 
                  cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
    }
  } else static if (real.mant_dig==53) { // real is double
    if (ex) { // If exponent is non-zero
        if (ex == F.EXPMASK) {   // infinity or NaN
            if (*vl == 0x7FF0_0000_0000_0000) {  // positive infinity
                exp = int.max;
            } else if (*vl == 0xFFF0_0000_0000_0000) { // negative infinity
                exp = int.min;
            } else { // NaN
                *vl |= 0x0008_0000_0000_0000;  // convert NaNS to NaNQ
                exp = int.min;
            }
        } else {
            exp = (ex - F.EXPBIAS) >>> 4;
            vu[F.EXPPOS_SHORT] = cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FE0);
        }
    } else if (!(*vl & 0x7FFF_FFFF_FFFF_FFFF)) {
        // value is +-0.0
        exp = 0;
    } else {
        // denormal
        ushort sgn;
        sgn = cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT])| 0x3FE0);
        *vl &= 0x7FFF_FFFF_FFFF_FFFF;

        int i = -0x3FD+11;
        do {
            i--;
            *vl <<= 1;
        } while (*vl > 0);
        exp = i;
        vu[F.EXPPOS_SHORT] = sgn;
    }
  } else { //static if(real.mant_dig==106) // doubledouble
    throw new НереализИскл("frexp");
  }
  return value;
}


unittest
{
    static real vals[][3] =     // x,frexp,exp
    [
        [0.0,   0.0,    0],
        [-0.0,  -0.0,   0],
        [1.0,   .5,     1],
        [-1.0,  -.5,    1],
        [2.0,   .5,     2],
    [double.min/2.0, .5, -1022],
        [real.infinity,real.infinity,int.max],
        [-real.infinity,-real.infinity,int.min],
        [real.nan,real.nan,int.min],
        [-real.nan,-real.nan,int.min],
    ];

    int i;

    for (i = 0; i < vals.length; i++) {
        real x = vals[i][0];
        real e = vals[i][1];
        int exp = cast(int)vals[i][2];
        int eptr;
        real v = frexp(x, eptr);
//        эхо("frexp(%La) = %La, should be %La, eptr = %d, should be %d\n",
//                x, v, e, eptr, exp);
        assert(isIdentical(e, v));
        assert(exp == eptr);

    }
   static if (real.mant_dig == 64) {
     static real extendedvals[][3] = [ // x,frexp,exp
        [0x1.a5f1c2eb3fe4efp+73L, 0x1.A5F1C2EB3FE4EFp-1L,   74],    // normal
        [0x1.fa01712e8f0471ap-1064L,  0x1.fa01712e8f0471ap-1L,     -1063],
        [real.min,  .5L,     -16381],
        [real.min/2.0L, .5L,     -16382]    // denormal
     ];

    for (i = 0; i < extendedvals.length; i++) {
        real x = extendedvals[i][0];
        real e = extendedvals[i][1];
        int exp = cast(int)extendedvals[i][2];
        int eptr;
        real v = frexp(x, eptr);
        assert(isIdentical(e, v));
        assert(exp == eptr);

    }
    }
}

/******************************************
 * Extracts the exponent of x as a signed integral value.
 *
 * If x is not a special value, the результат is the same as
 * $(D cast(int)logb(x)).
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                $(TH ilogb(x))     $(TH Range error?))
 *      $(TR $(TD 0)                 $(TD FP_ILOGB0)   $(TD yes))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD int.max)     $(TD no))
 *      $(TR $(TD $(NAN))            $(TD FP_ILOGBNAN) $(TD no))
 *      )
 */
int ilogb(real x)               { return cidrus.илогбд(x); }

const int FP_ILOGB0        = int.min;
const int FP_ILOGBNAN      = int.min;


/*******************************************
 * Compute n * 2$(SUP exp)
 * References: frexp
 */

real ldexp(real n, int exp);    /* intrinsic */

/**************************************
 * Calculate the natural logarithm of x.
 *
 *    $(TABLE_SV
 *    $(TR $(TH x)            $(TH log(x))    $(TH divide by 0?) $(TH invalid?))
 *    $(TR $(TD $(PLUSMN)0.0) $(TD -$(INFIN)) $(TD yes)          $(TD no))
 *    $(TR $(TD $(LT)0.0)     $(TD $(NAN))    $(TD no)           $(TD yes))
 *    $(TR $(TD +$(INFIN))    $(TD +$(INFIN)) $(TD no)           $(TD no))
 *    )
 */

real log(real x)
{
    version (INLINE_YL2X)
	return yl2x(x, LN2);
    else
	return cidrus.логд(x);
}

unittest
{
    assert(log(E) == 1);
}

/**************************************
 * Calculate the base-10 logarithm of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)            $(TH log10(x))  $(TH divide by 0?) $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0) $(TD -$(INFIN)) $(TD yes)          $(TD no))
 *      $(TR $(TD $(LT)0.0)     $(TD $(NAN))    $(TD no)           $(TD yes))
 *      $(TR $(TD +$(INFIN))    $(TD +$(INFIN)) $(TD no)           $(TD no))
 *      )
 */

real log10(real x)
{
    version (INLINE_YL2X)
	return yl2x(x, LOG2);
    else
	return cidrus.лог10д(x);
}

unittest
{
    //эхо("%Lg\n", log10(1000) - 3);
    assert(fabs(log10(1000) - 3) < .000001);
}

/******************************************
 *      Calculates the natural logarithm of 1 + x.
 *
 *      For very small x, log1p(x) will be more accurate than
 *      log(1 + x).
 *
 *  $(TABLE_SV
 *  $(TR $(TH x)            $(TH log1p(x))     $(TH divide by 0?) $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0) $(TD $(PLUSMN)0.0) $(TD no)           $(TD no))
 *  $(TR $(TD -1.0)         $(TD -$(INFIN))    $(TD yes)          $(TD no))
 *  $(TR $(TD $(LT)-1.0)    $(TD $(NAN))       $(TD no)           $(TD yes))
 *  $(TR $(TD +$(INFIN))    $(TD -$(INFIN))    $(TD no)           $(TD no))
 *  )
 */

real log1p(real x)              { return cidrus.лог1пд(x); }

/***************************************
 * Calculates the base-2 logarithm of x:
 * $(SUB log, 2)x
 *
 *  $(TABLE_SV
 *  $(TR $(TH x)            $(TH log2(x))   $(TH divide by 0?) $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0) $(TD -$(INFIN)) $(TD yes)          $(TD no) )
 *  $(TR $(TD $(LT)0.0)     $(TD $(NAN))    $(TD no)           $(TD yes) )
 *  $(TR $(TD +$(INFIN))    $(TD +$(INFIN)) $(TD no)           $(TD no) )
 *  )
 */
real log2(real x)
{
    version (INLINE_YL2X)
	return yl2x(x, 1);
    else
	return cidrus.лог2д(x);
}


/*****************************************
 * Extracts the exponent of x as a signed integral value.
 *
 * If x is subnormal, it is treated as if it were normalized.
 * For a positive, finite x:
 *
 * 1 $(LT)= $(I x) * FLT_RADIX$(SUP -logb(x)) $(LT) FLT_RADIX
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH logb(x))   $(TH divide by 0?) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD +$(INFIN)) $(TD no))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD -$(INFIN)) $(TD yes) )
 *      )
 */
real logb(real x)               { return cidrus.логбд(x); }

/************************************
 * Calculates the remainder from the calculation x/y.
 * Returns:
 * The value of x - i * y, where i is the number of times that y can
 * be completely subtracted from x. The результат has the same sign as x.
 *
 * $(TABLE_SV
 *  $(TR $(TH x)              $(TH y)             $(TH modf(x, y))   $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0)   $(TD not 0.0)       $(TD $(PLUSMN)0.0) $(TD no))
 *  $(TR $(TD $(PLUSMNINF))   $(TD anything)      $(TD $(NAN))       $(TD yes))
 *  $(TR $(TD anything)       $(TD $(PLUSMN)0.0)  $(TD $(NAN))       $(TD yes))
 *  $(TR $(TD !=$(PLUSMNINF)) $(TD $(PLUSMNINF))  $(TD x)            $(TD no))
 * )
 */
real modf(real x, inout real y) { return cidrus.модфд(x,&y); }

/*************************************
 * Efficiently calculates x * 2$(SUP n).
 *
 * scalbn handles underflow and overflow in
 * the same fashion as the basic arithmetic operators.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH scalb(x)))
 *      $(TR $(TD $(PLUSMNINF))      $(TD $(PLUSMNINF)) )
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0) )
 *      )
 */

 extern(C)   реал    scalbnl(реал x, цел n){return scalbnl(x, n);}

real scalbn(real x, int n)
{
    version(D_InlineAsm_X86) {
        // scalbnl is not supported on DMD-Windows, so use asm.
        asm {
            fild n;
            fld x;
            fscale;
            fstp ST(1), ST;
        }
    } else {
        return scalbnl(x, n);
    }
}

unittest {
    assert(scalbn(-real.infinity, 5) == -real.infinity);
}

/***************
 * Calculates the cube root of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH $(I x))            $(TH cbrt(x))           $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0)      $(TD no) )
 *      $(TR $(TD $(NAN))            $(TD $(NAN))            $(TD yes) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(PLUSMN)$(INFIN)) $(TD no) )
 *      )
 */
real cbrt(real x)               { return cidrus.кубкорд(x); }


/*******************************
 * Returns |x|
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH fabs(x)))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD +0.0) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD +$(INFIN)) )
 *      )
 */
real fabs(real x);      /* intrinsic */


/***********************************************************************
 * Calculates the length of the
 * hypotenuse of a right-angled triangle with sides of length x and y.
 * The hypotenuse is the value of the square root of
 * the sums of the squares of x and y:
 *
 *      sqrt($(POW x, 2) + $(POW y, 2))
 *
 * Note that hypot(x, y), hypot(y, x) and
 * hypot(x, -y) are equivalent.
 *
 *  $(TABLE_SV
 *  $(TR $(TH x)            $(TH y)            $(TH hypot(x, y)) $(TH invalid?))
 *  $(TR $(TD x)            $(TD $(PLUSMN)0.0) $(TD |x|)         $(TD no))
 *  $(TR $(TD $(PLUSMNINF)) $(TD y)            $(TD +$(INFIN))   $(TD no))
 *  $(TR $(TD $(PLUSMNINF)) $(TD $(NAN))       $(TD +$(INFIN))   $(TD no))
 *  )
 */

real hypot(real x, real y)
{
    /*
     * This is based on code from:
     * Cephes Math Library Release 2.1:  January, 1989
     * Copyright 1984, 1987, 1989 by Stephen L. Moshier
     * Direct inquiries to 30 Frost Street, Cambridge, MA 02140
     */

    const int PRECL = 32;
    const int MAXEXPL = real.max_exp; //16384;

    real xx, yy, b, re, im;
    int ex, ey, e;

    // Note, hypot(INFINITY, NAN) = INFINITY.
    if (isinf(x) || isinf(y))
        return real.infinity;

    if (isnan(x))
        return x;
    if (isnan(y))
        return y;

    re = fabs(x);
    im = fabs(y);

    if (re == 0.0)
        return im;
    if (im == 0.0)
        return re;

    // Get the exponents of the numbers
    xx = frexp(re, ex);
    yy = frexp(im, ey);

    // Check if one number is tiny compared to the other
    e = ex - ey;
    if (e > PRECL)
        return re;
    if (e < -PRECL)
        return im;

    // Find approximate exponent e of the geometric mean.
    e = (ex + ey) >> 1;

    // Rescale so mean is about 1
    xx = ldexp(re, -e);
    yy = ldexp(im, -e);

    // Hypotenuse of the right triangle
    b = sqrt(xx * xx  +  yy * yy);

    // Compute the exponent of the answer.
    yy = frexp(b, ey);
    ey = e + ey;

    // Check it for overflow. (Underflow is impossible).
    if (ey > MAXEXPL + 2)
    {
        //return __matherr(_OVERFLOW, INFINITY, x, y, "hypotl");
        return real.infinity;
    }

    // Undo the scaling
    b = ldexp(b, e);
    return b;
}

unittest
{
    static real vals[][3] =     // x,y,hypot
    [
        [ 0,      0,      0],
        [ 0,      -0,     0],
        [ 3,      4,      5],
        [ -300,   -400,   500],
        [ real.min, real.min, 4.75473e-4932L],
        [ real.max/2, real.max/2, 0x1.6a09e667f3bcc908p+16383L],
        [ 3*real.min*real.epsilon, 4*real.min*real.epsilon, 5*real.min*real.epsilon],
        [ real.infinity, real.nan, real.infinity],
        [ real.nan, real.nan, real.nan],
    ];

    for (int i = 0; i < vals.length; i++)
    {
        real x = vals[i][0];
        real y = vals[i][1];
        real z = vals[i][2];
        real h = hypot(x, y);
        assert(mfeq(z, h, .0000001));
    }
}

/**********************************
 * Returns the error function of x.
 *
 * <img src="erf.gif" alt="error function">
 */
real erf(real x)                { return cidrus.фцошд(x); }

/**********************************
 * Returns the complementary error function of x, which is 1 - erf(x).
 *
 * <img src="erfc.gif" alt="complementary error function">
 */
real erfc(real x)               { return cidrus.фцошкд(x); }

/***********************************
 * Natural logarithm of gamma function.
 *
 * Returns the base e (2.718...) logarithm of the absolute
 * value of the gamma function of the argument.
 *
 * For reals, lgamma is equivalent to log(fabs(gamma(x))).
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH lgamma(x)) $(TH invalid?))
 *      $(TR $(TD $(NAN))            $(TD $(NAN))    $(TD yes))
 *      $(TR $(TD integer $(LT)= 0)      $(TD +$(INFIN)) $(TD yes))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD +$(INFIN)) $(TD no))
 *      )
 */
/* Documentation prepared by Don Clugston */
real lgamma(real x)
{
    return cidrus.лгаммад(x);

    // Use etc.gamma.lgamma for those C systems that are missing it
}

/***********************************
 *  The Gamma function, $(GAMMA)(x)
 *
 *  $(GAMMA)(x) is a generalisation of the factorial function
 *  to real and complex numbers.
 *  Like x!, $(GAMMA)(x+1) = x*$(GAMMA)(x).
 *
 *  Mathematically, if z.re > 0 then
 *   $(GAMMA)(z) = $(INTEGRATE 0, &infin;) $(POWER t, z-1)$(POWER e, -t) dt
 *
 *    $(TABLE_SV
 *      $(TR $(TH x)              $(TH $(GAMMA)(x))       $(TH invalid?))
 *      $(TR $(TD $(NAN))         $(TD $(NAN))            $(TD yes))
 *      $(TR $(TD $(PLUSMN)0.0)   $(TD $(PLUSMNINF))      $(TD yes))
 *      $(TR $(TD integer $(GT)0) $(TD (x-1)!)            $(TD no))
 *      $(TR $(TD integer $(LT)0) $(TD $(NAN))            $(TD yes))
 *      $(TR $(TD +$(INFIN))      $(TD +$(INFIN))         $(TD no))
 *      $(TR $(TD -$(INFIN))      $(TD $(NAN))            $(TD yes))
 *    )
 *
 *  References:
 *      $(LINK http://en.wikipedia.org/wiki/Gamma_function),
 *      $(LINK http://www.netlib.org/cephes/ldoubdoc.html#gamma)
 */
real tgamma(real x)
{
    return cidrus.тгаммад(x);

    // Use etc.gamma.tgamma for those C systems that are missing it
}

/**************************************
 * Returns the value of x rounded upward to the next integer
 * (toward positive infinity).
 */
real ceil(real x)               { return cidrus.вокруглид(x); }

/**************************************
 * Returns the value of x rounded downward to the next integer
 * (toward negative infinity).
 */
real floor(real x)              { return cidrus.нокруглид(x); }

/******************************************
 * Rounds x to the nearest integer value, using the current rounding
 * mode.
 *
 * Unlike the rint functions, nearbyint does not raise the
 * FE_INEXACT exception.
 */
real nearbyint(real x) { return cidrus.ближцелд(x); }

/**********************************
 * Rounds x to the nearest integer value, using the current rounding
 * mode.
 * If the return value is not equal to x, the FE_INEXACT
 * exception is raised.
 * $(B nearbyint ) performs
 * the same operation, but does not set the FE_INEXACT exception.
 */
real rint(real x);      /* intrinsic */
extern(C) дол    llrintl(реал x);
/***************************************
 * Rounds x to the nearest integer value, using the current rounding
 * mode.
 *
 * This is generally the fastest method to convert a floating-point number
 * to an integer. Note that the results from this function
 * depend on the rounding mode, if the fractional part of x is exactly 0.5.
 * If using the default rounding mode (ties round to even integers)
 * lrint(4.5) == 4, lrint(5.5)==6.
 */
long lrint(real x)
{
    version (Posix)
        return llrintl(x);
    else version(D_InlineAsm_X86)
    {
        long n;
        asm
        {
            fld x;
            fistp n;
        }
        return n;
    }
    else
        throw new НереализИскл("lrint");
}

/*******************************************
 * Return the value of x rounded to the nearest integer.
 * If the fractional part of x is exactly 0.5, the return value is rounded to
 * the even integer.
 */
real round(real x) { return cidrus.округлид(x); }

/**********************************************
 * Return the value of x rounded to the nearest integer.
 *
 * If the fractional part of x is exactly 0.5, the return value is rounded
 * away from zero.
 *
 * Note: Not supported on windows
 */
 extern(C) 
 {
 дол    llroundl(реал x);
  real    truncl(real x);
  реал    remquol(реал x, реал y, цел* quo);
 }
 
long lround(real x)
{
    version (Posix)
        return llroundl(x);
    else
        throw new НереализИскл("lround");
}

/****************************************************
 * Returns the integer portion of x, dropping the fractional portion.
 *
 * This is also known as "chop" rounding.
 */
real trunc(real x) { return truncl(x); }

/****************************************************
 * Calculate the remainder x REM y, following IEC 60559.
 *
 * REM is the value of x - y * n, where n is the integer nearest the exact
 * value of x / y.
 * If |n - x / y| == 0.5, n is even.
 * If the результат is zero, it has the same sign as x.
 * Otherwise, the sign of the результат is the sign of x / y.
 * Precision mode has no effect on the remainder functions.
 *
 * remquo returns n in the parameter n.
 *
 * $(TABLE_SV
 *  $(TR $(TH x)               $(TH y)            $(TH remainder(x, y)) $(TH n)   $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0)    $(TD not 0.0)      $(TD $(PLUSMN)0.0)    $(TD 0.0) $(TD no))
 *  $(TR $(TD $(PLUSMNINF))    $(TD anything)     $(TD $(NAN))          $(TD ?)   $(TD yes))
 *  $(TR $(TD anything)        $(TD $(PLUSMN)0.0) $(TD $(NAN))          $(TD ?)   $(TD yes))
 *  $(TR $(TD != $(PLUSMNINF)) $(TD $(PLUSMNINF)) $(TD x)               $(TD ?)   $(TD no))
 * )
 *
 * Note: remquo not supported on windows
 */
real remainder(real x, real y) { return cidrus.остатокд(x, y); }

real remquo(real x, real y, out int n)  /// ditto
{
    version (Posix)
        return remquol(x, y, &n);
    else
        throw new НереализИскл("remquo");
}

/*********************************
 * Returns !=0 if e is a NaN.
 */

int isnan(real x)
{
  alias floatTraits!(real) F;
  static if (real.mant_dig==53) { // double
        ulong*  p = cast(ulong *)&x;
        return (*p & 0x7FF0_0000_0000_0000 == 0x7FF0_0000_0000_0000)
             && *p & 0x000F_FFFF_FFFF_FFFF;
  } else static if (real.mant_dig==64) {     // real80
        // Prevent a ridiculous warning
        // (why does (ushort | ushort) get promoted to int???)
        ushort e = cast(ushort)(F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT]);
        ulong*  ps = cast(ulong *)&x;
        return e == F.EXPMASK &&
            *ps & 0x7FFF_FFFF_FFFF_FFFF; // not infinity
  } else static if (real.mant_dig==113) {  // quadruple
        ushort e = cast(ushort)(F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT]);
        ulong*  ps = cast(ulong *)&x;
        return e == F.EXPMASK &&
           (ps[MANTISSA_LSB] | (ps[MANTISSA_MSB]& 0x0000_FFFF_FFFF_FFFF))!=0;
  } else {
      return x!=x;
  }
}

unittest
{
    assert(isnan(float.nan));
    assert(isnan(-double.nan));
    assert(isnan(real.nan));

    assert(!isnan(53.6));
    assert(!isnan(float.infinity));
}

/*********************************
 * Returns !=0 if e is finite (not infinite or $(NAN)).
 */

int isfinite(real e)
{
    alias floatTraits!(real) F;
    ushort* pe = cast(ushort *)&e;
    return (pe[F.EXPPOS_SHORT] & F.EXPMASK) != F.EXPMASK;
}

unittest
{
    assert(isfinite(1.23));
    assert(!isfinite(double.infinity));
    assert(!isfinite(float.nan));
}


/*********************************
 * Returns !=0 if x is normalized (not zero, subnormal, infinite, or $(NAN)).
 */

/* Need one for each format because subnormal floats might
 * be converted to normal reals.
 */

int isnormal(X)(X x)
{
    alias floatTraits!(X) F;

    static if(real.mant_dig==106) { // doubledouble
        // doubledouble is normal if the least significant part is normal.
        return isnormal((cast(double*)&x)[MANTISSA_LSB]);
    } else {
        // ridiculous DMD warning
        ushort e = cast(ushort)(F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT]);
        return (e != F.EXPMASK && e!=0);
    }
}


unittest
{
    float f = 3;
    double d = 500;
    real e = 10e+48;

    assert(isnormal(f));
    assert(isnormal(d));
    assert(isnormal(e));
    f = d = e = 0;
    assert(!isnormal(f));
    assert(!isnormal(d));
    assert(!isnormal(e));
    assert(!isnormal(real.infinity));
    assert(isnormal(-real.max));
    assert(!isnormal(real.min/4));

}

/*********************************
 * Is number subnormal? (Also called "denormal".)
 * Subnormals have a 0 exponent and a 0 most significant mantissa bit.
 */

/* Need one for each format because subnormal floats might
 * be converted to normal reals.
 */

int issubnormal(float f)
{
    uint *p = cast(uint *)&f;
    return (*p & 0x7F80_0000) == 0 && *p & 0x007F_FFFF;
}

unittest
{
    float f = 3.0;

    for (f = 1.0; !issubnormal(f); f /= 2)
        assert(f != 0);
}

/// ditto

int issubnormal(double d)
{
    uint *p = cast(uint *)&d;
    return (p[MANTISSA_MSB] & 0x7FF0_0000) == 0
        && (p[MANTISSA_LSB] || p[MANTISSA_MSB] & 0x000F_FFFF);
}

unittest
{
    double f;

    for (f = 1; !issubnormal(f); f /= 2)
        assert(f != 0);
}

/// ditto

int issubnormal(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return issubnormal(cast(double)x);
    } else static if (real.mant_dig == 113) { // quadruple
        ushort e = F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT];
        long*   ps = cast(long *)&x;
        return (e == 0 &&
          (((ps[MANTISSA_LSB]|(ps[MANTISSA_MSB]& 0x0000_FFFF_FFFF_FFFF))) !=0));
    } else static if (real.mant_dig==64) { // real80
        ushort* pe = cast(ushort *)&x;
        long*   ps = cast(long *)&x;

        return (pe[F.EXPPOS_SHORT] & F.EXPMASK) == 0 && *ps > 0;
    } else { // double double
        return issubnormal((cast(double*)&x)[MANTISSA_MSB]);
    }
}

unittest
{
    real f;

    for (f = 1; !issubnormal(f); f /= 2)
        assert(f != 0);
}

/*********************************
 * Return !=0 if e is $(PLUSMN)$(INFIN).
 */

int isinf(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return ((*cast(ulong *)&x) & 0x7FFF_FFFF_FFFF_FFFF)
                == 0x7FF8_0000_0000_0000;
    } else static if(real.mant_dig == 106) { //doubledouble
        return (((cast(ulong *)&x)[MANTISSA_MSB]) & 0x7FFF_FFFF_FFFF_FFFF)
                    == 0x7FF8_0000_0000_0000;
    } else static if (real.mant_dig == 113) { // quadruple
        long*   ps = cast(long *)&x;
        return (ps[MANTISSA_LSB] == 0)
         && (ps[MANTISSA_MSB] & 0x7FFF_FFFF_FFFF_FFFF) == 0x7FFF_0000_0000_0000;
    } else { // real80
        ushort e = cast(ushort)(F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT]);
        ulong*  ps = cast(ulong *)&x;

        return e == F.EXPMASK && *ps == 0x8000_0000_0000_0000;
   }
}

unittest
{
    assert(isinf(float.infinity));
    assert(!isinf(float.nan));
    assert(isinf(double.infinity));
    assert(isinf(-real.infinity));

    assert(isinf(-1.0 / 0.0));
}

/*********************************
 * Is the binary representation of x identical to y?
 *
 * Same as ==, except that positive and negative zero are not identical,
 * and two $(NAN)s are identical if they have the same 'payload'.
 */

bool isIdentical(real x, real y)
{
    // We're doing a bitwise comparison so the endianness is irrelevant.
    long*   pxs = cast(long *)&x;
    long*   pys = cast(long *)&y;
 static if (real.mant_dig == 53){ //double
    return pxs[0] == pys[0];
 } else static if (real.mant_dig == 113 || real.mant_dig==106) {
      // quadruple or doubledouble
    return pxs[0] == pys[0] && pxs[1] == pys[1];
 } else { // real80
    ushort* pxe = cast(ushort *)&x;
    ushort* pye = cast(ushort *)&y;
    return pxe[4] == pye[4] && pxs[0] == pys[0];
 }
}

/*********************************
 * Return 1 if sign bit of e is set, 0 if not.
 */

int signbit(real x)
{
    return ((cast(ubyte *)&x)[floatTraits!(real).SIGNPOS_BYTE] & 0x80) != 0;
}

unittest
{
    debug (math) эхо("math.signbit.unittest\n");
    assert(!signbit(float.nan));
    assert(signbit(-float.nan));
    assert(!signbit(168.1234));
    assert(signbit(-168.1234));
    assert(!signbit(0.0));
    assert(signbit(-0.0));
}

/*********************************
 * Return a value composed of to with from's sign bit.
 */

real copysign(real to, real from)
{
    ubyte* pto   = cast(ubyte *)&to;
    ubyte* pfrom = cast(ubyte *)&from;

    alias floatTraits!(real) F;
    pto[F.SIGNPOS_BYTE] &= 0x7F;
    pto[F.SIGNPOS_BYTE] |= pfrom[F.SIGNPOS_BYTE] & 0x80;
    return to;
}

unittest
{
    real e;

    e = copysign(21, 23.8);
    assert(e == 21);

    e = copysign(-21, 23.8);
    assert(e == 21);

    e = copysign(21, -23.8);
    assert(e == -21);

    e = copysign(-21, -23.8);
    assert(e == -21);

    e = copysign(real.nan, -23.8);
    assert(isnan(e) && signbit(e));
}



/******************************************
 * Creates a quiet NAN with the information from tagp[] embedded in it.
 *
 * BUGS: DMD always returns real.nan, ignoring the payload.
 */
real nan(char[] tagp) { return cidrus.нечислод(tagp); }

/**
 * Calculate the next largest floating point value after x.
 *
 * Return the least number greater than x that is representable as a real;
 * thus, it gives the next point on the IEEE number line.
 *
 *  $(TABLE_SV
 *    $(SVH x,            nextUp(x)   )
 *    $(SV  -$(INFIN),    -real.max   )
 *    $(SV  $(PLUSMN)0.0, real.min*real.epsilon )
 *    $(SV  real.max,     $(INFIN) )
 *    $(SV  $(INFIN),     $(INFIN) )
 *    $(SV  $(NAN),       $(NAN)   )
 * )
 *
 * Remarks:
 * This function is included in the forthcoming IEEE 754R standard.
 */
real nextUp(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return nextUp(cast(double)x);
    } else static if(real.mant_dig==113) {  // quadruple
        ushort e = F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT];
        if (e == F.EXPMASK) { // NaN or Infinity
             if (x == -real.infinity) return -real.max;
             return x; // +Inf and NaN are unchanged.
        }
        ulong*   ps = cast(ulong *)&e;
        if (ps[MANTISSA_LSB] & 0x8000_0000_0000_0000)  { // Negative number
            if (ps[MANTISSA_LSB] == 0
             && ps[MANTISSA_MSB] == 0x8000_0000_0000_0000) {
                // it was negative zero, change to smallest subnormal
                ps[MANTISSA_LSB] = 0x0000_0000_0000_0001;
                ps[MANTISSA_MSB] = 0;
                return x;
            }
            --*ps;
            if (ps[MANTISSA_LSB]==0) --ps[MANTISSA_MSB];
        } else { // Positive number
            ++ps[MANTISSA_LSB];
            if (ps[MANTISSA_LSB]==0) ++ps[MANTISSA_MSB];
        }
        return x;

    } else static if(real.mant_dig==64){ // real80
        // For 80-bit reals, the "implied bit" is a nuisance...
        ushort *pe = cast(ushort *)&x;
        ulong  *ps = cast(ulong  *)&x;

        if ((pe[F.EXPPOS_SHORT] & F.EXPMASK) == F.EXPMASK) {
            // First, deal with NANs and infinity
            if (x == -real.infinity) return -real.max;
            return x; // +Inf and NaN are unchanged.
        }
        if (pe[F.EXPPOS_SHORT] & 0x8000)  {
            // Negative number -- need to decrease the significand
            --*ps;
            // Need to маска with 0x7FFF... so subnormals are treated correctly.
            if ((*ps & 0x7FFF_FFFF_FFFF_FFFF) == 0x7FFF_FFFF_FFFF_FFFF) {
                if (pe[F.EXPPOS_SHORT] == 0x8000) { // it was negative zero
                    *ps = 1;
                    pe[F.EXPPOS_SHORT] = 0; // smallest subnormal.
                    return x;
                }
                --pe[F.EXPPOS_SHORT];
                if (pe[F.EXPPOS_SHORT] == 0x8000) {
                    return x; // it's become a subnormal, implied bit stays low.
                }
                *ps = 0xFFFF_FFFF_FFFF_FFFF; // set the implied bit
                return x;
            }
            return x;
        } else {
            // Positive number -- need to increase the significand.
            // Works automatically for positive zero.
            ++*ps;
            if ((*ps & 0x7FFF_FFFF_FFFF_FFFF) == 0) {
                // change in exponent
                ++pe[F.EXPPOS_SHORT];
                *ps = 0x8000_0000_0000_0000; // set the high bit
            }
        }
        return x;
    } else { // doubledouble
        assert(0, "Not implemented");
    }
}

/** ditto */
double nextUp(double x)
{
    ulong *ps = cast(ulong *)&x;

    if ((*ps & 0x7FF0_0000_0000_0000) == 0x7FF0_0000_0000_0000) {
        // First, deal with NANs and infinity
        if (x == -x.infinity) return -x.max;
        return x; // +INF and NAN are unchanged.
    }
    if (*ps & 0x8000_0000_0000_0000)  { // Negative number
        if (*ps == 0x8000_0000_0000_0000) { // it was negative zero
            *ps = 0x0000_0000_0000_0001; // change to smallest subnormal
            return x;
        }
        --*ps;
    } else { // Positive number
        ++*ps;
    }
    return x;
}

/** ditto */
float nextUp(float x)
{
    uint *ps = cast(uint *)&x;

    if ((*ps & 0x7F80_0000) == 0x7F80_0000) {
        // First, deal with NANs and infinity
        if (x == -x.infinity) return -x.max;
        return x; // +INF and NAN are unchanged.
    }
    if (*ps & 0x8000_0000)  { // Negative number
        if (*ps == 0x8000_0000) { // it was negative zero
            *ps = 0x0000_0001; // change to smallest subnormal
            return x;
        }
        --*ps;
    } else { // Positive number
        ++*ps;
    }
    return x;
}

/**
 * Calculate the next smallest floating point value before x.
 *
 * Return the greatest number less than x that is representable as a real;
 * thus, it gives the previous point on the IEEE number line.
 *
 *  $(TABLE_SV
 *    $(SVH x,            nextDown(x)   )
 *    $(SV  $(INFIN),     real.max  )
 *    $(SV  $(PLUSMN)0.0, -real.min*real.epsilon )
 *    $(SV  -real.max,    -$(INFIN) )
 *    $(SV  -$(INFIN),    -$(INFIN) )
 *    $(SV  $(NAN),       $(NAN)    )
 * )
 *
 * Remarks:
 * This function is included in the forthcoming IEEE 754R standard.
 */
real nextDown(real x)
{
    return -nextUp(-x);
}

/** ditto */
double nextDown(double x)
{
    return -nextUp(-x);
}

/** ditto */
float nextDown(float x)
{
    return -nextUp(-x);
}

unittest {
    assert( nextDown(1.0 + real.epsilon) == 1.0);
}


/******************************************
 * Calculates the next representable value after x in the direction of y.
 *
 * If y > x, the результат will be the next largest floating-point value;
 * if y < x, the результат will be the next smallest value.
 * If x == y, the результат is y.
 *
 * Remarks:
 * This function is not generally very useful; it's almost always better to use
 * the faster functions nextUp() or nextDown() instead.
 *
 * IEEE 754 requirements not implemented on Windows:
 * The FE_INEXACT and FE_OVERFLOW exceptions will be raised if x is finite and
 * the function результат is infinite. The FE_INEXACT and FE_UNDERFLOW
 * exceptions will be raised if the function value is subnormal, and x is
 * not equal to y.
 */
real nextafter(real x, real y)
{
    version (Windows) {
        if (x==y) return y;
        return (y>x) ? nextUp(x) : nextDown(x);
    } else {
        return cidrus.nextafterl(x, y);
    }
}

/// ditto
float nextafter(float x, float y)
{
    version (Windows) {
        if (x==y) return y;
        return (y>x) ? nextUp(x) : nextDown(x);
    } else {
        return cidrus.nextafterf(x, y);
    }
}

/// ditto
double nextafter(double x, double y)
{
    version (Windows) {
        if (x==y) return y;
        return (y>x) ? nextUp(x) : nextDown(x);
    } else {
        return cidrus.nextafter(x, y);
    }
}

unittest
{
    float a = 1;
    assert(is(typeof(nextafter(a, a)) == float));
    assert(nextafter(a, a.infinity) > a);

    double b = 2;
    assert(is(typeof(nextafter(b, b)) == double));
    assert(nextafter(b, b.infinity) > b);

    real c = 3;
    assert(is(typeof(nextafter(c, c)) == real));
    assert(nextafter(c, c.infinity) > c);
}

//real nexttoward(real x, real y) { return cidrus.nexttowardl(x, y); }

/*******************************************
 * Returns the positive difference between x and y.
 * Returns:
 *      $(TABLE_SV
 *      $(TR $(TH x, y)       $(TH fdim(x, y)))
 *      $(TR $(TD x $(GT) y)  $(TD x - y))
 *      $(TR $(TD x $(LT)= y) $(TD +0.0))
 *      )
 */
real fdim(real x, real y) { return (x > y) ? x - y : +0.0; }

/****************************************
 * Returns the larger of x and y.
 */
real fmax(real x, real y) { return x > y ? x : y; }

/****************************************
 * Returns the smaller of x and y.
 */
real fmin(real x, real y) { return x < y ? x : y; }

/**************************************
 * Returns (x * y) + z, rounding only once according to the
 * current rounding mode.
 *
 * BUGS: Not currently implemented - rounds twice.
 */
real fma(real x, real y, real z) { return (x * y) + z; }

/*******************************************************************
 * Fast integral powers.
 */

real pow(real x, uint n)
{
    real p;

    switch (n)
    {
        case 0:
            p = 1.0;
            break;

        case 1:
            p = x;
            break;

        case 2:
            p = x * x;
            break;

        default:
            p = 1.0;
            while (1)
            {
                if (n & 1)
                    p *= x;
                n >>= 1;
                if (!n)
                    break;
                x *= x;
            }
            break;
    }
    return p;
}

/// ditto

real pow(real x, int n)
{
    if (n < 0)
        return pow(x, cast(real)n);
    else
        return pow(x, cast(uint)n);
}

/*********************************************
 * Calculates x$(SUP y).
 *
 * $(TABLE_SV
 * $(TR $(TH x) $(TH y) $(TH pow(x, y))
 *      $(TH div 0) $(TH invalid?))
 * $(TR $(TD anything)      $(TD $(PLUSMN)0.0)                $(TD 1.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD |x| $(GT) 1)    $(TD +$(INFIN))                  $(TD +$(INFIN))
 *      $(TD no)        $(TD no) )
 * $(TR $(TD |x| $(LT) 1)    $(TD +$(INFIN))                  $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD |x| $(GT) 1)    $(TD -$(INFIN))                  $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD |x| $(LT) 1)    $(TD -$(INFIN))                  $(TD +$(INFIN))
 *      $(TD no)        $(TD no) )
 * $(TR $(TD +$(INFIN))      $(TD $(GT) 0.0)                  $(TD +$(INFIN))
 *      $(TD no)        $(TD no) )
 * $(TR $(TD +$(INFIN))      $(TD $(LT) 0.0)                  $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD -$(INFIN))      $(TD odd integer $(GT) 0.0)      $(TD -$(INFIN))
 *      $(TD no)        $(TD no) )
 * $(TR $(TD -$(INFIN))      $(TD $(GT) 0.0, not odd integer) $(TD +$(INFIN))
 *      $(TD no)        $(TD no))
 * $(TR $(TD -$(INFIN))      $(TD odd integer $(LT) 0.0)      $(TD -0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD -$(INFIN))      $(TD $(LT) 0.0, not odd integer) $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD $(PLUSMN)1.0)   $(TD $(PLUSMN)$(INFIN))          $(TD $(NAN))
 *      $(TD no)        $(TD yes) )
 * $(TR $(TD $(LT) 0.0)      $(TD finite, nonintegral)        $(TD $(NAN))
 *      $(TD no)        $(TD yes))
 * $(TR $(TD $(PLUSMN)0.0)   $(TD odd integer $(LT) 0.0)      $(TD $(PLUSMNINF))
 *      $(TD yes)       $(TD no) )
 * $(TR $(TD $(PLUSMN)0.0)   $(TD $(LT) 0.0, not odd integer) $(TD +$(INFIN))
 *      $(TD yes)       $(TD no))
 * $(TR $(TD $(PLUSMN)0.0)   $(TD odd integer $(GT) 0.0)      $(TD $(PLUSMN)0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD $(PLUSMN)0.0)   $(TD $(GT) 0.0, not odd integer) $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * )
 */

real pow(real x, real y)
{
    version (Posix) // C pow() often does not handle special values correctly
    {
        if (isnan(y))
            return y;

        if (y == 0)
            return 1;           // even if x is $(NAN)
        if (isnan(x) && y != 0)
            return x;
        if (isinf(y))
        {
            if (fabs(x) > 1)
            {
                if (signbit(y))
                    return +0.0;
                else
                    return real.infinity;
            }
            else if (fabs(x) == 1)
            {
                return real.nan;
            }
            else // < 1
            {
                if (signbit(y))
                    return real.infinity;
                else
                    return +0.0;
            }
        }
        if (isinf(x))
        {
            if (signbit(x))
            {   long i;

                i = cast(long)y;
                if (y > 0)
                {
                    if (i == y && i & 1)
                        return -real.infinity;
                    else
                        return real.infinity;
                }
                else if (y < 0)
                {
                    if (i == y && i & 1)
                        return -0.0;
                    else
                        return +0.0;
                }
            }
            else
            {
                if (y > 0)
                    return real.infinity;
                else if (y < 0)
                    return +0.0;
            }
        }

        if (x == 0.0)
        {
            if (signbit(x))
            {   long i;

                i = cast(long)y;
                if (y > 0)
                {
                    if (i == y && i & 1)
                        return -0.0;
                    else
                        return +0.0;
                }
                else if (y < 0)
                {
                    if (i == y && i & 1)
                        return -real.infinity;
                    else
                        return real.infinity;
                }
            }
            else
            {
                if (y > 0)
                    return +0.0;
                else if (y < 0)
                    return real.infinity;
            }
        }
    }
    return cidrus.степд(x, y);
}

unittest
{
    real x = 46;

    assert(pow(x,0) == 1.0);
    assert(pow(x,1) == x);
    assert(pow(x,2) == x * x);
    assert(pow(x,3) == x * x * x);
    assert(pow(x,8) == (x * x) * (x * x) * (x * x) * (x * x));
}

/****************************************
 * Simple function to compare two floating point values
 * to a specified precision.
 * Returns:
 *      1       match
 *      0       nomatch
 */

private int mfeq(real x, real y, real precision)
{
    if (x == y)
        return 1;
    if (isnan(x))
        return isnan(y);
    if (isnan(y))
        return 0;
    return fabs(x - y) <= precision;
}

/**************************************
 * To what precision is x equal to y?
 *
 * Returns: the number of mantissa bits which are equal in x and y.
 * eg, 0x1.F8p+60 and 0x1.F1p+60 are equal to 5 bits of precision.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)      $(TH y)          $(TH feqrel(x, y)))
 *      $(TR $(TD x)      $(TD x)          $(TD real.mant_dig))
 *      $(TR $(TD x)      $(TD $(GT)= 2*x) $(TD 0))
 *      $(TR $(TD x)      $(TD $(LT)= x/2) $(TD 0))
 *      $(TR $(TD $(NAN)) $(TD any)        $(TD 0))
 *      $(TR $(TD any)    $(TD $(NAN))     $(TD 0))
 *      )
 */
int feqrel(X)(X x, X y)
{
    /* Public Domain. Author: Don Clugston, 18 Aug 2005.
     */
  static assert(is(X==real) || is(X==double) || is(X==float),
        "Only float, double, and real are supported by feqrel");

  static if (X.mant_dig == 106) { // doubledouble.
     if (cast(double*)(&x)[MANTISSA_MSB] == cast(double*)(&y)[MANTISSA_MSB]) {
         return double.mant_dig
         + feqrel(cast(double*)(&x)[MANTISSA_LSB],
                  cast(double*)(&y)[MANTISSA_LSB]);
     } else {
         return feqrel(cast(double*)(&x)[MANTISSA_MSB],
                       cast(double*)(&y)[MANTISSA_MSB]);
     }
  } else static if (X.mant_dig==64 || X.mant_dig==113 || X.mant_dig==53) {

    if (x == y) return X.mant_dig; // ensure diff!=0, cope with INF.

    X diff = fabs(x - y);

    ushort *pa = cast(ushort *)(&x);
    ushort *pb = cast(ushort *)(&y);
    ushort *pd = cast(ushort *)(&diff);

    alias floatTraits!(X) F;

    // The difference in abs(exponent) between x or y and abs(x-y)
    // is equal to the number of significand bits of x which are
    // equal to y. If negative, x and y have different exponents.
    // If positive, x and y are equal to 'bitsdiff' bits.
    // AND with 0x7FFF to form the absolute value.
    // To avoid out-by-1 errors, we subtract 1 so it rounds down
    // if the exponents were different. This means 'bitsdiff' is
    // always 1 lower than we want, except that if bitsdiff==0,
    // they could have 0 or 1 bits in common.

 static if (X.mant_dig==64 || X.mant_dig==113) { // real80 or quadruple
    int bitsdiff = ( ((pa[F.EXPPOS_SHORT]&0x7FFF)
                    + (pb[F.EXPPOS_SHORT]&0x7FFF)-1)>>1)
                    - pd[F.EXPPOS_SHORT];
 } else static if (X.mant_dig==53) { // double
    int bitsdiff = (( ((pa[F.EXPPOS_SHORT]&0x7FF0)
                     + (pb[F.EXPPOS_SHORT]&0x7FF0)-0x10)>>1)
                     - (pd[F.EXPPOS_SHORT]&0x7FF0))>>4;
 }
    if (pd[F.EXPPOS_SHORT] == 0)
    {   // Difference is denormal
        // For denormals, we need to add the number of zeros that
        // lie at the start of diff's significand.
        // We do this by multiplying by 2^real.mant_dig
        diff *= F.POW2MANTDIG;
        return bitsdiff + X.mant_dig - pd[F.EXPPOS_SHORT];
    }

    if (bitsdiff > 0)
        return bitsdiff + 1; // add the 1 we subtracted before

    // Avoid out-by-1 errors when factor is almost 2.
     static if (X.mant_dig==64 || X.mant_dig==113) { // real80 or quadruple
        return (bitsdiff == 0) ? (pa[F.EXPPOS_SHORT] == pb[F.EXPPOS_SHORT]) : 0;
     } else static if (X.mant_dig==53) { // double
        if (bitsdiff == 0
          && !((pa[F.EXPPOS_SHORT] ^ pb[F.EXPPOS_SHORT])& F.EXPMASK)) {
              return 1;
        } else return 0;
     }
 } else {
    throw new НереализИскл("feqrel");
 }
}

unittest
{
   // Exact equality
   assert(feqrel(real.max,real.max)==real.mant_dig);
   assert(feqrel(0.0L,0.0L)==real.mant_dig);
   assert(feqrel(7.1824L,7.1824L)==real.mant_dig);
   assert(feqrel(real.infinity,real.infinity)==real.mant_dig);

   // a few bits away from exact equality
   real w=1;
   for (int i=1; i<real.mant_dig-1; ++i) {
      assert(feqrel(1+w*real.epsilon,1.0L)==real.mant_dig-i);
      assert(feqrel(1-w*real.epsilon,1.0L)==real.mant_dig-i);
      assert(feqrel(1.0L,1+(w-1)*real.epsilon)==real.mant_dig-i+1);
      w*=2;
   }
   assert(feqrel(1.5+real.epsilon,1.5L)==real.mant_dig-1);
   assert(feqrel(1.5-real.epsilon,1.5L)==real.mant_dig-1);
   assert(feqrel(1.5-real.epsilon,1.5+real.epsilon)==real.mant_dig-2);

   assert(feqrel(real.min/8,real.min/17)==3);;

   // Numbers that are close
   assert(feqrel(0x1.Bp+84, 0x1.B8p+84)==5);
   assert(feqrel(0x1.8p+10, 0x1.Cp+10)==2);
   assert(feqrel(1.5*(1-real.epsilon), 1.0L)==2);
   assert(feqrel(1.5, 1.0)==1);
   assert(feqrel(2*(1-real.epsilon), 1.0L)==1);

   // Factors of 2
   assert(feqrel(real.max,real.infinity)==0);
   assert(feqrel(2*(1-real.epsilon), 1.0L)==1);
   assert(feqrel(1.0, 2.0)==0);
   assert(feqrel(4.0, 1.0)==0);

   // Extreme inequality
   assert(feqrel(real.nan,real.nan)==0);
   assert(feqrel(0.0L,-real.nan)==0);
   assert(feqrel(real.nan,real.infinity)==0);
   assert(feqrel(real.infinity,-real.infinity)==0);
   assert(feqrel(-real.max,real.infinity)==0);
   assert(feqrel(real.max,-real.max)==0);
}

package: // Not public yet
/* Return the value that lies halfway between x and y on the IEEE number line.
 *
 * Formally, the результат is the arithmetic mean of the binary significands of x
 * and y, multiplied by the geometric mean of the binary exponents of x and y.
 * x and y must have the same sign, and must not be NaN.
 * Note: this function is useful for ensuring O(log n) behaviour in algorithms
 * involving a 'binary chop'.
 *
 * Special cases:
 * If x and y are within a factor of 2, (ie, feqrel(x, y) > 0), the return value
 * is the arithmetic mean (x + y) / 2.
 * If x and y are even powers of 2, the return value is the geometric mean,
 *   и3еСреднее(x, y) = sqrt(x * y).
 *
 */
T и3еСреднее(T)(T x, T y)
in {
    // both x and y must have the same sign, and must not be NaN.
    assert(signbit(x) == signbit(y));
    assert(x<>=0 && y<>=0);
}
body {
    // Runtime behaviour for contract violation:
    // If signs are opposite, or one is a NaN, return 0.
    if (!((x>=0 && y>=0) || (x<=0 && y<=0))) return 0.0;

    // The implementation is simple: cast x and y to integers,
    // average them (avoiding overflow), and cast the результат back to a floating-point number.

    alias floatTraits!(real) F;
    T u;
    static if (T.mant_dig==64) { // real80
        // There's slight additional complexity because they are actually
        // 79-bit reals...
        ushort *ue = cast(ushort *)&u;
        ulong *ul = cast(ulong *)&u;
        ushort *xe = cast(ushort *)&x;
        ulong *xl = cast(ulong *)&x;
        ushort *ye = cast(ushort *)&y;
        ulong *yl = cast(ulong *)&y;
        // Ignore the useless implicit bit. (Bonus: this prevents overflows)
        ulong m = ((*xl) & 0x7FFF_FFFF_FFFF_FFFFL) + ((*yl) & 0x7FFF_FFFF_FFFF_FFFFL);

        // Avoid ridiculous warning
        ushort e = cast(ushort)((xe[F.EXPPOS_SHORT] & 0x7FFF)
                              + (ye[F.EXPPOS_SHORT] & 0x7FFF));
        if (m & 0x8000_0000_0000_0000L) {
            ++e;
            m &= 0x7FFF_FFFF_FFFF_FFFFL;
        }
        // Now do a multi-byte right shift
        uint c = e & 1; // carry
        e >>= 1;
        m >>>= 1;
        if (c) m |= 0x4000_0000_0000_0000L; // shift carry into significand
        if (e) *ul = m | 0x8000_0000_0000_0000L; // set implicit bit...
        else *ul = m; // ... unless exponent is 0 (denormal or zero).
        // Avoid ridiculous warning
        ue[4]= cast(ushort)( e | (xe[F.EXPPOS_SHORT]& 0x8000)); // restore sign bit
    } else static if(T.mant_dig == 113) { //quadruple
        // This would be trivial if 'ucent' were implemented...
        ulong *ul = cast(ulong *)&u;
        ulong *xl = cast(ulong *)&x;
        ulong *yl = cast(ulong *)&y;
        // Multi-byte add, then multi-byte right shift.
        ulong mh = ((xl[MANTISSA_MSB] & 0x7FFF_FFFF_FFFF_FFFFL)
                  + (yl[MANTISSA_MSB] & 0x7FFF_FFFF_FFFF_FFFFL));
        // Discard the lowest bit (to avoid overflow)
        ulong ml = (xl[MANTISSA_LSB]>>>1) + (yl[MANTISSA_LSB]>>>1);
        // add the lowest bit back in, if necessary.
        if (xl[MANTISSA_LSB] & yl[MANTISSA_LSB] & 1) {
            ++ml;
            if (ml==0) ++mh;
        }
        mh >>>=1;
        ul[MANTISSA_MSB] = mh | (xl[MANTISSA_MSB] & 0x8000_0000_0000_0000);
        ul[MANTISSA_LSB] = ml;
    } else static if (T.mant_dig == double.mant_dig) {
        ulong *ul = cast(ulong *)&u;
        ulong *xl = cast(ulong *)&x;
        ulong *yl = cast(ulong *)&y;
        ulong m = (((*xl) & 0x7FFF_FFFF_FFFF_FFFFL)
                 + ((*yl) & 0x7FFF_FFFF_FFFF_FFFFL)) >>> 1;
        m |= ((*xl) & 0x8000_0000_0000_0000L);
        *ul = m;
    } else static if (T.mant_dig == float.mant_dig) {
        uint *ul = cast(uint *)&u;
        uint *xl = cast(uint *)&x;
        uint *yl = cast(uint *)&y;
        uint m = (((*xl) & 0x7FFF_FFFF) + ((*yl) & 0x7FFF_FFFF)) >>> 1;
        m |= ((*xl) & 0x8000_0000);
        *ul = m;
    } else {
        assert(0, "Not implemented");
    }
    return u;
}

unittest {
    assert(и3еСреднее(-0.0,-1e-20)<0);
    assert(и3еСреднее(0.0,1e-20)>0);

    assert(и3еСреднее(1.0L,4.0L)==2L);
    assert(и3еСреднее(2.0*1.013,8.0*1.013)==4*1.013);
    assert(и3еСреднее(-1.0L,-4.0L)==-2L);
    assert(и3еСреднее(-1.0,-4.0)==-2);
    assert(и3еСреднее(-1.0f,-4.0f)==-2f);
    assert(и3еСреднее(-1.0,-2.0)==-1.5);
    assert(и3еСреднее(-1*(1+8*real.epsilon),-2*(1+8*real.epsilon))
                 ==-1.5*(1+5*real.epsilon));
    assert(и3еСреднее(0x1p60,0x1p-10)==0x1p25);
    static if (real.mant_dig==64) { // x87, 80-bit reals
      assert(и3еСреднее(1.0L,real.infinity)==0x1p8192L);
      assert(и3еСреднее(0.0L,real.infinity)==1.5);
    }
    assert(и3еСреднее(0.5*real.min*(1-4*real.epsilon),0.5*real.min)
           == 0.5*real.min*(1-2*real.epsilon));
}

public:


/***********************************
 * Evaluate polynomial A(x) = $(SUB a, 0) + $(SUB a, 1)x + $(SUB a, 2)&sup2;
 *                          + $(SUB a,3)x&sup3; ...
 *
 * Uses Horner's rule A(x) = $(SUB a, 0) + x($(SUB a, 1) + x($(SUB a, 2)
 *                         + x($(SUB a, 3) + ...)))
 * Параметры:
 *      A =     array of coefficients $(SUB a, 0), $(SUB a, 1), etc.
 */
real poly(real x, real[] A)
in
{
    assert(A.length > 0);
}
body
{
    version (D_InlineAsm_X86)
    {
        static if (real.sizeof == 10)
        {
        // BUG: This code assumes a frame pointer in EBP.
            asm // assembler by W. Bright
            {
                // EDX = (A.length - 1) * real.sizeof
                mov     ECX,A[EBP]              ; // ECX = A.length
                dec     ECX                     ;
                lea     EDX,[ECX][ECX*8]        ;
                add     EDX,ECX                 ;
                add     EDX,A+4[EBP]            ;
                fld     real ptr [EDX]          ; // ST0 = coeff[ECX]
                jecxz   return_ST               ;
                fld     x[EBP]                  ; // ST0 = x
                fxch    ST(1)                   ; // ST1 = x, ST0 = r
                align   4                       ;
        L2:     fmul    ST,ST(1)                ; // r *= x
                fld     real ptr -10[EDX]       ;
                sub     EDX,10                  ; // deg--
                faddp   ST(1),ST                ;
                dec     ECX                     ;
                jne     L2                      ;
                fxch    ST(1)                   ; // ST1 = r, ST0 = x
                fstp    ST(0)                   ; // dump x
                align   4                       ;
        return_ST:                              ;
                ;
            }
        }
        else static if (real.sizeof == 12)
        {
            asm // assembler by W. Bright
            {
                // EDX = (A.length - 1) * real.sizeof
                mov     ECX,A[EBP]              ; // ECX = A.length
                dec     ECX                     ;
                lea     EDX,[ECX*8]             ;
                lea     EDX,[EDX][ECX*4]        ;
                add     EDX,A+4[EBP]            ;
                fld     real ptr [EDX]          ; // ST0 = coeff[ECX]
                jecxz   return_ST               ;
                fld     x[EBP]                  ; // ST0 = x
                fxch    ST(1)                   ; // ST1 = x, ST0 = r
                align   4                       ;
        L2:     fmul    ST,ST(1)                ; // r *= x
                fld     real ptr -12[EDX]       ;
                sub     EDX,12                  ; // deg--
                faddp   ST(1),ST                ;
                dec     ECX                     ;
                jne     L2                      ;
                fxch    ST(1)                   ; // ST1 = r, ST0 = x
                fstp    ST(0)                   ; // dump x
                align   4                       ;
        return_ST:                              ;
                ;
            }
        }
        else static if (real.sizeof == 16)
        {
            asm // assembler by W. Bright
            {
                // EDX = (A.length - 1) * real.sizeof
                mov     ECX,A[EBP]              ; // ECX = A.length
                dec     ECX                     ;
                lea     EDX,[ECX*8]             ;
                add     EDX,EDX                 ;
                add     EDX,A+4[EBP]            ;
                fld     real ptr [EDX]          ; // ST0 = coeff[ECX]
                jecxz   return_ST               ;
                fld     x[EBP]                  ; // ST0 = x
                fxch    ST(1)                   ; // ST1 = x, ST0 = r
                align   4                       ;
        L2:     fmul    ST,ST(1)                ; // r *= x
                fld     real ptr -16[EDX]       ;
                sub     EDX,16                  ; // deg--
                faddp   ST(1),ST                ;
                dec     ECX                     ;
                jne     L2                      ;
                fxch    ST(1)                   ; // ST1 = r, ST0 = x
                fstp    ST(0)                   ; // dump x
                align   4                       ;
        return_ST:                              ;
                ;
            }
        }
	else
	{
	    static assert(0);
	}
    }
    else
    {
        int i = A.length - 1;
        real r = A[i];
        while (--i >= 0)
        {
            r *= x;
            r += A[i];
        }
        return r;
    }
}

unittest
{
    debug (math) эхо("math.poly.unittest\n");
    real x = 3.1;
    static real pp[] = [56.1, 32.7, 6];

    assert( poly(x, pp) == (56.1L + (32.7L + 6L * x) * x) );
}

/* **********************************
 * Building block functions, they
 * translate to a single x87 instruction.
 */

real yl2x(real x, real y);	// y * log2(x)
real yl2xp1(real x, real y);	// y * log2(x + 1)

unittest
{
    version (INLINE_YL2X)
    {
	assert(yl2x(1024, 1) == 10);
	assert(yl2xp1(1023, 1) == 10);
    }
}


