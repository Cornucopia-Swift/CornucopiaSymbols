#!/usr/bin/env python3
"""
Walks Vendor/open-symbols/ and regenerates per-set Swift Package targets:
  - Sources/CornucopiaSymbols<Set>/<Set>.swift          (the enum)
  - Sources/CornucopiaSymbols<Set>/Resources/<Set>.xcassets/...
  - Sources/CornucopiaSymbols<Set>/ATTRIBUTION.md       (license + counts)
  - Sources/CornucopiaSymbols<Set>/LICENSE.txt          (upstream license text)

Also writes a top-level THIRD_PARTY_LICENSES.md aggregating the per-set entries.

Run AFTER Scripts/sync-symbols.sh.

Usage:
    Scripts/generate.py                  # all sets
    Scripts/generate.py feather lucide   # subset
"""

from __future__ import annotations

import json
import keyword
import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VENDOR_ROOT = ROOT / "Vendor" / "open-symbols"
SOURCES_ROOT = ROOT / "Sources"


@dataclass(frozen=True)
class SymbolSet:
    """One upstream symbol set."""
    upstream_dir: str         # folder name inside Vendor/open-symbols/
    target_suffix: str        # appended to "CornucopiaSymbols" → SPM target name
    swift_enum: str           # name of the generated Swift enum
    pretty_name: str          # human-friendly display name
    license_short: str        # short license id
    upstream_url: str         # canonical upstream project URL

ALL_SETS: list[SymbolSet] = [
    SymbolSet("feather",                       "Feather",       "Feather",       "Feather",                          "MIT",        "https://feathericons.com/"),
    SymbolSet("heroicons",                     "Heroicons",     "Heroicons",     "Heroicons",                        "MIT",        "https://heroicons.com/"),
    SymbolSet("lucide",                        "Lucide",        "Lucide",        "Lucide",                           "ISC",        "https://lucide.dev/"),
    SymbolSet("font-awesome",                  "FontAwesome",   "FontAwesome",   "Font Awesome (Free)",              "CC BY 4.0",  "https://fontawesome.com/"),
    SymbolSet("remix",                         "Remix",         "Remix",         "Remix",                            "Apache-2.0", "https://remixicon.com/"),
    SymbolSet("tabler",                        "Tabler",        "Tabler",        "Tabler",                           "MIT",        "https://tabler.io/icons"),
    SymbolSet("pictogrammers-material-design", "Pictogrammers", "Pictogrammers", "Pictogrammers Material Design",    "Apache-2.0", "https://pictogrammers.com/library/mdi/"),
]


# ---------- license texts --------------------------------------------------

# Font Awesome Free icons are CC BY 4.0 — but the upstream open-symbols
# repository ships no LICENSE file in the font-awesome/ subdirectory, only a
# README mention. Bundle the canonical CC BY 4.0 text so we ship a
# legally-complete distribution. Source: https://creativecommons.org/licenses/by/4.0/legalcode
CC_BY_4_0_TEXT = """\
Attribution 4.0 International (CC BY 4.0)

You are free to:

  Share — copy and redistribute the material in any medium or format
  Adapt — remix, transform, and build upon the material for any purpose,
          even commercially.

  The licensor cannot revoke these freedoms as long as you follow the
  license terms.

Under the following terms:

  Attribution — You must give appropriate credit, provide a link to the
                license, and indicate if changes were made. You may do so
                in any reasonable manner, but not in any way that suggests
                the licensor endorses you or your use.

  No additional restrictions — You may not apply legal terms or
                technological measures that legally restrict others from
                doing anything the license permits.

Notices:

  You do not have to comply with the license for elements of the material
  in the public domain or where your use is permitted by an applicable
  exception or limitation.

  No warranties are given. The license may not give you all of the
  permissions necessary for your intended use. For example, other rights
  such as publicity, privacy, or moral rights may limit how you use the
  material.

The full legal text is available at:
  https://creativecommons.org/licenses/by/4.0/legalcode

This file is bundled by CornucopiaSymbols to satisfy the attribution
requirement of CC BY 4.0 for the Font Awesome Free icons. The icons
themselves are © Fonticons, Inc. (https://fontawesome.com/) under CC BY 4.0.
"""


def find_upstream_license(upstream_dir: Path) -> Path | None:
    """Look for the upstream license file (case-insensitive)."""
    candidates = ["LICENSE", "License", "license", "LICENSE.txt", "COPYING", "NOTICE"]
    for name in candidates:
        path = upstream_dir / name
        if path.is_file():
            return path
    return None


def upstream_license_text(symset: SymbolSet) -> tuple[str, str]:
    """Return (license_text, source_description) for a symbol set."""
    upstream_dir = VENDOR_ROOT / symset.upstream_dir
    found = find_upstream_license(upstream_dir)
    if found is not None:
        return found.read_text(encoding="utf-8"), f"Vendor/open-symbols/{symset.upstream_dir}/{found.name}"
    if symset.license_short == "CC BY 4.0":
        return CC_BY_4_0_TEXT, "canonical CC BY 4.0 text (upstream ships no LICENSE file)"
    raise SystemExit(
        f"No upstream license file for {symset.upstream_dir} and no built-in fallback."
    )


# ---------- naming ---------------------------------------------------------

# Swift identifier sanitisation. Asset filenames from upstream use kebab-case,
# sometimes with dots (Font Awesome's ".fill" SF-Symbols variant convention),
# occasionally with underscores or digits.
_KEBAB_RE = re.compile(r"[-_.]+")
_NON_IDENT_RE = re.compile(r"[^A-Za-z0-9]")


def case_name_from_filename(stem: str) -> str:
    """Convert an upstream symbol filename (without .svg) into a Swift case name.

    Rules:
      - kebab/underscore/dot separators → camelCase
      - leading digits  → prefix with underscore (Swift identifiers can't start with a digit)
      - reserved keywords → wrap in backticks at emission time (handled by caller)
      - any remaining non-identifier chars are stripped
    """
    parts = [p for p in _KEBAB_RE.split(stem) if p]
    if not parts:
        return "_unnamed"
    # First part lowercased, rest title-cased.
    first = parts[0].lower()
    rest = "".join(p[:1].upper() + p[1:].lower() if p else "" for p in parts[1:])
    name = first + rest
    name = _NON_IDENT_RE.sub("", name)
    if not name:
        return "_unnamed"
    if name[0].isdigit():
        name = "_" + name
    return name


def needs_backticks(name: str) -> bool:
    return keyword.iskeyword(name) or name in {
        # Swift-only keywords / contextual keywords commonly seen in icon names.
        "class", "struct", "enum", "protocol", "func", "var", "let",
        "if", "else", "for", "while", "do", "switch", "case", "default",
        "break", "continue", "return", "throw", "throws", "rethrows",
        "import", "init", "deinit", "self", "super", "true", "false", "nil",
        "any", "some", "where", "as", "is", "in", "operator", "precedence",
        "associativity", "left", "right", "none", "infix", "prefix", "postfix",
        "static", "public", "private", "fileprivate", "internal", "open",
        "extension", "typealias", "associatedtype", "subscript", "guard",
        "defer", "repeat", "fallthrough", "lazy", "weak", "unowned",
        "convenience", "dynamic", "final", "override", "required",
        "indirect", "mutating", "nonmutating", "optional", "set", "get",
        "willSet", "didSet",
        "Type", "Protocol",
    }


# ---------- emit -----------------------------------------------------------

def asset_catalog_contents() -> str:
    return json.dumps({"info": {"version": 1, "author": "xcode"}}, indent=2) + "\n"


def symbolset_contents(svg_filename: str) -> str:
    return json.dumps({
        "info": {"version": 1, "author": "xcode"},
        "symbols": [{"filename": svg_filename, "idiom": "universal"}],
    }, indent=2) + "\n"


def write_if_changed(path: Path, content: str | bytes) -> bool:
    """Write only if content differs. Returns True if we wrote."""
    mode_b = isinstance(content, (bytes, bytearray))
    if path.exists():
        existing = path.read_bytes() if mode_b else path.read_text(encoding="utf-8")
        if existing == content:
            return False
    path.parent.mkdir(parents=True, exist_ok=True)
    if mode_b:
        path.write_bytes(content)
    else:
        path.write_text(content, encoding="utf-8")
    return True


def regenerate_set(symset: SymbolSet) -> None:
    upstream_symbols_dir = VENDOR_ROOT / symset.upstream_dir / "symbols"
    if not upstream_symbols_dir.is_dir():
        raise SystemExit(
            f"Upstream symbols not found at {upstream_symbols_dir}. "
            f"Run Scripts/sync-symbols.sh first."
        )

    target_dir = SOURCES_ROOT / f"CornucopiaSymbols{symset.target_suffix}"
    catalog_dir = target_dir / "Resources" / f"{symset.swift_enum}.xcassets"
    enum_path = target_dir / f"{symset.swift_enum}.swift"
    attribution_path = target_dir / "ATTRIBUTION.md"
    license_path = target_dir / "LICENSE.txt"

    # Wipe existing catalog contents (cheaper and more correct than diffing every
    # file when upstream renames or removes symbols).
    if catalog_dir.exists():
        shutil.rmtree(catalog_dir)
    catalog_dir.mkdir(parents=True)
    write_if_changed(catalog_dir / "Contents.json", asset_catalog_contents())

    # Walk upstream svgs, deterministic order.
    svgs = sorted(upstream_symbols_dir.glob("*.svg"))
    if not svgs:
        raise SystemExit(f"No SVGs found in {upstream_symbols_dir}")

    # Collect (case_name, raw_value) pairs, resolving collisions deterministically.
    seen: dict[str, int] = {}
    cases: list[tuple[str, str]] = []  # (case_name, raw_value)

    for svg in svgs:
        raw_value = svg.stem  # asset name == filename stem (preserves "house.fill" etc.)
        base_case = case_name_from_filename(raw_value)
        case = base_case
        if case in seen:
            seen[base_case] += 1
            case = f"{base_case}_{seen[base_case]}"
        else:
            seen[case] = 1
        cases.append((case, raw_value))

        # Asset catalog entry: <raw_value>.symbolset/Contents.json + the SVG.
        symbolset_dir = catalog_dir / f"{raw_value}.symbolset"
        symbolset_dir.mkdir(parents=True, exist_ok=True)
        (symbolset_dir / "Contents.json").write_text(symbolset_contents(svg.name), encoding="utf-8")
        shutil.copyfile(svg, symbolset_dir / svg.name)

    # Generate Swift enum.
    lines: list[str] = []
    lines.append("// AUTO-GENERATED by Scripts/generate.py — DO NOT EDIT.")
    lines.append("// Re-run `Scripts/sync-symbols.sh && Scripts/generate.py` to regenerate.")
    lines.append("")
    lines.append("import Foundation")
    lines.append("import CornucopiaSymbolsCore")
    lines.append("")
    lines.append(f"public enum {symset.swift_enum}: String, CornucopiaSymbol, Sendable {{")
    lines.append("")
    lines.append(f'    public static let setName = "{symset.swift_enum}"')
    lines.append(f'    public static let bundle = resolveCornucopiaBundle(')
    lines.append(f'        named: "CornucopiaSymbols_CornucopiaSymbols{symset.target_suffix}",')
    lines.append(f'        fallback: .module')
    lines.append(f'    )')
    lines.append("")
    for case_name, raw_value in cases:
        emitted = f"`{case_name}`" if needs_backticks(case_name) else case_name
        if emitted.strip("`") == raw_value:
            lines.append(f"    case {emitted}")
        else:
            lines.append(f'    case {emitted} = "{raw_value}"')
    lines.append("}")
    lines.append("")

    write_if_changed(enum_path, "\n".join(lines))

    # Bundle the upstream license text with the per-set target.
    license_text, license_source = upstream_license_text(symset)
    write_if_changed(license_path, license_text)

    # Per-target attribution stub.
    attribution = (
        f"# {symset.pretty_name}\n\n"
        f"- Symbols: {len(cases)}\n"
        f"- License: {symset.license_short}\n"
        f"- Upstream project: [{symset.upstream_url}]({symset.upstream_url})\n"
        f"- Upstream snapshot: [buzap/open-symbols /{symset.upstream_dir}/]"
        f"(https://github.com/buzap/open-symbols/tree/main/{symset.upstream_dir})\n"
        f"- License text: see [`LICENSE.txt`](LICENSE.txt) (sourced from {license_source})\n"
    )
    write_if_changed(attribution_path, attribution)

    print(f"  {symset.swift_enum:<14} {len(cases):>5} symbols    license: {symset.license_short}")


def main() -> None:
    requested = set(s.lower() for s in sys.argv[1:])
    if requested:
        sets = [s for s in ALL_SETS if s.upstream_dir in requested or s.swift_enum.lower() in requested]
        unknown = requested - {s.upstream_dir for s in sets} - {s.swift_enum.lower() for s in sets}
        if unknown:
            print(f"Unknown set(s): {', '.join(sorted(unknown))}")
            print(f"Known: {', '.join(s.upstream_dir for s in ALL_SETS)}")
            sys.exit(2)
    else:
        sets = ALL_SETS

    print(f"Regenerating {len(sets)} set(s) from {VENDOR_ROOT}:")
    for s in sets:
        regenerate_set(s)

    # Aggregate top-level THIRD_PARTY_LICENSES.md (always covers ALL sets,
    # not just the requested subset, so the file stays consistent).
    write_third_party_licenses()
    print("Done.")


def write_third_party_licenses() -> None:
    """Emit a top-level aggregator that lists each bundled set with a pointer
    to its license text. Required for honouring MIT / Apache / CC BY / ISC
    redistribution terms in a single discoverable place.
    """
    out = ROOT / "THIRD_PARTY_LICENSES.md"
    lines: list[str] = []
    lines.append("# Third-Party Licenses")
    lines.append("")
    lines.append(
        "CornucopiaSymbols bundles symbol assets converted from several open-source "
        "icon sets. Each set is redistributed under its original license. The full "
        "license text for each set is shipped inside its corresponding SwiftPM "
        "target directory; this file provides a discoverable index."
    )
    lines.append("")
    lines.append("| Set | Symbols | License | License text |")
    lines.append("| --- | ------: | ------- | ------------ |")
    for s in ALL_SETS:
        symbols_dir = VENDOR_ROOT / s.upstream_dir / "symbols"
        count = len(list(symbols_dir.glob("*.svg"))) if symbols_dir.is_dir() else 0
        target = f"CornucopiaSymbols{s.target_suffix}"
        lines.append(
            f"| [{s.pretty_name}]({s.upstream_url}) | {count} | {s.license_short} | "
            f"[Sources/{target}/LICENSE.txt](Sources/{target}/LICENSE.txt) |"
        )
    lines.append("")
    lines.append("## Attribution requirements summary")
    lines.append("")
    lines.append(
        "- **MIT / ISC / Apache 2.0:** include the license text and copyright "
        "notice with any redistribution. Bundling each set's `LICENSE.txt` "
        "inside its SwiftPM target satisfies this when the package is "
        "distributed via SwiftPM."
    )
    lines.append(
        "- **CC BY 4.0 (Font Awesome Free):** *also* requires that you give "
        "appropriate credit when you ship the icons in a product — typically by "
        "naming \"Font Awesome\" in your About / Acknowledgements UI. "
        "CornucopiaSymbols bundles the license text but cannot fulfil this "
        "obligation on your behalf."
    )
    lines.append(
        "- **Apache 2.0:** distribute a copy of the license, and if the upstream "
        "project ships a `NOTICE` file, redistribute that too. None of the "
        "Apache-2.0 sets bundled here ship a `NOTICE` file separately from "
        "their `LICENSE`/`License`."
    )
    lines.append("")
    lines.append(
        "Wrapper code (Swift sources, scripts, the menu-bar app) is MIT — see "
        "the top-level `LICENSE` file."
    )
    lines.append("")
    write_if_changed(out, "\n".join(lines))
    print(f"  THIRD_PARTY_LICENSES.md written at repo root")


if __name__ == "__main__":
    main()
