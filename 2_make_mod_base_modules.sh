#!/bin/bash

# License: GPL latest version
# Лицензия: GPL последней версии
# Description: Create XZM for basic modules
# Описание: Создает XZM для базовых модулей
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

if [ "$SQFSVER" = "3" ] ;then
  MKSQUASHFS=mksquashfs3
  UNSQUASHFS=unsquashfs3
  MODULEFORMAT=lzm
else
  MKSQUASHFS=mksquashfs
  UNSQUASHFS=unsquashfs
  MODULEFORMAT=xzm
fi

mkdir -p $ROOTFS

rm -f $MOD_ROOTFS_DIR/*base*.$MODULEFORMAT

mkdir -p $RPM_CACHE

for MOD in `ls -1 $MOD_NAMES_DIR/??-base*` ;do
    MOD_LINE=$MOD_ROOTFS_DIR/$(basename $MOD)
    echo "Moving rpms for the module $(basename $MOD) into $RPM_CACHE"
    echo "Перенос rpms для модуля $(basename $MOD) в $RPM_CACHE"
    mv -f $MOD_LINE/var/cache/urpmi/rpms/* $RPM_CACHE/ 2>/dev/null
    echo "Creating XZM for the module $(basename $MOD)"
    echo "Создание XZM для модуля $(basename $MOD)"
    mksquashfs $MOD_LINE $MOD_LINE.$MODULEFORMAT $MKSQOPT
    echo -ne \\n "---> OK."\\n
done

#if [ -d "$MOD_ROOTFS_DIR/$ADD_MOD_NAME" ]
#then
#  MOD_LINE=$MOD_ROOTFS_DIR/$ADD_MOD_NAME
#  echo "Creating XZM for the module $ADD_MOD_NAME"
#  echo "Создание XZM для модуля $ADD_MOD_NAME"
#  mksquashfs $MOD_LINE $MOD_LINE.$MODULEFORMAT $MKSQOPT
#  echo -ne \\n "---> OK."\\n
#fi

if [ "$DISTR_KIND" = "edu" ]
then
    for MOD in `ls -1 $MOD_NAMES_DIR/??-edu*` ;do
	MOD_LINE=$MOD_ROOTFS_DIR/$(basename $MOD)
	echo "Moving rpms for the module $(basename $MOD) into $RPM_CACHE"
	echo "Перенос rpms для модуля $(basename $MOD) в $RPM_CACHE"
	mv -f $MOD_LINE/var/cache/urpmi/rpms/* $RPM_CACHE/ 2>/dev/null
	echo "Creating XZM for the module $(basename $MOD)"
	echo "Создание XZM для модуля $(basename $MOD)"
	mksquashfs $MOD_LINE $MOD_LINE.$MODULEFORMAT $MKSQOPT
	echo -ne \\n "---> OK."\\n
    done

#    if [ -d "$MOD_ROOTFS_DIR/$ADD_MOD_NAME" ]
#    then
#      MOD_LINE=$MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME
#      echo "Creating XZM for the module $ADD_EDU_MOD_NAME"
#      echo "Создание XZM для модуля $ADD_EDU_MOD_NAME"
#      mksquashfs $MOD_LINE $MOD_LINE.$MODULEFORMAT $MKSQOPT
#      echo -ne \\n "---> OK."\\n
#    fi
fi

echo "The script has completed work"
echo "Работа скрипта завершена"
exit 0
