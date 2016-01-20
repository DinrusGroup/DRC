/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.lexer.Identifier;

import drc.lexer.TokensEnum,
       drc.lexer.IdentsEnum;
import common;

/// Represents an identifier as defined in the D specs.
///
/// $(PRE
///  Идентификатор := IdStart IdChar*
///  IdStart := "_" | Letter
///  IdChar := IdStart | "0"-"9"
///  Letter := UniAlpha
/// )
/// See_Also:
///  Unicode alphas are defined in Unicode 5.0.0.
align(1)
struct Идентификатор
{
  ткст ткт; /// The UTF-8 ткст of the identifier.
  TOK вид;   /// The сема вид.
  ВИД видИд; /// Only for predefined identifiers.

  static Идентификатор* opCall(ткст ткт, TOK вид)
  {
    auto ид = new Идентификатор;
    ид.ткт = ткт;
    ид.вид = вид;
    return ид;
  }

  static Идентификатор* opCall(ткст ткт, TOK вид, ВИД видИд)
  {
    auto ид = new Идентификатор;
    ид.ткт = ткт;
    ид.вид = вид;
    ид.видИд = видИд;
    return ид;
  }

  бцел вХэш()
  {
    бцел хэш;
    foreach(c; ткт) {
      хэш *= 11;
      хэш += c;
    }
    return хэш;
  }
}
// pragma(сооб, Идентификатор.sizeof.stringof);
