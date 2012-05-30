#!/sbin/busybox_disabled sh

if /sbin/busybox_disabled [ -f /data/dalvik-cache/system@app@SetupWizard.apk@classes.dex ]; then 
    if /sbin/busybox_disabled [ -f /data/local/bootanimation.bin ]; then
      /data/local/bootanimation.bin
    elif /sbin/busybox_disabled [ -f /data/local/bootanimation.zip ] || /sbin/busybox_disabled [ -f /system/media/bootanimation.zip ]; then
      /sbin/bootanimation &
      sleep 15
      kill $!
    else
      /system/bin/samsungani
    fi;
else
  /system/bin/samsungani
fi;
