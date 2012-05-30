#!/sbin/busybox sh

/sbin/busybox rm /etc
/sbin/busybox mkdir /etc
cat /res/etc/recovery.fstab > /etc/recovery.fstab

/sbin/busybox rm /sdcard
/sbin/busybox mkdir /sdcard
/sbin/busybox mount -t vfat -o noatime,nodiratime /dev/block/mmcblk0p1 /sdcard >> /dev/null 2>&1
/sbin/busybox umount /dbdata
