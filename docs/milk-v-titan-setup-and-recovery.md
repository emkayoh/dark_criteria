# Milk-V Titan — Setup, Headless Access, Wi-Fi and Recovery Guide

**Machine:** Milk-V Titan
**Operating system:** Ubuntu 24.04.4 LTS, RISC-V (`riscv64`)
**Vendor kernel tested:** `6.6.137`
**Last validated:** 15 August 2026
**Purpose:** Headless numerical-computing machine, accessed primarily by SSH over Wi-Fi.

> This document records the setup actually tested on this Titan. IP addresses shown below were allocated by DHCP and may change unless reserved in the router.

---

## 1. Hardware and network roles

The Titan exposes more than one Ethernet connection.

- **Main Gigabit Ethernet** — normal Ubuntu networking and SSH.
- **BMC Ethernet** — independent management interface used for BMC web access, UART/TTY, power control and recovery.

During initial setup the following DHCP addresses were observed:

| Interface/device | Address seen during setup |
|---|---:|
| Titan wired Ubuntu interface | `192.168.0.180` |
| Titan Wi-Fi interface | `192.168.0.182` |
| Titan BMC | `192.168.0.179` |
| Mac used for setup | `192.168.0.177` |

These are examples only. Check the router or ARP table if they change.

---

## 2. Preparing the Ubuntu image on macOS

The downloaded Ubuntu image is supplied as a multi-volume 7-Zip archive, for example:

```text
ubuntu-24.04-desktop-riscv64-rvck-titan-20260605.img.7z.001
ubuntu-24.04-desktop-riscv64-rvck-titan-20260605.img.7z.002
...
```

Do **not** concatenate the parts manually.

### Install 7-Zip on macOS

Using Homebrew:

```bash
brew install sevenzip
```

### Extract the image

```bash
cd ~/Downloads
7zz x ubuntu-24.04-desktop-riscv64-rvck-titan-20260605.img.7z.001
```

7-Zip automatically reads the remaining numbered archive parts.

The result should be:

```text
ubuntu-24.04-desktop-riscv64-rvck-titan-20260605.img
```

---

## 3. Verify the image with MD5

The supplied MD5 file contained:

```text
aeb66c791c5be327860b029fdc41429e  ubuntu-24.04-desktop-riscv64-rvck-titan-20260605.img
```

On macOS:

```bash
md5 -q ubuntu-24.04-desktop-riscv64-rvck-titan-20260605.img
```

Expected result for this specific image:

```text
aeb66c791c5be327860b029fdc41429e
```

A convenient pass/fail test:

```bash
[ "$(md5 -q ubuntu-24.04-desktop-riscv64-rvck-titan-20260605.img)" = \
"aeb66c791c5be327860b029fdc41429e" ] && echo "MD5 OK" || echo "MD5 FAILED"
```

Do not use this checksum for a different Titan image release.

---

## 4. Flash the SSD

Use BalenaEtcher:

1. **Flash from file**
2. Select the extracted `.img`
3. Select the Titan target SSD
4. Flash
5. Allow Etcher to verify the write

BalenaEtcher does not provide Raspberry-Pi-Imager-style preconfiguration of Titan SSH or Wi-Fi.

For first boot, use wired Ethernet.

---

## 5. First headless SSH login

Connect the patch cable to the Titan's **main Gigabit Ethernet port**, not the BMC port.

The router initially identified the Titan as `ubuntu`.

If its address is unknown, on the Mac:

```bash
arp -a
```

or find the Titan's MAC/IP pair in the router's DHCP/client list.

The wired Titan was initially found at:

```text
192.168.0.180
```

Connect:

```bash
ssh ubuntu@192.168.0.180
```

The vendor image initially used:

```text
username: ubuntu
password: ubuntu
```

Ubuntu forces a password change on the first login and then closes the connection. Reconnect using the new password:

```bash
ssh ubuntu@192.168.0.180
```

---

## 6. Configure SSH key access from the Mac

An existing Mac Ed25519 key was present but its private-key passphrase was unavailable, so a separate Titan-specific key was created.

### Create the Titan key

On the Mac:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_titan -C "milk-v-titan"
```

A passphrase is optional. In this setup no passphrase was used.

### Install the public key on the Titan

```bash
cat ~/.ssh/id_ed25519_titan.pub | \
ssh ubuntu@192.168.0.180 'cat >> ~/.ssh/authorized_keys'
```

Test explicitly:

```bash
ssh -i ~/.ssh/id_ed25519_titan -o IdentitiesOnly=yes ubuntu@192.168.0.180
```

### Add a convenient SSH alias

On the Mac, edit:

```bash
nano ~/.ssh/config
```

Example entry:

```sshconfig
Host titan
    HostName 192.168.0.182
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519_titan
    IdentitiesOnly yes
```

Then connect with:

```bash
ssh titan
```

`192.168.0.182` is the Wi-Fi DHCP address seen during setup. If DHCP later changes it, update `HostName` or reserve the address in the router.

---

## 7. Update Ubuntu safely

Refresh package metadata:

```bash
sudo apt update
```

Inspect proposed updates:

```bash
apt list --upgradable
```

The important point on this Titan is to avoid accidentally replacing the vendor kernel without checking first.

A dry run:

```bash
sudo apt upgrade --dry-run
```

Check specifically for kernel/vendor packages:

```bash
sudo apt upgrade --dry-run | \
grep -E '^(Inst|Remv|Conf) (linux-|.*ultrarisc|.*rvck)'
```

During this setup only `linux-libc-dev` appeared. The Titan's actual running vendor kernel was not replaced.

Proceed:

```bash
sudo apt upgrade
```

Then reboot:

```bash
sudo reboot
```

After reconnecting, confirm the kernel:

```bash
uname -a
```

and check for failed services:

```bash
systemctl --failed
```

Expected healthy result:

```text
0 loaded units listed.
```

---

## 8. BMC access and recovery

The Titan's BMC is independent of Ubuntu and is useful when the normal host network is unavailable.

Connect the single patch cable to the **BMC Ethernet port**.

If the router shows only a MAC address but no IP, force the Mac to populate its ARP cache:

```bash
for i in {2..254}; do
    ping -c 1 -W 100 192.168.0.$i >/dev/null 2>&1 &
done
wait
```

Then search for the BMC MAC:

```bash
arp -a | grep -i 'BMC_MAC_ADDRESS'
```

During setup the BMC was:

```text
192.168.0.179
```

Open:

```text
http://192.168.0.179:8000
```

The BMC interface used **Milk-V Cluster Pilot v0.2.1**.

### BMC agent

Initially the Titan appeared as:

```text
IP: N/A
Status: Offline
```

Under:

```text
Titan → Config → Agent manage
```

select **Install agent**.

After installation the BMC reported the Titan as online and showed live CPU, memory and disk usage.

Important security note: the installer TTY may echo the supplied Ubuntu sudo password in clear text. If that happens, change the Ubuntu password afterwards:

```bash
passwd
```

The SSH key continues to work after changing the Ubuntu account password.

---

## 9. Wi-Fi adapter

Adapter used:

```text
MediaTek MT7612U / AC1300 USB Wi-Fi adapter
```

The Titan kernel already contained the required driver:

```bash
modinfo mt76x2u | head
```

Example result:

```text
filename: /lib/modules/6.6.137/kernel/drivers/net/wireless/mediatek/mt76/mt76x2/mt76x2u.ko
```

The required firmware was also present:

```bash
find /lib/firmware -iname 'mt7662*'
```

---

## 10. Initial Wi-Fi dongle problem: USB mode switching

Immediately after insertion, `lsusb` showed:

```text
0e8d:2870 MediaTek Inc.
```

and:

```bash
nmcli device
```

showed no Wi-Fi interface.

The system already had the required packages:

```bash
dpkg -l | grep usb-modeswitch
```

including:

```text
usb-modeswitch
usb-modeswitch-data
```

The installed mode-switch database contained the correct profile:

```bash
tar -xOzf /usr/share/usb_modeswitch/configPack.tar.gz '0e8d:2870'
```

which produced:

```text
# COMFAST CF-WU782AC WiFi Dongle
TargetVendor=0x0e8d
TargetProduct=0x7612
StandardEject=1
```

### Manual mode switch

The following command successfully changes the adapter from its initial mode-switch state to the actual Wi-Fi device:

```bash
sudo usb_modeswitch \
    -v 0x0e8d \
    -p 0x2870 \
    -V 0x0e8d \
    -P 0x7612 \
    -K
```

Afterwards:

```bash
lsusb
```

shows:

```text
0e8d:7612 MediaTek Inc. MT7612U 802.11a/b/g/n/ac Wireless Adapter
```

and:

```bash
nmcli device
```

shows an interface similar to:

```text
wlx90de804e3255  wifi  disconnected
```

---

## 11. Connect to Wi-Fi

Scan:

```bash
nmcli dev wifi list
```

To connect without placing the Wi-Fi password in shell history:

```bash
nmcli --ask device wifi connect "SKYNRAYN" ifname wlx90de804e3255
```

NetworkManager may also request the Ubuntu account password for permission to modify system network settings.

Successful activation looked like:

```text
Device 'wlx90de804e3255' successfully activated
```

Check the assigned IPv4 address:

```bash
ip -4 addr show wlx90de804e3255
```

During setup:

```text
192.168.0.182/24
```

Check automatic reconnection:

```bash
nmcli connection show SKYNRAYN | grep connection.autoconnect
```

Expected:

```text
connection.autoconnect: yes
```

---

## 12. Wi-Fi boot problem

Although the normal udev rule existed:

```bash
grep -n '0e8d.*2870' \
    /usr/lib/udev/rules.d/40-usb_modeswitch.rules \
    /lib/udev/rules.d/40-usb_modeswitch.rules 2>/dev/null
```

and showed:

```text
ATTR{idVendor}=="0e8d", ATTR{idProduct}=="2870", RUN+="usb_modeswitch '/%k'"
```

the first reboot left the dongle stuck at:

```text
0e8d:2870
```

The boot journal showed that `usb_modeswitch` had been called and reported success:

```bash
sudo journalctl -b | grep -Ei 'usb_modeswitch|0e8d|2870'
```

Restarting its service manually after boot worked:

```bash
sudo systemctl restart usb_modeswitch@1-1.3.4.service
```

and the adapter immediately changed to:

```text
0e8d:7612
```

This established that the problem was a **boot timing/race condition**, not missing hardware support.

---

## 13. Persistent Wi-Fi boot workaround

A delayed one-shot systemd service was added.

### Script

Create:

```bash
sudo nano /usr/local/sbin/titan-wifi-modeswitch
```

Contents:

```bash
#!/bin/bash

# Milk-V Titan / MT7612U Wi-Fi dongle boot-time workaround.
# The dongle sometimes remains in 0e8d:2870 mode during early boot.
# Retry the standard eject-mode switch once the system has settled.

sleep 20

if /usr/bin/lsusb -d 0e8d:2870 >/dev/null 2>&1; then
    /usr/sbin/usb_modeswitch \
        -v 0x0e8d \
        -p 0x2870 \
        -V 0x0e8d \
        -P 0x7612 \
        -K
fi
```

Make executable:

```bash
sudo chmod 755 /usr/local/sbin/titan-wifi-modeswitch
```

### systemd service

Create:

```bash
sudo nano /etc/systemd/system/titan-wifi-modeswitch.service
```

Contents:

```ini
[Unit]
Description=Delayed USB mode switch for Titan MT7612U Wi-Fi adapter
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/titan-wifi-modeswitch

[Install]
WantedBy=multi-user.target
```

Reload and enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable titan-wifi-modeswitch.service
```

Validate the unit:

```bash
sudo systemd-analyze verify \
    /etc/systemd/system/titan-wifi-modeswitch.service
```

No output indicates that the unit file parsed successfully.

### Reboot test

```bash
sudo reboot
```

After reboot:

```bash
lsusb
nmcli device
```

The tested result was:

```text
0e8d:7612 MediaTek Inc. MT7612U 802.11a/b/g/n/ac Wireless Adapter
```

and:

```text
wlx90de804e3255  wifi  connected  SKYNRAYN
```

Ethernet was then physically removed and a fresh SSH connection over Wi-Fi succeeded.

This confirms a complete headless boot path.

---

## 14. Current normal operating state

With Ethernet unplugged:

```bash
nmcli device
```

should resemble:

```text
DEVICE             TYPE      STATE         CONNECTION
wlx90de804e3255    wifi      connected     SKYNRAYN
lo                 loopback  connected     lo
eth0               ethernet  unavailable   --
```

The Wi-Fi address can be checked with:

```bash
ip -4 addr show wlx90de804e3255
```

The Mac connects using:

```bash
ssh titan
```

---

## 15. Cleaning up stale SSH sessions

List logged-in sessions:

```bash
who
```

or:

```bash
w
```

Find the terminal for the current session:

```bash
tty
```

Example:

```text
/dev/pts/2
```

Inspect a stale terminal:

```bash
ps -t pts/0 -o pid,ppid,tty,stat,cmd
```

If killing the shell does not remove the login, inspect its parent `sshd` process:

```bash
ps -p <PPID> -o pid,ppid,tty,stat,cmd
```

Then kill only the stale SSH session process:

```bash
kill <SSHD_PID>
```

Recheck:

```bash
who
```

Do not kill the `pts/N` reported by the current `tty` command.

---

## 16. Temperature and health checks

List hardware monitors:

```bash
for h in /sys/class/hwmon/hwmon*; do
    echo "$h: $(cat "$h/name")"
done
```

This Titan exposed:

```text
nvme
corepvt_ultrarisc
```

Read temperatures:

```bash
for h in /sys/class/hwmon/hwmon*; do
    echo "=== $(cat $h/name) ==="
    grep . $h/temp*_input 2>/dev/null
done
```

Typical readings during setup were around:

- CPU: approximately 40–43 °C
- NVMe: approximately 37–49 °C

Check failed services:

```bash
systemctl --failed
```

Inspect recent kernel messages:

```bash
sudo dmesg -T | tail -40
```

---

## 17. Shutdown

For a clean power-down:

```bash
sudo poweroff
```

Wait for shutdown to complete before removing power.

---

## 18. Quick recovery checklist

If `ssh titan` fails after a future reboot:

1. Check whether the Titan's DHCP address changed.
2. If Wi-Fi is absent, connect Ethernet to the **main Gigabit port**.
3. SSH in over wired Ethernet.
4. Check the dongle:

   ```bash
   lsusb
   ```

5. If it shows `0e8d:2870`, check the delayed service:

   ```bash
   systemctl status titan-wifi-modeswitch.service
   ```

6. Retry the switch manually:

   ```bash
   sudo usb_modeswitch \
       -v 0x0e8d \
       -p 0x2870 \
       -V 0x0e8d \
       -P 0x7612 \
       -K
   ```

7. Check Wi-Fi:

   ```bash
   nmcli device
   ```

8. If normal Ubuntu networking is unavailable, move the patch cable to the **BMC Ethernet port**, identify the BMC IP and use the BMC web console/UART.

---

## 19. Useful identification commands

```bash
uname -a
```

```bash
lsusb
```

```bash
nmcli device
```

```bash
ip addr
```

```bash
systemctl --failed
```

```bash
who
```

```bash
w
```

```bash
sudo journalctl -b
```

---

## 20. Future numerical-computing setup

The intended role of this Titan is to run numerical experiments developed initially in R, with computational kernels potentially moved to compiled C++.

A minimal native C/C++ toolchain can be installed with:

```bash
sudo apt install build-essential cmake
```

Potential numerical libraries, to install only when required:

```bash
sudo apt install libopenblas-dev liblapack-dev libeigen3-dev
```

Because the Titan is RISC-V, native code should normally be compiled directly on the Titan unless a deliberate RISC-V cross-compilation toolchain is being used.

---

## 21. Notes for future maintenance

- Do not assume the DHCP addresses in this document are permanent.
- Consider reserving the Titan's Wi-Fi MAC/address in the router so that `ssh titan` remains stable.
- Keep the vendor-specific Titan kernel in mind when doing major kernel or distribution upgrades.
- Test Wi-Fi after any change to `usb-modeswitch`, `udev`, NetworkManager, kernel packages or firmware.
- Keep the BMC route available as the recovery path for headless operation.
- Do not record account, Wi-Fi or BMC passwords in this document.
