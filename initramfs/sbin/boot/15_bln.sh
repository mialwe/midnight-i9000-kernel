echo "installing backlightnotification lights.s5pc110.so..."
echo "remounting /system readwrite..."
/sbin/busybox mount -o remount,rw /system

bln_file="lights.s5pc110.so"
bln_src="/res/misc/$bln_file"
bln_trg="/system/lib/hw/$bln_file"
bln_bkp="/system/lib/hw/$bln_file.orig"
if /sbin/busybox [ -d /sys/class/misc/backlightnotification ]; then
    echo "kernel supports backlightnotification"
    if /sbin/busybox [ -f $bln_bkp ]; then
        echo "backup found ($bln_bkp), skipping..."     
    else    
        echo "backup not found, copying to $bln_bkp..." 
        /sbin/busybox cp "$bln_trg" "$bln_bkp"
    fi
    echo "copying BLN-patched liblights from neldar..."
    echo "source: $bln_src"
    echo "target: $bln_trg"
    /sbin/busybox cp "$bln_src" "$bln_trg"
    /sbin/busybox chown 0.0 "$bln_trg"
    /sbin/busybox chmod 644 "$bln_trg"
fi
if /sbin/busybox [ -f $bln_bkp ]; then echo "$bln_bkp found.";fi     
if /sbin/busybox [ -f $bln_trg ]; then echo "$bln_trg found.";fi  

echo "remounting /system readonly..."
/sbin/busybox mount -o remount,ro /system
  
