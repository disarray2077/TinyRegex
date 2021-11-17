# TinyRegex

Small and portable [Regular Expression](https://en.wikipedia.org/wiki/Regular_expression) (regex) library written in BeefLang.
Heavily based on <https://github.com/kokke/tiny-regex-c>

Supports a subset of the syntax and semantics of the Python standard library implementation (the re-module).

### Notable features and omissions

- Small code: ~500 SLOC.
- No use of dynamic memory allocation (i.e. no calls to `new` / `delete`).
- To avoid call-stack exhaustion, iterative searching is preferred over recursive by default.
- All groups are non-capturing groups, there's no support for capturing groups or named capture: `(^P<name>group)` etc.
- Greedy quantifiers can't be used inside of groups.
- Thorough testing : [exrex](https://github.com/asciimoo/exrex) is used to randomly generate test-cases from regex patterns, which are fed into the regex code for verification.

### API

This is the public API:

```cs
/// Indicates whether the regular expression finds a match in the input string.
/// @param regex The regular expression pattern to match.
/// @param text The string to search for a match.
public static bool IsMatch(StringView regex, StringView text);

/// Searches an input string for a substring that matches a regular expression pattern.
/// @param regex The regular expression pattern to match.
/// @param text The string to search for a match.
public static Result<Match, MatchError> Match(StringView regex, StringView text)

/// Lazily enumerates over all matches of a regular expression pattern.
/// @param regex The regular expression pattern to match.
/// @param text The string to search for a match.
public static MatchEnumerator AllMatches(StringView regex, StringView text);

/// Replaces the first string that matches a regular expression pattern with a specified replacement string.
/// @param regex The regular expression pattern to match.
/// @param text The string to search for a match and which will be modified.
/// @param replace The replacement string.
public static void Replace(StringView regex, String text, StringView replace);

/// Replaces the first string that matches a regular expression pattern using a custom function.
/// @param regex The regular expression pattern to match.
/// @param text The string to search for a match and which will be modified.
/// @param replaceFunc A custom function that modifies the match.
public static void Replace<TFunc>(StringView regex, String text, TFunc replaceFunc)
  where TFunc : delegate void(String match);

/// Replaces strings that match a regular expression pattern with a specified replacement string.
/// @param regex The regular expression pattern to match.
/// @param text The string to search for a match and which will be modified.
/// @param replace The replacement string.
public static void ReplaceAll(StringView regex, String text, StringView replace);

/// Replaces strings that match a regular expression pattern using a custom function.
/// @param regex The regular expression pattern to match.
/// @param text The string to search for a match and which will be modified.
/// @param replaceFunc A custom function that modifies each match.
public static void ReplaceAll<TFunc>(StringView regex, String text, TFunc replaceFunc)
  where TFunc : delegate void(String match);
```

### Supported regex-operators

The following features / regex-operators are supported by this library.

- `.`        Dot, matches any character
- `^`        Start anchor, matches beginning of string
- `$`        End anchor, matches end of string
- `*`        Asterisk, match zero or more (greedy)
- `+`        Plus, match one or more (greedy)
- `?`        Question, match zero or one (greedy)
- `{m,n}`    Quantifier, match from m to n (greedy if m != n)
- `[abc]`    Character class, match if one of {'a', 'b', 'c'}
- `[^abc]`   Inverted class, match if NOT one of {'a', 'b', 'c'}
- `[a-zA-Z]` Character ranges, the character set of the ranges { a-z | A-Z }
- `(expr)`   Groups, they are non-capturing by default.
- `\s`       Whitespace, \t \f \r \n \v and spaces
- `\S`       Non-whitespace
- `\w`       Alphanumeric, [a-zA-Z0-9_]
- `\W`       Non-alphanumeric
- `\d`       Digits, [0-9]
- `\D`       Non-digits

### Examples

Example of usage:

```cs
if (Regex.Match(@"[Hh]ello [Ww]orld\s*[!]?", "ahem.. 'hello world !' ..") case .Ok(let match))
{
  Console.WriteLine($"Matched '{match.Value}' at index {match.Index}, {match.Length} chars long.");
}
```

For more usage examples I encourage you to look at the code in the `Tests` project.
