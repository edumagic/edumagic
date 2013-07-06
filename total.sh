#!/bin/bash

# License: GPL latest version
# Лицензия: GPL последней версии
# Description: Run general scripts step by step
# Описание: Запуск основных скриптов сразу пошагово
# Author: Alexey Loginov
# Автор: Логинов Алексей

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

echo "Run script 0_urpmi_root.sh"
echo "Запуск скрипта 0_urpmi_root.sh"
./0_urpmi_root.sh
echo "Script 0_urpmi_root.sh was ended"
echo "Скрипт 0_urpmi_root.sh завершён"

echo "Run script 1_make_mod_base_rootfs.sh"
echo "Запуск скрипта 1_make_mod_base_rootfs.sh"
./1_make_mod_base_rootfs.sh
echo "Script 1_make_mod_base_rootfs.sh was ended"
echo "Скрипт 1_make_mod_base_rootfs.sh завершён"

echo "Run script 2_make_mod_base_modules.sh"
echo "Запуск скрипта 2_make_mod_base_modules.sh"
./2_make_mod_base_modules.sh
echo "Script 2_make_mod_base_modules.sh was ended"
echo "Скрипт 2_make_mod_base_modules.sh завершён"

echo "Run script 3_make_mod_patch_modules.sh"
echo "Запуск скрипта 3_make_mod_patch_modules.sh"
./3_make_mod_patch_modules.sh
echo "Script 3_make_mod_patch_modules.sh was ended"
echo "Скрипт 3_make_mod_patch_modules.sh завершён"

echo "Run script 4_makeflash.sh"
echo "Запуск скрипта 4_makeflash.sh"
./4_makeflash.sh
echo "Script 4_makeflash.sh was ended"
echo "Скрипт 4_makeflash.sh завершён"

#echo "Run script 5_clear_work.sh"
#echo "Запуск скрипта 5_clear_work.sh"
#./5_clear_work.sh
#echo "Script 5_clear_work.sh was ended"
#echo "Скрипт 5_clear_work.sh завершён"

exit 0
