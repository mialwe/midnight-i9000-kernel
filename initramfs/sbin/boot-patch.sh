#!/sbin/busybox sh

/sbin/busybox cp /data/user.log /data/user.log.bak
/sbin/busybox rm /data/user.log
exec >>/data/user.log
exec 2>&1

# say hello :)
echo
echo "************************************************"
echo "MIDNIGHT KERNEL INITSCRIPT LOG"
echo "************************************************"
echo
echo -n "Kernel: ";uname -r
echo -n "PATH: ";echo $PATH
echo -n "ROM: ";cat /system/build.prop|grep ro.build.display.id
echo
echo "Starting script processing in /sbin/boot..."
echo
# start initscript processing
echo $(date) USER INIT START from /sbin/boot
if cd /sbin/boot >/dev/null 2>&1 ; then
    for file in * ; do
        if ! ls "$file" >/dev/null 2>&1 ; then continue ; fi
        echo "START '$file'"
        /sbin/busybox_disabled sh "$file"
        echo "EXIT '$file' ($?)"
        echo ""
    done
fi
echo $(date) USER INIT DONE from /sbin/boot

read sync < /data/sync_fifo
rm /data/sync_fifo
