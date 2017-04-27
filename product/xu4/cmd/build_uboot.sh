#! /bin/bash

build_uboot() {
	export PATH=${OPT_TOOLCHAIN}/${UBOOT_TOOLCHAIN}/bin:$PATH
	export CROSS_COMPILE=arm-linux-gnueabihf-

	if ! [ -d $ROOT/${PRODUCT}/${PLATFORM} ]; then
		mkdir -p $ROOT/${PRODUCT}/${PLATFORM}
	fi

	# avoid duplicated works.
	if [ -f $ROOT/$PRODUCT/$PLATFORM/u-boot/u-boot.bin ]
	then
		return
	fi

	echo "Download u-boot source tree."
	pushd $ROOT/${PRODUCT}/${PLATFORM}
	git clone https://github.com/hardkernel/u-boot.git -b odroidxu3-v2012.07
	cd u-boot

	echo "Build u-boot."
	make odroid_config
	make
	popd
}
