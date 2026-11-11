# Installation

This document covers upgrading a JioRouter AX6000 JIDU6611 that already runs
OpenWrt. For a first installation from the stock Jio firmware, see the
procedure in
[openwrt/openwrt#26498](https://github.com/openwrt/openwrt/pull/26498), which
requires a serial console.

## Before you begin

- These images are built for the **JIDU6611 only**. The image selects
  calibration variant `JIDU6611`. Check the model on the label of the unit.
- Connect to the router over Ethernet, not Wi-Fi.
- Have the recovery equipment described in [RECOVERY.md](RECOVERY.md) at hand.
  The device has a single firmware slot, so an image that does not boot can
  only be recovered over the serial console.

## Back up first

The `0:ART` partition holds the radio calibration and MAC addresses of your
unit, and `MFG` holds data needed for console access. Neither can be recreated
if they are lost. Copy every partition except `ubi` off the router:

```sh
mkdir /tmp/backup
for n in $(sed -n 's/^mtd\([0-9]*\): [0-9a-f]* [0-9a-f]* "\(.*\)"/\1/p' /proc/mtd); do
	name=$(sed -n "s/^mtd$n: [0-9a-f]* [0-9a-f]* \"\(.*\)\"/\1/p" /proc/mtd | tr ':' '_')
	[ "$name" = ubi ] && continue
	cat /dev/mtd$n > /tmp/backup/mtd$n-$name.bin
done
sysupgrade -b /tmp/backup/config.tar.gz
(cd /tmp/backup && md5sum * > MD5SUMS)
```

Copy `/tmp/backup` to another computer, for example with
`scp -O -r root@192.168.1.1:/tmp/backup .`, and keep it.

## Choose the image

```sh
cat /tmp/sysinfo/board_name
```

| Board name | Image |
|---|---|
| `jiorouter,ax6000-jidu6j11` (community firmware) | `openwrt-qualcommbe-ipq95xx-jiorouter_ax6000-jidu6611-squashfs-sysupgrade-from-community.bin` |
| `jiorouter,ax6000-jidu6611` | `openwrt-qualcommbe-ipq95xx-jiorouter_ax6000-jidu6611-squashfs-sysupgrade.bin` |

The community firmware only accepts a sysupgrade archive whose directory
matches its own board name. The `from-community` image contains the same kernel
and root filesystem as the regular image. The only difference is that its
archive directory is renamed to `sysupgrade-jiorouter_ax6000-jidu6j11`. After
the upgrade the board name is `jiorouter,ax6000-jidu6611`, and later upgrades
use the regular image.

## Prepare the configuration (community firmware only)

1. Remove board data overrides from the list of files kept across upgrades.
   Otherwise the old files are restored over the ones in the image:

   ```sh
   sed -i '\#^/lib/firmware/ath11k/#d' /etc/sysupgrade.conf
   ```

2. Disable 802.11r. It disconnects clients on ath11k; see
   [KNOWN_ISSUES.md](KNOWN_ISSUES.md#80211r-fast-roaming-disconnects-clients):

   ```sh
   for s in $(uci show wireless | sed -n 's/^wireless\.\([^.]*\)=wifi-iface$/\1/p'); do
   	uci set wireless.$s.ieee80211r='0'
   done
   uci commit wireless
   ```

## Upgrade

```sh
# on your computer
scp -O <image>.bin root@192.168.1.1:/tmp/

# on the router
sha256sum /tmp/<image>.bin          # compare with sha256sums from the release
sysupgrade -T /tmp/<image>.bin      # dry run: must finish without errors
sysupgrade -v /tmp/<image>.bin      # keep settings; add -n to reset them
```

The router reboots within about a minute. If the dry run reports
`invalid sysupgrade file`, the image does not match the running firmware; see
[Choose the image](#choose-the-image).

## Verify

```sh
cat /tmp/sysinfo/board_name          # jiorouter,ax6000-jidu6611
dmesg | grep -E 'q6wcss is now up|fw_build_id'
iwinfo phy0-ap0 info | grep -E 'Channel|Tx-Power'
iwinfo phy1-ap0 info | grep -E 'Channel|Tx-Power'
```

Expected:

- `remote processor q6wcss is now up`
- `fw_build_id WLAN.HK.2.9.0.1-01890-QCAHKSWPL_SILICONZ-1` for the 2.4 GHz radio
- both radios up, at the transmit power listed in the [README](../README.md#transmit-power)

## Installing kernel modules

Each release includes a `kmods-*.tar.gz` archive of the kernel modules built
together with the image. Copy the modules you need to the router and install
them:

```sh
apk add --allow-untrusted /tmp/kmod-wireguard-*.apk
```

Modules from `downloads.openwrt.org` are built for a different kernel and do
not load.
