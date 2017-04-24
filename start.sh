#! /bin/bash

OPT_TOOLCHAIN=/opt/toolchains
ANDROID_CROSS_COMPILE=arm-eabi-
CURRENT_PATH=`pwd`
LOCAL_TOOLCHAIN=${CURRENT_PATH}/toolchain

# export environment variables

echo cur_path=$CURRENT_PATH

# check & install toolchain
checkNcreate_toolchain_path() {
	echo "Check toolchain=$OPT_TOOLCHAIN"
	if ! [ -d $OPT_TOOLCHAIN ]
	then
		sudo mkdir -p $OPT_TOOLCHAIN
	fi
}

install_android_toolchain() {
	checkNcreate_toolchain_path

	if  ! [ -d ${OPT_TOOLCHAIN}/${ANDROID_CROSS_COMPILE}4.6 ]
	then
		echo "Download toolchain."
		mkdir ${LOCAL_TOOLCHAIN}
		wget http://dn.odroid.com/ODROID-XU/compiler/arm-eabi-4.6.tar.gz \
			-O ${LOCAL_TOOLCHAIN}/${ANDROID_CROSS_COMPILE}4.6.tar.gz
		sudo tar xvfz ${LOCAL_TOOLCHAIN}/${ANDROID_CROSS_COMPILE}4.6.tar.gz -C ${OPT_TOOLCHAIN}
		echo "Toolchain install is complete."
	else echo "Toolchian is already installed."
	fi
}

install_dependency_packages() {
	case "$DISTRIBUTE" in
		"ubuntu")
			sudo apt -y install 
			;;
		"debian")
			;;
	esac
}

install_android_toolchain
source `pwd`/set_env.sh
