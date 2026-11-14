# Building

## Requirements

- Linux on x86_64 or arm64, on a case-sensitive file system
- About 40 GB of free disk space and 8 GB of RAM
- The OpenWrt build prerequisites. On Debian 13 or Ubuntu 24.04:

  ```sh
  sudo apt install build-essential clang flex bison g++ gawk gcc-multilib \
      g++-multilib gettext git libncurses-dev libssl-dev python3 python3-dev \
      python3-setuptools python3-pyelftools libelf-dev rsync swig unzip \
      zlib1g-dev file wget zstd
  ```

A first build takes about 1.5 to 2 hours on six Haswell cores. Later builds
reuse the toolchain and finish in minutes.

## Build

```sh
./scripts/build.sh
```

The script:

1. clones OpenWrt into `./openwrt` and checks out the pinned commit
2. applies `patches/*.patch` with `git am`
3. verifies `board-data/SHA256SUMS` and installs the board data into
   `package/firmware/ipq-wifi/src`
4. pins the feeds to fixed commits
5. loads `config/jidu6611.diffconfig` and builds with `IGNORE_ERRORS=m`, so an
   optional module that fails to build does not stop the images
6. creates the `sysupgrade-from-community` image and `sha256sums-*`

The images are written to `openwrt/bin/targets/qualcommbe/ipq95xx/`, and the
kernel modules to `openwrt/bin/targets/qualcommbe/ipq95xx/packages/`.

### Options

| Variable | Default | Meaning |
|---|---|---|
| `WORKDIR` | `./openwrt` | OpenWrt source directory |
| `JOBS` | number of CPUs | Parallel make jobs |
| `OPENWRT_DL_DIR` | unset | Shared download cache, linked as `$WORKDIR/dl` |

The script can be run again in the same `WORKDIR`. It resets the tree to the
pinned commit and applies the patches again before building.

## Pinned sources

| Source | Commit |
|---|---|
| openwrt/openwrt | `3b197b2007b13b4fae1f5dd6ca04f2390dfd78fd` |
| feed packages | `9273f21834bd824d6a462a2fe9cf101075137a9f` |
| feed luci | `a7e26c4c7deb27f114f0bab9227be077cf62aeb7` |
| feed routing | `ea8633da9c461a9bdc62a0323439d31180762e03` |
| feed telephony | `9bcb6d71db03377ff49ccb099be763add9a5b059` |
| feed video | `92f51f0f3fffa718fc9d3717a5e852e8ddb2b1e7` |

## Patches

| Patch | Source |
|---|---|
| `0001-qualcommbe-add-JioRouter-AX6000-JIDU6J11.patch` | openwrt/openwrt#26498 (Sahil Bakshi) |
| `0002-mac80211-ath11k-isolate-RXDMA-page-frag-caches.patch` | openwrt/openwrt#24254 (Mark Ruvald Pedersen), renumbered and refreshed |
| `0003-qualcommbe-jidu6j11-accept-upgrades-from-the-communi.patch` | This repository |
| `0004-qualcommbe-edma-wake-the-Tx-queue-of-the-completed-r.patch` | This repository |

## Updating to a newer OpenWrt

1. Change `OPENWRT_COMMIT` and the feed commits in `scripts/build.sh`.
2. Run the build. If `git am` stops on a patch, refresh that patch against the
   new tree with `git am --3way`, and replace the file in `patches/` with
   `git format-patch`.
3. Check that the ath11k patches still apply cleanly. The mac80211 build log
   reports any failed hunk.

## Signing keys

OpenWrt generates a signing key (`key-build`) in each build tree. Images and
packages from your own build are signed with your key, not with the key used
for the published releases.
