#!/usr/bin/env python3
"""Generate lib/core/localization/strings.dart from assets/i18n/en.json.

Run after adding or renaming a key:

    python3 scripts/gen_strings.py

The English catalog is the source of truth: every key becomes a typed getter
(or a method, when the string carries {placeholders}). The script also fails
loudly if fr/ht are missing keys or have mismatched placeholders.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
I18N = ROOT / "assets" / "i18n"
OUT = ROOT / "lib" / "core" / "localization" / "strings.dart"

DART_KEYWORDS = {
    "assert", "break", "case", "catch", "class", "const", "continue", "default",
    "do", "else", "enum", "extends", "false", "final", "finally", "for", "if",
    "in", "is", "new", "null", "rethrow", "return", "super", "switch", "this",
    "throw", "true", "try", "var", "void", "while", "with",
}


def placeholders(value: str) -> list[str]:
    seen: list[str] = []
    for name in re.findall(r"\{(\w+)\}", value):
        if name not in seen:
            seen.append(name)
    return seen


def main() -> int:
    en = json.loads((I18N / "en.json").read_text(encoding="utf-8"))
    problems: list[str] = []

    for code in ("fr", "ht"):
        other = json.loads((I18N / f"{code}.json").read_text(encoding="utf-8"))
        for key, value in en.items():
            if key not in other:
                problems.append(f"{code}: missing key '{key}'")
            elif set(placeholders(value)) != set(placeholders(other[key])):
                problems.append(f"{code}: placeholder mismatch on '{key}'")
        for key in other:
            if key not in en:
                problems.append(f"{code}: unknown key '{key}' (not in en.json)")

    for key in en:
        if key in DART_KEYWORDS:
            problems.append(f"en: key '{key}' is a Dart keyword; rename it")
        if not re.fullmatch(r"[a-z][A-Za-z0-9]*", key):
            problems.append(f"en: key '{key}' must be lowerCamelCase")

    if problems:
        for problem in problems:
            print(f"error: {problem}", file=sys.stderr)
        return 1

    lines: list[str] = [
        "// GENERATED FILE — do not edit by hand.",
        "// Run `python3 scripts/gen_strings.py` after changing assets/i18n/en.json.",
        "",
        "import 'app_localizations.dart';",
        "",
        "/// Typed access to every translated string in the catalog.",
        "class Strings {",
        "  const Strings(this._l);",
        "",
        "  final AppLocalizations _l;",
        "",
    ]

    for key, value in en.items():
        names = placeholders(value)
        comment = value.replace("\n", " ")
        lines.append(f"  /// en: {comment}")
        if not names:
            lines.append(f"  String get {key} => _l.raw('{key}');")
        else:
            params = ", ".join(f"Object? {n}" for n in names)
            args = ", ".join(f"'{n}': {n}" for n in names)
            lines.append(
                f"  String {key}({{required {params.replace(', ', ', required ')}}}) =>"
            )
            lines.append(
                f"      _l.sub('{key}', <String, Object?>{{{args}}});"
            )
        lines.append("")

    lines.append("}")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} ({len(en)} keys)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
