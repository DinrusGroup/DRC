﻿module common;

public import io.Stdout;
public import text.convert.Layout, text.convert.Format;
alias Стдвыв выдай;

проц ошибнс(ткст ткт){Стдош(ткт).нс;}
проц скажи(ткст ткт){выдай(ткт);}
проц скажи(цел ч){выдай.форматируй("{}", ч);}
проц скажинс(ткст ткт){выдай(ткт).нс;}
проц нс(){выдай("").нс;}
проц таб(){выдай("\t");}

