# minix-boot-loader
Customized Minix Boot Loader with examples of BIOS 13h and 16h calls, before loading the original bootloader.
After starting, it waits for the user to write either 'y' or 'n' option. It saves the choice in the 2nd section of the used partition and proceeds with uploading an original boot loader. 

It can be installed on a running Minix instance with `install.sh` script. 
