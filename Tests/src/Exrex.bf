using System;
using System.Diagnostics;
using System.IO;

namespace TinyRegexTests
{
	public static class Exrex
	{
		private const int TEST_MULTIPLIER = 10;

		private static readonly String mTestPatterns =
			"""
			\\d+\\w?\\D\\d
			\\s+[a-zA-Z0-9?]*
			\\w*\\d?\\w\\?
			[^\\d]+\\\\?\\s
			[^\\w][^-1-4]
			[^\\w]
			[^1-4]
			[^-1-4]
			[^\\d]+\\s?[\\w]*
			a+b*[ac]*.+.*.[\\.].
			a?b[ac*]*.?[\\]+[?]?
			[1-5-]+[-1-2]-[-]
			[-1-3]-[-]+
			[1-5]+[-1-2]-[\\-]
			[-1-2]*
			\\s?[a-fKL098]+-?
			[\\-]*
			[\\\\]+
			[0-9a-fA-F]+
			[1379][2468][abcdef]
			[012345-9]?[0123-789]
			[012345-9]
			[0-56789]
			[abc-zABC-Z]
			[a\\d]?1234
			.*123faerdig
			.?\\w+jsj$
			[?to][+to][?ta][*ta]
			\\d+
			[a-z]+
			\\s+[a-zA-Z0-9?]*
			\\w
			\\d
			[\\d]
			[^\\d]
			[^-1-4]
			""";

		private static readonly String mTestNegPatterns =
			"""
			\\d+
			[a-z]+
			\\s+[a-zA-Z0-9?]*
			^\\w
			^\\d
			[\\d]
			^[^\\d]
			[^\\w]+
			^[\\w]+
			^[^0-9]
			[a-z].[A-Z]
			[-1-3]-[-]+
			[1-5]+[-1-2]-[\\-]
			[-0-9]+
			[\\-]+
			[\\\\]+
			[0-9a-fA-F]+
			[1379][2468][abcdef]
			[012345-9]
			[0-56789]
			.*123faerdig
			""";

		public static Result<void> UnQuoteString(StringView str, String outString)
		{
			if (str.Length < 2)
				return .Err;

			var ptr = str.Ptr;

			if ((*ptr != '\'' && ptr[str.Length - 1] != '\'') && (*ptr != '"' && ptr[str.Length - 1] != '"'))
			{
				return .Err;
			}

			ptr++;
			char8* endPtr = ptr + str.Length - 2;

			while (ptr < endPtr)
			{
				char8 c = *(ptr++);
				if (c == '\\')
				{
					if (ptr == endPtr)
						return .Err;

					char8 nextC = *(ptr++);
					switch (nextC)
					{
					case '\'': outString.Append("'");
					case '\"': outString.Append("\"");
					case '\\': outString.Append("\\");
					case '0': outString.Append("\0");
					case 'a': outString.Append("\a");
					case 'b': outString.Append("\b");
					case 'f': outString.Append("\f");
					case 'n': outString.Append("\n");
					case 'r': outString.Append("\r");
					case 't': outString.Append("\t");
					case 'v': outString.Append("\v");
					case 'x': outString.Append((char8)int32.Parse(StringView(ptr, 2), .AllowHexSpecifier)); ptr += 2;
					default:
						return .Err;
					}
					continue;
				}

				outString.Append(c);
			}

			return .Ok;
		}

		[Test]
		public static void Test()
		{
			let startInfo = scope ProcessStartInfo();
			startInfo.SetFileNameAndArguments("python -i");
			startInfo.SetWorkingDirectory(@"D:\BeefLang\TinyRegex\Tests"); // BROKEN: Directory.GetCurrentDirectory(.. scope .()));
			startInfo.UseShellExecute = false;
			startInfo.RedirectStandardInput = true;
			startInfo.RedirectStandardOutput = true;
			startInfo.CreateNoWindow = true;

			let proc = scope SpawnedProcess();
			if (proc.Start(startInfo) case .Err)
			{
				Console.WriteLine("Couldn't launch python, make sure that you have python installed.");
				Console.WriteLine("Test skipped.");
				return;
			}

			let input = scope FileStream();
			let sw = scope StreamWriter(input, System.Text.Encoding.UTF8, 4096) { AutoFlush = true };
			proc.AttachStandardInput(input);

			let output = scope FileStream();
			let sr = scope StreamReader(output);
			proc.AttachStandardOutput(output);

			sw.WriteLine("import exrex");

			for (int i = 0; i < TEST_MULTIPLIER; i++)
			{
				for (let pattern in mTestPatterns.Split('\n'))
				{
					sw.WriteLine($"print(repr(exrex.getone(R'{pattern}')))");
					let exampleQuoted = sr.ReadLine(.. scope .());
					let exampleUnquoted = UnQuoteString(exampleQuoted, .. scope .());
					FullMatchAssert!(pattern, exampleUnquoted);
				}
			}

			sw.WriteLine(
				"""
				import random, string, re
				def gen_no_match(pattern, minlen=1, maxlen=50, maxattempts=500):
					nattempts = 0
					while True:
						nattempts += 1
						ret = "".join([random.choice(string.printable) for i in range(random.Random().randint(minlen, maxlen))])
						if re.findall(pattern, ret) == []:
							return ret
						if nattempts >= maxattempts:
							raise Exception("Could not generate string that did not match the regex pattern '%s' after %d attempts" % (pattern, nattempts))
				""");
			sw.WriteLine(""); // finish method

			for (int i = 0; i < TEST_MULTIPLIER; i++)
			{
				for (let pattern in mTestNegPatterns.Split('\n'))
				{
					sw.WriteLine($"print(repr(gen_no_match(R'{pattern}')))");
					let exampleQuoted = sr.ReadLine(.. scope .());
					let exampleUnquoted = UnQuoteString(exampleQuoted, .. scope .());
					NoMatchAssert!(pattern, exampleUnquoted);
				}
			}
		}
	}
}
