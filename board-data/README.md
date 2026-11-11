# Board data

These files are installed into OpenWrt's `ipq-wifi` package. They are
packaged as `/lib/firmware/ath11k/<chip>/hw1.0/board-2.bin` in the
`ipq-wifi-jiorouter_ax6000-jidu6j11` package.

Each file is an ath11k `board-2.bin` container with one payload, registered
under two names:

- `bus=<ahb|pci>,qmi-chip-id=0,qmi-board-id=255,variant=JIDU6611`
- `bus=<ahb|pci>,qmi-chip-id=0,qmi-board-id=255`, used as a fallback

| File | Radio | Payload | Payload MD5 |
|---|---|---|---|
| `board-jiorouter_ax6000-jidu6j11.ipq9574` | 2.4 GHz (IPQ9574, AHB) | Maximum-power board data taken from the community JIDU6J11 firmware (OpenWrt r35553+327-fdb162fb81). It does not match any stock Jio file; all conformance (CTL) limits are set to 31.5 dBm. | `6080dd5b35f912ed7e51ee148a21eee7` |
| `board-jiorouter_ax6000-jidu6j11.qcn9074` | 5 GHz (QCN9074, PCIe) | Maximum-power board data taken from the same community firmware. | `d7606db39a14ffa868be5ae97af58ab2` |

`SHA256SUMS` covers the container files and is checked by `scripts/build.sh`.

See [docs/TRANSMIT_POWER.md](../docs/TRANSMIT_POWER.md) for what the board
data controls, and how to use Jio's data instead.
