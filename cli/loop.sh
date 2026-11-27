#!/bin/sh
# VaultLift in-container pipeline: register -> login -> import -> export.
# Runs on demand: docker compose run --rm -e BW_IMPORT_FORMAT=<id> bwcli
# (compose auto-starts the healthy vaultwarden; the account is auto-
# registered in cli/register.sh). Format ids: VENDOR_FORMATS.MD vendor table.

set -eu

die() {
    printf 'loop.sh: %s\n' "$1" >&2
    exit 1
}

step() {
    printf '\n=== %s\n' "$1"
}

if [ -z "${BW_LOGIN_ONLY:-}" ]; then
    [ -n "${BW_IMPORT_FORMAT:-}" ] \
        || die "BW_IMPORT_FORMAT is unset - run: docker compose run --rm -e BW_IMPORT_FORMAT=<id> bwcli"

    # exactly one vendor export in work/ (bw.json is the output, never input)
    FILE=""
    COUNT=0
    for f in /work/*; do
        [ -f "$f" ] || continue
        [ "$(basename -- "$f")" = "bw.json" ] && continue
        FILE="$f"
        COUNT=$((COUNT + 1))
    done
    [ "$COUNT" -eq 1 ] \
        || die "expected exactly one export file in work/ (besides bw.json, found $COUNT) - drop one vendor export and remove the rest"

    FORMAT="$BW_IMPORT_FORMAT"

    step "Auto-registering the throwaway account"
    . /register.sh
    register_account
    case "${VAULTLIFT_SHOW_PASSPHRASE:-}" in
        1|[Tt]rue|[Yy]es|[Oo]n)
            printf '  ephemeral account: %s\n  passphrase: %s\n' "$CREDS_EMAIL" "$CREDS_PASS"
            ;;
    esac
fi

step "Starting local TLS shim (bw refuses plain-HTTP server URLs)"
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -keyout /tmp/tls.key -out /tmp/tls.crt -days 2 -subj /CN=localhost -addext subjectAltName=DNS:localhost,IP:127.0.0.1 >/dev/null 2>&1
socat OPENSSL-LISTEN:8443,reuseaddr,fork,verify=0,cert=/tmp/tls.crt,key=/tmp/tls.key TCP4:vaultwarden:80 &
export NODE_EXTRA_CA_CERTS=/tmp/tls.crt
curl --fail --silent --retry 10 --retry-connrefused --cacert /tmp/tls.crt https://localhost:8443/alive >/dev/null || die "local TLS shim did not come up"

step "Pointing bw at the throwaway server"
bw config server "https://localhost:8443"

if [ -n "${BW_LOGIN_ONLY:-}" ]; then
    # README test step 6: after teardown, a wiped database must reject the
    # noted credentials. Exits 1 with bw's rejection message on success.
    step "Login attempt with the wiped-database credentials (must be rejected)"
    export BW_PASSWORD="${BW_TEST_PASS:-}"
    SESSION="$(bw login "${BW_TEST_EMAIL:-}" --passwordenv BW_PASSWORD --nointeraction --raw)" \
        && die "credential was ACCEPTED - the throwaway database still holds data?!"
    unset BW_PASSWORD
    printf 'login rejected as expected - nothing survived\n'
    exit 1
fi

step "Logging in to the throwaway account"
# --raw + --passwordenv: non-interactive; bw keeps chatter on stderr and
# writes ONLY the session key to stdout, which is captured quietly.
export BW_PASSWORD="$CREDS_PASS"
SESSION="$(bw login "$CREDS_EMAIL" --passwordenv BW_PASSWORD --nointeraction --raw)" \
    || die "bw login failed (error above)"
unset BW_PASSWORD
export BW_SESSION="$SESSION"

# fail loudly (instead of silently prompting mid-pipeline) if the session
# does not actually unlock the vault
bw status </dev/null 2>/dev/null | grep -Eq '"status":[[:space:]]*"unlocked"' \
    || die "session captured but the vault did not unlock - check the errors above"

step "Validating format '$FORMAT' against this bw build"
# The authoritative check: the live bw build answers directly.
bw import --formats | grep -qx "$FORMAT" \
    || die "'$FORMAT' is not supported by this bw build - see 'bw import --formats'"

step "Importing $FILE (format: $FORMAT)"
bw import "$FORMAT" "$FILE"

step "Syncing"
bw sync

step "Exporting vault as unencrypted Bitwarden JSON -> /work/bw.json"
OUT=/work/bw.json
bw export --format json --output "$OUT"

step "Export written: $OUT"
