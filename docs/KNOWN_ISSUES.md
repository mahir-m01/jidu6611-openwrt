# Known issues

## 802.11r fast roaming disconnects clients

**Symptom.** Every fast-transition association fails, and the client is
disconnected and reconnects with a full handshake:

```
hostapd: phy1-ap0: nl80211: kernel reports: key addition failed
hostapd: phy1-ap0: AP-STA-CONNECTED xx:xx:xx:xx:xx:xx auth_alg=ft
hostapd: phy1-ap0: AP-STA-DISCONNECTED xx:xx:xx:xx:xx:xx
```

It was observed on both radios, on two units running as access points of the
same network, with WPA2/WPA3 (`sae-compat`).

**Cause.** hostapd installs the pairwise key before mac80211 marks the station
as associated, and mac80211 rejects it with `-ENOENT`. A fix that defers the
upload ([openwrt/openwrt#23181](https://github.com/openwrt/openwrt/pull/23181))
deliberately excludes drivers that set `SW_CRYPTO_CONTROL`. ath11k sets that
flag in its default (native Wi-Fi) mode, so the fix does not apply to this
device.

**Workaround.** Disable 802.11r on every access point:

```sh
uci set wireless.default_radio0.ieee80211r='0'
uci set wireless.default_radio1.ieee80211r='0'
uci commit wireless && wifi reload
```

802.11k (`ieee80211k`) and 802.11v (`bss_transition`) are not affected.
Together with `usteer`, they are enough to move clients between access points.

## Wired traffic stalls until reboot (EDMA Tx queues)

**Symptom.** Part of the traffic leaving an Ethernet port stops and does not
recover. New connections fail at random, roughly one in four per stuck
queue, while ping may still work. Nothing is logged. The port's Tx qdisc
shows a backlog that never drains (normally `0p`):

```
tc -s qdisc show dev wan | grep backlog
 backlog 0b 0p requeues 0
 backlog 430378b 1458p requeues 7
 backlog 344550b 1455p requeues 5
```

It occurs when a burst arrives faster than the port can send, for example
Wi-Fi clients uploading over a 100 Mbit/s uplink. It was reproduced on a
JIDU6411 by sending 400 Mbit/s of UDP over its 100 Mbit/s uplink.

**Cause.** The EDMA driver stops Tx queue N when Tx ring N has no free
descriptors. After Tx completion it wakes the queue numbered after the CPU
that handled the completion, not queue N. Every Tx completion interrupt runs
on CPU0 by default, so only queue 0 is ever restarted.

**Fix.** Patch `0004` wakes the queue that belongs to the completed ring. It
is included from the release after v2026.11.11.

**Workaround for v2026.11.11.** Pin each Tx completion interrupt to its own
CPU so the two numbers match. Save this as `/etc/edma-txcmpl-affinity.sh`,
make it executable, call it from `/etc/rc.local` before `exit 0`, add it to
`/etc/sysupgrade.conf` and reboot:

```sh
#!/bin/sh
awk '/txcmpl_/ { sub(":", "", $1); split($NF, a, "_"); print $1, a[2] % 4 }' /proc/interrupts |
while read -r irq cpu; do
	echo "$cpu" > "/proc/irq/$irq/smp_affinity_list"
done
```

## 2.4 GHz stops passing traffic (community firmware)

**Symptom.** On a JIDU6411 running the community firmware
`r35553+327-fdb162fb81`, the 2.4 GHz radio stopped forwarding client traffic
after about 19 and 29 hours of uptime, on two occasions. The radio kept
beaconing and accepting associations. Clients completed the 4-way handshake
but obtained no DHCP lease, and most disconnected within 20 to 30 seconds.
The 5 GHz radio was not affected, and a reboot restored service.

**Status.** The symptoms match the
[wired Tx queue stall](#wired-traffic-stalls-until-reboot-edma-tx-queues): the
same unit later showed stuck uplink queues in all four stalls it logged,
including one where its 2.4 GHz clients lost connectivity. Which clients are
affected depends on which queue their traffic hashes to, so one band can look
dead while the other works. That stall is the most likely cause. If you still see this with patch `0004`
or the workaround applied, please report it.

**If you see it**, record the uptime and attach the output of the following
to an issue:

```sh
uptime; free
logread | tail -300
dmesg | tail -200
iw dev phy0-ap0 station dump
```

## Kernel modules from the official feed do not load

The kernel in these images is built here, so modules from
`downloads.openwrt.org` do not match it and are rejected. Install modules from
the `kmods-*.tar.gz` archive attached to the same release:

```sh
apk add --allow-untrusted /tmp/kmod-<name>-*.apk
```

Userland packages from the official snapshot feed normally install. Snapshot
packages can, however, move ahead of the image over time.

## Memory headroom

The device has 512 MB of RAM, about 433 MB of it usable. Both radios run
ath11k firmware memory mode 2. With AdGuard Home and Tailscale installed,
about 75 MB remained available on the tested JIDU6611. Keep large services and
in-memory logs to a minimum.

## Board data provenance

The board data in this repository does not come from
`openwrt/firmware_qca-wireless`. See [board-data/README.md](../board-data/README.md).
Stock board data for the JIDU6J11 variants is proposed in
[openwrt/firmware_qca-wireless#193](https://github.com/openwrt/firmware_qca-wireless/pull/193).
In that pull request, the payloads listed for JIDU6111 are identical to the
factory `0:BDF` partition of a JIDU6411 unit (version 2.0, 2024-03-15), and
the JIDU6411 entries differ from it.

## Fresh installations start with Wi-Fi disabled

This is standard OpenWrt behaviour. Upgrades that keep settings are not
affected.
