using System;
using TinyRegex;

namespace TinyRegexTests
{
	public static class Utilities
	{
		[Test]
		public static void AllMatchesTest()
		{
			for (let match in Regex.Matches("[0-9][A-z]", "0a---3b---6c"))
			{
				Test.Assert(
					match.Value == "0a"
					|| match.Value == "3b"
					|| match.Value == "6c"
				);
			}

			for (let match in Regex.Matches("0x[0-9A-Fa-f]{2,8}", "0xdeadbeef---0x3k21---0x6c----0x"))
			{
				Test.Assert(
					match.Value == "0xdeadbeef"
					|| match.Value == "0x6c"
				);
			}

			int matchCount = 0;
			for (let match in Regex.Matches("[0-9]", "1234567890"))
				matchCount += 1;
			Test.Assert(matchCount == 10);

			matchCount = 0;
			for (let match in Regex.Matches("[0-9][A-Z]", "1A2B3C4D5E6F7G8H9I0J"))
				matchCount += 1;
			Test.Assert(matchCount == 10);
		}

		[Test]
		public static void ReplaceTest()
		{
			String testStr = scope .("int id = 0;");
			Regex.Replace(@"\d", testStr, "1337");
			Test.Assert(testStr == "int id = 1337;");

			Regex.Replace(@"\d33\d", testStr,
				(match) => {
					match.Set("2077");
				});
			Test.Assert(testStr == "int id = 2077;");

			Regex.Replace(@"\d+", testStr, "0xFFFFFFFF");
			Test.Assert(testStr == "int id = 0xFFFFFFFF;");

			Regex.Replace(@"0x[0-9A-Fa-f]{2,8}", testStr,
				(match) => {
					match.Set("0");
				});
			Test.Assert(testStr == "int id = 0;");
		}

		[Test]
		public static void ReplaceAll()
		{
			String testStr = scope .("int id1 = 1337; int id2 = 1337; int id3 = 1337;");
			Regex.ReplaceAll(@"\d{2,}", testStr, "<Avocado>");
			Test.Assert(testStr == "int id1 = <Avocado>; int id2 = <Avocado>; int id3 = <Avocado>;");

			let rand = scope Random(524754213);
			Regex.ReplaceAll(@"<\w+>", testStr,
				(match) => {
					match.Clear();
					match.Append("<");
					match.Append(rand.NextS64().ToString(.. scope .()));
					match.Append(">");
				});

			let rand2 = scope Random(524754213);
			Regex.ReplaceAll(@"<-?\d+>", testStr,
				(match) => {
					match.Remove(0, 1);
					match.RemoveFromEnd(1);
					let num = int64.Parse(match);
					Test.Assert(num == rand2.NextS64());
					match.Set("<OK>");
				});
			Test.Assert(testStr == "int id1 = <OK>; int id2 = <OK>; int id3 = <OK>;");

			Regex.ReplaceAll(@"<OK>", testStr, "0");
			Test.Assert(testStr == "int id1 = 0; int id2 = 0; int id3 = 0;");
		}
	}
}
