using System;

namespace TinyRegex
{
	struct Match : this(int Index, StringView Value)
	{
		public int Length => Value.Length;
	}
}
