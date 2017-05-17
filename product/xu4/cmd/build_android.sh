#! /bin/bash
build_android() {
	pushd ${ROOT}/${PRODUCT}/${PLATFORM}/android
	echo "Build Android."
	./build.sh odroidxu3 platform -j${CORE}
	popd

}
