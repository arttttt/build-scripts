#!/bin/bash

cd root
find . | cpio -o -H newc | gzip > ../initramfs.cpio.gz
cd ..

rm -f new_boot.img
tools/mkbootimg --kernel zImage --dt dtb --ramdisk initramfs.cpio.gz -o new_boot.img --cmdline "vpr_resize console=tty1 fbcon=rotate:1 tegraid=40.1.1.0.0 otf_key=c765c04dccd12501f0ba2154786d2c92 panel_id=32ы memtype=0 tsec=32M@4064M tzram=4M@4058M commchip_id=0 usb_port_owner_info=0 lane_owner_info=0 emc_max_dvfs=0 touch_id=0@2150632068 video=tegrafb no_console_suspend=1 debug_uartport=lsport,3 sku_override=0 usbcore.old_scheme_first=1 lp0_vec=2896@0xfdfff000 tegra_fbmem=25296896@0xad012000 nvdumper_reserved=0xfd700000 core_edp_mv=1150 core_edp_ma=4000 pmuboard=0x06c8:0x03e8:0x00:0x44:0x04 displayboard=0x8038:0x0000:0x00:0x00:0x00 power_supply=Battery board_info=0x06f4:0x044c:0x03:0x41:0x07 tegraboot=sdmmc gpt gpt_sector=41983 modem_id=1 watchdog=disable nck=1048576@0xfd700000"

rm initramfs.cpio.gz
