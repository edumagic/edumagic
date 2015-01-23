#!/bin/bash

set -e
TARGET=""
MBR=""

LOCF=`pwd`/`locale | grep ^LANG= | awk -F= '{print $2}'`
function t_echo()
{
  STR=""
  while [ "$1" != "" ] ;do
       if grep -q "^$1|" $LOCF 2>/dev/null ;then
          STR="$STR `grep "^$1|" $LOCF | awk -F\| '{print $2}'`"
       else
          STR="$STR $1"
       fi
       shift
  done
  echo $STR
}

# Find out which partition or disk are we using
MYMNT=$(cd -P $(dirname $0) ; pwd)
while [ "$MYMNT" != "" -a "$MYMNT" != "." -a "$MYMNT" != "/" ]; do
   TARGET=$(egrep "[^[:space:]]+[[:space:]]+$MYMNT[[:space:]]+" /proc/mounts | cut -d " " -f 1)
   if [ "$TARGET" != "" ]; then break; fi
   MYMNT=$(dirname "$MYMNT")
done

if [ "$TARGET" = "" ]; then
   t_echo "Can't find device to install to."
   t_echo "Make sure you run this script from a mounted device."
   exit 1
fi

if [ "$(cat /proc/mounts | grep "^$TARGET" | grep noexec)" ]; then
   t_echo "The disk" $TARGET "is mounted with noexec parameter, trying to remount..."
   mount -o remount,exec "$TARGET"
fi

MBR=$(echo "$TARGET" | sed -r "s/[0-9]+\$//g")
NUM=${TARGET:${#MBR}}
#cd "$MYMNT"

clear
t_echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
t_echo "                        Welcome to MagicOS boot installer                         "
t_echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
echo
t_echo "This installer will setup disk" $TARGET "to boot only MagicOS."
if [ "$MBR" != "$TARGET" ]; then
   t_echo
   t_echo "Warning! Master boot record (MBR) of" $MBR "will be overwritten."
   t_echo "If you use" $MBR "to boot any existing operating system, it will not work"
   t_echo "anymore. Only MagicOS will boot from this device. Be careful!"
fi
t_echo
t_echo "Press Enter to continue, or Ctrl+C to abort..."
read junk
clear

t_echo "Flushing filesystem buffers, this may take a while..."
sync

cd ../

t_echo "Copying grub4dos files on" $TARGET...
cp -f magicos.ldr ../../

if [ "$MBR" != "$TARGET" ]; then
   t_echo "Saving old MBR ..."
   dd if=$MBR of=backup.mbr count=1 2>/dev/null
   t_echo "Setting up MBR on" $MBR...
   ./bootlace.com.bat --no-backup-mbr --time-out=0 $MBR
else
    echo ./bootlace.com.bat --floppy $TARGET
fi

t_echo "Disk" $TARGET "should be bootable now. Installation finished."

t_echo
t_echo "Read the information above and then press Enter to exit..."
read junk
