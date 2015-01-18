#!/usr/bin/env bash

set -e

if [ "${PACKER_DEBUG:-false}" == "true" ]; then
  set -o xtrace
fi

# This script expects the environment variables:
#   $BUILD_USER - User created with the build environment setup
#   $BUILD_USER_GROUP - Primary group for $BUILD_USER
#   $BUILD_DIR - The mount point and $LFS target
#   $BUILD_DISK - The drive to partition and format as target drive for the build

BOOT_PARTITION="${BUILD_DISK}1"
ROOT_PARTITION="${BUILD_DISK}2"

echo "--> creating build user ${BUILD_USER}"

/usr/bin/useradd -s /bin/bash -g ${BUILD_USER_GROUP} -m -k /dev/null -N ${BUILD_USER}
/usr/bin/passwd -d ${BUILD_USER}

echo "${BUILD_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


echo "--> partitioning disk ${BUILD_DISK} for build"
/usr/bin/sfdisk ${BUILD_DISK} -uM << PARTITION_TABLE
,${BOOT_PARTITION_SIZE}
;
PARTITION_TABLE

/usr/bin/sfdisk -A1 ${BUILD_DISK}

/usr/bin/mkfs.ext4 -jv ${ROOT_PARTITION}

/usr/bin/mkdir -p ${BUILD_DIR}
/usr/bin/mount -o noatime ${ROOT_PARTITION} ${BUILD_DIR}

/usr/bin/mkfs.ext2 -v ${BOOT_PARTITION}
/usr/bin/mkdir -p ${BUILD_DIR}/boot
/usr/bin/mount -o noatime ${ROOT_PARTITION} ${BUILD_DIR}/boot

echo "==> setting up build environment in ${BUILD_DIR}"

/usr/bin/install -d -m 1777 -o ${BUILD_USER} ${BUILD_DIR}/build
/usr/bin/install -d -m 1777 -o ${BUILD_USER} ${BUILD_DIR}/sources

/usr/bin/install -d -o ${BUILD_USER} ${BUILD_DIR}/tools
/usr/bin/ln -sv ${BUILD_DIR}/tools /

SOURCE_CACHE_SHARE_NAME=source_cache

echo "==> loading source cache '${SOURCE_CACHE_SHARE_NAME}'"

if modprobe vboxsf; then
	# uid=${BUILD_USER},gid=${BUILD_USER_GROUP},rw,dmode=700,fmode=600,comment=systemd.automount 0 0
	/usr/bin/mount -t vboxsf -o uid=${BUILD_USER},gid=${BUILD_USER_GROUP},rw,dmode=0700,fmode=600 ${SOURCE_CACHE_SHARE_NAME} ${BUILD_DIR}/sources
else
	echo "Source cache disabled, failed to load vboxsf module"
fi
