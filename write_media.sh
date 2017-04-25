#! /bin/bash

if [ $# -lt 3 ]
then
	echo "Usage: ./write_media.sh <Target Board Name> (sd|emmc) <target device node>"
	exit 0
fi

target=
case $1 in
	"odroidxu4")
		$target=xu3
		;;
	"odroidc2")
		$target=c2
		;;
	"odroidc1")
		$target=c
		;;
	*)
		echo "Wrong argument"
		exit 0
		;;
esac

OUT_PATH=`pwd`/android/out/target/product/${target}

if [ $target != "xu3" ]
then
	sudo dd if=${OUT_PATH}/selfinstall-odroid${target}.bin of=$3 bs=1M
else
#TODO : xu3 case must be impl
fi

sync
sudo eject  $3
