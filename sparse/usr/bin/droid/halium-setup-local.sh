#! /bin/sh

mkdir -p /data/vendor/audiohal/audio_param/
chmod a+w /data/vendor/audiohal/audio_param

# The halium-14 system ships APEXes as .apex files, which droid-hal-startup.sh
# can't bind-mount. Loop-mount their payloads, libhybris needs bionic from the
# runtime APEX and the vendor HALs need VNDK v34.
apex_payload_offset() {
    python3 -c "
import struct, sys, zipfile
info = zipfile.ZipFile(sys.argv[1]).getinfo('apex_payload.img')
if info.compress_type != zipfile.ZIP_STORED:
    sys.exit(1)
with open(sys.argv[1], 'rb') as f:
    f.seek(info.header_offset)
    name_len, extra_len = struct.unpack('<HH', f.read(30)[26:30])
print(info.header_offset + 30 + name_len + extra_len)
" "$1" 2>/dev/null || echo 0
}

for apex in /android/system/apex/*.apex /android/system/system_ext/apex/*.apex; do
    [ -f "$apex" ] || continue
    name=$(basename "$apex" .apex)
    case "$name" in
        com.android.runtime|com.android.art|com.android.i18n|com.android.vndk.*) ;;
        *) continue ;;
    esac

    target=/android/apex/$name
    mountpoint -q "$target" && continue

    offset=$(apex_payload_offset "$apex")
    [ "$offset" -gt 0 ] || continue
    mkdir -p "$target"
    mount -o loop,ro,offset="$offset" "$apex" "$target"
done

# setgid clients such as lipstick drop HYBRIS_LD_LIBRARY_PATH and only get the
# built-in libhybris path, which starts with the droid-hybris dir. Link there
# whatever the compositor path adds on top of /system and /vendor.
hybris_dir=/run/droid-hybris/lib64
hybris_path=$(sed -n "s/^HYBRIS_LD_LIBRARY_PATH=//p" /var/lib/environment/compositor/droid-hal-device.conf)
mkdir -p $hybris_dir
for dir in $(echo "$hybris_path" | tr ":" " "); do
    [ "$dir" = /system/lib64 ] && continue
    for lib in "$dir"/*.so; do
        [ -e "$lib" ] || continue
        name=$(basename "$lib")
        if [ -e "/system/lib64/$name" ] || [ -e "/vendor/lib64/$name" ] || [ -e "$hybris_dir/$name" ]; then
            continue
        fi
        ln -s "$lib" "$hybris_dir/$name"
    done
done
