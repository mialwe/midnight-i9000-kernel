#initialize cpu
uv100=0;uv200=0;uv400=0;uv800=0;uv1000=0;uv1128=0;uv1200=0;cpumax=1000000;

# app settings parsing
if /sbin/busybox [ ! -f /cache/midnight_block ];then
    echo "APP: no blocker file present, proceeding..."
    xmlfile="/dbdata/databases/com.mialwe.midnight.control/shared_prefs/com.mialwe.midnight.control_preferences.xml"
    echo "APP: checking app preferences..."
    if /sbin/busybox [ -f $xmlfile ];then
        echo "APP: preferences file found, parsing..."
        sched=`/sbin/busybox sed -n 's|<string name=\"midnight_io\">\(.*\)</string>|\1|p' $xmlfile`
        echo "APP: IO sched -> $sched"
        cpumax=`/sbin/busybox sed -n 's|<string name=\"midnight_cpu_max\">\(.*\)</string>|\1|p' $xmlfile`
        echo "APP: cpumax -> $cpumax"
        cpugov=`/sbin/busybox sed -n 's|<string name=\"midnight_cpu_gov\">\(.*\)</string>|\1|p' $xmlfile`
        echo "APP: cpugov -> $cpugov"
        uvatboot=`/sbin/busybox awk -F"\"" ' /c_toggle_uv_boot\"/ {print $4}' $xmlfile`
        uv1200=`/sbin/busybox awk -F"\"" ' /uv_1200\"/ {print $4}' $xmlfile`;#uv1200=$(($uv1200*(-1)))
        uv1128=`/sbin/busybox awk -F"\"" ' /uv_1128\"/ {print $4}' $xmlfile`;#uv1128=$(($uv1128*(-1)))
        uv1000=`/sbin/busybox awk -F"\"" ' /uv_1000\"/ {print $4}' $xmlfile`;#uv1000=$(($uv1000*(-1)))
        uv800=`/sbin/busybox awk -F"\"" ' /uv_800\"/ {print $4}' $xmlfile`;#uv800=$(($uv800*(-1)))
        uv400=`/sbin/busybox awk -F"\"" ' /uv_400\"/ {print $4}' $xmlfile`;#uv400=$(($uv400*(-1)))
        uv200=`/sbin/busybox awk -F"\"" ' /uv_200\"/ {print $4}' $xmlfile`;#uv200=$(($uv200*(-1)))
        uv100=`/sbin/busybox awk -F"\"" ' /uv_100\"/ {print $4}' $xmlfile`;#uv100=$(($uv100*(-1)))
        echo "APP: uv at boot -> $uvatboot"
        echo "APP: uv1200 -> $uv1200"
        echo "APP: uv1128 -> $uv1128"
        echo "APP: uv1000 -> $uv1000"
        echo "APP: uv800  -> $uv800"
        echo "APP: uv400  -> $uv400"
        echo "APP: uv200  -> $uv200"
        echo "APP: uv100  -> $uv100"
        mr=`/sbin/busybox awk -F"\"" ' /midnight_mul_r\"/ {print $4}' $xmlfile`
        mg=`/sbin/busybox awk -F"\"" ' /midnight_mul_g\"/ {print $4}' $xmlfile`
        mb=`/sbin/busybox awk -F"\"" ' /midnight_mul_b\"/ {print $4}' $xmlfile`
        mrn=`/sbin/busybox awk -F"\"" ' /midnight_mul_r_night\"/ {print $4}' $xmlfile`
        mgn=`/sbin/busybox awk -F"\"" ' /midnight_mul_g_night\"/ {print $4}' $xmlfile`
        mbn=`/sbin/busybox awk -F"\"" ' /midnight_mul_b_night\"/ {print $4}' $xmlfile`
        mbright=`/sbin/busybox awk -F"\"" ' /midnight_mult_brightness\"/ {print $4}' $xmlfile`
        mbrightn=`/sbin/busybox awk -F"\"" ' /midnight_mult_brightness_night\"/ {print $4}' $xmlfile`
        echo "APP: brightness  -> $mbright"
        echo "APP: mul_r       -> $mr"
        echo "APP: mul_g       -> $mg"
        echo "APP: mul_b       -> $mb"
        echo "APP: brightness_n-> $mbrightn"
        echo "APP: mul_r_night -> $mrn"
        echo "APP: mul_g_night -> $mgn"
        echo "APP: mul_b_night -> $mbn"
        tun=`/sbin/busybox awk -F"\"" ' /c_toggle_tun\"/ {print $4}' $xmlfile`
        logcat=`/sbin/busybox awk -F"\"" ' /c_toggle_logcat\"/ {print $4}' $xmlfile`
        cifs=`/sbin/busybox awk -F"\"" ' /c_toggle_cifs\"/ {print $4}' $xmlfile`
        initd=`/sbin/busybox awk -F"\"" ' /c_toggle_initd\"/ {print $4}' $xmlfile`
        echo "APP: initd  -> $initd"
        echo "APP: tun    -> $tun"
        echo "APP: cifs   -> $cifs"
        echo "APP: logcat -> $logcat"
        touch=`/sbin/busybox sed -n 's|<string name=\"midnight_sensitivity\">\(.*\)</string>|\1|p' $xmlfile`
        echo "APP: sensitivity -> $touch"
        lmk=`/sbin/busybox sed -n 's|<string name=\"midnight_lmk\">\(.*\)</string>|\1|p' $xmlfile`
        echo "APP: LMK -> $lmk"
        readahead=`/sbin/busybox sed -n 's|<string name=\"midnight_rh\">\(.*\)</string>|\1|p' $xmlfile`
        echo "APP: readahead -> $readahead"
        timeout=`/sbin/busybox awk -F"\"" ' /midnight_led_timeout\"/ {print $4}' $xmlfile`
        echo "APP: LED timeout -> $timeout"
    else
        echo "APP: preferences file not found."
    fi
else
    echo "APP: blocker file found, not processing MidnightControl settings..."
    echo "APP: removing blocker file..."
    rm /cache/midnight_block
fi

#--------------------------------------------------------------------
# COLORS - AS SOON AS POSSIBLE
#--------------------------------------------------------------------                               
#echo
#echo -n "COLOR: initial R: ";cat /sys/class/misc/rgbb_multiplier/red_multiplier
#echo -n "COLOR: initial G: ";cat /sys/class/misc/rgbb_multiplier/green_multiplier
#echo -n "COLOR: initial B: ";cat /sys/class/misc/rgbb_multiplier/blue_multiplier

#mmr=$(($mr*1000000));
#mmg=$(($mg*1000000));
#mmb=$(($mb*1000000));
#echo "COLOR: multiplied multiplier: $mmr, $mmg, $mmb"

#mrr=$((1887492806+$mmr));
#mgg=$((2169824215+$mmg));
#mbb=$((3209991042+$mmb));
#echo "COLOR: new multipliers: $mrr, $mgg, $mbb"

#echo "$mrr" > /sys/class/misc/rgbb_multiplier/red_multiplier
#echo "$mgg" > /sys/class/misc/rgbb_multiplier/green_multiplier
#echo "$mbb" > /sys/class/misc/rgbb_multiplier/blue_multiplier

#echo -n "COLOR: new R: ";cat /sys/class/misc/rgbb_multiplier/red_multiplier
#echo -n "COLOR: new G: ";cat /sys/class/misc/rgbb_multiplier/green_multiplier
#echo -n "COLOR: new B: ";cat /sys/class/misc/rgbb_multiplier/blue_multiplier

#--------------------------------------------------------------------
# LET'S GO
#--------------------------------------------------------------------                               
echo
echo "Mounting rootfs readwrite..."
/sbin/busybox mount -t rootfs -o remount,rw rootfs
#--------------------------------------------------------------------
# FS
#--------------------------------------------------------------------
echo
echo "MOUNT: remounting partitions with speed tweaks..."
for k in $(/sbin/busybox mount | busybox grep relatime | busybox cut -d " " -f3)
do
    sync
    /sbin/busybox mount -o remount,noatime,nodiratime $k
done
echo "MOUNT: trying to remount EXT4 partitions with speed tweaks if any..."
for k in $(/sbin/busybox mount | grep ext4 | cut -d " " -f3)
do
  sync;
  if /sbin/busybox [ "$k" = "/system" ]; then
    /sbin/busybox mount -o remount,noauto_da_alloc,barrier=0,commit=40 $k;
  elif /sbin/busybox [ "$k" = "/dbdata" ]; then
    /sbin/busybox mount -o remount,noauto_da_alloc,barrier=1,nodelalloc,commit=40 $k;
  elif /sbin/busybox [ "$k" = "/data" ]; then
    /sbin/busybox mount -o remount,noauto_da_alloc,barrier=1,commit=40 $k;
  elif /sbin/busybox [ "$k" = "/cache" ]; then
    /sbin/busybox mount -o remount,noauto_da_alloc,barrier=0,commit=40 $k;
  fi;
done
echo "MOUNT: check mounted partitions: "
/sbin/busybox mount|grep /system
/sbin/busybox mount|grep /data
/sbin/busybox mount|grep /dbdata
/sbin/busybox mount|grep /cache
#--------------------------------------------------------------------
# LMK
#--------------------------------------------------------------------
echo
echo "LMK tweaks"

#MIDNIGHT: 6,9,15,48,55,65
ADJ0=1536;ADJ1=2304;ADJ2=3840;ADJ7=12288;ADJ14=14080;ADJ15=16640

if /sbin/busybox [ "$lmk" == "SGSGINGERBREAD" ];then
    # SGS GB STOCK: 
    ADJ0=2560;ADJ1=4096;ADJ2=6144;ADJ7=10240;ADJ14=11264;ADJ15=12288
    echo "LMK: using preset SGS-GINGERBREAD"
elif /sbin/busybox [ "$lmk" == "MODERATE" ];then
    # MODERATE (56Mb): 
    ADJ0=1536;ADJ1=2304;ADJ2=5120;ADJ7=8192;ADJ14=11264;ADJ15=14336
    echo "LMK: using preset MODERATE"
elif /sbin/busybox [ "$lmk" == "NEXUS" ];then
    # NEXUS: 
    ADJ0=2048;ADJ1=3072;ADJ2=4096;ADJ7=6144;ADJ14=7168;ADJ15=8192
    echo "LMK: using preset NEXUS"
elif /sbin/busybox [ "$lmk" == "AGGRESSIVE1" ];then
    # MORE RAM
    ADJ0=2048;ADJ1=4096;ADJ2=11776;ADJ7=14080;ADJ14=15360;ADJ15=17920
    echo "LMK: using preset AGGRESSIVE1"
elif /sbin/busybox [ "$lmk" == "AGGRESSIVE2" ];then
    # BIGRAM: 
    ADJ0=2048;ADJ1=4096;ADJ2=11776;ADJ7=15872;ADJ14=18944;ADJ15=21760
    echo "LMK: using preset AGGRESSIVE2"
else
    echo "LMK: using MIDNIGHT default preset"
fi
echo "LMK: Setting APP ADJs..."
setprop ro.FOREGROUND_APP_MEM "$ADJ0"
setprop ro.HOME_APP_MEM "$ADJ1"
setprop ro.VISIBLE_APP_MEM "$ADJ1"
setprop ro.PERCEPTIBLE_APP_MEM "$ADJ2"
setprop ro.HEAVY_WEIGHT_APP_MEM "$ADJ7"
setprop ro.SECONDARY_SERVER_MEM "$ADJ2"
setprop ro.BACKUP_APP_MEM "$ADJ7"
setprop ro.HIDDEN_APP_MEM "$ADJ7"
setprop ro.CONTENT_PROVIDER_MEM "$ADJ14"
setprop ro.EMPTY_APP_MEM "$ADJ15"
echo "LMK: Setting minfree values..."  
echo "$ADJ0,$ADJ1,$ADJ2,$ADJ7,$ADJ14,$ADJ15" > /sys/module/lowmemorykiller/parameters/minfree
echo "0,1,2,7,14,15" > /sys/module/lowmemorykiller/parameters/adj
echo "LMK: Check used values:"
echo -n "LMK: FOREGROUND_APP_MEM: ";getprop ro.FOREGROUND_APP_MEM
echo -n "LMK: HOME_APP_MEM: ";getprop ro.HOME_APP_MEM
echo -n "LMK: VISIBLE_APP_MEM: ";getprop ro.VISIBLE_APP_MEM
echo -n "LMK: PERCEPTIBLE_APP_MEM: ";getprop ro.PERCEPTIBLE_APP_MEM
echo -n "LMK: HEAVY_WEIGHT_APP_MEM: ";getprop ro.HEAVY_WEIGHT_APP_MEM
echo -n "LMK: SECONDARY_SERVER_MEM: ";getprop ro.SECONDARY_SERVER_MEM
echo -n "LMK: BACKUP_APP_MEM: ";getprop ro.BACKUP_APP_MEM
echo -n "LMK: HIDDEN_APP_MEM: ";getprop ro.HIDDEN_APP_MEM
echo -n "LMK: CONTENT_PROVIDER_MEM: ";getprop ro.CONTENT_PROVIDER_MEM
echo -n "LMK: EMPTY_APP_MEM: ";getprop ro.EMPTY_APP_MEM
echo -n "LMK: /sys/module/lowmemorykiller/parameters/minfree: ";cat /sys/module/lowmemorykiller/parameters/minfree
echo -n "LMK: /sys/module/lowmemorykiller/parameters/adj: ";cat /sys/module/lowmemorykiller/parameters/adj
echo "LMK: Mb translation: $(($ADJ0/256)),$(($ADJ1/256)),$(($ADJ2/256)),$(($ADJ7/256)),$(($ADJ14/256)),$(($ADJ15/256))"
echo "LMK: Check ADJs:"
getprop|grep ADJ
#--------------------------------------------------------------------
# VM
#--------------------------------------------------------------------
echo
echo "VM: setting VM tweaks..."
echo "0" > /proc/sys/vm/swappiness                   # Not really needed as no /swap used...
echo "2000" > /proc/sys/vm/dirty_writeback_centisecs # Flush after 20sec. (o:500)
echo "2000" > /proc/sys/vm/dirty_expire_centisecs    # Pages expire after 20sec. (o:200)
echo "55" > /proc/sys/vm/dirty_background_ratio      # flush pages later (default 5% active mem)
echo "80" > /proc/sys/vm/dirty_ratio                 # process writes pages later (default 20%)  
echo "5" > /proc/sys/vm/page-cluster
echo "0" > /proc/sys/vm/laptop_mode
echo "0" > /proc/sys/vm/oom_kill_allocating_task
echo "0" > /proc/sys/vm/panic_on_oom
echo "0" > /proc/sys/vm/overcommit_memory  
echo -n "VM: check vm/swappiness :";cat /proc/sys/vm/swappiness                   
echo -n "VM: check vm/dirty_writeback_centisecs :";cat /proc/sys/vm/dirty_writeback_centisecs
echo -n "VM: check vm/dirty_expire_centisecs: ";cat /proc/sys/vm/dirty_expire_centisecs    
echo -n "VM: check vm/dirty_background_ratio: ";cat /proc/sys/vm/dirty_background_ratio
echo -n "VM: check vm/dirty_ratio :";cat /proc/sys/vm/dirty_ratio       
echo -n "VM: check vm/page-cluster: ";cat /proc/sys/vm/page-cluster
echo -n "VM: check vm/laptop_mode: ";cat /proc/sys/vm/laptop_mode
echo -n "VM: check vm/oom_kill_allocating_task: ";cat /proc/sys/vm/oom_kill_allocating_task
echo -n "VM: check vm/panic_on_oom: ";cat /proc/sys/vm/panic_on_oom
echo -n "VM: check vm/overcommit_memory: ";cat /proc/sys/vm/overcommit_memory
      
#--------------------------------------------------------------------
# SETPROP
#--------------------------------------------------------------------
echo
echo "SETPROP: setting prop tweaks..."
setprop debug.sf.nobootanimation 0;
setprop wifi.supplicant_scan_interval 180
setprop windowsmgr.max_events_per_sec 76;
setprop ro.ril.disable.power.collapse 1;
setprop ro.telephony.call_ring.delay 1000;
setprop mot.proximity.delay 150;
setprop ro.mot.eri.losalert.delay 1000;

# disabled 2012/02/04, testing...
#setprop debug.sf.hw 1
#setprop debug.performance.tuning 1
#setprop video.accelerate.hw 1
#echo -n "PROP: debug.sf.hw: ";getprop debug.sf.hw
#echo -n "PROP: debug.performance.tuning: ";getprop debug.performance.tuning
#echo -n "PROP: video.accelerate.hw: ";getprop video.accelerate.hw

echo -n "PROP: debug.sf.nobootanimation: ";getprop debug.sf.nobootanimation
echo -n "PROP: wifi.supplicant_scan_interval: ";getprop wifi.supplicant_scan_interval
echo -n "PROP: windowsmgr.max_events_per_sec: ";getprop windowsmgr.max_events_per_sec
echo -n "PROP: ro.ril.disable.power.collapse: ";getprop ro.ril.disable.power.collapse
echo -n "PROP: ro.telephony.call_ring.delay: ";getprop ro.telephony.call_ring.delay
echo -n "PROP: mot.proximity.delay: ";getprop mot.proximity.delay
echo -n "PROP: ro.mot.eri.losalert.delay: ";getprop ro.mot.eri.losalert.delay

#--------------------------------------------------------------------
# KERNEL/SCHED
#--------------------------------------------------------------------
echo
echo "KERNEL: setting kernel tweaks..."
echo "NO_GENTLE_FAIR_SLEEPERS" > /sys/kernel/debug/sched_features
echo 500 512000 64 2048 > /proc/sys/kernel/sem 

echo 3000000 > /proc/sys/kernel/sched_latency_ns
echo 500000 > /proc/sys/kernel/sched_wakeup_granularity_ns
echo 500000 > /proc/sys/kernel/sched_min_granularity_ns

# Midnight 0.7.6
#echo 100000 > /proc/sys/kernel/sched_latency_ns
#echo 500000 > /proc/sys/kernel/sched_wakeup_granularity_ns
#echo 750000 > /proc/sys/kernel/sched_min_granularity_ns
        
# pikachu01/Thunderbolt aggressive, performance
#echo 400000 > /proc/sys/kernel/sched_latency_ns
#echo 100000 > /proc/sys/kernel/sched_wakeup_granularity_ns
#echo 200000 > /proc/sys/kernel/sched_min_granularity_ns

echo 0 > /proc/sys/kernel/panic_on_oops
echo 0 > /proc/sys/kernel/panic

# have to re-check those...
#echo 2048 > /proc/sys/kernel/msgmni 
#echo 64000 > /proc/sys/kernel/msgmax
#echo 268435456 > /proc/sys/kernel/shmmax

echo -n "KERNEL: check sched_latency_ns: ";cat /proc/sys/kernel/sched_latency_ns
echo -n "KERNEL: check sched_wakeup_granularity_ns: "; cat /proc/sys/kernel/sched_wakeup_granularity_ns
echo -n "KERNEL: check sched_min_granularity_ns: ";cat /proc/sys/kernel/sched_min_granularity_ns
echo -n "KERNEL: check sleepers: ";cat /sys/kernel/debug/sched_features
echo -n "KERNEL: check semaphores: ";cat /proc/sys/kernel/sem

#--------------------------------------------------------------------
# IPv4/TCP
#--------------------------------------------------------------------
echo
echo "TCP: setting ipv4/tcp tweaks..."
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
echo 1 > /proc/sys/net/ipv4/tcp_sack
echo 1 > /proc/sys/net/ipv4/tcp_dsack
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1 > /proc/sys/net/ipv4/tcp_window_scaling
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_probes
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 0 > /proc/sys/net/ipv4/tcp_timestamps

#--------------------------------------------------------------------
# RGB
#--------------------------------------------------------------------
#echo "VIDEO: setting rgb multiplier..."
#echo 2259970880 > /sys/class/misc/rgbb_multiplier/red_multiplier
#echo 2249744960 > /sys/class/misc/rgbb_multiplier/green_multiplier
#echo 2556528160 > /sys/class/misc/rgbb_multiplier/blue_multiplier
#--------------------------------------------------------------------
# IPvX/SEC
#--------------------------------------------------------------------
echo
echo "SEC: setting various IPv4/IPv6 security enhancements..."
echo 0 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 2 > /proc/sys/net/ipv6/conf/all/use_tempaddr
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
echo -n "SEC: ip_forward :";cat /proc/sys/net/ipv4/ip_forward
echo -n "SEC: rp_filter :";cat /proc/sys/net/ipv4/conf/all/rp_filter
echo -n "SEC: use_tempaddr :";cat /proc/sys/net/ipv6/conf/all/use_tempaddr
echo -n "SEC: accept_source_route :";cat /proc/sys/net/ipv4/conf/all/accept_source_route
echo -n "SEC: send_redirects :";cat /proc/sys/net/ipv4/conf/all/send_redirects
echo -n "SEC: icmp_echo_ignore_broadcasts :";cat /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts  
#--------------------------------------------------------------------
# MODULES AND TOUCHSCREEN
#--------------------------------------------------------------------
echo
echo "MISC: loading modules..."

# enable CIFS module loading 
if /sbin/busybox [ "$cifs" == "true" ];then
  echo "MISC: loading cifs.ko..."
  insmod /lib/modules/cifs.ko
fi

# enable TUN module loading 
if /sbin/busybox [ "$tun" == "true" ];then
  echo "MISC: loading tun.ko..."
  insmod /lib/modules/tun.ko
  echo "MISC: disabling IPv4 rp_filter for VPN..."
  echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
fi
echo "MODULES:"
lsmod
echo    
if /sbin/busybox [ "$touch" == "TOUCH1" ];then
    echo "TOUCH: setting preset TOUCH1..."
    echo 7035 > /sys/class/touch/switch/set_touchscreen     # sensitivity orig:tchthr 40
    echo 8002 > /sys/class/touch/switch/set_touchscreen     # touch register duration orig:tchdi 2
    echo 11002 > /sys/class/touch/switch/set_touchscreen    # min. motion orig: movhysti 3
    echo 13040 > /sys/class/touch/switch/set_touchscreen    # motion filter orig: movfilter 46     
elif /sbin/busybox [ "$touch" == "TOUCH2" ];then
    echo "TOUCH: setting preset TOUCH2..."
    echo 7027 > /sys/class/touch/switch/set_touchscreen
    echo 8001 > /sys/class/touch/switch/set_touchscreen
    echo 11001 > /sys/class/touch/switch/set_touchscreen
    echo 13030 > /sys/class/touch/switch/set_touchscreen   
elif /sbin/busybox [ "$touch" == "TOUCH3" ];then
    echo "TOUCH: setting preset TOUCH3..."
    echo 7020 > /sys/class/touch/switch/set_touchscreen
    echo 8000 > /sys/class/touch/switch/set_touchscreen
    echo 11001 > /sys/class/touch/switch/set_touchscreen
    echo 13020 > /sys/class/touch/switch/set_touchscreen     
else
    echo "TOUCH: using default values."
fi


#--------------------------------------------------------------------
# CPU
#--------------------------------------------------------------------
echo
echo "CPU: applying CPU settings..."
if /sbin/busybox [[ "$cpumax" -eq 1200000 || "$cpumax" -eq 1128000 || "$cpumax" -eq 1000000 || "$cpumax" -eq 800000  || "$cpumax" -eq 400000 ]];then
    echo "CPU: found vaild cpumax: <$cpumax>"
    echo $cpumax > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
fi

if /sbin/busybox [[ "$cpugov" == "ondemand" || "$cpugov" == "conservative" ]];then
    echo "CPU: found vaild cpugov: <$cpugov>"
    echo $cpugov > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
fi

if /sbin/busybox [ ! -f /cache/midnight_block ];then
    if /sbin/busybox [ "$uv1200" -lt 0 ];then uv1200=$(($uv1200*(-1)));else uv1200=0;fi
    if /sbin/busybox [ "$uv1128" -lt 0 ];then uv1128=$(($uv1128*(-1)));else uv1128=0;fi
    if /sbin/busybox [ "$uv1000" -lt 0 ];then uv1000=$(($uv1000*(-1)));else uv1000=0;fi
    if /sbin/busybox [ "$uv800" -lt 0 ];then uv800=$(($uv800*(-1)));else uv800=0;fi
    if /sbin/busybox [ "$uv400" -lt 0 ];then uv400=$(($uv400*(-1)));else uv400=0;fi
    if /sbin/busybox [ "$uv200" -lt 0 ];then uv200=$(($uv200*(-1)));else uv200=0;fi
    if /sbin/busybox [ "$uv100" -lt 0 ];then uv100=$(($uv100*(-1)));else uv100=0;fi
fi

echo "CPU: values after parsing: $uv1200, $uv1128, $uv1000, $uv800, $uv400, $uv200, $uv100"
if /sbin/busybox [ "$uvatboot" == "true" ];then
    echo "CPU: UV at boot enabled, setting values now..."
    echo $uv1200 $uv1128 $uv1000 $uv800 $uv400 $uv200 $uv100 > /sys/devices/system/cpu/cpu0/cpufreq/UV_mV_table
fi;
echo -n "CPU: Check governor: ";cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo -n "CPU: Check max frequency: ";cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo -n "CPU: Check UV values: ";cat /sys/devices/system/cpu/cpu0/cpufreq/UV_mV_table

#--------------------------------------------------------------------
# IO
#--------------------------------------------------------------------
echo
if /sbin/busybox [ -e /sys/devices/virtual/bdi/default/read_ahead_kb ]; then
    echo "IO: setting default READ_AHEAD for newly created devices..."
    echo "128" > /sys/devices/virtual/bdi/default/read_ahead_kb;
fi
echo "IO: setting default sdcard readahead 128Kb..."
echo "128" > /sys/devices/virtual/bdi/179:0/read_ahead_kb
echo "128" > /sys/devices/virtual/bdi/179:8/read_ahead_kb
if /sbin/busybox [ ! -z "$readahead" ];then
    echo "IO: checking user configured sdcard READ_AHEAD..."
    if /sbin/busybox [[ "$readahead" -eq 32 || "$readahead" -eq 64 || "$readahead" -eq 128 || "$readahead" -eq 256 || "$readahead" -eq 512 || "$readahead" -eq 1024 || "$readahead" -eq 2048 ]];then
        echo "IO: found vaild sdcard read_ahead: <$readahead>"
        echo $readahead > /sys/devices/virtual/bdi/179:0/read_ahead_kb
        echo $readahead > /sys/devices/virtual/bdi/179:8/read_ahead_kb
    fi
fi
echo "IO: setting readahead for /system, /dbdata, /cache..."
echo "16" > /sys/devices/virtual/bdi/138:9/read_ahead_kb
echo "128" > /sys/devices/virtual/bdi/138:10/read_ahead_kb
echo "16" > /sys/devices/virtual/bdi/138:11/read_ahead_kb 

STL=`ls -d /sys/block/stl*`;
BML=`ls -d /sys/block/bml*`;
MMC=`ls -d /sys/block/mmc*`;
TFSR=`ls -d /sys/block/tfsr*`;

if /sbin/busybox [ ! -z "$sched" ];then
    echo "IO: setting scheduler..."
    if /sbin/busybox [[ "$sched" == "noop" || "$sched" == "sio" || "$sched" == "vr" ]];then
        echo "IO: setting <$sched>..."
        for i in $STL $BML $MMC $TFSR; do
            echo "$sched" > "$i"/queue/scheduler;
        done
    fi
fi

echo "IO: setting scheduler tweaks..."
for i in $STL $BML $MMC $TFSR; 
do                            
    echo 0 > $i/queue/rotational;               
    echo 0 > $i/queue/iostats;
    if /sbin/busybox [ -e $i/queue/nr_requests ];then
        echo 8192 > $i/queue/nr_requests
    fi
    if /sbin/busybox [ -e $i/queue/iosched/writes_starved ];then
        echo 1 > $i/queue/iosched/writes_starved
    fi    
    if /sbin/busybox [ -e $i/queue/iosched/fifo_batch ];then
        echo 1 > $i/queue/iosched/fifo_batch
    fi
done;
echo -n "IO: check read_ahead 179.0: "; cat /sys/devices/virtual/bdi/179:0/read_ahead_kb
echo -n "IO: check read_ahead 179.8: "; cat /sys/devices/virtual/bdi/179:8/read_ahead_kb
echo -n "IO: check /system read_ahead: "; cat /sys/block/stl9/queue/read_ahead_kb
echo -n "IO: check /dbdata read_ahead: "; cat /sys/block/stl10/queue/read_ahead_kb
echo -n "IO: check /cache read_ahead: "; cat /sys/block/stl11/queue/read_ahead_kb
echo -n "IO: Recheck scheduler: "; cat /sys/block/stl10/queue/scheduler
echo -n "IO: Recheck rotational: "; cat /sys/block/stl10/queue/rotational
echo -n "IO: Recheck iostats: "; cat /sys/block/stl10/queue/iostats
if /sbin/busybox [ -e /sys/block/stl10/queue/rq_affinity ];then
    echo -n "IO: Recheck rq_affinity (1): "; cat /sys/block/stl10/queue/rq_affinity                          
fi
if /sbin/busybox [ -e /sys/block/stl10/queue/nr_requests ];then
    echo -n "IO: Recheck nr_requests (8192): ";cat /sys/block/stl10/queue/nr_requests
fi
if /sbin/busybox [ -e /sys/block/stl10/queue/iosched/writes_starved ];then
    echo -n "IO: Recheck writes_starved (1): "; cat /sys/block/stl10/queue/iosched/writes_starved
fi    
if /sbin/busybox [ -e /sys/block/stl10/queue/iosched/fifo_batch ];then
    echo -n "IO: Recheck fifo_batch (1): "; cat /sys/block/stl10/queue/iosched/fifo_batch
fi

echo;echo "LED timeout"
if /sbin/busybox [ ! -z "$timeout" ];then
    echo "found valid timeout value, using <$timeout> ms";
    echo $timeout > /sys/class/misc/backlightnotification/timeout
else
    echo -n "using default ms, ";cat /sys/class/misc/backlightnotification/timeout
fi
#--------------------------------------------------------------------
# MISC LOG
#--------------------------------------------------------------------
echo   
echo "RAM (/proc/meminfo):"
cat /proc/meminfo|grep ^MemTotal
cat /proc/meminfo|grep ^MemFree
cat /proc/meminfo|grep ^Buffers
cat /proc/meminfo|grep ^Cached
#--------------------------------------------------------------------
# INIT_D
#--------------------------------------------------------------------          
echo
echo "INIT.D: starting..."
# init.d support 
# executes <E>scriptname, <S>scriptname, <0-9><0-9>scriptname
# in this order.
if /sbin/busybox [ "$initd" == "true" ];then
    echo $(date) USER EARLY INIT START from /system/etc/init.d
    if cd /system/etc/init.d >/dev/null 2>&1 ; then
        for file in E* ; do
            if ! cat "$file" >/dev/null 2>&1 ; then continue ; fi
            echo "INIT.D: START '$file'"
            /system/bin/sh "$file"
            echo "INIT.D: EXIT '$file' ($?)"
        done
    fi
    echo $(date) USER EARLY INIT DONE from /system/etc/init.d

    echo $(date) USER INIT START from /system/etc/init.d
    if cd /system/etc/init.d >/dev/null 2>&1 ; then
        for file in S* ; do
            if ! ls "$file" >/dev/null 2>&1 ; then continue ; fi
            echo "INIT.D: START '$file'"
            /system/bin/sh "$file"
            echo "INIT.D: EXIT '$file' ($?)"
        done
    fi
    echo $(date) USER INIT DONE from /system/etc/init.d

    echo $(date) USER INIT START from /system/etc/init.d
    if cd /system/etc/init.d >/dev/null 2>&1 ; then
        for file in [0-9][0-9]* ; do
            if ! ls "$file" >/dev/null 2>&1 ; then continue ; fi
            echo "INIT.D: START '$file'"
            /system/bin/sh "$file"
            echo "INIT.D: EXIT '$file' ($?)"
        done
    fi
    echo $(date) USER INIT DONE from /system/etc/init.d
    
    # recheck what all those init.d scripts changed...
    echo
    echo "LOG: VALUES *AFTER* INIT.D EXECUTION:"
    echo "MOUNT: Check mounted partitions: "
    /sbin/busybox mount|grep /system
    /sbin/busybox mount|grep /data
    /sbin/busybox mount|grep /dbdata
    /sbin/busybox mount|grep /cache
    echo "LMK: Check used values:"
    echo -n "LMK: FOREGROUND_APP_MEM: ";getprop ro.FOREGROUND_APP_MEM
    echo -n "LMK: HOME_APP_MEM: ";getprop ro.HOME_APP_MEM
    echo -n "LMK: VISIBLE_APP_MEM: ";getprop ro.VISIBLE_APP_MEM
    echo -n "LMK: PERCEPTIBLE_APP_MEM: ";getprop ro.PERCEPTIBLE_APP_MEM
    echo -n "LMK: HEAVY_WEIGHT_APP_MEM: ";getprop ro.HEAVY_WEIGHT_APP_MEM
    echo -n "LMK: SECONDARY_SERVER_MEM: ";getprop ro.SECONDARY_SERVER_MEM
    echo -n "LMK: BACKUP_APP_MEM: ";getprop ro.BACKUP_APP_MEM
    echo -n "LMK: HIDDEN_APP_MEM: ";getprop ro.HIDDEN_APP_MEM
    echo -n "LMK: CONTENT_PROVIDER_MEM: ";getprop ro.CONTENT_PROVIDER_MEM
    echo -n "LMK: EMPTY_APP_MEM: ";getprop ro.EMPTY_APP_MEM
    echo -n "LMK: /sys/module/lowmemorykiller/parameters/minfree: ";cat /sys/module/lowmemorykiller/parameters/minfree
    echo -n "LMK: /sys/module/lowmemorykiller/parameters/adj: ";cat /sys/module/lowmemorykiller/parameters/adj
    echo "LMK: Mb translation: $(($ADJ0/256)),$(($ADJ1/256)),$(($ADJ2/256)),$(($ADJ7/256)),$(($ADJ14/256)),$(($ADJ15/256))"
    echo "LMK: Check ADJs:"
    getprop|grep ADJ
    echo -n "VM: check vm/swappiness :";cat /proc/sys/vm/swappiness                   
    echo -n "VM: check vm/dirty_writeback_centisecs :";cat /proc/sys/vm/dirty_writeback_centisecs
    echo -n "VM: check vm/dirty_expire_centisecs: ";cat /proc/sys/vm/dirty_expire_centisecs    
    echo -n "VM: check vm/dirty_background_ratio: ";cat /proc/sys/vm/dirty_background_ratio
    echo -n "VM: check vm/dirty_ratio :";cat /proc/sys/vm/dirty_ratio       
    echo -n "VM: check vm/page-cluster: ";cat /proc/sys/vm/page-cluster
    echo -n "VM: check vm/laptop_mode: ";cat /proc/sys/vm/laptop_mode
    echo -n "VM: check vm/oom_kill_allocating_task: ";cat /proc/sys/vm/oom_kill_allocating_task
    echo -n "VM: check vm/panic_on_oom: ";cat /proc/sys/vm/panic_on_oom
    echo -n "VM: check vm/overcommit_memory: ";cat /proc/sys/vm/overcommit_memory
    echo -n "PROP: debug.sf.hw: ";getprop debug.sf.hw
    echo -n "PROP: debug.sf.nobootanimation: ";getprop debug.sf.nobootanimation
    echo -n "PROP: wifi.supplicant_scan_interval: ";getprop wifi.supplicant_scan_interval
    echo -n "PROP: windowsmgr.max_events_per_sec: ";getprop windowsmgr.max_events_per_sec
    echo -n "PROP: ro.ril.disable.power.collapse: ";getprop ro.ril.disable.power.collapse
    echo -n "PROP: ro.telephony.call_ring.delay: ";getprop ro.telephony.call_ring.delay
    echo -n "PROP: mot.proximity.delay: ";getprop mot.proximity.delay
    echo -n "PROP: ro.mot.eri.losalert.delay: ";getprop ro.mot.eri.losalert.delay
    echo -n "PROP: debug.performance.tuning: ";getprop debug.performance.tuning
    echo -n "PROP: video.accelerate.hw: ";getprop video.accelerate.hw
    #echo -n "VIDEO: initial R: ";cat /sys/class/misc/rgbb_multiplier/red_multiplier
    #echo -n "VIDEO: initial G: ";cat /sys/class/misc/rgbb_multiplier/green_multiplier
    #echo -n "VIDEO: initial B: ";cat /sys/class/misc/rgbb_multiplier/blue_multiplier
    echo -n "KERNEL: check sched_latency_ns: ";cat /proc/sys/kernel/sched_latency_ns
    echo -n "KERNEL: check sched_wakeup_granularity_ns: "; cat /proc/sys/kernel/sched_wakeup_granularity_ns
    echo -n "KERNEL: check sched_min_granularity_ns: ";cat /proc/sys/kernel/sched_min_granularity_ns
    echo -n "KERNEL: check sleepers: ";cat /sys/kernel/debug/sched_features
    echo -n "KERNEL: check semaphores: ";cat /proc/sys/kernel/sem
    echo -n "SEC: ip_forward :";cat /proc/sys/net/ipv4/ip_forward
    echo -n "SEC: rp_filter :";cat /proc/sys/net/ipv4/conf/all/rp_filter
    echo -n "SEC: use_tempaddr :";cat /proc/sys/net/ipv6/conf/all/use_tempaddr
    echo -n "SEC: accept_source_route :";cat /proc/sys/net/ipv4/conf/all/accept_source_route
    echo -n "SEC: send_redirects :";cat /proc/sys/net/ipv4/conf/all/send_redirects
    echo -n "SEC: icmp_echo_ignore_broadcasts :";cat /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts     
    echo -n "CPU: Check governor: ";cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    echo -n "CPU: Check max frequency: ";cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    echo -n "CPU: Check UV values: ";cat /sys/devices/system/cpu/cpu0/cpufreq/UV_mV_table
    echo -n "IO: check READ_AHEAD 179.0: "; cat /sys/devices/virtual/bdi/179:0/read_ahead_kb
    echo -n "IO: check READ_AHEAD 179.8: "; cat /sys/devices/virtual/bdi/179:8/read_ahead_kb
    echo -n "IO: check /system read_ahead: "; cat /sys/block/stl9/queue/read_ahead_kb
    echo -n "IO: check /dbdata read_ahead: "; cat /sys/block/stl10/queue/read_ahead_kb
    echo -n "IO: check /cache read_ahead: "; cat /sys/block/stl11/queue/read_ahead_kb
    echo -n "IO: Recheck scheduler: "; cat /sys/block/stl10/queue/scheduler
    echo -n "IO: Recheck rotational: "; cat /sys/block/stl10/queue/rotational
    echo -n "IO: Recheck iostats: "; cat /sys/block/stl10/queue/iostats
    if /sbin/busybox [ -e /sys/block/stl10/queue/rq_affinity ];then
        echo -n "IO: Recheck rq_affinity (1): "; cat /sys/block/stl10/queue/rq_affinity                          
    fi
    if /sbin/busybox [ -e /sys/block/stl10/queue/nr_requests ];then
        echo -n "IO: Recheck nr_requests (8192): ";cat /sys/block/stl10/queue/nr_requests
    fi
    if /sbin/busybox [ -e /sys/block/stl10/queue/iosched/writes_starved ];then
        echo -n "IO: Recheck writes_starved (1): "; cat /sys/block/stl10/queue/iosched/writes_starved
    fi    
    if /sbin/busybox [ -e /sys/block/stl10/queue/iosched/fifo_batch ];then
        echo -n "IO: Recheck fifo_batch (1): "; cat /sys/block/stl10/queue/iosched/fifo_batch
    fi
    echo "MODULES:"
    lsmod
    echo "RAM (/proc/meminfo):"
    cat /proc/meminfo|grep ^MemTotal
    cat /proc/meminfo|grep ^MemFree
    cat /proc/meminfo|grep ^Buffers
    cat /proc/meminfo|grep ^Cached
    echo "LOG: VALUES *AFTER* INIT.D END"
else 
    echo "INIT.D: disabled..."
fi

#--------------------------------------------------------------------
# CLEANUP
#--------------------------------------------------------------------
echo
echo "disabling /sbin/busybox, using /system/xbin/busybox now..."
/sbin/busybox_disabled rm /sbin/busybox

echo "mounting rootfs readonly..."
/sbin/busybox_disabled mount -t rootfs -o remount,ro rootfs;
