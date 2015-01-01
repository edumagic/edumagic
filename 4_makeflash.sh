#!/bin/bash

# License: GPL latest version
# Лицензия: GPL последней версии
# Description: Create a final distro
# Описание: Создает итоговый дистрибутив
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

DISTRVERSION=$(date +%Y%m%d)
DESTDIR=flash/${FLASHNAME}_${VERREL}_${DISTRVERSION}
if [ "$SQFSVER" = "3" ] ;then
  MKSQUASHFS=mksquashfs3
  UNSQUASHFS=unsquashfs3
  MODULEFORMAT=lzm
else
  MKSQUASHFS=mksquashfs
  UNSQUASHFS=unsquashfs
  MODULEFORMAT=xzm
fi

echo "Preparing"
echo "Подготовка"
[ -d "$DESTDIR" ] && rm -fr "$DESTDIR"
mkdir -p "$DESTDIR" || exit 1
mkdir -p "$DESTDIR"/MagicOS/{base,modules,optional,rootcopy}
mkdir -p "$DESTDIR"/MagicOS-Data/{changes,homes,modules,optional,rootcopy}
cp -pR files/patches/flash/* "$DESTDIR"/

cd "$MYPATH"

if [ "$FS_KERNEL" = "unionfs" ]
then
   echo "An amendment to items of boot menu for unionfs"
   echo "Внесение поправки для unionfs в пункты загрузочного меню"
   sed -i -e 's|root=/dev/ram0|root=/dev/ram0 unionfs|g' "$DESTDIR"/boot/grub4dos/menu.lst
   sed -i -e 's|root=/dev/ram0|root=/dev/ram0 unionfs|g' "$DESTDIR"/boot/syslinux/syslinux.cfg
   sed -i -e 's|root=/dev/ram0|root=/dev/ram0 unionfs|g' "$DESTDIR"/boot/syslinux/isolinux.cfg
fi

echo $VERREL $DISTRVERSION  > "$DESTDIR"/MagicOS/VERSION
cd work/${FLASHNAME}_${VERREL}
echo $VERREL $DISTRVERSION  > VERSION

cd "$MYPATH"

umount $ROOTFS_INITRD/proc >/dev/null 2>&1
umount $ROOTFS_INITRD/dev >/dev/null 2>&1

if [ ! $ROOTFS_INITRD = $ROOTFS ]
then
    echo "Preparing to create initrd: cleaning $ROOTFS_INITRD, copying the contents of $ROOTFS into $ROOTFS_INITRD"
    echo "Подготовка к созданию initrd: очистка $ROOTFS_INITRD, копирование содержимого $ROOTFS в $ROOTFS_INITRD"
    rm -rf $ROOTFS_INITRD
    mkdir -p $ROOTFS_INITRD
    cp -pfR $ROOTFS/bin $ROOTFS_INITRD/
    cp -pfR $ROOTFS/boot $ROOTFS_INITRD/
    cp -pfR $ROOTFS/etc $ROOTFS_INITRD/
    cp -pfR $ROOTFS/home $ROOTFS_INITRD/
    cp -pfR $ROOTFS/initrd $ROOTFS_INITRD/
    cp -pfR $ROOTFS/lib $ROOTFS_INITRD/
    cp -pfR $ROOTFS/media $ROOTFS_INITRD/
    cp -pfR $ROOTFS/mnt $ROOTFS_INITRD/
    cp -pfR $ROOTFS/opt $ROOTFS_INITRD/
    cp -pfR $ROOTFS/root $ROOTFS_INITRD/
    cp -pfR $ROOTFS/run $ROOTFS_INITRD/
    cp -pfR $ROOTFS/sbin $ROOTFS_INITRD/
    cp -pfR $ROOTFS/srv $ROOTFS_INITRD/
    cp -pfR $ROOTFS/usr $ROOTFS_INITRD/
    cp -pfR $ROOTFS/var $ROOTFS_INITRD/
fi

echo "Creating links to the kernel sources"
echo "Создание ссылок на исходники ядра"
cd "$ROOTFS_INITRD"/boot
ln -sf $(ls -1 vmlinuz-*-* | sed 's|.*/||' | tail -1) vmlinuz || exit 1
cd "$MYPATH"
cp -L "$ROOTFS_INITRD"/boot/vmlinuz "$DESTDIR"/MagicOS
echo "Patching $ROOTFS_INITRD"
echo "Патчи $ROOTFS_INITRD"
cp -pfR patches/rootfs/* $ROOTFS_INITRD/

echo "Creating initrd"
echo "Cоздание initrd"
mkdir -p $ROOTFS_INITRD/{tmp,proc,sys,dev,/mnt/live} || exit 1

mount -o bind /dev $ROOTFS_INITRD/dev || exit 1
mount -o bind /proc $ROOTFS_INITRD/proc || exit 1

cp -p work/${FLASHNAME}_${VERREL}/VERSION $ROOTFS_INITRD/mnt/live || exit 1

chroot $ROOTFS_INITRD /usr/lib/magicos/scripts/mkinitrd /boot/initrd.gz || exit 1
mv $ROOTFS_INITRD/boot/initrd.gz "$MYPATH/$DESTDIR/MagicOS" || exit 1

if [ ! $ROOTFS_INITRD = $ROOTFS ]
then
    echo "Deleting $ROOTFS_INITRD"
    echo "Удаление $ROOTFS_INITRD"
    umount $ROOTFS_INITRD/proc || exit 1
    umount $ROOTFS_INITRD/dev || exit 1
    rm -rf $ROOTFS_INITRD
fi

echo "Copying modules"
echo "Копирование модулей"
cd "$MYPATH/work/${FLASHNAME}_${VERREL}" || exit 1
rsync -a --exclude=*edu* *.$MODULEFORMAT $MYPATH/$DESTDIR/MagicOS/base/
cd "$MYPATH/$DESTDIR/MagicOS/base"
chmod 444 *
md5sum *.$MODULEFORMAT > MD5SUM

cd "$MYPATH"
echo "Creating files for data saving" 
echo "Создание файлов для сохранения данных" 
cd "$MYPATH"/$DESTDIR/MagicOS-Data || exit 1
[ "$DATASIZE1" != "" ] && dd if=/dev/zero of=MagicOS_save1.img bs=1M count=$DATASIZE1 && mkfs.ext3 -F -j MagicOS_save1.img >/dev/null 2>&1

cd "$MYPATH"

if [ ! "$DISTR_KIND" = "edu" ]
then
   echo "The script has completed work, there is system in a directory flash, it's ready for installing :-)"
   echo "Работа скрипта завершена, в папке flash лежит готовая к установке система :-)"
fi

if [ "$DISTR_KIND" = "edu" ]
then
  echo "Creating edu version of the distro"
  echo "Cоздание edu версии дистрибутива"
  DESTDIR_EDU=flash-edu/${FLASHNAME}_${VERREL}_${DISTRVERSION}
  [ -d "$DESTDIR_EDU" ] && rm -fr "$DESTDIR_EDU"
  mkdir -p "$DESTDIR_EDU" || exit 1
  cp -pfR "$DESTDIR"/* "$DESTDIR_EDU"/
  cd "$MYPATH/work/${FLASHNAME}_${VERREL}" || exit 1
  cp -f *edu*.$MODULEFORMAT $MYPATH/$DESTDIR_EDU/MagicOS/base/
  cd "$MYPATH/$DESTDIR_EDU/MagicOS/base"
  chmod 444 *
  md5sum *.$MODULEFORMAT > MD5SUM
  cd "$MYPATH"
  echo "Replacing names of iso images"
  echo "Замена названий iso образов"
  sed -i -e 's|CDLABEL=".*."|CDLABEL="EduMagicboot"|g' "$DESTDIR_EDU"/boot/grub4dos/install.lin/make_boot_iso.sh
  sed -i -e 's|CDLABEL=".*."|CDLABEL="EduMagic"|g' "$DESTDIR_EDU"/boot/grub4dos/install.lin/make_iso.sh
  sed -i -e 's|CDLABEL=.*.|CDLABEL=EduMagicboot\r|g' "$DESTDIR_EDU"/boot/grub4dos/install.win/make_boot_iso.bat
  sed -i -e 's|CDLABEL=.*.|CDLABEL=EduMagic\r|g' "$DESTDIR_EDU"/boot/grub4dos/install.win/make_iso.bat
  sed -i -e 's|CDLABEL=".*."|CDLABEL="EduMagicboot"|g' "$DESTDIR_EDU"/boot/syslinux/install.lin/make_boot_iso.sh
  sed -i -e 's|CDLABEL=".*."|CDLABEL="EduMagic"|g' "$DESTDIR_EDU"/boot/syslinux/install.lin/make_iso.sh
  sed -i -e 's|CDLABEL=.*.|CDLABEL=EduMagicboot\r|g' "$DESTDIR_EDU"/boot/syslinux/install.win/make_boot_iso.bat
  sed -i -e 's|CDLABEL=.*.|CDLABEL=EduMagic\r|g' "$DESTDIR_EDU"/boot/syslinux/install.win/make_iso.bat
  if [ -f "files/patches/flash-edu/isolinux.cfg" ]
  then
    cp -f files/patches/flash-edu/isolinux.cfg $MYPATH/$DESTDIR_EDU/boot/syslinux/
  fi
  if [ -f "files/patches/flash-edu/menu.lst" ]
  then
    cp -f files/patches/flash-edu/menu.lst $MYPATH/$DESTDIR_EDU/boot/grub4dos/
  fi
  if [ -f "files/patches/flash-edu/syslinux.cfg" ]
  then
    cp -f files/patches/flash-edu/syslinux.cfg $MYPATH/$DESTDIR_EDU/boot/syslinux/
  fi
  if [ "$FS_KERNEL" = "unionfs" ]
  then
    echo "An amendment to items of boot menu for unionfs"
    echo "Внесение поправки для unionfs в пункты загрузочного меню"
    sed -i -e 's|root=/dev/ram0|root=/dev/ram0 unionfs|g' "$DESTDIR_EDU"/boot/grub4dos/menu.lst
    sed -i -e 's|root=/dev/ram0|root=/dev/ram0 unionfs|g' "$DESTDIR_EDU"/boot/syslinux/syslinux.cfg
    sed -i -e 's|root=/dev/ram0|root=/dev/ram0 unionfs|g' "$DESTDIR_EDU"/boot/syslinux/isolinux.cfg
  fi
  mv -f $DESTDIR_EDU flash-edu/EduMagic_${VERREL}_${DISTRVERSION}
  echo "The script has completed work, there is edu version of system in a directory flash-edu, it's ready for installing :-)"
  echo "Работа скрипта завершена, в папке flash-edu лежит готовая к установке edu версия системы :-)"
fi

cd "$MYPATH"

echo "Copying documents *.txt in directory docs"
echo "Копирование документов *.txt в директорию docs"
mkdir -p "$MYPATH"/docs
cp -f "$MYPATH"/work/*.txt "$MYPATH"/docs/
cd "$MYPATH"/docs
tr -d '\r' < log_urpmi.txt > log_urpmi.txt.tmp
mv -f log_urpmi.txt.tmp log_urpmi.txt

echo "Run the script 9_clear_work.sh for deleting work directory"
echo "Запустите скрипт 9_clear_work.sh для удаления сборочной директории work"
exit 0
