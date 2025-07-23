# Build SSR ISO

## Background:
With SSR version 6.x, Juniper is transitioning from package-based deployments to image-based deployments methods. There is a lot of benefits of the image-based deployments but it drastically changes the initialization process. This project helps with streamlining the USB bootstrapping process of the SSR.

### Testing environments
- MacOS Sequoia 15.5
- Ubuntu 22.04
- EVE-NG 6.2.0

## References
- [Initialize - Advanced](https://docs.128technology.com/docs/initialize_u-iso_adv_workflow)
- [Initialize - Azure BYOL](https://www.juniper.net/documentation/us/en/software/session-smart-router/docs/intro_installation_byol_azure_conductor/)

## Troubleshooting
### How to verify the ISO
- mkdir /mnt/iso
- mount -o loop cdrom.iso /mnt/iso

## End of file
