#!/bin/sh
for d in sda vda
do
  [ -e /dev/$d ] && dd if=/dev/$d of=/boot/MBR_$d bs=512 count=1 2>/dev/null >/dev/null
done

