# OpenWrt for the JioRouter AX6000 JIDU6611

Build recipe and release images of OpenWrt for the JioRouter AX6000 JIDU6611
(Qualcomm IPQ9554, target `qualcommbe/ipq95xx`). The firmware is built from
current OpenWrt main, plus the device support and fixes that are still under
review upstream.

> [!WARNING]
> This is an unofficial build. It is not affiliated with Reliance Jio or the
> OpenWrt project. Installing third-party firmware can leave a device
> unusable. Read [Installation](docs/INSTALL.md) and [Recovery](docs/RECOVERY.md)
> before you flash anything.

For the JIDU6411, see
[jidu6411-openwrt](https://github.com/mahir-m01/jidu6411-openwrt).

## Status

| | |
|---|---|
| Device | JioRouter AX6000 JIDU6611 |
| OpenWrt base | main `3b197b2007` (r38207, 2026-11-11) |
| Linux | 6.18.60 |
| Wi-Fi driver | ath11k, mac80211 backports 7.2 |
| Latest release | [v2026.11.11](https://github.com/mahir-m01/jidu6611-openwrt/releases/tag/v2026.11.11) (testing) |
| Tested on | one JIDU6611 unit, used as the main router (PPPoE, SQM, AdGuard Home, Tailscale), since 2026-11-11 |

## Changes compared with the community firmware

Most JIDU6J11 units that run OpenWrt today use the community image
`r35553+327-fdb162fb81`. That image uses one generic board name,
`jiorouter,ax6000-jidu6j11`, for every variant. Compared with it, this firmware:

- **Is built from current OpenWrt main.** It is per-variant: the JIDU6611 image
  selects calibration variant `JIDU6611` for both radios. Device support comes
  from [openwrt/openwrt#26498](https://github.com/openwrt/openwrt/pull/26498).
- **Uses OpenWrt's upstream IPQ9574 Wi-Fi stack.** The 2.4 GHz radio's WCSS
  is started through the secure PIL (TrustZone) loader and runs Qualcomm
  firmware `WLAN.HK.2.9.0.1-01890`. This replaces the out-of-tree
  non-secure loader.
- **Fixes ath11k memory growth under traffic.** It includes the RXDMA
  page-frag fix from
  [openwrt/openwrt#24254](https://github.com/openwrt/openwrt/pull/24254), on
  top of the AHB interrupt and crash-recovery fixes already in main.
- **Ships maximum transmit power board data.** See
  [Transmit power](#transmit-power).
- **Uses the full hostapd (`wpad-mbedtls`).** This enables 802.11k/v, SAE and
  802.11s.
- **Builds every kernel module against the image kernel.** The modules are
  attached to each release, so WireGuard and other modules can be installed.
- **Provides a migration image.** It installs over the community firmware with
  a normal `sysupgrade`, without a serial console.

The calibration offsets in `0:ART`, the MAC address layout and the wireless
device paths are unchanged from the community firmware. Settings kept across
the upgrade therefore continue to apply.

## Downloads

Every [release](https://github.com/mahir-m01/jidu6611-openwrt/releases) contains:

| File | Purpose |
|---|---|
| `*-jidu6611-squashfs-sysupgrade-from-community.bin` | Upgrade from the community firmware |
| `*-jidu6611-squashfs-sysupgrade.bin` | Upgrade from this firmware or another per-variant JIDU6611 build |
| `*-jidu6611-initramfs-uImage.itb` | RAM boot over TFTP, for first installs and recovery |
| `*-jidu6611-squashfs-factory.ubi` | Raw UBI image |
| `kmods-*.tar.gz` | Kernel modules built for this image |
| `sha256sums` | SHA-256 checksums of all files |

## Installation

1. Back up the factory partitions. See [Installation](docs/INSTALL.md#back-up-first).
2. Check the current board name:

   ```sh
   cat /tmp/sysinfo/board_name
   ```

   - `jiorouter,ax6000-jidu6j11`: you are on the community firmware. Use the
     `sysupgrade-from-community` image.
   - `jiorouter,ax6000-jidu6611`: use the regular `sysupgrade` image.
   - Stock Jio firmware: not covered here. See
     [openwrt/openwrt#26498](https://github.com/openwrt/openwrt/pull/26498).
3. Test the image, then flash it with settings kept:

   ```sh
   sysupgrade -T /tmp/<image>.bin && sysupgrade -v /tmp/<image>.bin
   ```

The full procedure and the checks to run afterwards are in
[docs/INSTALL.md](docs/INSTALL.md).

## Transmit power

These images ship board data that lets both radios transmit at the highest
level the firmware and regulatory database allow (30 dBm for country `IN`).
Values reported by `iwinfo` on the tested unit:

| Radio | Board data | Reported transmit power | Channel tested |
|---|---|---|---|
| 2.4 GHz (IPQ9574, AHB) | maximum-power data, conformance limits disabled | 30 dBm | 11 |
| 5 GHz (QCN9074, PCIe) | maximum-power data | 30 dBm | 36 |

With Jio's own JIDU6611 board data (version 1.0, 2024-03-12) the 2.4 GHz radio
reports 16 dBm on channel 11. Its conformance tables limit the channels near the
band edges to 10.5-19 dBm. Replacing it with the maximum-power data raised the
signal measured at a client from -61 dBm to -47 dBm, at the same position.

To reduce power, set **Network > Wireless > Edit > Transmit Power** in LuCI,
or run:

```sh
uci set wireless.radio0.txpower='20'   # dBm
uci commit wireless && wifi reload
```

You can lower the power in settings, but you cannot raise a limit that the
board data imposes. That is why the images default to the maximum-power data.
You are responsible for operating the device within the limits that apply
where you use it. Background and measurements are in
[docs/TRANSMIT_POWER.md](docs/TRANSMIT_POWER.md).

## Known issues

- **802.11r fast roaming disconnects clients on ath11k.** Disable it
  (`ieee80211r '0'`). 802.11k and 802.11v work.
- **2.4 GHz stopped passing traffic after about a day on the community
  firmware.** This firmware replaces every component involved. Whether that
  resolves it is under observation.
- **Kernel modules from `downloads.openwrt.org` do not match this kernel.**
  Install them from the release's `kmods` archive instead.
- **Memory headroom is limited.** The device has 512 MB of RAM, and both
  radios use ath11k firmware memory mode 2.

Details, logs and workarounds: [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md).

## Building

```sh
git clone https://github.com/mahir-m01/jidu6611-openwrt.git
cd jidu6611-openwrt
./scripts/build.sh
```

All sources are pinned: the OpenWrt commit, the feed commits, and the patch
and board data checksums. Requirements and options are described in
[docs/BUILDING.md](docs/BUILDING.md).

## Repository layout

```
.
|-- board-data/            board-2.bin files installed into the ipq-wifi package
|-- config/                OpenWrt build configuration (diffconfig)
|-- docs/                  installation, recovery, known issues, building, transmit power
|-- patches/               patch series applied on top of OpenWrt main
|-- scripts/
|   |-- build.sh           reproducible build from pinned sources
|   `-- make-migration-image.sh
|-- CHANGELOG.md
`-- LICENSE
```

## Credits

- Sandeep Sondagar: original JIDU6J11 port
  ([openwrt/openwrt#24432](https://github.com/openwrt/openwrt/pull/24432)).
- Sahil Bakshi: per-variant device support
  ([openwrt/openwrt#26498](https://github.com/openwrt/openwrt/pull/26498)).
- Mark Ruvald Pedersen: ath11k RXDMA page-frag fix
  ([openwrt/openwrt#24254](https://github.com/openwrt/openwrt/pull/24254)).
- Satoshi Ikeuchi and Alexandru Gagniuc: IPQ9574 Wi-Fi support in OpenWrt.
- Julius Bairaktaris: ath11k AHB interrupt and crash-recovery fixes.
- The OpenWrt project and its contributors.

## License

The scripts and documentation in this repository are licensed under the
[GNU General Public License v2.0](LICENSE). Patches carry the licenses of the
files they modify. Firmware images contain software under various licenses;
the license texts are included in the images (`/usr/share/licenses`).
Qualcomm Wi-Fi firmware is redistributed under its own license.
