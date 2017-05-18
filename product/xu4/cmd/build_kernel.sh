#! /bin/bash

ANDROID_PATH=${ROOT}/${PRODUCT}/${PLATFORM}/android
KERNEL_PATH=${ANDROID_PATH}/kernel/samsung/exynos5422

build_kernel() {
	# avoid duplicated works.
	if [ -f ${KERNEL_PATH}/arch/arm/boot/Image ]
	then
		echo "Kernel is already made."
		echo "If you want to build it, please rm by following commands."
		echo "$ rm ${KERNEL_PATH}/arch/arm/boot/Image"
		return
	fi

	pushd ${ANDROID_PATH}
	echo "Build Kernel."
	./build.sh odroidxu3 kernel -j${CORE}
	echo "Kernel build complete."
	popd
}
