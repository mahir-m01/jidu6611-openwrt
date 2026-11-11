# Recovery

The JIDU6611 has one firmware slot. If an image does not boot, the router has to
be recovered from the U-Boot console over a serial connection.

## Serial console

| | |
|---|---|
| Signal level | **3.3 V** on JIDU6111, JIDU6411 and JIDU6611; 1.8 V on JIDU6711, JIDU6811 and JIDU6911 |
| Settings | 115200 baud, 8N1 |
| Adapter | USB-to-TTL adapter (CH340, CP2102, FT232R) set to 3.3 V |

Identify the header pins (GND, TX, RX) on your board before connecting.
Connect the adapter's TX to the router's RX and RX to TX, and do not connect
VCC. Using a 3.3 V adapter on a 1.8 V model can damage the SoC.

## U-Boot access

U-Boot asks for credentials when autoboot is interrupted. Reports from the
OpenWrt forum describe the user name as the last eight characters of the
router serial number, and the password as a device-specific string stored in
the `MFG` partition. Keep the `MFG` backup from
[INSTALL.md](INSTALL.md#back-up-first).

## Boot the RAM image over TFTP

1. Give your computer a static address, for example `192.168.1.2/24`.
2. Serve `openwrt-qualcommbe-ipq95xx-jiorouter_ax6000-jidu6611-initramfs-uImage.itb`
   with a TFTP server.
3. Connect a LAN port, power on the router, and interrupt autoboot.
4. Boot the image:

   ```
   setenv ipaddr 192.168.1.1
   setenv serverip 192.168.1.2
   tftpboot 0x44000000 openwrt-qualcommbe-ipq95xx-jiorouter_ax6000-jidu6611-initramfs-uImage.itb
   bootm 0x44000000
   ```

5. OpenWrt starts from RAM at `192.168.1.1`. Copy the regular sysupgrade image
   to `/tmp` and flash it:

   ```sh
   sysupgrade -n /tmp/openwrt-qualcommbe-ipq95xx-jiorouter_ax6000-jidu6611-squashfs-sysupgrade.bin
   ```

## Restoring partitions

Restoring `0:ART`, `0:BDF` or `MFG` is rarely needed. Only write a partition
back from your own backup, and only when its content is known to be damaged:

```sh
mtd write /tmp/mtd20-0_ART.bin 0:ART
```
