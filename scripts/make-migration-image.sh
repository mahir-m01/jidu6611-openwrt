#!/usr/bin/env bash
#
# Repackage a JIDU6J11 sysupgrade image so that it is accepted by firmware
# that uses the generic community board name jiorouter,ax6000-jidu6j11.
#
# That firmware's nand_do_platform_check() looks for the archive directory
# sysupgrade-<board name>. This script renames the directory and re-attaches
# the image metadata. The kernel and root filesystem are not modified, and the
# script verifies that they are identical afterwards.
#
# Usage: make-migration-image.sh <sysupgrade.bin> <output.bin>
#
# Environment:
#   FWTOOL  path to OpenWrt's fwtool (default: fwtool in PATH)
#
set -euo pipefail

if [ $# -ne 2 ]; then
	echo "usage: $0 <sysupgrade.bin> <output.bin>" >&2
	exit 1
fi

IN="$1"
OUT="$2"
FWTOOL="${FWTOOL:-fwtool}"
LEGACY_DIR="sysupgrade-jiorouter_ax6000-jidu6j11"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cp "$IN" "$tmp/image.bin"
"$FWTOOL" -q -t -i "$tmp/metadata.json" "$tmp/image.bin"

mkdir "$tmp/root"
tar -xf "$tmp/image.bin" -C "$tmp/root"
src_dirs=("$tmp"/root/sysupgrade-*)
if [ ${#src_dirs[@]} -ne 1 ] || [ ! -d "${src_dirs[0]}" ]; then
	echo "error: expected exactly one sysupgrade-* directory in $IN" >&2
	exit 1
fi
src_dir="$(basename "${src_dirs[0]}")"
mv "$tmp/root/$src_dir" "$tmp/root/$LEGACY_DIR"

tar -c --numeric-owner --owner=0 --group=0 --mode=a-s --sort=name \
	-f "$OUT" -C "$tmp/root" "$LEGACY_DIR/"
"$FWTOOL" -q -I "$tmp/metadata.json" "$OUT"

for part in kernel root; do
	if ! cmp -s <(tar -xOf "$IN" "$src_dir/$part") <(tar -xOf "$OUT" "$LEGACY_DIR/$part"); then
		echo "error: $part differs between $IN and $OUT" >&2
		exit 1
	fi
done

echo "$OUT"
