module drc.ast.NodesEnum;

/// Перечисляет категории узла.
enum КатегорияУзла : бкрат
{
  Неопределённый,
  Декларация,
  Инструкция,
  Выражение,
  Тип,
  Иное // Параметр
}

/// Список имен классов, наследующих от Узел.
static const сим[][] г_именаКлассов = [
  // Декларации:
  "СложнаяДекларация",
  "ПустаяДекларация",
  "НелегальнаяДекларация",
  "ДекларацияМодуля",
  "ДекларацияИмпорта",
  "ДекларацияАлиаса",
  "ДекларацияТипдефа",
  "ДекларацияПеречня",
  "ДекларацияЧленаПеречня",
  "ДекларацияКласса",
  "ДекларацияИнтерфейса",
  "ДекларацияСтруктуры",
  "ДекларацияСоюза",
  "ДекларацияКонструктора",
  "ДекларацияСтатическогоКонструктора",
  "ДекларацияДеструктора",
  "ДекларацияСтатическогоДеструктора",
  "ДекларацияФункции",
  "ДекларацияПеременных",
  "ДекларацияИнварианта",
  "ДекларацияЮниттеста",
  "ДекларацияОтладки",
  "ДекларацияВерсии",
  "ДекларацияСтатическогоЕсли",
  "ДекларацияСтатическогоПодтверди",
  "ДекларацияШаблона",
  "ДекларацияНов",
  "ДекларацияУдали",
  "ДекларацияЗащиты",
  "ДекларацияКлассаХранения",
  "ДекларацияКомпоновки",
  "ДекларацияРазложи",
  "ДекларацияПрагмы",
  "ДекларацияСмеси",

  // Инструкции:
  "СложнаяИнструкция",
  "НелегальнаяИнструкция",
  "ПустаяИнструкция",
  "ИнструкцияТелаФункции",
  "ИнструкцияМасштаб",
  "ИнструкцияСМеткой",
  "ИнструкцияВыражение",
  "ИнструкцияДекларация",
  "ИнструкцияЕсли",
  "ИнструкцияПока",
  "ИнструкцияДелайПока",
  "ИнструкцияПри",
  "ИнструкцияСКаждым",
  "ИнструкцияДиапазонСКаждым", // D2.0
  "ИнструкцияЩит",
  "ИнструкцияРеле",
  "ИнструкцияДефолт",
  "ИнструкцияДалее",
  "ИнструкцияВсё",
  "ИнструкцияИтог",
  "ИнструкцияПереход",
  "ИнструкцияДля",
  "ИнструкцияСинхр",
  "ИнструкцияПробуй",
  "ИнструкцияЛови",
  "ИнструкцияИтожь",
  "ИнструкцияСтражМасштаба",
  "ИнструкцияБрось",
  "ИнструкцияЛетучее",
  "ИнструкцияБлокАсм",
  "ИнструкцияАсм",
  "ИнструкцияАсмРасклад",
  "ИнструкцияНелегальныйАсм",
  "ИнструкцияПрагма",
  "ИнструкцияСмесь",
  "ИнструкцияСтатическоеЕсли",
  "ИнструкцияСтатическоеПодтверди",
  "ИнструкцияОтладка",
  "ИнструкцияВерсия",

  // Выражения:
  "НелегальноеВыражение",
  "ВыражениеУсловия",
  "ВыражениеЗапятая",
  "ВыражениеИлиИли",
  "ВыражениеИИ",
  "ВыражениеИли",
  "ВыражениеИИли",
  "ВыражениеИ",
  "ВыражениеРавно",
  "ВыражениеРавенство",
  "ВыражениеОтнош",
  "ВыражениеВхо",
  "ВыражениеЛСдвиг",
  "ВыражениеПСдвиг",
  "ВыражениеБПСдвиг",
  "ВыражениеПлюс",
  "ВыражениеМинус",
  "ВыражениеСоедини",
  "ВыражениеУмножь",
  "ВыражениеДели",
  "ВыражениеМод",
  "ВыражениеПрисвой",
  "ВыражениеПрисвойЛСдвиг",
  "ВыражениеПрисвойПСдвиг",
  "ВыражениеПрисвойБПСдвиг",
  "ВыражениеПрисвойИли",
  "ВыражениеПрисвойИ",
  "ВыражениеПрисвойПлюс",
  "ВыражениеПрисвойМинус",
  "ВыражениеПрисвойДел",
  "ВыражениеПрисвойУмн",
  "ВыражениеПрисвойМод",
  "ВыражениеПрисвойИИли",
  "ВыражениеПрисвойСоед",
  "ВыражениеАдрес",
  "ВыражениеПреИнкр",
  "ВыражениеПреДекр",
  "ВыражениеПостИнкр",
  "ВыражениеПостДекр",
  "ВыражениеДереф",
  "ВыражениеЗнак",
  "ВыражениеНе",
  "ВыражениеКомп",
  "ВыражениеВызов",
  "ВыражениеНов",
  "ВыражениеНовАнонКласс",
  "ВыражениеУдали",
  "ВыражениеКаст",
  "ВыражениеИндекс",
  "ВыражениеСрез",
  "ВыражениеМасштабМодуля",
  "ВыражениеИдентификатор",
  "ВыражениеСпецСема",
  "ВыражениеТочка",
  "ВыражениеЭкземплярШаблона",
  "ВыражениеЭтот",
  "ВыражениеСупер",
  "ВыражениеНуль",
  "ВыражениеДоллар",
  "БулевоВыражение",
  "ЦелВыражение",
  "ВыражениеРеал",
  "ВыражениеКомплекс",
  "ВыражениеСим",
  "ТекстовоеВыражение",
  "ВыражениеЛитералМассива",
  "ВыражениеЛитералАМассива",
  "ВыражениеПодтверди",
  "ВыражениеСмесь",
  "ВыражениеИмпорта",
  "ВыражениеТипа",
  "ВыражениеИдТипаТочка",
  "ВыражениеИдТипа",
  "ВыражениеЯвляется",
  "ВыражениеРодит",
  "ВыражениеЛитералФункции",
  "ВыражениеТрактовки", // D2.0
  "ВыражениеИницПроц",
  "ВыражениеИницМассива",
  "ВыражениеИницСтруктуры",
  "ВыражениеТипАсм",
  "ВыражениеСмещениеАсм",
  "ВыражениеСегАсм",
  "ВыражениеАсмПослеСкобки",
  "ВыражениеАсмСкобка",
  "ВыражениеЛокальногоРазмераАсм",
  "ВыражениеАсмРегистр",

  // Типы:
  "НелегальныйТип",
  "ИнтегральныйТип",
  "КвалифицированныйТип",
  "ТМасштабМодуля",
  "ТИдентификатор",
  "ТТип",
  "ТЭкземплярШаблона",
  "ТУказатель",
  "ТМассив",
  "ТФункция",
  "ТДелегат",
  "ТУказательНаФункСи",
  "ТипКлассОснова",
  "ТКонст", // D2.0
  "ТИнвариант", // D2.0

  // Параметры:
  "Параметр",
  "Параметры",
  "ПараметрАлиасШаблона",
  "ПараметрТипаШаблона",
  "ПараметрЭтотШаблона", // D2.0
  "ПараметрШаблонЗначения",
  "ПараметрКортежШаблона",
  "ПараметрыШаблона",
  "АргументыШаблона",
];

/// Генерирует члены перечня ВидУзла.
ткст генерируйЧленыВидовУзла()
{
  ткст текст;
  foreach (имяКласса; г_именаКлассов)
    текст ~= имяКласса ~ ",";
  return текст;
}
// pragma(сооб, генерируйЧленыВидовУзла());

version(DDoc)
  /// Вид узла идентифицирует каждый класс, наследующий от Узел.
  enum ВидУзла : бкрат;
else
mixin(
  "enum ВидУзла : бкрат"
  "{"
    ~ генерируйЧленыВидовУзла ~
  "}"
);
