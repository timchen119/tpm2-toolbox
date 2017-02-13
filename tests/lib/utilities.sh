#!/bin/sh

wait_for_systemd_service() {
	while ! systemctl status $1 ; do
		sleep 1
	done
	sleep 1
}

wait_for_systemd_service_exit() {
	while systemctl status $1 ; do
		sleep 1
	done
	sleep 1
}

install_snap_under_test() {
	# If we don't install the snap here we get a system
	# without any network connectivity after reboot.
	if [ -n "$SNAP_CHANNEL" ] ; then
		# Don't reinstall if we have it installed already
		if ! snap list | grep $SNAP_NAME ; then
			snap install --$SNAP_CHANNEL $SNAP_NAME
		fi
	else
		# Install prebuilt snap
		snap install --dangerous ${PROJECT_PATH}/${SNAP_NAME}_*_${SNAP_ARCH}.snap
		# As we have a snap which we build locally it's unasserted and therefore
		# we don't have any snap-declarations in place and need to manually
		# connect all plugs.
		for plug in $SNAP_AUTOCONNECT_CORE_PLUGS ; do
			snap connect ${SNAP_NAME}:${plug} core
		done
		# Setup all necessary aliases
		for alias in $SNAP_AUTO_ALIASES ; do
			snap alias $SNAP_NAME $alias
		done
	fi
}
