# VaultLift bw toolbox: Debian slim + the pinned Bitwarden CLI release.
FROM debian:12-slim@sha256:e67eeead736ff7bbe258ef088bff683635c561b1fcfefad0806c1df4ab49ce0e

ARG BW_VERSION=2026.11.0
ARG BW_ZIP_SHA256=bfc7643cbc20f970bf04b994f96489703fcf77217a2384f1743e43848363b0ba

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip openssl socat \
 && rm -rf /var/lib/apt/lists/* \
 \
 && curl -fsSLo /tmp/bw.zip \
      "https://github.com/bitwarden/clients/releases/download/cli-v${BW_VERSION}/bw-bit-linux-${BW_VERSION}.zip" \
 && echo "${BW_ZIP_SHA256}  /tmp/bw.zip" | sha256sum -c - \
 && unzip -q /tmp/bw.zip -d /usr/local/bin \
 && chmod 0755 /usr/local/bin/bw \
 \
 && rm -rf /tmp/*

COPY --chmod=0755 loop.sh /loop.sh
COPY --chmod=0755 register.sh /register.sh

CMD ["/bin/sh"]
