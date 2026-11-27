# VaultLift

A disposable, zero-retention password-export migrator: vendor exports go
in, unencrypted Bitwarden JSON comes out. No conversion code is written -
every byte of transformation is done by the pinned official `bw` CLI inside
a throwaway container stack. Three guarantees: everything runs on tmpfs or
dies on teardown, no containers have an outbound network route, and no
volumes are left behind.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/).

## Usage

1. Drop your vendor export into `work/`.
2. Pick your format id from the [vendor table](VENDOR_FORMATS.MD).
3. Run and clean up:
   ```
   docker compose run --rm -e BW_IMPORT_FORMAT=<format> bwcli
   docker compose down -v
   ```
4. `work/bw.json` is your vault in unencrypted Bitwarden JSON.

### Security

`work/bw.json` contains **plaintext credentials** - passwords, usernames,
notes: move it to its destination and delete it.  
For extreme security, an air-gapped operating system booted from
RAM is the best environment to run VaultLift.

