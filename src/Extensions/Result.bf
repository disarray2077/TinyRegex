using System;

namespace TinyRegex.Internal
{
	static
	{
		public static T? ToNullable<T>(this Result<T> result)
			where T : struct
		{
			switch (result)
			{
			case .Ok(let inner): return inner;
			case .Err: return null;
			}
		}

		public static T? ToNullable<T, TErr>(this Result<T, TErr> result)
			where T : struct
			where TErr : var
		{
			switch (result)
			{
			case .Ok(let inner): return inner;
			case .Err: return null;
			}
		}
	}
}
