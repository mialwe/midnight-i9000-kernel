#!/sbin/busybox_disabled sh
/sbin/busybox_disabled rm /cache/recovery/command
/sbin/busybox_disabled rm /cache/update.zip
/sbin/busybox_disabled touch /tmp/.ignorebootmessage
kill $(ps | grep /sbin/adbd)
kill $(ps | grep /sbin/recovery)

# On the Galaxy S, the recovery comes test signed, but the
# recovery is not automatically restarted.
if /sbin/busybox_disabled [ -f /init.smdkc110.rc ]
then
    /sbin/recovery &
fi

# Droid X
if /sbin/busybox_disabled [ -f /init.mapphone_cdma.rc ]
then
    /sbin/recovery &
fi

exit 1
