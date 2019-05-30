#!/bin/bash

export ARCH="arm"
export KBUILD_BUILD_HOST=$(lsb_release -d | awk -F":"  '{print $2}' | sed -e 's/^[ \t]*//' | sed -r 's/[ ]+/-/g')
export KBUILD_BUILD_USER="$USER"

clean_build=0
config="tegra12_defconfig"
dtb_name="tegra124-mocha.dtb"
dtb_only=0
kernel_name=$(git rev-parse --abbrev-ref HEAD)
cpus_count=$(grep -c ^processor /proc/cpuinfo)
toolchain=PUT YOUR TOOLCHAIN PATH HERE

KERNEL_DIR=$PWD
ORIGINAL_OUTPUT_DIR="$KERNEL_DIR/arch/$ARCH/boot"
OUTPUT_DIR="$KERNEL_DIR/output"

ERROR=0
HEAD=1
WARNING=2

function printfc() {
	if [[ $2 == $ERROR ]]; then
		printf "\e[1;31m$1\e[0m"
		return
	fi;
	if [[ $2 == $HEAD ]]; then
		printf "\e[1;32m$1\e[0m"
		return
	fi;
	if [[ $2 == $WARNING ]]; then
		printf "\e[1;35m$1\e[0m"
		return
	fi;
}

function make_img()
{
	if [[ -d "$KERNEL_DIR/Initramfs" ]]; then
		printfc "\Creating boot.img\n\n" $HEAD
	else
		printfc "\nFolder $KERNEL_DIR/Initramfs does not exist\n\n" $ERROR
		return
	fi;

	if [[ -f "$ORIGINAL_OUTPUT_DIR/zImage" ]]; then
		mv $ORIGINAL_OUTPUT_DIR/zImage $PWD/Initramfs/
	else
		if [[ $dtb_only == 0 ]]; then
			printfc "File $ORIGINAL_OUTPUT_DIR/zImage does not exist\n\n" $ERROR
			return
		fi
	fi

	if [[ -f "$ORIGINAL_OUTPUT_DIR/dts/$dtb_name" ]]; then
		mv $ORIGINAL_OUTPUT_DIR/dts/$dtb_name $PWD/Initramfs/dtb
	else
		if [[ $dtb_only == 0 ]]; then
			printfc "File $ORIGINAL_OUTPUT_DIR/dts/$dtb_name does not exist\n\n" $ERROR
			return
		fi
	fi

	cd $KERNEL_DIR/Initramfs

	./build.sh

	cd $KERNEL_DIR
}

function compile()
{
	local start=$(date +%s)
	clear

	if [[ "$clean_build" == 1 ]]; then
		make clean
		make mrproper
	fi

	make $config
	make -j$threads ARCH=$ARCH CROSS_COMPILE=$toolchain zImage

	printfc "\nCompiling device tree\n\n" $HEAD

	make -j$threads ARCH=$ARCH CROSS_COMPILE=$toolchain $dtb_name

	local end=$(date +%s)
	local comp_time=$((end-start))
	printf "\e[1;32m\nKernel compiled for %02d:%02d\n\e[0m" $((($comp_time/60)%60)) $(($comp_time%60))

	make_img
}

function compile_dtb()
{
	clear

	dtb_only=1
	make $config
	make -j$threads ARCH=$ARCH CROSS_COMPILE=$toolchain $dtb_name

	if [[ -f "$ORIGINAL_OUTPUT_DIR/dts/$dtb_name" ]]; then
		mv $ORIGINAL_OUTPUT_DIR/dts/$dtb_name $PWD/anykernel/kernel/dtb
	else
		printfc "File $ORIGINAL_OUTPUT_DIR/dts/$dtb_name does not exist\n\n" $ERROR
		return
	fi

	make_img
}

function main()
{
	clear
	echo "---------------------------------------------------"
	echo "Run a clean build?                                -"
	echo "---------------------------------------------------"
	echo "1 - Yes                                           -"
	echo "---------------------------------------------------"
	echo "2 - No                                            -"
	echo "---------------------------------------------------"
	echo "3 - compile dtb only                              -"
	echo "---------------------------------------------------"
	echo "4 - Exit                                          -"
	echo "---------------------------------------------------"
	printf %s "Your choice: "
	read env

	case $env in
		1) clean_build=1;compile;;
		2) compile;;
		3) compile_dtb;;
		4) clear;return;;
		*) main;;
	esac
}

main
