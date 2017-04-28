#! /bin/bash

KERNEL_PATH=$ROOT/$PRODUCT/$PLATFORM/kernel

build_kernel() {
	if ! [ -d $KERNEL_PATH ]; then
		mkdir -p $KERNEL_PATH
	fi

	if ! [ -d $KERNEL_PATH ]
	then
		mkdir -d $KERNEL_PATH
	fi

	# avoid duplicated works.
	if [ -f $KERNEL_PATH/arch/arm/boot/Image ]
	then
		echo "Kernel is already made."
		echo "If you want to build it, please rm by following commands."
		echo "$ rm $KERNEL_PATH/arch/arm/boot/Image"
		return
	fi

	pushd $KERNEL_PATH
	if ! [ -f $ROOT/.kernel ]
	then
		echo "Download kernel source tree."
		git clone --depth 1 https://github.com/hardkernel/linux.git -b odroidxu3-3.10.y-android $KERNEL_PATH && touch $ROOT/.kernel
	else
		git pull origin odroidxu3-3.10.y-android
	fi

	echo "Build kernel."
	make odroidxu3_defconfig
	make -j$CORE
	popd
}
