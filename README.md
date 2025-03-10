# Documentation

## Quick Links
[How to use](#how-to-use)
[Build Instructions](https://github.com/PartialVolume/shredos.x86_64?tab=readme-ov-file#compiling-shredos-and-burning-to-usb-stick-the-harder-way-)  
[Changes in the custom build](#changes-in-the-custom-build)  
[Official Documentation](https://github.com/PartialVolume/shredos.x86_64)  


## How to use
These instructions are in addition to the official [ShredOS repo](https://github.com/PartialVolume/shredos.x86_64)
- Build the image as per the upstream documentation.
- Mount image so it's available for the PXE boot setup.
- Create a directory to store the [CTA Hardward Info](https://github.com/CommunityTechaid/HardwardInfo) scripts on the server.
	(eg `mkdir /srv/netboot/shredos/HardwardInfoScripts`)
- Copy / clone scripts into the folder
	(`git clone https://github.com/CommunityTechaid/HardwardInfo /srv/netboot/shredos/HardwardInfoScripts`)
- Add kernal parameters to the `menu.ipxe` file (Or `/boot/grub/grub.cfg` and `/EFI/grub/grub.cfg` if not using the PXE setup)
	- Get the scripts
		- `get_scripts="open 10.0.0.1; user ServerUser Password; cd path/To/HardwardInfo/Scripts; mget -O /usr/bin/scripts ./*sh; exit`
  		- The custom scripts directory on the server should hold all the scripts that need to be executed before or after nwipe. The scripts should be named as follows. 
			- `pre_00X[scriptname].sh` for all scripts that need to be run *before* nwipe is launched. `00X` is a number used to denote precedence.  Lower numbered scripts are executed first. 
			- `post_00X[scriptname].sh` for all scripts that need to be run *after* nwipe is launched.- 
	- Nwipe_logs param (old setup using the .txt logs)
   		- `lftp="open 10.0.0.1; user ServerUser Password; cd shredos; mput nwipe_*.txt; exit`
     	- JSON device logs
      		- `lftp="open 10.0.0.1; user ServerUser Password; cd shredos; mput device*.json; exit`

- Note: Make sure the custom scripts are tested. If one script fails. the execution of the remaining scripts are abandoned. Some logs will be available in scripts.log but on the filesystem. 

## Changes in the custom build

### Changes to `nwipe_launcher`
The nwipe\_launcher (`board/shredos/fsoverlay/usr/bin/nwipe_launcher.sh`) is the main script that is launched in the terminal that is responsible for launching nwipe. The following changes were introduced to the script. 

- Hooks to run execute custom scripts before and after nwipe executes was introduced. `nwipe_launcher.sh` gets the lftp command that was passed through the `get_scripts` parameter that can be configured in grub.cfg (check ShredOS documentation for more instructions on grub.cfg). This parameter expects an `lftp` command to grab custom scripts from the local ftp server and place them in a scripts directory (`/urs/bin/scripts/`). All scripts named `pre_*.sh` will be executed before nwipe is launched and all scripts named `post_*.sh` will be executed after nwipe completes. 
- `nwipe_launcher` also creates an output folder (`/usr/output/`) which can be used to store the results of any custom scripts that are executed. These results can be then transferred to a local ftp server using another lftp command that should be configured in grub.cfg the same way as above. Refer [GitHub - ShredOs documentation](https://github.com/PartialVolume/shredos.x86_64?tab=readme-ov-file#transferring-nwipe-log-files-to-a-ftp-server)
- A confirmation was added before nwipe is launched. If you answer N (anything but Y technically), nwipe will not be run. **Note that post_*.sh scripts will still be executed.**

The following new scripts were also added: 
(all scripts are in `board/shredos/fsoverlay/usr/bin/`)
- `pre.sh` : Executes all the `pre_*.sh` scripts inside `/usr/bin/scripts/`. Executed by `nwipe_launcher`
- `post.sh` Executes all the `post_*.sh` scripts inside `/usr/bin/scripts/`Executed by `nwipe_launcher`
These will be executed only if the `get_scripts` argument is found.

### New packages

The following packages are part of this build (configured using buildroot):
- `dialog`
- `jq`
- `lshw`
- `lsblk`

If starting from scratch, after running `make shredos_defconfig`, run `make menuconfig` to ensure that they are added.

Add them via the Target packages menu:
	> Shell and utilities > dialog
	> Development tools > jq
	> Hardware handling > lshw

(Optional: Build Options > Enable compiler cache - This option will enable the use of ccache, a compiler cache. It will cache the result of previous builds to speed up builds.)

Save the config, exit and run `make` to build the image.