using System.Diagnostics;
using System;

namespace TinyRegex.Internal
{
	static
	{
		// Returns the number slice of the string starting at the supplied index.
		public static Result<StringView> GetNumberSlice(this StringView self, int index = 0)
		{
			Debug.Assert(self.Length > index && index >= 0);

			int i = index;
			for (; i < self.Length; i++)
			{
				if (!self[i].IsDigit)
					break;
			}

			if (i == index)
				return .Err;

			return .Ok(.(self.Ptr + index, i - index));
		}
	}
}