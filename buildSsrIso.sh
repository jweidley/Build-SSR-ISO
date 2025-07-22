#!/bin/bash
# Purpose: MacOS: Build a custom ISO for SSR image-based deployments (6.x)
# Version: 0.4 
#--------- Changelog-------------
# 0.4 - 16Jul25 - MacOS/EVE version
# 0.3 - 14Jul25 - autocopy cdrom.iso to the end location
# 0.2 - 10Jul25 - Added prompts & defaults for values
# 0.1 - Initial script from Larry Sherrow
############################################################################################
# TODO
# 1. check for genisoimage & maybe hdiutil packages, fail if not installed & provide a hint.
############################################################################################

#############
# Variables
# - Default values, these are useful if you create a lot of similiarly configured fabrics
#############
CONDUCTOR_NAME="Conductor"
CONDUCTOR_IP='10.255.255.10'
CONDUCTOR_PREFIX='24'
CONDUCTOR_GW='10.255.255.1'
CONDUCTOR_INTF='ge-0-0'
DNS_SVR='8.8.8.8'
ROUTER_NAME="Herndon"

#############
# Functions
#############
buildConductor () {
        # Set default variables
        TEMPLATE='./iso-files/conductor.template'

	# Get/confirm implementation values
	read -rp "  Enter Conductor name [${CONDUCTOR_NAME}]: " conductorName
	read -rp "  Enter Conductor IP [${CONDUCTOR_IP}]: " conductorIp
	read -rp "  Enter Conductor IP Mask [${CONDUCTOR_PREFIX}]: " conductorMask
	read -rp "  Enter Conductor Gateway [${CONDUCTOR_GW}]: " conductorGw
	read -rp "  Enter Conductor Interface [${CONDUCTOR_INTF}]: " conductorIntf

	# Make variable changes
	echo "- Making variable substitutions"
	if [[ -n "$conductorName" ]]; then CONDUCTOR_NAME=$conductorName; fi
	if [[ -n "$conductorIp" ]]; then CONDUCTOR_IP=$conductorIp; fi
	if [[ -n "$conductorMask" ]]; then CONDUCTOR_PREFIX=$conductorMask; fi
	if [[ -n "$conductorGw" ]]; then CONDUCTOR_GW=$conductorGw; fi
	if [[ -n "$conductorIntf" ]]; then CONDUCTOR_INTF=$conductorIntf; fi

         # Concatenate conductor IP & mask
         CONDUCTOR_IM="${CONDUCTOR_IP}/${CONDUCTOR_PREFIX}"

	# Create conductor JSON
	echo "- Building custom onboarding-config.json file"
	if [ -f onboarding-config.json ]; then rm -f onboarding-config.json; fi
	cp ${TEMPLATE} onboarding-config.json

         # Need to test the -i.bak on Linux to ensure it works the same!
	sed -i.bak "s/CONDUCTOR_NAME/$CONDUCTOR_NAME/" onboarding-config.json > /dev/null 2>&1
	sed -i.bak "s|CONDUCTOR_IP|$CONDUCTOR_IM|" onboarding-config.json > /dev/null 2>&1
	sed -i.bak "s/CONDUCTOR_GW/$CONDUCTOR_GW/" onboarding-config.json > /dev/null 2>&1
	sed -i.bak "s/CONDUCTOR_INTF/$CONDUCTOR_INTF/" onboarding-config.json > /dev/null 2>&1

	echo "- Creating tmp iso directory"
	mkdir -p iso_tmp

	echo "- Copying important files to iso_tmp"
	cp onboarding-config.json iso_tmp/
	# When bootstrapping a conductor, if you include the pre/post-bootstrap files in the ISO
	# the bootstrapping process will fail!
	#cp pre-bootstrap iso_tmp/
	#cp post-bootstrap iso_tmp/

	# Build the ISO
	buildISO
}

buildRouter () {
        # Set default variables
        TEMPLATE='./iso-files/router.template'

	# Get/confirm implementation values
	read -rp "  Enter Conductor IP [${CONDUCTOR_IP}]: " conductorIp
	read -rp "  Enter DNS server IP [${DNS_SVR}]: " dnsSvr
	read -rp "  Enter Router name [${ROUTER_NAME}]: " routerName

	# Make variable changes
	echo "- Making variable substitutions"
	if [[ -n "$conductorIp" ]]; then CONDUCTOR_IP=$conductorIp; fi
	if [[ -n "$dnsSvr" ]]; then DNS_SVR=$dnsSvr; fi
	if [[ -n "$routerName" ]]; then ROUTER_NAME=$routerName; fi

	# Create router JSON
	echo "- Building custom onboarding-config.json file"
	if [ -f onboarding-config.json ]; then rm -f onboarding-config.json; fi
	cp ${TEMPLATE} onboarding-config.json

	sed -i.bak "s/CONDUCTOR_IP/$CONDUCTOR_IP/" onboarding-config.json > /dev/null 2>&1
	sed -i.bak "s/DNS_SVR/$DNS_SVR/" onboarding-config.json > /dev/null 2>&1
	sed -i.bak "s/ROUTER_NAME/$ROUTER_NAME/" onboarding-config.json > /dev/null 2>&1

	echo "- Creating tmp iso directory"
	mkdir -p iso_tmp

	echo "- Copying important files to iso_tmp"
	cp onboarding-config.json iso_tmp/
	cp iso-files/pre-bootstrap iso_tmp/
	cp iso-files/post-bootstrap iso_tmp/
	cp iso-files/devicemap.json iso_tmp/
	chmod +x iso-files/*

	# Build the ISO
	buildISO $OS
}

buildISO () {
	echo "- Removing old cdrom.iso"
	if [ -f cdrom.iso ]; then rm -f cdrom.iso; fi

         if [ "$OS" = "Darwin" ]; then
	   echo "- Building ISO (MacOS)..."
	   hdiutil makehybrid -iso -joliet -iso-volume-name "BOOTSTRAP" -joliet-volume-name "BOOTSTRAP" -o cdrom.iso iso_tmp
            # Below seems correct but the volumn name is iso_tmp so the bootstrap fails
	   #hdiutil makehybrid -iso -joliet -iso-volume-name "BOOTSTRAP" -o cdrom.iso iso_tmp
            # UDF doesnt work, the SSR VM doesnt bootstrap even though the volumn name is BOOTSTRAP
	   #hdiutil makehybrid -iso -udf -iso-volume-name "BOOTSTRAP" -udf-volume-name "BOOTSTRAP" -o cdrom.iso iso_tmp
	   #hdiutil makehybrid -o "output.iso" "iso_tmp/" -volname BOOTSTRAP -iso -joliet
         elif [ "$OS" = "Linux" ]; then
	   echo "- Building ISO (Linux)..."
	   genisoimage -o cdrom.iso -J -R -V BOOTSTRAP iso_tmp/
         fi

	echo "- Cleaning up"
	rm -f onboarding-config.json
	rm -f onboarding-config.json.bak
	rm -rf iso_tmp

	# Finished & Next Steps
         if [ "$OS" = "Darwin" ]; then
	   echo "! Finished creating SSR Bootstrapper ISO !"
	   echo "MacOS Next Steps: "
	   echo "- Move cdrom.iso to the hypervisor to use as a boot device"
	   echo "- Use a tool to create a bootable USB"
         elif [ "$OS" = "Linux" ]; then
	   # Prompt for file copy
           read -rp "  Copy cdrom.iso to EVE directory [y/n]: " fileCopy

           if [ "$fileCopy" = "y" ]; then
                copyISO
           else
                echo "NO file copy chosen. Exiting"
                exit 1
           fi
	   copyISO
         fi
}

copyISO () {
        echo "- Where should the new ISO be copied? Select the destination folder: "
        ls -ld /opt/unetlab/addons/qemu/128T*

        echo " "
        read -rp "  Enter Destination Folder: " destFolder

        echo "- Copying the ISO to the desired folder"
        cp cdrom.iso $destFolder

        # Fix EVE permissions
        echo "- Fixing EVE permissions"
        /opt/unetlab/wrappers/unl_wrapper -a fixpermissions

        # Finished
        echo "! Custom ISO created and staged for deployment !"
        exit 1
}

#############
# Main
#############
# OS Handling
UNAME=$(uname)

if [ "$UNAME" = "Darwin" ]; then
    OS="Darwin"
elif [ "$UNAME" = "Linux" ]; then
    OS="Linux"
fi

echo "################################################"
echo "# Custom SSR Bootstrap Creator"
echo "################################################"
echo "Choose onboarding mode:"
echo "  (c) Conductor"
echo "  (m) Conductor-Managed"
read -rp "Enter choice [c/m]: " CHOICE

case "$CHOICE" in
  c|C)
    buildConductor
   ;;
  m|M)
    buildRouter
    ;;
  *)
    echo "Invalid choice: exiting."
    exit 1
    ;;
esac

## End of Script ##
