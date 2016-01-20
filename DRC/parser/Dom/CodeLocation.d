module drc.dom.CodeLocation;

	class МестоКода : IComparable!(МестоКода), IEquatable!(МестоКода)
	{
		 const МестоКода пустое = МестоКода(-1, -1);

		  цел колонка, строка;

		 this(цел колонка, цел строка)
		{
			this.колонка = колонка;
			this.строка = строка;
		}

		 бул пустое_ли(){	return колонка < 1 && строка < 1;}

		 override ткст вТкст()
		{
			//return форматируй("(строка {1}, колонка {0})", колонка, строка);
		}

		 override т_хэш вХэш()
		{
			//return unchecked(87 * колонка.вХэш() ^ строка.вХэш());
		}

		 override цел opCmp(Объект obj)
		{
			if (!obj is typeof(МестоКода)) return false;
			return cast(МестоКода)obj == this;
		}

		 цел opCmp(МестоКода др){ return this == др; }

		 static bool operator ==(МестоКода a, МестоКода b)
		{
			return a.колонка == b.колонка && a.строка == b.строка;
		}

		 static bool operator !=(МестоКода a, МестоКода b)
		{
			return a.колонка != b.колонка || a.строка != b.строка;
		}

		 static bool operator <(МестоКода a, МестоКода b)
		{
			if (a.строка < b.строка)
				return true;
			else if (a.строка == b.строка)
				return a.колонка < b.колонка;
			else
				return false;
		}

		 static bool operator >(МестоКода a, МестоКода b)
		{
			if (a.строка > b.строка)
				return true;
			else if (a.строка == b.строка)
				return a.колонка > b.колонка;
			else
				return false;
		}

		 static bool operator <=(МестоКода a, МестоКода b)
		{
			return !(a > b);
		}

		 static bool operator >=(МестоКода a, МестоКода b)
		{
			return !(a < b);
		}

		 цел CompareTo(МестоКода other)
		{
			if (this == other)
				return 0;
			if (this < other)
				return -1;
			else
				return 1;
		}
	}

