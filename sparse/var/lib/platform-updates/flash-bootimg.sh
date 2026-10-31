#!/bin/sh

/usr/sbin/flash-partition boot_a /boot/boot.img
/usr/sbin/flash-partition boot_b /boot/boot.img

/usr/sbin/flash-partition init_boot_a /boot/init_boot.img
/usr/sbin/flash-partition init_boot_b /boot/init_boot.img

/usr/sbin/flash-partition vendor_boot_a /boot/vendor_boot.img
/usr/sbin/flash-partition vendor_boot_b /boot/vendor_boot.img
