#// Build SSR ISO

##// Background:
With SSR version 6.x, we are transitioning from package-based deployments to image-based deployments. Package-based means that software is added/upgraded on the platform using packages (think 'yum') whereas the image-based deployments the entire OS comes as one image and in order to upgrade you get a new image instead of installing a bunch of packages.

Image-based deployments offer many benefits like easily downgrade (in the event of a failed upgrade or bug), create snapshots for recovery purposes (think about the snapshot with Junos), and many others.

The change to image-based deployments introduce a number of foundational changes to how the SSR deployments used to work.

###// Testing environments
- MacOS Sequoia 15.5
- Ubuntu 22.04
- EVE-NG 6.0.2

##// Troubleshooting
###// How to verify the ISO
mkdir /mnt/iso
mount -o loop cdrom.iso /mnt/iso

// End of file //
