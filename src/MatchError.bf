namespace TinyRegex
{
	public enum MatchError
	{
		None,
		NotMatched,
		EndsWithBackslash,
		MissingRightSquareBracket,
		MissingRightCurlyBrace,
		MissingRightParenthesis,
		DigitExpectedInQuantifier,
		QuantifierMinGreaterThanMax,
		BadEscape,
		BadQuantifierFormat,
		InvalidQuantifierTarget,
		BranchNotImplemented,
		GreedyGroupNotImplemented
	}
}
