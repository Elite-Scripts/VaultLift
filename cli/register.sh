#!/bin/sh
# VaultLift throwaway-account auto-registration library, sourced by loop.sh.
# Generates the ephemeral credentials in-container (CREDS_EMAIL / CREDS_PASS,
# never printed), hand-rolls the web vault's client-side key derivation, and
# registers the account via the vaultwarden API over plain HTTP.
# KDF is PBKDF2-SHA256 x600k: bookworm's OpenSSL 3.0 has no Argon2id.

# hex -> raw bytes (GNU printf understands \xHH; dash's builtin does not)
_hex2raw() {
    /usr/bin/printf "$(printf '%s' "$1" | sed 's/../\\x&/g')"
}

# HKDF-expand (SHA256, first 32B block): HMAC(prk, info || 0x01) -> hex
_hkdf_expand() {
    printf '%s\001' "$2" \
        | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$1" -binary \
        | od -An -v -tx1 | tr -d ' \n'
}

# enc_string <encKeyHex> <macKeyHex> <plaintext-file>: sets _ENC to
# "2.<b64iv>|<b64ct>|<b64mac>" (AES-256-CBC + HMAC-SHA256 over iv||ct)
_enc_string() {
    local d ivhex
    d="$(mktemp -d)"
    openssl rand 16 > "$d/iv"
    ivhex="$(od -An -v -tx1 "$d/iv" | tr -d ' \n')"
    openssl enc -aes-256-cbc -K "$1" -iv "$ivhex" -nosalt -in "$3" -out "$d/ct"
    cat "$d/iv" "$d/ct" > "$d/ivct"
    _ENC="2.$(openssl base64 -A -in "$d/iv" | tr -d '\n')|$(openssl base64 -A -in "$d/ct" | tr -d '\n')|$(openssl dgst -sha256 -mac HMAC -macopt "hexkey:$2" -binary "$d/ivct" | openssl base64 -A | tr -d '\n')"
    rm -rf "$d"
}

register_account() {
    CREDS_EMAIL="$(printf 'vaultlift-%s@vaultlift.invalid' "$(openssl rand -hex 4)")"
    CREDS_PASS="$(openssl rand -hex 24)"

    local salt_hex pass_hex mk_hash_hex uk_enc uk_mac pub_b64 curl_out token d
    salt_hex="$(printf '%s' "$CREDS_EMAIL" | tr '[:upper:]' '[:lower:]' | od -An -v -tx1 | tr -d ' \n')"
    pass_hex="$(printf '%s' "$CREDS_PASS" | od -An -v -tx1 | tr -d ' \n')"

    # registration is two-step: request the verification email first; with
    # mail off, the server returns the token directly in the response body
    token="$(curl --fail-with-body -sS -X POST \
        -H 'Content-Type: application/json' \
        -d "{\"email\":\"$CREDS_EMAIL\"}" \
        http://vaultwarden:80/identity/accounts/register/send-verification-email 2>&1)" \
        || die "verification-email step failed: $token"
    token="$(printf '%s' "$token" | tr -d '\n"')"

    # master key = PBKDF2-SHA256(password, salt=normalized email, 600k, 32B)
    # (openssl kdf prints colon-separated hex; strip everywhere)
    MASTER_KEY_HEX="$(openssl kdf -keylen 32 \
        -kdfopt digest:SHA256 -kdfopt iter:600000 \
        -kdfopt "pass:$CREDS_PASS" -kdfopt "hexsalt:$salt_hex" PBKDF2 | tr -d ' \n:')"

    # auth hash = base64(PBKDF2-SHA256(key=masterKey, salt=password, 1 iter))
    mk_hash_hex="$(openssl kdf -keylen 32 \
        -kdfopt digest:SHA256 -kdfopt iter:1 \
        -kdfopt "hexpass:$MASTER_KEY_HEX" -kdfopt "hexsalt:$pass_hex" PBKDF2 | tr -d ' \n:')"
    MP_HASH="$(_hex2raw "$mk_hash_hex" | openssl base64 -A | tr -d '\n')"

    # stretch: HKDF-expand(masterKey, "enc"/"mac") -> 32B enc + 32B mac
    ENC_MK="$(_hkdf_expand "$MASTER_KEY_HEX" enc)"
    MAC_MK="$(_hkdf_expand "$MASTER_KEY_HEX" mac)"

    # user key: 64 random bytes wrapped with the stretched master key
    d="$(mktemp -d)"
    openssl rand 64 > "$d/userkey"
    uk_enc="$(head -c 32 "$d/userkey" | od -An -v -tx1 | tr -d ' \n')"
    uk_mac="$(tail -c 32 "$d/userkey" | od -An -v -tx1 | tr -d ' \n')"
    _enc_string "$ENC_MK" "$MAC_MK" "$d/userkey"; KEY_STR="$_ENC"

    # RSA-2048 pair (schema-mandated; unused by this session's pipeline).
    # genpkey's DER is PKCS#1; the SDK needs strict PKCS#8 - convert.
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 2>/dev/null \
        | openssl pkcs8 -topk8 -nocrypt -outform DER -out "$d/priv.der"
    openssl pkey -inform DER -in "$d/priv.der" -pubout -outform DER -out "$d/pub.der" 2>/dev/null
    _enc_string "$uk_enc" "$uk_mac" "$d/priv.der"; EPK_STR="$_ENC"
    pub_b64="$(openssl base64 -A -in "$d/pub.der" | tr -d '\n')"
    rm -rf "$d"

    printf '{"name":"","email":"%s","masterPasswordHash":"%s","masterPasswordHint":null,"kdf":0,"kdfIterations":600000,"key":"%s","keys":{"publicKey":"%s","encryptedPrivateKey":"%s"},"emailVerificationToken":"%s"}' \
        "$CREDS_EMAIL" "$MP_HASH" "$KEY_STR" "$pub_b64" "$EPK_STR" "$token" > /tmp/register.json

    curl_out="$(curl --fail-with-body -sS -X POST \
        -H 'Content-Type: application/json' \
        --data-binary @/tmp/register.json \
        http://vaultwarden:80/identity/accounts/register/finish 2>&1)" \
        || { rm -f /tmp/register.json; die "registration failed: $curl_out"; }
    rm -f /tmp/register.json
}
