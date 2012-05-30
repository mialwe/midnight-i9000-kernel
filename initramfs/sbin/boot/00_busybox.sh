echo "mounting /system readwrite..."
# mount system and rootfs r/w
/sbin/busybox mount -o remount,rw /system

# make sure we have /system/xbin
/sbin/busybox mkdir -p /system/xbin

# if symlinked busybox in /system/bin or /system/xbin, remove them
echo "checking for busybox symlinks..."
if /sbin/busybox [ -h /system/bin/busybox ]; then
    /sbin/busybox rm -rf /system/bin/busybox;
fi
if /sbin/busybox [ -h /system/xbin/busybox ]; then
    /sbin/busybox rm -rf /system/xbin/busybox;
fi


echo "checking for real busybox..."
# if real busybox in /system/bin, move to /system/xbin
if /sbin/busybox [ -f /system/bin/busybox ]; then
    echo "real busybox binary found, moving to /system/xbin..."
    /sbin/busybox mv /system/bin/busybox /system/xbin/busybox
else
    echo "no real busybox binary found, nothing to do..."
fi;

# to be sure...
# default PATH = PATH: /sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
# so we delete every busybox within this path except in /system/xbin
/sbin/busybox rm -f /vendor/bin/busybox
/sbin/busybox rm -f /system/sbin/busybox
/sbin/busybox rm -f /system/bin/busybox
#/sbin/busybox rm -f /sbin/busybox

echo "checking /system/xbin for busybox..."
if /sbin/busybox [ -f /system/xbin/busybox ];then
    echo "/system/xbin/busybox found, nothing to do..."
else
    echo "/system/xbin/busybox not found, installing recovery busybox to /system/xbin/busybox..."
    /sbin/busybox cp /sbin/recovery /system/xbin/busybox
    /sbin/busybox chown 0.0 /system/xbin/busybox
    /sbin/busybox chmod 4755 /system/xbin/busybox
    if /sbin/busybox [ -f /system/xbin/busybox ];then
        echo "/system/xbin/busybox binary installed."
    fi
fi    

echo "creating busybox symlinks in /system/xbin..."
lskip=0
lok=0
for linkname in [ [[ ash awk basename bbconfig bunzip2 bzcat bzip2 cal \
    cat catv chgrp chmod chown chroot cksum clear cmp cp cpio cut date \
    dc dd depmod devmem df diff dirname dmesg dos2unix du echo egrep \
    env expr false fdisk fgrep find fold free freeramdisk fuser getopt \
    grep gunzip gzip head hexdump id insmod install kill killall \
    killall5 length less ln losetup ls lsmod lspci lsusb lzop lzopcat \
    md5sum mkdir mke2fs mkfifo mkfs.ext2 mknod mkswap mktemp modprobe \
    more mount mountpoint mv nice nohup od patch pgrep pidof pkill \
    printenv printf ps pwd rdev readlink realpath renice reset rm rmdir \
    rmmod run-parts sed seq setsid sh sha1sum sha256sum sha512sum sleep \
    sort split stat strings stty swapoff swapon sync sysctl tac tail \
    tar tee test time top touch tr true tty tune2fs umount uname uniq \
    unix2dos unlzop unzip uptime usleep uudecode uuencode watch wc \
    which whoami xargs yes zcat; do
    
    if /sbin/busybox [ -h /system/xbin/$linkname ]; then
        lskip=$(($lskip+1))
    else
        echo "creating symlink /system/xbin/busybox -> /system/xbin/$linkname..."
        lok=$(($lok+1))
        /sbin/busybox ln -s /system/xbin/busybox /system/xbin/$linkname
    fi
done 
echo "skipped $lskip existing, created $lok missing symlinks."

echo "remounting /system readonly..."
/sbin/busybox mount -o remount,ro /system
