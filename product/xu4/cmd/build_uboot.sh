#! /bin/bash
UBOOT_PATH=${ROOT}/${PRODUCT}/${PLATFORM}/u-boot

	# xu4 used prebuilt u-boot binaries.
build_uboot() {
	:'
	export PATH=${OPT_TOOLCHAIN}/${UBOOT_TOOLCHAIN}/bin:${PATH}
	export CROSS_COMPILE=arm-linux-gnueabihf-

	if ! [ -d ${UBOOT_PATH} ]
	then
		mkdir -p ${UBOOT_PATH}
	fi

	# avoid duplicated works.
	if [ -f ${UBOOT_PATH}/u-boot.bin ]
	then
		echo "U-boot image is already made."
		echo "If you want to build it, please rm by following commands."
		echo "$ rm ${UBOOT_PATH}/u-boot.bin"
		return
	fi

	pushd ${UBOOT_PATH}
	if ! [ -f ${ROOT}/.uboot ]
	then
		echo "Download u-boot source tree."
		git clone https://github.com/hardkernel/u-boot.git -b odroidxu3-v2012.07 ${UBOOT_PATH} && touch ${ROOT}/.uboot
	else
		git pull origin odroidxu3-v2012.07
	fi

	echo "Build u-boot."
	make odroid_config
	make
	popd
	'
}
