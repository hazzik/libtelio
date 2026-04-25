set -e
set -x

if ! docker image inspect libtelio-builder > /dev/null 2>&1; then
    cd 3rd-party/rust_build_utils
    docker build --platform=linux/amd64 -t libtelio-builder -f builders/build-openwrt-rust/Dockerfile .
    cd -
fi

find target -name "nordvpnlite.sha256" -delete 2>/dev/null || true

docker run --platform=linux/amd64 --rm \
    -e BYPASS_LLT_SECRETS=1 \
    -v "$PWD":/project \
    -v libtelio-cargo-registry:/usr/local/cargo/registry \
    -v libtelio-cargo-git:/usr/local/cargo/git \
    -v libtelio-rustup:/usr/local/rustup \
    -w /project libtelio-builder \
    python3 ci/build_libtelio.py build openwrt mips

ls -lh dist/openwrt/release/mips/nordvpnlite

exit 0

upx --best dist/openwrt/release/mips/nordvpnlite

if ! docker image inspect libtelio-openwrt-mips-builder > /dev/null 2>&1; then
    docker build --platform=linux/amd64 -t libtelio-openwrt-mips-builder -f 3rd-party/rust_build_utils/builders/package-openwrt/Dockerfile .
fi

docker run --rm \
    --platform=linux/amd64 \
    -v "$PWD":/project \
    -w /builder \
    libtelio-openwrt-mips-builder \
    /project/3rd-party/rust_build_utils/builders/package-openwrt/package.sh \
    /project/clis/nordvpnlite/openwrt/feed \
    src-link \
    /project/dist/openwrt/release/mips/nordvpnlite \
    nordvpnlite