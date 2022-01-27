msg "Initializing zram..."
modprobe zram
MEM=$(( $(rg -oPm1 '(?<=MemTotal:       )[0-9]*' /proc/meminfo) * 25 / 100 ))K
DEV=$(zramctl --algorithm zstd --find --size $MEM --streams $(nproc))
mkswap --label zram $DEV
swapon --priority 32767 $DEV
