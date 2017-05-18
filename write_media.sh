#! /bin/bash

if [ $# -lt 3 ]
then
	echo "Usage: ./write_media.sh <Target Board Name> (emmc|sd|sd2emmc) <target device node>"
    echo "     : When write image to xu3/4, you have to enter the media."
	exit 0
fi

media=$2
target=
platform=android
case $1 in
	"odroidxu4")
		target=xu4
		;;
	"odroidc2")
		target=c2
		;;
	"odroidc1")
		target=c
		;;
	*)
		echo "Wrong argument"
		exit 0
		;;
esac

OUT_PATH=`pwd`/${target}/${platform}/android/out/target/product/odroid${target}

case ${target} in
    xu4) # <target_media> <root_path>
        sudo dd if=`pwd`/out/${target}/${media}.img of=$3 bs=1M
        ;;
    c2|c1)
        sudo dd if=${OUT_PATH}/selfinstall-odroid${target}.bin of=$3 bs=1M
        ;;
esac

sync
sudo eject  $3
