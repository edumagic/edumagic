#!/bin/bash

# License: GPL latest version
# Лицензия: GPL последней версии
# Description: Clear the build directory
# Описание: Очищает сборочную
# Authors: Goroshkin Anton, Alexey Loginov
# Авторы: Горошкин Антон, Логинов Алексей

if [ "`id -u`" != "0" ] ;then
   echo "Need root permissions"
   echo "Нужны права root"
   exit 1
fi

if [ -f config ] ;then
  . config
else
  echo "Can not see config file"
  echo "Не вижу файла config" ;  exit 1
fi

A=`which urpmi`
if [ "$A" = "" ]
then
  echo "No found buldrequires urpmi"
  echo "Не найдено сборочной зависимости urpmi"
  exit 1
fi
A=`which mksquashfs`
if [ "$A" = "" ]
then
  A=`which mksquashfs3`
  if [ "$A" = "" ]
  then
    echo "No found buldrequires mksquashfs or mksquashfs3"
    echo "Не найдено сборочной зависимости mksquashfs или mksquashfs3"
    exit 1
  fi
fi
A=`which rsync`
if [ "$A" = "" ]
then
  echo "No found buldrequires rsync"
  echo "Не найдено сборочной зависимости rsync"
  exit 1
fi

cd "$MYPATH"

function umountbranches()
{
 while grep -q "$1" /proc/mounts ;do
    grep "$1" /proc/mounts | awk '{print $2}' | while read a ;do
       echo umount "$a"
       umount "$a" 2>/dev/null
    done
 done
}

umountbranches "$ROOTFS"

rm -f ./uname

#rm -rf work

echo "The script has completed work"
echo "Работа скрипта завершена"
exit 0
