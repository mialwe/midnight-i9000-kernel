echo "remounting /system readwrite..."
/sbin/busybox mount -o remount,rw /system

#echo "creating /system/etc/midnight..."
#mkdir -p /system/etc/midnight

# create xbin
if /sbin/busybox [ -d /system/xbin ];then
    echo "/system/xbin found, skipping mkdir..."
else
    echo "/system/xbin not found, creating..."
    /sbin/busybox mkdir /system/xbin
    /sbin/busybox chmod 755 /system/xbin
fi

# create init.d
if /sbin/busybox [ -d /system/etc/init.d ];then
    echo "/system/etc/init.d found, skipping mkdir..."
else
    echo "/system/etc/init.d not found, creating..."
    /sbin/busybox mkdir /system/etc/init.d
    /sbin/busybox chmod 777 /system/etc/init.d
fi

# clean multiple su binaries
echo "cleaning su installations except /system/xbin/su if any..."
/sbin/busybox rm -f /system/bin/su
/sbin/busybox rm -f /vendor/bin/su
/sbin/busybox rm -f /system/sbin/su

# install xbin/su if not there
if /sbin/busybox [ -f /system/xbin/su ];then
    echo "/system/xbin/su found, skipping..."
else
    echo "cleaning up su installations..."
    echo "installing /system/xbin/su..."
    echo "if this fails free some space on /system."
    /sbin/busybox cat /res/misc/su > /system/xbin/su
    /sbin/busybox chown 0.0 /system/xbin/su
    /sbin/busybox chmod 4755 /system/xbin/su
fi

# install /system/app/Superuser.apk if not there
if /sbin/busybox [ -f /system/app/Superuser.apk ];then
    echo "/system/app/Superuser.apk found, skipping..."
else
    echo "cleaning up Superuser.apk installations..."
    /sbin/busybox rm -f /system/app/Superuser.apk
    /sbin/busybox rm -f /data/app/Superuser.apk
    echo "installing /system/app/Superuser.apk"
    echo "if this fails free some space on /system."
    /sbin/busybox cat /res/misc/Superuser.apk > /system/app/Superuser.apk
    /sbin/busybox chown 0.0 /system/app/Superuser.apk
    /sbin/busybox chmod 644 /system/app/Superuser.apk
fi

# install MidnightControl.apk
#echo "rm old MidnightControl apk's..."
#/sbin/busybox rm -f /system/app/MidnightControl.apk
#/sbin/busybox rm -f /data/app/com.mialwe.midnight.control-1.apk
echo "installing /system/app/MidnightControl.apk"
/sbin/busybox cat /res/misc/MidnightControl.apk > /system/app/MidnightControl.apk
/sbin/busybox chown 0.0 /system/app/MidnightControl.apk
/sbin/busybox chmod 644 /system/app/MidnightControl.apk

echo "checking /data/local/logger.ko (Logcat)..."
if /sbin/busybox [ -f /data/local/logger.ko ];then
    echo "Logcat enabled, copying logger.ko..."
    cat /lib/modules/logger.ko > /data/local/logger.ko
fi

echo "remounting /system readonly..."
/sbin/busybox mount -o remount,ro /system
