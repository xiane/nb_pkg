#!/bin/bash

MEDIA=$1
ROOT=$2

UBOOT_ROOT=$ROOT/xu4/android/u-boot
ANDROID_ROOT=$ROOT/xu4/android/android
OUT=$ROOT/out/
RESOURCE=$ROOT/product/xu4/resource

echo "Prepare the images"

if ! [ -f $ROOT/xu4/android/android/out/target/product/odroidxu3/update.zip ]
then
    echo "Use have to build android before using this."
    exit 1
fi

pushd $ROOT/xu4/android/android/out/target/product/odroidxu3
cp update.zip $OUT
popd

pushd $OUT
unzip update.zip
popd

sudo mkdir /media/$USER/fat32

sudo umount /media/$USER/fat32
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
pushd ${UBOOT_ROOT}/sd_fuse/hardkernel
sudo ./sd_fusing.sh /dev/loop0
popd

# mount user fat partition.
sudo mount /dev/loop0p1 /media/$USER/fat32/

# copy android images and u-boot binaries.
sudo cp $OUT/update/* /media/$USER/fat32/

case $MEDIA in
    emmc)
        # copy script for eMMC.
        sudo cp ${RESOURCE}/emmc_boot.ini /media/$USER/fat32/boot.ini
        sleep 3
        sudo umount /media/$USER/fat32
        # dump binary
        sudo dd if=/dev/loop0 of=$OUT/xu4-emmc.img count=1024000
        ;;

    sd)
        # copy script for SD.
        sudo mount /dev/loop0p1 /media/$USER/fat32/
        sudo cp ${RESOURCE}/sd_boot.ini /media/$USER/fat32/boot.ini
        sleep 3
        sudo umount /media/$USER/fat32
        # dump binary
        sudo dd if=/dev/loop0 of=$OUT/xu4-sd.img count=1024000
        ;;

    sd2emmc)
        # copy script for SD to eMMC.
        sudo mount /dev/loop0p1 /media/$USER/fat32/
        sudo cp ${RESOURCE}/xu4-sd2emmc_boot.ini /media/$USER/fat32/boot.ini
        sleep 3
        sudo umount /media/$USER/fat32
        # dump binary
        sudo dd if=/dev/loop0 of=$OUT/xu4-sd2emmc.img count=1024000
        ;;
esac

# umount loop device.
sudo losetup -d /dev/loop0

sudo rm /tmp/installer.img
