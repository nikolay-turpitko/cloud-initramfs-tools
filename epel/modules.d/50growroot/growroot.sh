#!/bin/sh

. /lib/dracut-lib.sh

# Environment variables that this script relies upon:
# - NEWROOT
# - root
# - fstype
# - rflags

_info() {
    echo "growroot: $@"
}

_warning() {
    _info "Warning: $@"
}

# This will drop us into an emergency shell
_fatal() {
    _info "Fatal: $@"
    exit 1
}

# This runs right before exec of /sbin/init, the real root is already mounted
# at NEWROOT
_growroot()
{
	local rootdev rootdisk partnum out
	local ROOTMNT ROOT FSTYPE RFLAGS

	# Assign environment variables to local variables
	ROOTMNT=${NEWROOT}
	ROOT=${root#*:}
	FSTYPE=${fstype}
	RFLAGS=${rflags}

        # If a file indicates we should do nothing, then just return
	for file in /var/lib/cloud/instance/root-grown \
		/etc/growroot-disabled /etc/growroot-grown; do
		if [ -f "${ROOTMNT}${file}" ] ; then
			_info "${file} exists, nothing to do"
			return
		fi
	done

        # Figure out what device ROOT is on
	rootdev=$(readlink -f ${ROOT})
	if [ ! -e ${rootdev} ] ; then
		_warning "Failed to get target of link for ${ROOT}"
		return
	fi

        # If the basename of the root device (ie 'xvda1', 'sda1', 'vda') exists
        # in /sys/block/ then it is a block device, not a partition
	if [ -e "/sys/block/${rootdev##*/}" ] ; then
		_info "${rootdev} is not a partition"
		return
	fi

	# Check if the root device is a partition (name ends with a digit)
	if [ "${rootdev%[0-9]}" = "${rootdev}" ] ; then
		_warning "${rootdev} is not a partition"
		return
	fi

        # Remove all numbers from the end of rootdev to get the rootdisk and
	# partition number
	rootdisk=${rootdev}
	while [ "${rootdisk%[0-9]}" != "${rootdisk}" ] ; do
		rootdisk=${rootdisk%[0-9]}
	done
	partnum=${rootdev#${rootdisk}}

        # Do a growpart dry run and exit if it fails or doesn't have
	# anything to do
	if ! out=$(growpart --dry-run "${rootdisk}" "${partnum}" 2>&1) ; then
		_info "${out}"
		return
	fi

        # There is something to do, unmount and repartition
	if ! umount "${ROOTMNT}" ; then
		_warning "Failed to umount ${ROOTMNT}"
		return
	fi

        # Wait for any of the initial udev events to finish otherwise growpart
	# might fail
	udevsettle

        # Resize the root partition
	if out=$(growpart "${rootdisk}" "${partnum}" 2>&1) ; then
		_info "${out}"
	else
		_warning "${out}"
		_warning "growpart failed"
	fi

        # Wait for the partition re-read events to complete so that the root
	# partition is available for remounting
	udevsettle

        # Remount the root filesystem (from 95rootfs-block/mount-root.sh)
	mount -t ${FSTYPE:-auto} -o "${RFLAGS}" ${ROOT} ${ROOTMNT} || \
		_fatal "Failed to re-mount ${ROOT}, this is bad"

        # Write to /etc/growroot-grown, most likely this wont work (read-only)
	{
		date --utc > "${ROOTMNT}/etc/growroot-grown"
	} >/dev/null 2>&1
}

_growroot
