using System;
using TinyRegex;

namespace TinyRegexTests
{
	static
	{
		public static mixin FullMatchAssert(var regex, var text)
		{
			switch (Regex.Match(regex, text))
			{
			case .Ok(let match):
				Test.Assert(match.Length == text.Length, "Incorrect match length.");
			case .Err(let err):
				Test.FatalError(scope $"Error: {err}");
			}
		}

		public static mixin PartialMatchAssert(var regex, var text, var expectedLength)
		{
			switch (Regex.Match(regex, text))
			{
			case .Ok(let match):
				Test.Assert(match.Length == expectedLength, "Incorrect match length.");
			case .Err(let err):
				Test.FatalError(scope $"Error: {err}");
			}
		}

		public static mixin PartialMatchAssert(var regex, var text, var expectedOffset, var expectedLength)
		{
			switch (Regex.Match(regex, text))
			{
			case .Ok(let match):
				Test.Assert(match.Index == expectedOffset, "Incorrect match offset.");
				Test.Assert(match.Length == expectedLength, "Incorrect match length.");
			case .Err(let err):
				Test.FatalError(scope $"Error: {err}");
			}
			
		}

		public static mixin NoMatchAssert(var regex, var text)
		{
			Match match;

			Test.Assert(!(Regex.Match(regex, text) case .Ok(out match)),
				match.Length > 0 ? scope $"Matched: {StringView(text, match.Index, match.Length)}" : "Error As Expected");
		}
	}
}
