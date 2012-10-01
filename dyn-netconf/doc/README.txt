This initramfs module writes /run/network/dynamic-interfaces based on
interfaces that were brought up during initramfs.

It also replaces 'BOOTIF' in an ip= parameter with the name of the device.  Ie:
  ip=::::<hostname>:BOOTIF
gets changed to something like:
  ip=::::<hostname>:eth0
before configure_networking would be run

If BOOTIF_DEFAULT (example 'BOOTIF_DEFAULT=eth0') is provided, but BOOTIF is
not, then it will act as if BOOTIF was provided with the mac address of the
given NIC.
