namespace TinyRegex.Internal
{
	static
	{
		public static bool IsAlphaNum(this char8 self)
		{
			return self.IsLetterOrDigit || self == '_';
		}

		public static bool IsWhiteSpace(this char8 self)
		{
			switch (self)
			{
			case ' ', '\v', '\f', '\t', '\n', '\r': return true;
			default: return false;
			}
		}
	}
}
