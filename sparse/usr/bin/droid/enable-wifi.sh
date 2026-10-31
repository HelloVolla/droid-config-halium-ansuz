#!/bin/bash
# Possible values for /dev/wmtWifi
# 0 Power Off
# 1 Power On
# S Station/P2P mode
# P Also Station/P2P mode
# A AP mode
# C Concurrent mode
# N Disable concurrent mode
# D Dual P2P mode
# E Dual AP mode
# LLM0x9999 Low Latency
# WR-BUF:NVRAM
# WR-BUF:DRVCFG
# WR-BUF:FWCFG
# RM-BUF:DRVCFG
# RM-BUF:FWCFG
# Newer devices als have
# 2 Test mode

# Wait for the property system to be up.
while [ ! -e /dev/socket/property_service ]; do sleep 0.1; done

# Wait for nvram to be loaded.
while [ "$(getprop vendor.service.nvram_init)" != "Ready" ]; do sleep 0.2; done


# The WLAN driver lives in vendor_dlkm, outside the host's module tree.
# mac80211 needs libarc4 from system_dlkm.
modprobe -q libarc4
for mod in cfg80211 mac80211 wlan_drv_gen4m_6878; do
    insmod /vendor_dlkm/lib/modules/$mod.ko 2>/dev/null
done

# Silence all wlan debug logging down to just errors/warnings
printf '0xFF:0x03' > /proc/net/wlan/dbgLevel

# Wait for nvram yet again..
while [ "$(getprop vendor.mtk.nvram.ready)" != "1" ]; do sleep 0.2; done

# Wait for /dev/wmtWifi to exist..
while [ ! -c /dev/wmtWifi ]; do sleep 0.2; done

# Avoid ap0 interface getting created on some boots
sleep 1

# Finally enable the adapter in station mode
echo P > /dev/wmtWifi


# Enable WoWLAN to avoid network disconnect before suspend
while [ ! -e /sys/class/ieee80211/phy0 ]; do sleep 1; done
iw phy phy0 wowlan enable magic-packet
