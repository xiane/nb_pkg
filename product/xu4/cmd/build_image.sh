#!/bin/bash

ANDROID_PATH=${ROOT}/${PRODUCT}/android/android
UBOOT_PATH=${ANDROID_PATH}/device/hardkernel/odroidxu3/uboot
OUT=${ROOT}/out/
RESOURCE=${ROOT}/product/${PRODUCT}/resource

build_image() {
	if ! [ -d ${OUT}/${PRODUCT} ]
	then
		mkdir -p ${OUT}/${PRODUCT}
	fi

	echo "Prepare the images"

	if ! [ -f ${ANDROID_PATH}/out/target/product/odroidxu3/update.zip ]
	then
		echo "You have to build android before self install image."
		exit 1
	fi

	pushd ${ANDROID_PATH}/out/target/product/odroidxu3
	cp update.zip ${OUT}/${PRODUCT}
	popd

	pushd ${OUT}/${PRODUCT}
	unzip update.zip
	popd

	sudo mkdir -p /media/${USER}/fat32

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

	# fusing & copy u-boot.
	pushd ${UBOOT_PATH}
	sudo ./sd_fusing.sh /dev/loop0 && sync
	cp ./bl1.bin ${OUT}/${PRODUCT}/update/
	cp ./bl2.bin ${OUT}/${PRODUCT}/update/
	cp ./tzsw.bin ${OUT}/${PRODUCT}/update/
	cp ./u-boot.bin ${OUT}/${PRODUCT}/update/
	popd

	# mount user fat partition.
	sudo mount /dev/loop0p1 /media/${USER}/fat32/

	# copy android images and u-boot binaries.
	sudo cp ${OUT}/${PRODUCT}/update/* /media/${USER}/fat32/

	# copy script for eMMC.
	sudo cp ${RESOURCE}/emmc_boot.ini /media/${USER}/fat32/boot.ini
	sleep 3
	sudo umount /media/${USER}/fat32
	# dump binary
	sudo dd if=/dev/loop0 of=${OUT}/${PRODUCT}/emmc.img count=1024000 && sync

	# copy script for SD.
	sudo mount /dev/loop0p1 /media/${USER}/fat32/
	sudo cp ${RESOURCE}/sd_boot.ini /media/${USER}/fat32/boot.ini
	sleep 3
	sudo umount /media/${USER}/fat32
	# dump binary
	sudo dd if=/dev/loop0 of=${OUT}/${PRODUCT}/sd.img count=1024000 && sync

	# copy script for SD to eMMC.
	sudo mount /dev/loop0p1 /media/${USER}/fat32/
	sudo cp ${RESOURCE}/sd2emmc_boot.ini /media/${USER}/fat32/boot.ini
	sleep 3
	sudo umount /media/${USER}/fat32
	# dump binary
	sudo dd if=/dev/loop0 of=${OUT}/${PRODUCT}/sd2emmc.img count=1024000 && sync

	# umount loop device.
	sudo losetup -d /dev/loop0

	sudo rm /tmp/installer.img
}
