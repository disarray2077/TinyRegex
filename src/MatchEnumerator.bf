using System.Collections;
using System;
using System.Diagnostics;

namespace TinyRegex
{
	struct MatchEnumerator : IEnumerator<Match>
	{
		StringView mRegex;
		char8* mInitialPtr;
		StringView mText;
		Match mCurMatch;

		public this(StringView regex, StringView text)
		{
			mRegex = regex;
			mInitialPtr = text.Ptr;
			mText = text;
			mCurMatch = default(Match);
		}

		public Match Current
		{
		    get
			{
				return mCurMatch;
			}
		}

		private void Reset(String text, int offset) mut
		{
			mInitialPtr = text.Ptr;
			mText = text.Substring(offset, text.Length - offset);
			mCurMatch = default(Match);
		}

		public bool MoveNext() mut
		{
			if (mRegex[0] == '^')
			{
				// The start of the string was already matched.
				if (!mCurMatch.Value.IsNull)
					return false;

				switch (Regex.[Friend]MatchStartOnly(mRegex.Substring(1), mText))
				{
				case .Ok(let matchLength):
					mCurMatch = .(0, mText.Substring(0, matchLength));
					return true;
				case .Err(let err):
					return false;
				}
			}

			mText.Adjust(mCurMatch.Length);
			if (mText.IsEmpty)
				return false;

			for (;; mText.Adjust(1))
			{
				switch (Regex.[Friend]MatchStartOnly(mRegex, mText))
				{
				case .Ok(let matchLength):
					mCurMatch = .(mText.Ptr - mInitialPtr, mText.Substring(0, matchLength));
					return true;
				case .Err(let err):
					if (err != .NotMatched || mText.IsEmpty)
						return false;
				}
			}
		}

		public void Dispose()
		{
		}

		public Result<Match> GetNext() mut
		{
			if (!MoveNext())
				return .Err;
			return Current;
		}
	}
}
