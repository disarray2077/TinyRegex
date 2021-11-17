using System;

namespace TinyRegex.Internal
{
	typealias MatchResult = Result<int, MatchError>;

	static
	{
		public static mixin TryMatch(var result)
		{
			if (result case .Err(var err))
				return .Err((.)err);
			result.Get()
		}

		public static mixin TryMatchOpt(var result)
		{
			if (result case .Err(var err))
			{
				if ((MatchError)err != .NotMatched)
					return .Err((.)err);
			}
			(result case .Ok, result.Get(0))
		}
	}
}
