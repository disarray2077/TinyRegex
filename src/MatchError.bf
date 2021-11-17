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
		GreedyGroupNotImplemented,
		GroupNotImplemented // only if TR_NO_GROUPS is defined.
	}
}
