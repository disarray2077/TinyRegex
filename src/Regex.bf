using System;
using System.Diagnostics;
using System.Collections;
using TinyRegex.Internal;

namespace TinyRegex
{
	public static class Regex
	{
		// Used internally for skipping tests
#if TR_NO_GROUPS
		internal const bool NoGroups = true;
#else
		internal const bool NoGroups = false;
#endif

		/// Replaces strings that match a regular expression pattern using a custom function.
		/// @param regex The regular expression pattern to match.
		/// @param text The string to search for a match and which will be modified.
		/// @param replaceFunc A custom function that modifies each match.
		public static void ReplaceAll<TFunc>(StringView regex, String text, TFunc replaceFunc)
			where TFunc : delegate void(String match)
		{
			for (let match in Matches(regex, text))
			{
				String matchStr = scope String(match.Value);
				replaceFunc(matchStr);

				if (matchStr != match.Value)
				{
					text.Remove(match.Index, match.Length);
					text.Insert(match.Index, matchStr);
					@match.[Friend]Reset(text, match.Index + matchStr.Length);
				}
			}
		}

		/// Replaces strings that match a regular expression pattern with a specified replacement string.
		/// @param regex The regular expression pattern to match.
		/// @param text The string to search for a match and which will be modified.
		/// @param replace The replacement string.
		public static void ReplaceAll(StringView regex, String text, StringView replace)
		{
			for (let match in Matches(regex, text))
			{
				if (replace != match.Value)
				{
					text.Remove(match.Index, match.Length);
					text.Insert(match.Index, replace);
					@match.[Friend]Reset(text, match.Index + replace.Length);
				}
			}
		}

		/// Replaces the first string that matches a regular expression pattern using a custom function.
		/// @param regex The regular expression pattern to match.
		/// @param text The string to search for a match and which will be modified.
		/// @param replaceFunc A custom function that modifies the match.
		public static void Replace<TFunc>(StringView regex, String text, TFunc replaceFunc)
			where TFunc : delegate void(String match)
		{
			Match match = ?;
			if (!(Regex.Match(regex, text) case .Ok(out match)))
				return;

			String matchStr = scope String(match.Value);
			replaceFunc(matchStr);

			if (matchStr != match.Value)
			{
				text.Remove(match.Index, match.Length);
				text.Insert(match.Index, matchStr);
			}
		}

		/// Replaces the first string that matches a regular expression pattern with a specified replacement string.
		/// @param regex The regular expression pattern to match.
		/// @param text The string to search for a match and which will be modified.
		/// @param replace The replacement string.
		public static void Replace(StringView regex, String text, StringView replace)
		{
			Match match = ?;
			if (!(Regex.Match(regex, text) case .Ok(out match)))
				return;

			if (replace != match.Value)
			{
				text.Remove(match.Index, match.Length);
				text.Insert(match.Index, replace);
			}
		}

		/// Lazily enumerates over all matches of a regular expression pattern.
		/// @param regex The regular expression pattern to match.
		/// @param text The string to search for a match.
		public static MatchEnumerator Matches(StringView regex, StringView text)
		{
			return MatchEnumerator(regex, text);
		}

		/// Indicates whether the regular expression finds a match in the input string.
		/// @param regex The regular expression pattern to match.
		/// @param text The string to search for a match.
		public static bool IsMatch(StringView regex, StringView text)
		{
			return Match(regex, text) case .Ok;
		}

		/// Searches an input string for a substring that matches a regular expression pattern.
		/// @param regex The regular expression pattern to match.
		/// @param text The string to search for a match.
		public static Result<Match, MatchError> Match(StringView regex, StringView text)
		{
			if (regex[0] == '^')
			{
				switch (MatchStartOnly(regex.Substring(1), text))
				{
				case .Ok(let matchLength):
					return .Ok(.(0, text.Substring(0, matchLength)));
				case .Err(let err):
					return .Err(err);
				}
			}

			var text;
			let textStart = text.Ptr;
			for (;; text.Adjust(1))
			{
				switch (MatchStartOnly(regex, text))
				{
				case .Ok(let matchLength):
					return .Ok(.(text.Ptr - textStart, text.Substring(0, matchLength)));
				case .Err(let err):
					if (err != .NotMatched || text.IsEmpty)
						return .Err(err);
				}
			}
		}

		private static MatchResult MatchStartOnly(StringView regex, StringView text, int32 depth = 0)
		{
			var regex, text;
			int matchLength = 0;

			outerLoop: while (true)
			{
				if (regex.IsEmpty)
					return .Ok(matchLength);

				let ch = regex[0];

				if (ch == '|')
					return .Err(.BranchNotImplemented);

				if (ch == '*' || ch == '+' || ch == '?' || ch == '{')
					return .Err(.InvalidQuantifierTarget);

				int nodeLength = ?;
				switch (GetNodeLength(regex))
				{
				case .Ok(out nodeLength):
					break;
				case .Err(let err):
					return .Err(err);
				}

				let nextRegex = regex.Substring(nodeLength);
				if (!nextRegex.IsEmpty)
				{
					let nextCh = nextRegex[0];
					switch (nextCh)
					{
					case '?':
						Debug.Assert(GetNodeLength(nextRegex) == 1);
						return matchLength + TryMatch!(MatchQuantifier(regex, nextRegex.Substring(1), text, 0, 1, depth));
					case '+':
						Debug.Assert(GetNodeLength(nextRegex) == 1);
						return matchLength + TryMatch!(MatchQuantifier(regex, nextRegex.Substring(1), text, 1, int.MaxValue, depth));
					case '{':
						switch (GetQuantifierInfo(nextRegex))
						{
						case .Ok(let quantifierInfo):
							Debug.Assert(quantifierInfo.nodeLength >= 3);
							return matchLength + TryMatch!(MatchQuantifier(regex, nextRegex.Substring(quantifierInfo.nodeLength), text, quantifierInfo.minMax.min, quantifierInfo.minMax.max, depth));
						case .Err(let err):
							return .Err(err);
						}
					case '*':
						Debug.Assert(GetNodeLength(nextRegex) == 1);
						switch (MatchQuantifier(regex, nextRegex.Substring(1), text, 1, int.MaxValue, depth))
						{
						case .Ok(let outLength):
							return matchLength + outLength;
						case .Err:
							regex = nextRegex.Substring(1);
							continue outerLoop;
						}
					case '|':
						return .Err(.BranchNotImplemented);
					default:
						break;
					}
				}
				else if (ch == '$')
				{
					if (text.IsEmpty)
						return matchLength;
					break;
				}

				(let matched, let outLength) = TryMatchOpt!(TryMatchExpr(regex, text, depth));

				if (!matched)
					break;

				matchLength += outLength;
				text.Adjust(outLength);
				regex = nextRegex;
			}

			return .Err(.NotMatched);
		}

		private static MatchResult GetNodeLength(StringView regex)
		{
			if (regex.IsEmpty)
				return 0;

			switch (regex[0])
			{
			case '[':
				bool inEscape = false;
				for (int i < regex.Length)
				{
					switch (regex[i])
					{
					case ']':
						if (!inEscape)
							return i + 1;
						inEscape = false;
					case '\\':
						inEscape = !inEscape;
					default:
						inEscape = false;
					}
				}
				return .Err(.MissingRightSquareBracket);
			case '{':
				bool comma = false, num = false;
				for (int i = 1; i < regex.Length; i++)
				{
					switch (regex[i])
					{
					case ',':
						if (!num)
							return .Err(.DigitExpectedInQuantifier);
						else if (comma)
							return .Err(.BadQuantifierFormat);
						comma = true;
					case '}':
						if (!num)
							return .Err(.DigitExpectedInQuantifier);
						return i + 1;
					default:
						if (!regex[i].IsDigit)
							return .Err(.DigitExpectedInQuantifier);
						num = true;
					}
				}
				return .Err(.MissingRightCurlyBrace);
			case '(':
				int depth = 1;
				bool inEscape = false;
				for (int i = 1; i < regex.Length; i++)
				{
					switch (regex[i])
					{
					case '(':
						if (!inEscape)
							depth++;
						inEscape = false;
					case ')':
						if (!inEscape && --depth == 0)
							return i + 1;
						inEscape = false;
					case '\\':
						inEscape = !inEscape;
					default:
						inEscape = false;
					}
				}
				return .Err(.MissingRightParenthesis);
			case '\\':
				if (regex.Length == 1)
					return .Err(.EndsWithBackslash);
				return 2;
			}

			return 1;
		}

		private static Result<(int nodeLength, (int min, int max) minMax), MatchError>
			GetQuantifierInfo(StringView regex)
		{
			int? min = null, max = null;
			int commaPos = 0;

			for (int i = 1; i < regex.Length; i++)
			{
				switch (regex[i])
				{
				case ',':
					if (min.HasValue) // more than one comma (invalid)
						return .Err(.BadQuantifierFormat);
					if (i == 1) // {,n} (invalid)
						return .Err(.DigitExpectedInQuantifier);
					min = int.Parse(regex.Substring(1, i - 1)).ToNullable();
					commaPos = i;
				case '}':
					if (commaPos > 0)
					{
						if (commaPos != i - 1) // {m,n}
						{
							Debug.Assert(min.HasValue);
							max = int.Parse(regex.Substring(commaPos + 1, i - commaPos - 1)).ToNullable();
						}
						else if (min.HasValue) // {m,}
							max = int.MaxValue;
					}
					else if (i != 1) // {m}
					{
						min = int.Parse(regex.Substring(1, i - 1)).ToNullable();
						max = min;
					}
					else // {} (invalid)
						return .Err(.DigitExpectedInQuantifier);
					if (max.HasValue && min > max)
						return .Err(.QuantifierMinGreaterThanMax);
					return .Ok((i + 1, (min.Value, max.Value)));
				default:
					if (!regex[i].IsDigit)
						return .Err(.DigitExpectedInQuantifier);
				}
			}

			return .Err(.MissingRightCurlyBrace);
		}

		private static MatchResult TryMatchExpr(StringView regex, StringView text, int32 depth)
		{
			Debug.Assert(depth >= 0);

			if (regex[0] == '(')
			{
#if !TR_NO_GROUPS
				// all groups are non-capturing for now, so let's just use this to skip "?:".
				let nonCapturing = regex.Length >= 3 && regex[1] == '?' && regex[2] == ':';
				let regexOffset = nonCapturing ? 3 : 1;
				switch (GetNodeLength(regex))
				{
				case .Ok(let val):
					var depth;
					return MatchStartOnly(regex.Substring(regexOffset, val - 1 - regexOffset), text, ++depth);
				case .Err(let err):
					return .Err(err);
				}
#else
				return .Err(.GroupNotImplemented);
#endif
			}

			if (text.IsEmpty)
				return .Err(.NotMatched);

			if (TryMatchOne(regex, text[0]) case .Ok(let matched))
				return matched ? .Ok(1) : .Err(.NotMatched);

			return .Err(.BadEscape);
		}

		private static Result<bool> TryMatchEscape(char8 regexCh, char8 textCh)
		{
			switch (regexCh)
			{
			case 'd':
				return textCh.IsDigit;
			case 'D':
				return !textCh.IsDigit;
			case 'w':
				return textCh.IsAlphaNum();
			case 'W':
				return !textCh.IsAlphaNum();
			case 's':
				return textCh.IsWhiteSpace();
			case 'S':
				return !textCh.IsWhiteSpace();

			// common escapes
			case 't':
				return textCh == '\t';
			case 'n':
				return textCh == '\n';

			default:
				return regexCh == textCh;
			}
		}

		private static Result<bool> TryMatchOne(StringView regex, char8 textCh)
		{
			let regexCh = regex[0];
			switch (regexCh)
			{
			case '\\':
				return TryMatchEscape(regex[1], textCh);
			case '.':
				return textCh != '\n';
			case '[':
				if (regex[1] == '^')
				{
					if (TryMatchCharSet(regex.Substring(2), textCh) case .Ok(let val))
						return !val;
					return .Err;
				}
				return TryMatchCharSet(regex.Substring(1), textCh);
			default:
				return regexCh == textCh;
			}
		}

		private static Result<bool> TryMatchCharSet(StringView regex, char8 textCh)
		{
			for (int i = 0; i < regex.Length;)
			{
				let regexCh = regex[i];
				if (regexCh == ']')
					return false;

				if (regex[i + 1] == '-' && regex[i + 2] != ']')
				{
					if (textCh >= regexCh && textCh <= regex[i + 2])
						return true;
					i += 3;
				}
				else
				{
					if (regexCh == '\\')
					{
						if (Try!(TryMatchEscape(regex[i + 1], textCh)))
							return true;
						i += 2;
					}
					else if (regexCh == '.')
						return textCh != '\n';
					else
					{
						if (regexCh == textCh)
							return true;
						i++;
					}
				}
			}

			Debug.Assert(false, "This should never be reached?");
			return false;
		}

		private static MatchResult MatchQuantifier(StringView regexLeft, StringView regexRight, StringView text, int minMatches, int maxMatches, int32 depth)
		{
#if !TR_NO_GROUPS
			// There would be no greed if Min == Max.
			if (depth != 0 && minMatches != maxMatches)
				return .Err(.GreedyGroupNotImplemented);
#endif

			var regexRight, text;
			int matchCount = 0;
			int matchLength = 0;

			while (!text.IsEmpty)
			{
				(let matched, let outLength) = TryMatchOpt!(TryMatchExpr(regexLeft, text, depth));

				if (!matched)
					break;

				text.Adjust(outLength);
				
				Debug.Assert((matchCount == 0 && matchLength == 0) || outLength == matchLength);
				matchLength = outLength;
				matchCount++;

				if (matchCount >= maxMatches)
					break;
			}

			// TODO: Find any way to make this code better
			if (matchCount >= minMatches)
			{
				// Rollback if it was too greedy.
				while (true)
				{
					if (MatchStartOnly(regexRight, text, depth) case .Ok(var outLength))
					{
						outLength += matchCount * matchLength;
						return .Ok(outLength);
					}
	
					if (matchCount == minMatches ||
						matchCount == 0)
						break;

					matchCount--;
	
					// Adjust() doesn't allow rollback. (as it should)
					text.Ptr -= matchLength;
					text.Length += matchLength;
				}
			}

			return .Err(.NotMatched);
		}
	}
}
