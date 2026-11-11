# Transmit power

## Summary

| Radio | Board data | Reported transmit power | Channel tested |
|---|---|---|---|
| 2.4 GHz (IPQ9574, AHB) | maximum-power data, conformance limits disabled | 30 dBm | 11 |
| 5 GHz (QCN9074, PCIe) | maximum-power data | 30 dBm | 36 |

With Jio's own JIDU6611 board data (version 1.0, 2024-03-12) the 2.4 GHz radio
reports 16 dBm on channel 11. Its conformance tables limit the channels near the
band edges to 10.5-19 dBm. Replacing it with the maximum-power data raised the
signal measured at a client from -61 dBm to -47 dBm, at the same position.

## How board data limits transmit power

ath11k radios read two kinds of data at start-up:

- **Per-unit calibration** from the `0:ART` partition. This is unchanged by
  this firmware.
- **Per-model board data** (`board-2.bin`). It holds per-rate target powers
  and the conformance test limit (CTL) tables, which cap the power on
  individual channels so that the model passes emission tests.

The firmware uses the lowest of the target power, the CTL limit for the
current channel and mode, and the regulatory limit for the configured country.
The result is the value reported as `Tx-Power` by `iwinfo`.

Comparing the IPQ9574 (2.4 GHz) board data files:

- The per-rate target power tables are nearly identical between Jio's JIDU6611
  data and the maximum-power data (about 24 and 24.5 dBm per chain).
- Jio's JIDU6611 data (version 1.0, 2024-03-12) limits the channels near the
  band edges, including 2462 MHz (channel 11), to between 10.5 and 19 dBm.
- The maximum-power data sets every CTL entry to 31.5 dBm, which removes those
  limits. Only the regulatory limit then applies: 30 dBm for country `IN`.

The higher setting is real output, not a different way of reporting it. On a
JIDU6611 at a fixed client position, the measured 2.4 GHz signal rose from
-61 dBm to -47 dBm.

## Reducing transmit power

In LuCI, open **Network > Wireless**, edit the radio, and set
**Transmit Power**. With UCI:

```sh
uci set wireless.radio0.txpower='20'   # 2.4 GHz, in dBm
uci set wireless.radio1.txpower='20'   # 5 GHz, in dBm
uci commit wireless && wifi reload
```

## Using Jio's board data instead

Jio's per-model data is proposed upstream in
[openwrt/firmware_qca-wireless#193](https://github.com/openwrt/firmware_qca-wireless/pull/193).
To build with it, replace the files in `board-data/`, update
`board-data/SHA256SUMS`, and rebuild. Each file must contain an entry named
`variant=JIDU6611`. With Jio's data, the 2.4 GHz radio of a JIDU6611 is
limited on the band-edge channels, while channels in the middle of the band,
such as channel 6, are not.

## Regulatory note

The maximum-power data can exceed the limits that the manufacturer applied to
this model, and the limits that apply where you use the device. You are
responsible for operating it lawfully. Set the correct country code and
reduce transmit power where required.
