#!/usr/bin/env bash
#
# Build OpenWrt for the JioRouter AX6000 JIDU6611 from pinned sources.
#
# Usage: scripts/build.sh
#
# Environment:
#   WORKDIR         OpenWrt source directory (default: ./openwrt)
#   JOBS            parallel make jobs (default: number of CPUs)
#   OPENWRT_DL_DIR  optional shared download cache, linked as $WORKDIR/dl
#
set -euo pipefail

DEVICE="jiorouter_ax6000-jidu6611"
CONFIG="jidu6611.diffconfig"

OPENWRT_URL="https://github.com/openwrt/openwrt.git"
OPENWRT_COMMIT="3b197b2007b13b4fae1f5dd6ca04f2390dfd78fd"

FEEDS=(
	"packages https://git.openwrt.org/feed/packages.git 9273f21834bd824d6a462a2fe9cf101075137a9f"
	"luci https://git.openwrt.org/project/luci.git a7e26c4c7deb27f114f0bab9227be077cf62aeb7"
	"routing https://git.openwrt.org/feed/routing.git ea8633da9c461a9bdc62a0323439d31180762e03"
	"telephony https://git.openwrt.org/feed/telephony.git 9bcb6d71db03377ff49ccb099be763add9a5b059"
	"video https://github.com/openwrt/video.git 92f51f0f3fffa718fc9d3717a5e852e8ddb2b1e7"
)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${WORKDIR:-$ROOT/openwrt}"
JOBS="${JOBS:-$(nproc)}"
TARGET_DIR="bin/targets/qualcommbe/ipq95xx"

log() { printf '==> %s\n' "$*"; }

# Source tree at the pinned commit, with the patch series applied.
if [ ! -d "$WORKDIR/.git" ]; then
	log "Cloning OpenWrt into $WORKDIR"
	git clone --quiet "$OPENWRT_URL" "$WORKDIR"
fi
cd "$WORKDIR"
git am --abort >/dev/null 2>&1 || true
if ! git cat-file -e "$OPENWRT_COMMIT^{commit}" 2>/dev/null; then
	git fetch --quiet origin
fi
log "Checking out $OPENWRT_COMMIT"
git checkout --quiet --force --detach "$OPENWRT_COMMIT"

log "Applying patches"
for patch in "$ROOT"/patches/*.patch; do
	git -c user.name=build -c user.email=build@localhost am --quiet --3way "$patch"
done

# Board data.
log "Installing board data"
(cd "$ROOT/board-data" && sha256sum --check --quiet SHA256SUMS)
mkdir -p package/firmware/ipq-wifi/src
cp "$ROOT"/board-data/board-jiorouter_ax6000-jidu6j11.* package/firmware/ipq-wifi/src/

# Feeds pinned to fixed commits.
log "Updating feeds"
: > feeds.conf
for feed in "${FEEDS[@]}"; do
	read -r name url commit <<<"$feed"
	printf 'src-git %s %s^%s\n' "$name" "$url" "$commit" >> feeds.conf
done
./scripts/feeds update -a
./scripts/feeds install -a

# Configuration.
log "Loading config/$CONFIG"
cp "$ROOT/config/$CONFIG" .config
make defconfig

if [ -n "${OPENWRT_DL_DIR:-}" ]; then
	mkdir -p "$OPENWRT_DL_DIR"
	if [ ! -L dl ]; then
		rm -rf dl
		ln -s "$OPENWRT_DL_DIR" dl
	fi
fi

log "Downloading sources"
make download -j"$JOBS"

# The ipq-wifi package is cleaned so that changed board data is always used.
log "Building"
make package/firmware/ipq-wifi/clean
make -j"$JOBS" IGNORE_ERRORS=m

log "Creating migration image"
SYSUPGRADE="$TARGET_DIR/openwrt-qualcommbe-ipq95xx-$DEVICE-squashfs-sysupgrade.bin"
FWTOOL="$WORKDIR/staging_dir/host/bin/fwtool" \
	"$ROOT/scripts/make-migration-image.sh" "$SYSUPGRADE" \
	"${SYSUPGRADE%.bin}-from-community.bin"

(cd "$TARGET_DIR" && sha256sum openwrt-qualcommbe-ipq95xx-"$DEVICE"-* > "sha256sums-$DEVICE")
log "Images: $WORKDIR/$TARGET_DIR"
