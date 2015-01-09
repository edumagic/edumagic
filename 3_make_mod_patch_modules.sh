#!/bin/bash

# License: GPL latest version
# Лицензия: GPL последней версии
# Description: Create XZM module-patches
# Описание: Создает XZM для модулей-патчей
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

rm -f $MOD_ROOTFS_DIR/*patch*.$MODULEFORMAT

MOD_LINE=$MOD_PREV
echo "Creating XZM for the module $MOD_PATCH_URPMI"
echo "Создание XZM для модуля $MOD_PATCH_URPMI"
mksquashfs $MOD_LINE $MOD_ROOTFS_DIR/$MOD_PATCH_URPMI.$MODULEFORMAT $MKSQOPT
echo -ne \\n "---> OK."\\n

MOD_LINE=patches/rootfs
echo "Creating XZM for the module $MOD_PATCH_MAGICOS"
echo "Создание XZM для модуля $MOD_PATCH_MAGICOS"
mksquashfs $MOD_LINE $MOD_ROOTFS_DIR/$MOD_PATCH_MAGICOS.$MODULEFORMAT $MKSQOPT
echo -ne \\n "---> OK."\\n

DISTRVERSION=$(date +%Y%m%d)
DESTDIR=flash/${FLASHNAME}_${VERREL}_${DISTRVERSION}

if [ -d "$MYPATH/$DESTDIR/$FLASHNAME/base" ]
then
    echo "Copying modules"
    echo "Копирование модулей"
    cd "$MYPATH/work/${FLASHNAME}_${VERREL}" || exit 1
    rm -f $MYPATH/$DESTDIR/$FLASHNAME/base/*patch*.$MODULEFORMAT
    cp -f $MOD_PATCH_MAGICOS.$MODULEFORMAT $MYPATH/$DESTDIR/$FLASHNAME/base/
    cp -f $MOD_PATCH_URPMI.$MODULEFORMAT $MYPATH/$DESTDIR/$FLASHNAME/base/
    cd "$MYPATH/$DESTDIR/$FLASHNAME/base"
    chmod 444 *
    md5sum *.$MODULEFORMAT > MD5SUM
fi

cd "$MYPATH"

if [ "$DISTR_KIND" = "edu" ]
then
    MOD_LINE=patches/edu
    echo "Creating XZM for the module $MOD_PATCH_EDUMAGIC"
    echo "Создание XZM для модуля $MOD_PATCH_EDUMAGIC"
    mksquashfs $MOD_LINE $MOD_ROOTFS_DIR/$MOD_PATCH_EDUMAGIC.$MODULEFORMAT $MKSQOPT
    echo -ne \\n "---> OK."\\n
    DISTRVERSION=$(date +%Y%m%d)
    DESTDIR_EDU=flash-edu/${FLASHNAME}_${VERREL}_${DISTRVERSION}
fi

if [ ! -d "$DESTDIR_EDU" ]
then
   DESTDIR_EDU=flash-edu/EduMagic_${VERREL}_${DISTRVERSION}
fi

if [ -d "$MYPATH/$DESTDIR_EDU/$FLASHNAME/base" ]
then
    echo "Copying modules"
    echo "Копирование модулей"
    cd "$MYPATH/work/${FLASHNAME}_${VERREL}" || exit 1
    rm -f $MYPATH/$DESTDIR_EDU/$FLASHNAME/base/*patch*.$MODULEFORMAT
    cp -f *patch*.$MODULEFORMAT $MYPATH/$DESTDIR_EDU/$FLASHNAME/base/
    cd "$MYPATH/$DESTDIR_EDU/$FLASHNAME/base"
    chmod 444 *
    md5sum *.$MODULEFORMAT > MD5SUM
fi

echo "The script has completed work"
echo "Работа скрипта завершена"
exit 0
