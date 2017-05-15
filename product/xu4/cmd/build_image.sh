#!/bin/bash

UBOOT_PATH=${ROOT}/${PRODUCT}/android/u-boot
ANDROID_PATH=${ROOT}/${PRODUCT}/android/android/android
OUT=${ROOT}/out/
RESOURCE=${ROOT}/product/${PRODUCT}/resource

build_image() {
	if ! [ -d ${OUT} ]
	then
		mkdir -p ${OUT}
	fi

	echo "Prepare the images"

	if ! [ -f ${UBOOT_PATH}/u-boot.bin ]
	then
		echo "You have to build u-boot before make self install image."
		exit 1
	fi

	if ! [ -f ${ANDROID_PATH}/out/target/product/odroidxu3/update.zip ]
	then
		echo "You have to build android before self install image."
		exit 1
	fi

	pushd ${ANDROID_PATH}/out/target/product/odroidxu3
	cp update.zip ${OUT}
	popd

	pushd ${OUT}
	unzip update.zip
	popd

	sudo mkdir /media/${USER}/fat32

	sudo umount /media/${USER}/fat32
	sudo losetup -d /dev/loop0

	# make image of loop devices filled zero.
	dd if=/dev/zero of=/tmp/installer.img count=1024000

	# mount loop devices.
	sudo losetup /dev/loop0 /tmp/installer.img

	# create partition table.
	sudo parted /dev/loop0 mktable msdos

	# make file-system.
	sudo parted /dev/loop0 mkpart primary fat32 90 525

	# format file-system.
	sudo mkfs.vfat -F 32 /dev/loop0p1

	# fusing u-boot.
	pushd ${UBOOT_PATH}/sd_fuse/hardkernel
	sudo ./sd_fusing.sh /dev/loop0
	popd

	# mount user fat partition.
	sudo mount /dev/loop0p1 /media/${USER}/fat32/

	# copy android images and u-boot binaries.
	sudo cp ${OUT}/update/* /media/${USER}/fat32/

	# copy script for eMMC.
	sudo cp ${RESOURCE}/emmc_boot.ini /media/${USER}/fat32/boot.ini
	sleep 3
	sudo umount /media/${USER}/fat32
	# dump binary
	sudo dd if=/dev/loop0 of=${OUT}/xu4-emmc.img count=1024000

	# copy script for SD.
	sudo mount /dev/loop0p1 /media/${USER}/fat32/
	sudo cp ${RESOURCE}/sd_boot.ini /media/${USER}/fat32/boot.ini
	sleep 3
	sudo umount /media/${USER}/fat32
	# dump binary
	sudo dd if=/dev/loop0 of=${OUT}/xu4-sd.img count=1024000

	# copy script for SD to eMMC.
	sudo mount /dev/loop0p1 /media/${USER}/fat32/
	sudo cp ${RESOURCE}/xu4-sd2emmc_boot.ini /media/${USER}/fat32/boot.ini
	sleep 3
	sudo umount /media/${USER}/fat32
	# dump binary
	sudo dd if=/dev/loop0 of=${OUT}/xu4-sd2emmc.img count=1024000

	# umount loop device.
	sudo losetup -d /dev/loop0

	sudo rm /tmp/installer.img
}
