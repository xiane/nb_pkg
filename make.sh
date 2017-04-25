#! /bin/bash

OPT_TOOLCHAIN=/opt/toolchains
XU4_ANDROID_TOOLCHAIN=arm-eabi-4.6
#TODO
C2_ANDROID_TOOLCHAIN=gcc-linaro-aarch64-linux-gnu-4.9_linux
C2_KERNEL_TOOLCHAIN=
C1_TOOLCHAIN=
ANDROID_CROSS_COMPILE=
ROOT_PATH=`pwd`
CMD_PATH=${ROOT_PATH}/cmd
LOCAL_TOOLCHAIN=${ROOT_PATH}/toolchain
CORE=`cat /proc/cpuinfo | grep cores | wc -l`

make() {
	option="a"
	target_board="odroid"

	echo $#
	#check target board name
	if [ $# -lt 1 ]
	then
		echo "Usage: ./make.sh <Target Board Name> [help|u|k|n|a]"
		exit 0
	fi

	case $1 in
		"odroidxu4")
			target_board="xu4"
			;;
		"odroidc2")
			taget_board="c2"
			;;
		"odroidc1")
			target_board="c1"
			;;
		*)
			echo "I couldn't identify your board."
			echo "Please check your board name."
			exit 0
			;;
	esac

	#TODO
	case $target_board in
		"xu4")
			ANDROID_CROSS_COMPILE=${XU4_ANDROID_TOOLCHAIN}
			;;
		"c2")
			ANDROID_CROSS_COMPILE=${C2_ANDROID_TOOLCHAIN}
			;;
		"c1")
			ANDROID_CROSS_COMPILE=${C1_TOOLCHAIN}
			;;
	esac

	if [ $option == "a" ]
	then
		install_dependency_packages
		install_android_toolchain
		install_repo

		source ${CMD_PATH}/set_env.sh

		build_android
	fi
}

install_dependency_packages() {
	_DISTRIBUTE=`lsb_release -i -s`
	RELEASE=`lsb_release -r -s`

	# check distributor
	case "$_DISTRIBUTE" in
		"Ubuntu")
			export DISTRIBUTE="ubuntu"
			;;
		"Debian")
			export DISTRIBUTE="debian"
			;;
		*)
			echo "Not yet support other os"
			exit 0
			;;
	esac

	# install dependency packages
	case "$DISTRIBUTE" in
		"ubuntu")
			# check java version
			if ! [ `java -version 2>&1 | grep -i openjdk` ]
			then
				# add java repository
				sudo add-apt-repository -y ppa:webupd8team/java
				sudo apt-get update
			fi

            # reference : https://source.android.com/source/initializing
			case "$RELEASE" in
				"14.04")
					sudo apt -y install wget curl oracle-java6-installer \
						git-core gnupg flex bison gperf build-essential \
						zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
						lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache \
						libgl1-mesa-dev libxml2-utils xsltproc unzip
					;;
				"16.04")
					# TODO : check dependency
					sudo apt -y install wget curl 
					;;
			esac
			;;
		"debian")
			;;
	esac
}

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

	if  ! [ -d ${OPT_TOOLCHAIN}/${ANDROID_CROSS_COMPILE} ]
	then
		echo "Download toolchain."
		mkdir ${LOCAL_TOOLCHAIN}
		wget http://dn.odroid.com/${ANDROID_CROSS_COMPILE}.tar.gz \
			-O ${LOCAL_TOOLCHAIN}/${ANDROID_CROSS_COMPILE}.tar.gz
		sudo tar xvfz ${LOCAL_TOOLCHAIN}/${ANDROID_CROSS_COMPILE}.tar.gz -C ${OPT_TOOLCHAIN}
		echo "Toolchain install is complete."
	else echo "Toolchian is already installed."
	fi
}

# check n install repo
install_repo() {
	REPO=`which repo`

	if [ "$REPO" == "" ]
	then
		echo "Install repo"
		# create repo bin
		mkdir ~/bin
		#download
		curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
		export PATH=~/bin:$PATH
		chmod a+x ~/bin/repo
	fi
}

build_android() {
	if ! [ -d ${ROOT_PATH}/android ]; then
		mkdir ${ROOT_PATH}/android
	fi

	echo "Download android full source tree."
	echo "!!WARNNING!! Android full source code size is around 58GB!!"

	cd ${ROOT_PATH}/android
	repo init -u https://github.com/hardkernel/android.git -b 5422_4.4.4_master
	repo sync -j${core}
	repo start 5422_4.4.4_master --all

	echo "Build Android."
	./build.sh odroidxu3 all -j${CORE}
}

make