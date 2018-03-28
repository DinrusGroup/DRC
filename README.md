﻿# DRC (DinRus Compiler) 
 
__Компилятор Динрус, написанный на самом Динрусе.
В проекте содержатся основные рабочие материалы. 
Используется руссифицированная копия dil, адаптированная под новую среду выполнения. 
**Dil** - это проект турецкого программиста **Азиза Кёксала**,
находящийся в данный момент в недоработанном состоянии.
Фактически готов фронт-энд, - работа над бэк-эндом ещё только в плане.
Если есть желающие выполнить такое полезное дело, ждём в данном проекте!__
 
## :sparkles: **Добро пожаловать!**:sparkles:

# Справочник Разработчика ДИНРУС РНЦП

Вы читаете справочную информацию, относящуюся к разработке *русской национальной цифровой платформы Динрус (Динрус РНЦП)*. [**Репозиторий ДИНРУС РНЦП**](http://github.com/DinrusGroup) находится по данной ссылке. Другой [**репозиторий для готовых пакетов Динрус**](http://github.com/dinrus) предназначен для последующей автоматизированной работы с пакетами через сеть с помощью специальных инструментов с системой контроля версий исходного кода.

### Установка инcтрументария Динрус
Чтобы установить весь необходимый инструментарий, посетите [**репозиторий инструментария Динрус**](http://github.com/DinrusGroup/DinrusBin)  и скачайте его издание (релиз) последней версии. 

### Установка НРПО Динрус
[**Набор для разработки программного обеспечения (НРПО) Динрус**](http://github.com/DinrusGroup/Dinrus), также известный под английским названием SDK (Software Development Kit), расположен по указанной ссылке. Его можно скачать так же, как и набор инструментов, либо использовать клиент системы контроля версий Git или SVN. На ОС Windows удобнее всего использовать [**TortoiseSVN**](http://tortoisesvn.net).

# План работ

[x]1. Ввести два набора ключевых слов - англ. и рус., которые могли бы использоваться в равноправном режиме.

[x]2. Создать базу для анализа и компиляции, которая в будущем использовалась бы для быстрого дополнения и введения в язык новых ключевых слов и семантических оборотов.

[x]3. Создать отдельную бибилиотеку dll и присоединить к ней exe с функцией компилятора, чтобы использовать это в трёх режимах:
а) для компиляции;
б) для предварительной обработки и подготовки кода;
в) для прямой тулчейн (цепочки инструментов), которая могла бы использоваться из IDE без обращения к самому exe компилятора, а непосредственно.

[x]4. Попытаться усовершенствовать компилятор, используя специальную базу данных с исходниками модулей пакетов, что станет предлогом отказа от промежуточных библиотек (в пользу объектных СУБД): если использовать эту систему, то меняя код в БД (совершенствуя его непосредственно в ней), можно рекомпилировать объектный код в базе данных. Кроме того, это позволяет синхронизировать библиотеки (=централизовать их). Таким образом, в будущем не потребуется наличие полного набора на каждом компьютере разработчика. Одним словом, вместо интеллисенса будет достаточно базы данных с заголовочными интерфейсами (в языке на данный момент это .di файлы); причём даже эти файлы могут быть в одном централизованном интернет-хранилище и фактически программисты будут работать с одним и тем же интерфейсом и набором инструмента посредством новейшей сериализационной модели работы (= облачной технологии).

[x]5. Создание языка программирования Динрус, чем мы здесь с вами и занимаемся, - это стратегически важный момент, так как **данный язык должен достичь стадии УНИВЕРСАЛЬНОСТИ, т.е. он ПРЕТЕНДУЕТ на РОЛЬ БУДУЩЕГО в ПРОГРАММИРОВАНИИ всех рускоязычных обитателей Земли, - МЕТАНАУЧНОГО БУДУЩЕГО!)))**


