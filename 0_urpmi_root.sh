#!/bin/bash

# License: GPL latest version
# Лицензия: GPL последней версии
# Description: Connects and configures the repository
# Описание: Подключает и настраивает источники
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

rm -rf $MOD_PREV

mkdir -p $MOD_PREV

urpmi.addmedia --distrib --urpmi-root $MOD_PREV $DIST_MIRROR_0
urpmi.addmedia --distrib --urpmi-root $MOD_PREV $DIST_MIRROR_1
#urpmi.addmedia --distrib --urpmi-root $MOD_PREV $DIST_MIRROR_2

if [ -f urpmi.cfg ]
then
  mkdir -p $MOD_PREV/etc/urpmi
  cp -f urpmi.cfg $MOD_PREV/etc/urpmi/
  urpmi.update -a --urpmi-root $MOD_PREV
fi

echo "The script has completed work"
echo "Работа скрипта завершена"
exit 0
