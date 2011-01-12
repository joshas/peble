#!/bin/bash

/usr/bin/xmodmap ~/.Xmodmap

# set mouse acceleration and threshold (pointer is too fast with new Xvesa build)
#/usr/bin/xset m 1.5/1 4

if [ ! -e /tmp/firsttime ]; then

	# run this script once
	touch /tmp/firsttime

	# for aufs to merge opt-get plugin
	mount -t tmpfs none /opt

	# setup keymap from kmap= parameter
	setxkbmap -layout $KEYMAP

	# start system bus
	dbus-launch --config-file=/etc/dbus-1/system.conf

	# start connman
	connmand &

	# mount all partitions
	#for i in `fdisk -l | grep "^/dev" | cut -d' ' -f1`; do
	#   mkdir -p /mnt/`basename $i`;
	#   mount $i /mnt/`basename $i`;
	#done

	# EXPERIMENTAL: try to mount cdrom
	#if [ -e /dev/sr0 ]; then
	#	mkdir /mnt/cdrom
	#	mount -t auto /dev/sr0 /mnt/cdrom
	#fi

	# auto load user data if exist
	if [ ! "$(cat /proc/cmdline | grep xpud-data )" ]; then
		/usr/local/bin/load_data
	fi

	# install opt file if exist
	if [ ! "$(cat /proc/cmdline | grep opt=no )" ]; then
		find /mnt -maxdepth 4 -type f -name '*.opt' -exec opt-get {} \;
	fi

	# generate menu
	#/usr/local/bin/update-menus

	# start hotplug script
	#/bin/cp /sbin/hotplug-x /sbin/hotplug

	# setup sound channel
	CARD=`grep '0 \[' /proc/asound/cards | cut -d'[' -f2| cut -d']' -f1`
	if [ ! -z $CARD ]; then 
	sed -e "s/Intel/$CARD/g" /etc/asound.conf > /etc/asound.conf.tmp
	mv /etc/asound.conf.tmp /etc/asound.conf
	for channel in Master Front PCM; do
		/usr/bin/amixer set $channel 95% on
	done
	fi

	# turn on Lenovo R61 (and maybe other systems) speaker
	/usr/bin/amixer set Speaker on

	# Suggest to set all CPUs to "ondemand" governor.
	# recent AMD/Intel CPUs are all supported.
	modprobe acpi_cpufreq
	modprobe cpufreq_ondemand
	CPUS=`$(($(cat /proc/cpuinfo|grep processor|wc -l)-1))`
	for i in `seq 0 $CPUS`
	do
		echo ondemand > /sys/devices/system/cpu/cpu$CPUS/cpufreq/scaling_governor
	done


	# post hook
	find /etc/post-boot.d/ -type f -exec {} \;

fi
