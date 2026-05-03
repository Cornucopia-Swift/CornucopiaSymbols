# Third-Party Licenses

CornucopiaSymbols bundles symbol assets converted from several open-source icon sets. Each set is redistributed under its original license. The full license text for each set is shipped inside its corresponding SwiftPM target directory; this file provides a discoverable index.

| Set | Symbols | License | License text |
| --- | ------: | ------- | ------------ |
| [Feather](https://feathericons.com/) | 287 | MIT | [Sources/CornucopiaSymbolsFeather/LICENSE.txt](Sources/CornucopiaSymbolsFeather/LICENSE.txt) |
| [Heroicons](https://heroicons.com/) | 648 | MIT | [Sources/CornucopiaSymbolsHeroicons/LICENSE.txt](Sources/CornucopiaSymbolsHeroicons/LICENSE.txt) |
| [Lucide](https://lucide.dev/) | 1557 | ISC | [Sources/CornucopiaSymbolsLucide/LICENSE.txt](Sources/CornucopiaSymbolsLucide/LICENSE.txt) |
| [Font Awesome (Free)](https://fontawesome.com/) | 2059 | CC BY 4.0 | [Sources/CornucopiaSymbolsFontAwesome/LICENSE.txt](Sources/CornucopiaSymbolsFontAwesome/LICENSE.txt) |
| [Remix](https://remixicon.com/) | 3058 | Apache-2.0 | [Sources/CornucopiaSymbolsRemix/LICENSE.txt](Sources/CornucopiaSymbolsRemix/LICENSE.txt) |
| [Tabler](https://tabler.io/icons) | 5880 | MIT | [Sources/CornucopiaSymbolsTabler/LICENSE.txt](Sources/CornucopiaSymbolsTabler/LICENSE.txt) |
| [Pictogrammers Material Design](https://pictogrammers.com/library/mdi/) | 7447 | Apache-2.0 | [Sources/CornucopiaSymbolsPictogrammers/LICENSE.txt](Sources/CornucopiaSymbolsPictogrammers/LICENSE.txt) |

## Attribution requirements summary

- **MIT / ISC / Apache 2.0:** include the license text and copyright notice with any redistribution. Bundling each set's `LICENSE.txt` inside its SwiftPM target satisfies this when the package is distributed via SwiftPM.
- **CC BY 4.0 (Font Awesome Free):** *also* requires that you give appropriate credit when you ship the icons in a product — typically by naming "Font Awesome" in your About / Acknowledgements UI. CornucopiaSymbols bundles the license text but cannot fulfil this obligation on your behalf.
- **Apache 2.0:** distribute a copy of the license, and if the upstream project ships a `NOTICE` file, redistribute that too. None of the Apache-2.0 sets bundled here ship a `NOTICE` file separately from their `LICENSE`/`License`.

Wrapper code (Swift sources, scripts, the menu-bar app) is MIT — see the top-level `LICENSE` file.
