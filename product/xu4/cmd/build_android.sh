#! /bin/bash

build_android() {
	if ! [ -d $ROOT/${PRODUCT}/${PLATFORM}/android ]; then
		mkdir -p $ROOT/${PRODUCT}/${PLATFORM}/android
	fi

	echo "Download android full source tree."
	echo "!!WARNNING!! Android full source code size is around 58GB!!"

	pushd $ROOT/${PRODUCT}/${PLATFORM}/android
	repo init -u https://github.com/hardkernel/android.git -b 5422_4.4.4_master
	repo sync -j${CORE}
	repo start 5422_4.4.4_master --all

	echo "Build Android."
	./build.sh odroidxu3 all -j${CORE}
	popd

}
