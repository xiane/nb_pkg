#! /bin/bash
ANDROID_PATH=${ROOT}/${PRODUCT}/${PLATFORM}/android

build_android() {
	pushd ${ANDROID_PATH}
	echo "Build Android."
	./build.sh odroidxu3 platform -j${CORE}
	popd

}
