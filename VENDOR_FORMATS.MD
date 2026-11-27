# Vendor export formats

| Vendor | Get the export from | Format id |
|---|---|---|
| 1Password | Desktop app: File - Export - All items (unencrypted .1pux; older .1pif) | `1password1pux` / `1password1pif` |
| 1Password (browser extension) | Extension settings - Export | `1passwordmaccsv` (macOS) / `1passwordwincsv` (Windows) |
| LastPass | Vault: Account Options - Advanced - Export (CSV download; the .html form is NOT what the CLI importer parses) | `lastpasscsv` |
| Chrome | chrome://settings/passwords - Export passwords | `chromecsv` |
| Edge | edge://settings/passwords - Export passwords | `edgecsv` |
| Brave | brave://settings/passwords - Export | `bravecsv` |
| Opera | opera://settings/passwords - Export | `operacsv` |
| Vivaldi | vivaldi://settings/passwords - Export | `vivaldicsv` |
| Arc | arc://settings/passwords - Export | `arccsv` |
| Firefox | Settings - Privacy & Security - Saved logins - Export | `firefoxcsv` |
| Safari | File - Export - Passwords (macOS) | `safaricsv` |
| Dashlane | Web vault: My account - Export vault (.csv or .json) | `dashlanecsv` / `dashlanejson` |
| KeePass 2.x | Database: File - Export (XML) | `keepass2xml` |
| KeePass 2.x (database itself) | The .kdbx file + master password; may prompt for an import-file password and key file | `keepasskdbx` |
| KeePassXC | Database: Database - Export - CSV | `keepassxcsv` |
| Keeper | Vault: Settings - Download your data (.csv or .json) | `keeper` (file extension decides) / `keepercsv` / `keeperjson` |
| NordPass | Web vault: Settings - Export | `nordpasscsv` |
| Proton Pass | Web app: Settings - Export (.zip containing data.json) | `protonpass` |
| Enpass | Desktop: File - Export - as JSON/CSV | `enpassjson` / `enpasscsv` |
| RoboForm | Editor: File - Print list - Save to file (CSV) | `roboformcsv` |
| Avast / Avira | Passwords app: Settings - Export | `avastcsv` / `avastjson` / `aviracsv` |
| Kaspersky | Password Manager: Settings - Export (TXT) | `kasperskytxt` |

## All ids (bw 2026.11.0)

`1password1pif, 1password1pux, 1passwordmaccsv, 1passwordwincsv, arccsv,
ascendocsv, avastcsv, avastjson, aviracsv, bitwardencsv, bitwardenjson,
blackberrycsv, blurcsv, bravecsv, buttercupcsv, chromecsv, clipperzhtml,
codebookcsv, dashlanecsv, dashlanejson, delineacsv, delineaxml, edgecsv,
encryptrcsv, enpasscsv, enpassjson, firefoxcsv, fsecurefsk, gnomejson,
kasperskytxt, keepass2xml, keepasskdbx, keepassxcsv, keeper, keepercsv,
keeperjson, lastpasscsv, logmeoncecsv, meldiumcsv, msecurecsv, mykicsv,
netwrixpasswordsecure, nordpasscsv, operacsv, padlockcsv, passboltcsv,
passkeepcsv, passkyjson, passmanjson, passpackcsv, passwordagentcsv,
passwordbossjson, passworddepot17xml, passworddragonxml, passwordwallettxt,
passwordxpcsv, protonpass, psonojson, pwsafexml, remembearcsv, roboformcsv,
safaricsv, safeincloudxml, saferpasscsv, securesafecsv, splashidcsv,
stickypasswordxml, truekeycsv, upmcsv, vivaldicsv, yoticsv, zohovaultcsv`
