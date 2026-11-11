# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Releases are named after their build date.

## [v2026.11.11] - 2026-11-11

### Added

- Build recipe for the JioRouter AX6000 JIDU6611 based on OpenWrt main
  `3b197b2007` (r38207), Linux 6.18.60, mac80211 backports 7.2.
- Per-variant device support from openwrt/openwrt#26498.
- ath11k RXDMA page-frag fix from openwrt/openwrt#24254, renumbered to
  960/961 and refreshed for backports 7.2.
- `SUPPORTED_DEVICES` entry for the community board name
  `jiorouter,ax6000-jidu6j11`, and a migration image for upgrading from the
  community firmware.
- Maximum transmit power board data.
- Full hostapd (`wpad-mbedtls`) in place of `wpad-basic-mbedtls`.
- Kernel modules for the image kernel, published with the release.

[v2026.11.11]: https://github.com/mahir-m01/jidu6611-openwrt/releases/tag/v2026.11.11
