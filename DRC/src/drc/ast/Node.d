/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.ast.Node;

import common;

public import drc.lexer.Token;
public import drc.ast.NodesEnum;

/// Коневой класс всех элементов синтаксического древа Динрус.
abstract class Узел
{
  КатегорияУзла категория; /// Категория данного узла.
  ВидУзла вид; /// Вид данного узла.
  Узел[] отпрыски; // Will be probably removed sometime.
  Сема* начало, конец; /// Семы в начале и конце данного узла.

  /// Строит объект Узел.
  this(КатегорияУзла категория)
  {
    assert(категория != КатегорияУзла.Неопределённый);
    this.категория = категория;
  }

  проц  установиСемы(Сема* начало, Сема* конец)
  {
    this.начало = начало;
    this.конец = конец;
  }

  Класс устСемы(Класс)(Класс узел)
  {
    узел.установиСемы(this.начало, this.конец);
    return узел;
  }

  проц  добавьОтпрыск(Узел отпрыск)
  {
    assert(отпрыск !is null, "ошибка в " ~ this.classinfo.name);
    this.отпрыски ~= отпрыск;
  }

  проц  добавьОпцОтпрыск(Узел отпрыск)
  {
    отпрыск is null || добавьОтпрыск(отпрыск);
  }

  проц  добавьОтпрыски(Узел[] отпрыски)
  {
    assert(отпрыски !is null && delegate{
      foreach (отпрыск; отпрыски)
        if (отпрыск is null)
          return нет;
      return да; }(),
      "ошибка в " ~ this.classinfo.name
    );
    this.отпрыски ~= отпрыски;
  }

  проц  добавьОпцОтпрыски(Узел[] отпрыски)
  {
    отпрыски is null || добавьОтпрыски(отпрыски);
  }

  /// Returns a reference в Класс if this узел can be cast в it.
  Класс Является(Класс)()
  {
    if (вид == mixin("ВидУзла." ~ Класс.stringof))
      return cast(Класс)cast(ук)this;
    return null;
  }

  /// Casts this узел в Класс.
  Класс в(Класс)()
  {
    return cast(Класс)cast(ук)this;
  }

  /// Returns a deep копируй of this узел.
  abstract Узел копируй();

  /// Returns a shallow копируй of this object.
  final Узел dup()
  {
    // Find out the размер of this object.
    alias typeof(this.classinfo.иниц[0]) byte_t;
    т_мера размер = this.classinfo.иниц.length;
    // Copy this object's данные.
    byte_t[] данные = (cast(byte_t*)this)[0..размер].dup;
    return cast(Узел)данные.ptr;
  }

  /// Этот ткст is mixed into the constructor of a class that inherits
  /// из Узел. It sets the член вид.
  const ткст установить_вид = `this.вид = mixin("ВидУзла." ~ typeof(this).stringof);`;
}
