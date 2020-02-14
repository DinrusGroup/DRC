/*******************************************************************************

        copyright:      Copyright (c) 2006 Keinfarbton. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2006

        author:         Keinfarbton & Kris

*******************************************************************************/

module stringz;

export:

/*********************************
 * Convert array of симs to a C-style 0 terminated string.
 * Providing a врм will use that instead of the heap, where
 * appropriate.
 */

сим* вТкст0 (ткст s, ткст врм=null)
{
        static ткст empty = "\0";

        auto len = s.length;
        if (s.ptr)
            if (len is 0)
                s = empty;
            else
               if (s[len-1] != 0)
                  {
                  if (врм.length <= len)
                      врм = new сим[len+1];
                  врм [0..len] = s;
                  врм [len] = 0;
                  s = врм;
                  }
        return s.ptr;
}

/*********************************
 * Convert a series of ткст to C-style 0 terminated строки, using 
 * врм as a workspace and прм as a place to put the resulting сим*'s.
 * This is handy for efficiently converting multiple строки at once.
 *
 * Returns a populated slice of прм
 *
 * Since: 0.99.7
 */

сим*[] вТкст0 (ткст врм, сим*[] прм, ткст[] строки...)
{
        assert (прм.length >= строки.length);

        auto len = строки.length;
        foreach (s; строки)
                 len += s.length;
        if (врм.length < len)
            врм.length = len;

        foreach (i, s; строки)
                {
                прм[i] = вТкст0 (s, врм);
                врм = врм [s.length + 1 .. len];
                }
        return прм [0 .. строки.length];
}

/*********************************
 * Convert a C-style 0 terminated string to an array of сим
 */

ткст изТкст0 (сим* s)
{
        return s ? s[0 .. длинтекс0(s)] : null;
}

/*********************************
 * Convert array of wсимs s[] to a C-style 0 terminated string.
 */

шим* вТкст16н (шткст s)
{
        if (s.ptr)
            if (! (s.length && s[$-1] is 0))
                   s = s ~ "\0"w;
        return s.ptr;
}

/*********************************
 * Convert a C-style 0 terminated string to an array of шим
 */

шткст изТкст16н (шим* s)
{
        return s ? s[0 .. длинтекс0(s)] : null;
}

/*********************************
 * Convert array of dсимs s[] to a C-style 0 terminated string.
 */

дим* вТкст32н (юткст s)
{
        if (s.ptr)
            if (! (s.length && s[$-1] is 0))
                   s = s ~ "\0"d;
        return s.ptr;
}

/*********************************
 * Convert a C-style 0 terminated string to an array of дим
 */

юткст изТкст32н (дим* s)
{
        return s ? s[0 .. длинтекс0(s)] : null;
}

/*********************************
 * portable strlen
 */

т_мера длинтекс0(T) (T* s)
{
        т_мера i;

        if (s)
            while (*s++)
                   ++i;
        return i;
}


