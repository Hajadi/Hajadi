#!/usr/bin/env python3
"""Static sanity checks for the Dart sources.

Not a substitute for `flutter analyze` — it is what CI can run before the
Flutter SDK is available, and it catches the three mistakes that actually
happen when a large codebase is written in one pass:

  1. unbalanced braces / parens / brackets;
  2. relative imports pointing at files that do not exist;
  3. localization getters that are not in the generated catalog;
  4. package imports that are not declared in pubspec.yaml.

Usage: python3 scripts/check_dart_sources.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
TEST = ROOT / "test"

SDK_PACKAGES = {"flutter", "flutter_test", "flutter_localizations", "jwenn_met"}


def strip_code(source: str) -> str:
    """Blank out comments and string literals so delimiters inside them
    do not confuse the balance check."""
    out = []
    i = 0
    n = len(source)
    while i < n:
        ch = source[i]
        two = source[i:i + 2]
        if two == "//":
            j = source.find("\n", i)
            i = n if j < 0 else j
            continue
        if two == "/*":
            j = source.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        if source[i:i + 3] in ("'''", '"""'):
            quote = source[i:i + 3]
            j = source.find(quote, i + 3)
            i = n if j < 0 else j + 3
            continue
        if ch in "'\"":
            # Dart interpolation can nest braces inside a string; keep the
            # braces so `${...}` blocks still balance.
            j = i + 1
            buf = []
            while j < n:
                if source[j] == "\\":
                    j += 2
                    continue
                if source[j] == ch:
                    j += 1
                    break
                if source[j] == "$" and j + 1 < n and source[j + 1] == "{":
                    depth = 0
                    k = j + 1
                    while k < n:
                        if source[k] == "{":
                            depth += 1
                        elif source[k] == "}":
                            depth -= 1
                            if depth == 0:
                                k += 1
                                break
                        k += 1
                    buf.append(source[j + 1:k])
                    j = k
                    continue
                if source[j] == "\n":
                    break
                j += 1
            out.append(" ")
            out.append("".join(buf))
            i = j
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def check_balance(path: pathlib.Path, code: str) -> list[str]:
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    line = 1
    for ch in code:
        if ch == "\n":
            line += 1
        elif ch in "([{":
            stack.append((ch, line))
        elif ch in ")]}":
            if not stack or stack[-1][0] != pairs[ch]:
                return [f"{path}: unbalanced '{ch}' on line {line}"]
            stack.pop()
    if stack:
        opener, opened_at = stack[-1]
        return [f"{path}: '{opener}' opened on line {opened_at} is never closed"]
    return []


def main() -> int:
    problems: list[str] = []

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    declared = set(
        re.findall(r"^  ([a-z_0-9]+):", pubspec, flags=re.MULTILINE)
    ) | SDK_PACKAGES

    catalog = (LIB / "core" / "localization" / "strings.dart").read_text(
        encoding="utf-8"
    )
    catalog_members = set(re.findall(r"String (?:get )?(\w+)", catalog))

    dart_files = sorted(LIB.rglob("*.dart")) + sorted(TEST.rglob("*.dart"))
    for path in dart_files:
        source = path.read_text(encoding="utf-8")
        code = strip_code(source)
        problems += check_balance(path, code)

        for match in re.finditer(r"""import\s+'([^']+)'""", source):
            target = match.group(1)
            if target.startswith("package:"):
                package = target.split(":", 1)[1].split("/", 1)[0]
                if package not in declared:
                    problems.append(f"{path}: undeclared package '{package}'")
            elif target.startswith("dart:"):
                continue
            else:
                resolved = (path.parent / target).resolve()
                if not resolved.exists():
                    problems.append(f"{path}: import not found -> {target}")

        # Localization getters, reached either as `s.foo` or `context.l10n.foo`.
        # The lookbehind keeps `import 'strings.dart'` out of the match.
        for match in re.finditer(
            r"(?<![\w'\"/])\b(?:s|l10n)\.([a-z]\w*)", source
        ):
            member = match.group(1)
            if member not in catalog_members and member not in {
                "raw",
                "sub",
                "supportedLocales",
                "localizationsDelegates",
            }:
                problems.append(
                    f"{path}: '{member}' is not in the localization catalog"
                )

    if problems:
        for problem in sorted(set(problems)):
            print(f"error: {problem}", file=sys.stderr)
        print(f"\n{len(set(problems))} problem(s)", file=sys.stderr)
        return 1

    print(f"checked {len(dart_files)} Dart files — no structural problems")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
