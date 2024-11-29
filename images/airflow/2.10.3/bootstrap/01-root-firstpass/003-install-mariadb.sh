#!/bin/bash
set -e

# shellcheck source=images/airflow/2.10.3/bootstrap/common.sh
source /bootstrap/common.sh

verify_env_vars_exist \
    BUILDARCH \
    MARIADB_DOWNLOAD_BASE_URL \
    MARIADB_DOWLOAD_URL_X86_SUFFIX \
    MARIADB_DOWLOAD_URL_ARM_SUFFIX \
    MARIADB_ARM_SUFFIX \
    MARIADB_X86_SUFFIX \
    MARIADB_RPM_COMMON_PREFIX \
    MARIADB_RPM_COMMON_X86_CHECKSUM \
    MARIADB_RPM_COMMON_ARM_CHECKSUM \
    MARIADB_RPM_DEVEL_PREFIX \
    MARIADB_RPM_DEVEL_X86_CHECKSUM \
    MARIADB_RPM_DEVEL_ARM_CHECKSUM \
    MARIADB_RPM_SHARED_PREFIX \
    MARIADB_RPM_SHARED_X86_CHECKSUM \
    MARIADB_RPM_SHARED_ARM_CHECKSUM

dnf install -y wget

# Select the right RPMs based on the architecture.
if [ "$BUILDARCH" == "arm64" ]; then
    MARIADB_DOWNLOAD_FULL_BASE_URL="${MARIADB_DOWNLOAD_BASE_URL}${MARIADB_DOWLOAD_URL_ARM_SUFFIX}"
    MARIADB_RPM_COMMON="$MARIADB_RPM_COMMON_PREFIX$MARIADB_ARM_SUFFIX"
    MARIADB_RPM_DEVEL="$MARIADB_RPM_DEVEL_PREFIX$MARIADB_ARM_SUFFIX"
    MARIADB_RPM_SHARED="$MARIADB_RPM_SHARED_PREFIX$MARIADB_ARM_SUFFIX"
    MARIADB_RPM_COMMON_CHECKSUM="$MARIADB_RPM_COMMON_ARM_CHECKSUM"
    MARIADB_RPM_DEVEL_CHECKSUM="$MARIADB_RPM_DEVEL_ARM_CHECKSUM"
    MARIADB_RPM_SHARED_CHECKSUM="$MARIADB_RPM_SHARED_ARM_CHECKSUM"
elif [ "$BUILDARCH" == "amd64" ]; then
    MARIADB_DOWNLOAD_FULL_BASE_URL="${MARIADB_DOWNLOAD_BASE_URL}${MARIADB_DOWLOAD_URL_X86_SUFFIX}"
    MARIADB_RPM_COMMON="$MARIADB_RPM_COMMON_PREFIX$MARIADB_X86_SUFFIX"
    MARIADB_RPM_DEVEL="$MARIADB_RPM_DEVEL_PREFIX$MARIADB_X86_SUFFIX"
    MARIADB_RPM_SHARED="$MARIADB_RPM_SHARED_PREFIX$MARIADB_X86_SUFFIX"
    MARIADB_RPM_COMMON_CHECKSUM="$MARIADB_RPM_COMMON_X86_CHECKSUM"
    MARIADB_RPM_DEVEL_CHECKSUM="$MARIADB_RPM_DEVEL_X86_CHECKSUM"
    MARIADB_RPM_SHARED_CHECKSUM="$MARIADB_RPM_SHARED_X86_CHECKSUM"
else
    echo "Unsupported architecture: $BUILDARCH"
    exit 1
fi

# Download the necessary RPMs.
mkdir /mariadb_rpm
wget "${MARIADB_DOWNLOAD_FULL_BASE_URL}/${MARIADB_RPM_COMMON}" -P /mariadb_rpm
wget "${MARIADB_DOWNLOAD_FULL_BASE_URL}/${MARIADB_RPM_SHARED}" -P /mariadb_rpm
wget "${MARIADB_DOWNLOAD_FULL_BASE_URL}/${MARIADB_RPM_DEVEL}" -P /mariadb_rpm

# Verify their checkums
echo "$MARIADB_RPM_COMMON_CHECKSUM /mariadb_rpm/$MARIADB_RPM_COMMON" | md5sum --check - | grep --basic-regex "^/mariadb_rpm/$MARIADB_RPM_COMMON: OK$"
echo "$MARIADB_RPM_SHARED_CHECKSUM /mariadb_rpm/$MARIADB_RPM_SHARED" | md5sum --check - | grep --basic-regex "^/mariadb_rpm/$MARIADB_RPM_SHARED: OK$"
echo "$MARIADB_RPM_DEVEL_CHECKSUM /mariadb_rpm/$MARIADB_RPM_DEVEL" | md5sum --check - | grep --basic-regex "^/mariadb_rpm/$MARIADB_RPM_DEVEL: OK$"

# Install the RPMs.
rpm -ivh /mariadb_rpm/*

rm -rf /mariadb_rpm

dnf remove -y wget