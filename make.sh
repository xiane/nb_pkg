#! /bin/bash

OPT_TOOLCHAIN=/opt/toolchains
XU4_ANDROID_TOOLCHAIN=arm-eabi-4.6
XU4_UBOOT_TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-4.7-2013.04-20130415_linux

#TODO
C2_ANDROID_TOOLCHAIN=gcc-linaro-aarch64-linux-gnu-4.9_linux
C2_KERNEL_TOOLCHAIN=

C1_TOOLCHAIN=

UBOOT_TOOLCHAIN=
KERNEL_TOOLCHAIN=
ANDROID_TOOLCHAIN=

ROOT=`pwd`
CMD_PATH=${ROOT}/product
LOCAL_TOOLCHAIN=${ROOT}/toolchains
CORE=`cat /proc/cpuinfo | grep cores | wc -l`

# initial argument settings
OPTION="ukni"
PRODUCT=
PLATFORM=android

message_help() {
	echo "Usage: ./make.sh <Target Board Name> (-p (android|ubuntu)) -[h|u|k|n|a]"
	echo "   h : This help message"
	echo "   u : build the u-boot"
	echo "   k : build the kernel"
	echo "   n : build the android"
	echo "   i : build self install image"
	echo "   a : build the all things"
	exit 0
}

build() {
	case ${PRODUCT} in
		"xu4")
			ANDROID_TOOLCHAIN=${XU4_ANDROID_TOOLCHAIN}
			UBOOT_TOOLCHAIN=${XU4_UBOOT_TOOLCHAIN}
			;;
		"c2")
			ANDROID_TOOLCHAIN=${C2_ANDROID_TOOLCHAIN}
			;;
		"c1")
			ANDROID_TOOLCHAIN=${C1_TOOLCHAIN}
			;;
	esac

	# Check build environment
	install_dependency_packages
	install_uboot_toolchain

	#TODO add option parsing
	if [[ ${OPTION} == *u* ]]
	then
		build_uboot
	fi

	install_repo
	install_android_toolchain
	source ${CMD_PATH}/set_env.sh

	download_repo
	if [[ ${OPTION} == *k* ]]
	then
		build_kernel
	fi

	if [[ ${OPTION} == *n* ]]
	then
		build_android 
	fi

	if [[ ${OPTION} == *i* ]]
	then
		build_image
	fi

	# Create selfinstall image
}

download_repo() {
	if ! [ -d ${ROOT}/${PRODUCT}/${PLATFORM}/android ]; then
		mkdir -p ${ROOT}/${PRODUCT}/${PLATFORM}/android
	fi

	echo "Download android full source tree."
	echo "!!WARNNING!! Android full source code size is around 58GB!!"

	pushd ${ROOT}/${PRODUCT}/${PLATFORM}/android
	if ! [ -f ${ROOT}/.and ]
	then
		repo init -u https://github.com/hardkernel/android.git -b 5422_4.4.4_master && touch ${ROOT}/.and
	fi

	repo sync -j${CORE}
	repo start 5422_4.4.4_master --all
	popd
}

install_dependency_packages() {
	_DISTRIBUTE=`lsb_release -i -s`
	RELEASE=`lsb_release -r -s`

	if ! [ -f ${ROOT}/.dep ]
	then
		return
	fi

	# check distributor
	case "${_DISTRIBUTE}" in
		"Ubuntu")
			export DISTRIBUTE="ubuntu"
			;;
			# TODO support debian and other OS.
			"Debian")
			export DISTRIBUTE="debian"
			;;
		*)
			echo "Not yet support other os"
			exit 0
			;;
	esac

	# install dependency packages
	case "${DISTRIBUTE}" in
		"ubuntu")
			# check java version
			if [ `java -version 2>&1 | grep -i openjdk` ]
			then
				# add java repository
				sudo add-apt-repository -y ppa:webupd8team/java
				sudo apt-get update
			fi

			# reference : https://source.android.com/source/initializing
			case "${RELEASE}" in
				"14.04")
					sudo apt -y install oracle-java6-installer \
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

	touch ${ROOT}/.dep
}

# check & install toolchain
checkNcreate_toolchain_path() {
	echo "Check toolchain"
	if ! [ -d ${OPT_TOOLCHAIN} ]
	then
		sudo mkdir -p ${OPT_TOOLCHAIN}
	fi
}

install_uboot_toolchain() {
	checkNcreate_toolchain_path
	if ! [ -z `which arm-linux-gnueabihf-gcc` ]
	then
		echo "uboot toolchains is existed."
		return
	fi

	if ! [ -d ${OPT_TOOLCHAIN}/${UBOOT_TOOLCHAIN} ]
	then
		echo "Download u-boot toolchain."
		if ! [ -d ${LOCAL_TOOLCHAIN} ]
		then mkdir ${LOCAL_TOOLCHAIN}
		fi

		pushd ${LOCAL_TOOLCHAIN}
		wget http://dn.odroid.com/toolchains/${UBOOT_TOOLCHAIN}.tar.bz2 \
			-O ${UBOOT_TOOLCHAIN}.tar.bz2
		sudo tar jxf ${UBOOT_TOOLCHAIN}.tar.bz2 -C ${OPT_TOOLCHAIN}
		popd

		echo "U-boot toolchain install is completed."
	else echo "U-boot toolchain is already installed."
	fi
}

install_android_toolchain() {
	checkNcreate_toolchain_path

	if ! [ -z `which arm-eabi-gcc` ]
	then
		echo "android toolchains is existed."
		return
	fi

	if  ! [ -d ${OPT_TOOLCHAIN}/${ANDROID_TOOLCHAIN} ]
	then
		echo "Download android toolchain."
		if ! [ ${LOCAL_TOOLCHAIN} ]
		then mkdir ${LOCAL_TOOLCHAIN}
		fi

		pushd ${LOCAL_TOOLCHAIN}
		wget http://dn.odroid.com/toolchains/${ANDROID_TOOLCHAIN}.tar.gz \
			-O ${ANDROID_TOOLCHAIN}.tar.gz
		sudo tar xvfz ${ANDROID_TOOLCHAIN}.tar.gz -C ${OPT_TOOLCHAIN}
		popd

		echo "Android toolchain install is complete."
	else echo "Android toolchian is already installed."
	fi
}

# check n install repo
install_repo() {
	REPO=`which repo`

	if [ "${REPO}" == "" ]
	then
		echo "Install repo"
		# create repo bin
		mkdir ~/bin
		#download
		curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
		export PATH=~/bin:${PATH}
		chmod a+x ~/bin/repo
		echo 'export PATH=~/bin:${PATH}' >> ~/.bashrc
	fi
}

# Check target board name
if [ $# -lt 1 ]
then
	message_help
fi

# Set target board
case $1 in
	"odroidxu4")
		PRODUCT="xu4"
		;;
	"odroidc2")
		PRODUCT="c2"
		;;
	"odroidc1")
		PRODUCT="c1"
		;;
	"help")
		message_help
		;;
	*)
		echo "I couldn't identify your board."
		echo "Please check your board name."
		exit 0
		;;
esac

# set build option
if [ $# -ge 2 ]
then
	OPTIND=2

	OPTION=""
	while getopts "ahknuiAHKNUIp:P:" arg; do
		case "${arg}" in
			h|H) # help!
				echo "help"
				message_help
				;;
			a|A) # build all
				if ! [[ ${OPTION} == *[aA]* ]]
				then
					OPTION=ukni
				fi
				;;
			u|U) # build u-boot
				if ! [[ ${OPTION} == *[uU]* ]]
				then
					OPTION+=u
				fi
				;;
			k|K) # build kernel
				if ! [[ ${OPTION} == *[kK]* ]]
				then
					OPTION+=k
				fi
				;;
			n|N) # build android
				if ! [[ ${OPTION} == *[nN]* ]]
				then
					OPTION+=n
				fi
				;;
			i|I) # build self install image
				if ! [[ ${OPTION} == *[iI]* ]]
				then
					OPTION+=i
				fi
				;;
			p|p) # set target platform
				PLATFORM=${OPTARG}
				;;
		esac
		if [ -z ${OPTION} ]
		then
			case ${PLATFORM} in
				android)
					OPTION=ukni
					;;
				#ubuntu)
					*)
					echo "this platform is not supported."
					exit 0
					;;
			esac
		fi
	done
fi

source ${ROOT}/product/${PRODUCT}/cmd/build_uboot.sh
source ${ROOT}/product/${PRODUCT}/cmd/build_android.sh
source ${ROOT}/product/${PRODUCT}/cmd/build_kernel.sh
source ${ROOT}/product/${PRODUCT}/cmd/build_image.sh

CMD_PATH+=/${PRODUCT}/cmd
build
