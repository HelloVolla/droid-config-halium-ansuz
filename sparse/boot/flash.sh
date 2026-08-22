# README
# Use this script to flash SailfishOS to the Volla Phone Plinius
# The device must be in "fastboot" (or bootloader) mode.
# It may be necessary to run this script as root.
# Usage: sh flash.sh or ./flash.sh

if ! command -v fastboot &> /dev/null
then
    echo "
$(tput setaf 196)fastboot could not be found on your system. Install fastboot (android-tools or android-tools-fastboot) from your package manager.$(tput sgr0)"
    exit
else
    echo "
$(tput setaf 2)fastboot found, proceeding.$(tput sgr0)"
fi

echo "
$(tput setaf 220)Be aware, the flashing process might take up to 10 minutes.
The screen is expected to go black. This is fine, flashing continues.$(tput sgr0)
"

fastboot $* getvar product 2>&1 | grep "^product: k6878v1_64"
if [ $? -ne 0 ] ; then
	echo "$(tput setaf 1)Mismatched image and device$(tput sgr0)";
	exit 1;
fi

handle_error()
{
    echo $@
    exit 2;
}

#Flash kernel and init
fastboot flash boot_a boot.img || handle_error flash boot_a error
fastboot flash boot_b boot.img || handle_error flash boot_b error

#Flash init ramdisk
fastboot flash init_boot_a init_boot.img || handle_error flash init_boot_a error
fastboot flash init_boot_b init_boot.img || handle_error flash init_boot_b error

#Flash vendor_boot
fastboot flash vendor_boot_a vendor_boot.img || handle_error flash vendor_boot_a error
fastboot flash vendor_boot_b vendor_boot.img || handle_error flash vendor_boot_b error

#Flash super
fastboot flash super super.img || handle_error flash super error

#Set slot a
fastboot set_active a || fastboot --set-active=a

# Warn about formatting user data
echo "
$(tput setaf 2)Formatting userdata is required for normal operation the first time sailfish is installed.$(tput sgr0)
$(tput setaf 220)You can skip this if it has previously been done.  Formatting will remove your home data.$(tput sgr0)
$(tput setaf 220)Format userdata? [y/n] $(tput sgr0)
"
read -rsn1 input
if [ "$input" == "y" ] ; then
    fastboot format:ext4 userdata || handle_error format userdata error
fi

echo "
$(tput setaf 2)Flashing process successful.$(tput sgr0)
$(tput setaf 220)Reboot now? [Y/n] $(tput sgr0)
"
read -rsn1 input
if [ "$input" != "n" ] ; then
    fastboot reboot
    break
else
    echo "$(tput setaf 220)Please reboot manually now. (e.g. using fastboot reboot or holding the power button)$(tput sgr0)"
    break
fi
