# DEVELOPERS

## Output format: Bitwarden unencrypted JSON

`work/bw.json` is produced by `bw export --format json` on the pinned CLI -
Bitwarden's standard unencrypted individual-vault export, accepted by
Bitwarden, Vaultwarden and every compatible importer. No conversion code is
written here, and the schema is deliberately not documented in this repo:
written schema notes go stale. The live export is the source of truth.

Upstream reference:

- [Bitwarden CLI releases](https://github.com/bitwarden/clients/releases) -
  the exporter's code and release notes; see the pinned version there

Known consumer caveats: the individual-vault export carries no attachments
and no organizational data, and importer quirks (vendor field loss) are
upstream's, not VaultLift's.

Regenerate the truth any time: Self-verification step 3 below produces a
live `work/bw.json` from the fixture. If a future pin changes the schema,
re-run and trust only the fresh export - nothing written here needs
updating.

## Self-verification

Numbered checklist, from a clean checkout:

1. `docker compose config --quiet` - compose file parses.
2. `cp fixtures/lastpass-sample.csv work/`
3. `docker compose run --rm -e BW_IMPORT_FORMAT=lastpasscsv bwcli` - compose
   starts the healthy vaultwarden and the conversion runs end to end with
   zero interaction (the throwaway account is auto-registered inside
   `cli/register.sh`). The run exits 0.
4. Verify `work/bw.json` opens as JSON
   (`python3 -m json.tool work/bw.json | head`).
5. `docker compose down -v`; then confirm `docker ps -a` shows no vaultlift
   containers and `docker volume ls` shows nothing new.
6. (Optional retention check) rerun step 3 with an extra
   `-e VAULTLIFT_SHOW_PASSPHRASE=true` and note the printed email +
   passphrase. After the step-5 teardown, start the empty stack
   (`docker compose up -d vaultwarden`) and attempt the noted credentials
   with bw - the login must be rejected:
   ```
   docker compose run --rm -e BW_LOGIN_ONLY=1 \
     -e BW_TEST_EMAIL=<noted email> -e BW_TEST_PASS=<noted passphrase> bwcli
   ```
   It exits 1 with `Username or password is incorrect` and prints
   `login rejected as expected` - nothing survived the wipe. Then
   `docker compose down -v` again.
