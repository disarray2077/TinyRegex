using System;
using TinyRegex;
using internal TinyRegex;

namespace TinyRegexTests
{
	public static class Basic
	{
		[Test]
		public static void MFTest()
		{
			FullMatchAssert!("\\s+", "\t \n");
			NoMatchAssert!("\\S+", "\t \n");
			FullMatchAssert!("[\\s]+", "\t \n");
			NoMatchAssert!("[\\S]+", "\t \n");
			FullMatchAssert!("[0-9]+", "12345");
			FullMatchAssert!("^.*\\\\.*$", "c:\\Tools");
			FullMatchAssert!("\\d\\d?:\\d\\d?:\\d\\d?", "00:00:00");

			FullMatchAssert!("^[0-9][a-z]-?$", "0a-");
			FullMatchAssert!("^[0-9][a-z]-?$", "0a");
			PartialMatchAssert!("[0-9][a-z]-?", "1=4cheeses", 2, 2);
		}

		[Test]
		public static void GreedTest()
		{
			NoMatchAssert!(@"a+a", "a");
			NoMatchAssert!(@"aa+a", "aa");
			NoMatchAssert!(@"a+aaa+a", "aaaa");
			FullMatchAssert!(@"a+aaa+a", "aaaaa");
		}

		[Test]
		public static void EmailTest()
		{
			FullMatchAssert!(@"^[\w\.\+\-]+\@[\w]+\.[a-z]{2,3}$", "example@example.com");
			FullMatchAssert!(@"^[\w\.\+\-]+\@[\w]+\.[a-z]{2,3}$", "a+1@b.com");
			NoMatchAssert!(@"^[\w\.\+\-]+\@[\w]+\.[a-z]{2,3}$", "ab.com");
			NoMatchAssert!(@"^[\w\.\+\-]+\@[\w]+\.[a-z]{2,3}$", "@ab.com");
			NoMatchAssert!(@"^[\w\.\+\-]+\@[\w]+\.[a-z]{2,3}$", "a@.com");
		}

		[Test]
		public static void UsernameTest()
		{
			FullMatchAssert!("^[a-zA-Z0-9_-]{3,16}$", "Regex");
			NoMatchAssert!("^[a-zA-Z0-9_-]{3,16}$", "dorit@");
			NoMatchAssert!("^[a-zA-Z0-9_-]{3,16}$", "as");
			NoMatchAssert!("^[a-zA-Z0-9_-]{3,16}$", "abcdefghijklmnopq");
		}

		[Test]
		public static void StarTest()
		{
			FullMatchAssert!("^a*b+c$", "bc");
			FullMatchAssert!("^a*b+c$", "abc");
			NoMatchAssert!("^a*b+c$", "ac");
			NoMatchAssert!("^a*b+c$", "acbc");
		}

		[Test]
		public static void QuantifierTest()
		{
			NoMatchAssert!(@"^_{3}abc$", "_abc");
			FullMatchAssert!(@"^_{3}abc$", "___abc");
			NoMatchAssert!(@"^_{3}abc$", "____abc");
			FullMatchAssert!(@"^_{3,}abc$", "______________abc");
			FullMatchAssert!(@"^_{3,4}abc$", "____abc");
			NoMatchAssert!(@"^_{,4}abc$", "____abc"); // invalid regex
			NoMatchAssert!(@"^_{3,4}abc$", "_____abc");
			FullMatchAssert!(@"^_{0,1}abc$", "abc");
			FullMatchAssert!(@"^_{0,1}abc$", "_abc");
		}

		[Test]
		public static void GroupTest()
		{
			if (Regex.NoGroups)
			{
				Console.WriteLine("TR_NO_GROUPS defined, test skipped.");
			}
			else
			{
				FullMatchAssert!(@"^(abc){2,3}abc$", "abcabcabc");
				FullMatchAssert!(@"^([abc]{3}){2,3}abc$", "abcabcabc");
				NoMatchAssert!(@"^(abc){3}abc$", "abcabcabc");
				PartialMatchAssert!("[01]?[0-9][0-9]?", "0.0.1", 1);
			}
		}

		[Test]
		public static void NotImplementedTest()
		{
			Test.Assert((Regex.Match(@"a|b", "a") case .Err(let err1)) && err1 == .BranchNotImplemented);
			if (!Regex.NoGroups)
			{
				Test.Assert((Regex.Match(@"a(a|b)", "a") case .Err(let err2)) && err2 == .BranchNotImplemented);
				Test.Assert((Regex.Match(@"a(b+)b", "abb") case .Err(let err3)) && err3 == .GreedyGroupNotImplemented);
				Test.Assert((Regex.Match(@"a(b(c?))b", "abb") case .Err(let err4)) && err4 == .GreedyGroupNotImplemented);
				Test.Assert((Regex.Match(@"a(b(c)d?)", "abc") case .Err(let err5)) && err5 == .GreedyGroupNotImplemented);
				FullMatchAssert!(@"a(b(c))d?", "abc");
			}
		}
	}
}
