#!/bin/bash

# License: GPL latest version
# Лицензия: GPL последней версии
# Description: Build basic modules
# Описание: Собирает базовые модули
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

if [ -d $RPM_CACHE ]
then
  FULL_CACHE=`ls $RPM_CACHE`
  if [ ! "$FULL_CACHE" = "" ]
  then
    echo "Moving rpms from $RPM_CACHE into $MOD_PREV/var/cache/urpmi/rpms"
    echo "Перенос rpms из $RPM_CACHE в $MOD_PREV/var/cache/urpmi/rpms"
    mkdir -p $MOD_PREV/var/cache/urpmi/rpms
    mv -f $RPM_CACHE/* $MOD_PREV/var/cache/urpmi/rpms/
  fi
fi

rm -rf /tmp/building
mkdir -p /tmp/building
mv -f /var/lib/rpm/__db.* /tmp/building/

if [ ! -d $ROOTFS ]
then
    mkdir -p $ROOTFS
    if [ "$FS_ROOTFS" = "unionfs" ]
    then
      modprobe unionfs
      mount -t unionfs -o dirs=$MOD_PREV wiz_fly $ROOTFS
    fi

    if [ "$FS_ROOTFS" = "aufs" ]
    then
      mount -t aufs wiz_fly -o br:$MOD_PREV $ROOTFS
    fi
    mkdir -p $ROOTFS/{proc,dev,sys}
    mount -o bind /proc $ROOTFS/proc
    mount -o bind /dev $ROOTFS/dev
    mount -o bind /sys $ROOTFS/sys
fi

DIR_KERNEL=`ls ./kernel`
MOD_PREV0=$MOD_PREV

for MOD in `ls -1 $MOD_NAMES_DIR/??-base*` ;do
    echo "Generating rootfs for the module $(basename $MOD)"
    echo "Генерация rootfs для модуля $(basename $MOD)"
    if [ -d $MOD_ROOTFS_DIR/$(basename $MOD) ] ;then 
        echo "...directory already created"
        echo "...директория уже создана"
    else
        mkdir -p $MOD_ROOTFS_DIR/$(basename $MOD)
    fi

    MOD_LINE=$MOD_ROOTFS_DIR/$(basename $MOD)
    if [ "$FS_ROOTFS" = "unionfs" ]
    then
      mount -o remount,rw,add=$MOD_LINE=rw,mode=$MOD_PREV0=ro wiz_fly $ROOTFS
    fi
    if [ "$FS_ROOTFS" = "aufs" ]
    then
      mount -o remount,prepend:$MOD_LINE=rw,mod:$MOD_PREV0=rr wiz_fly $ROOTFS
    fi
    MOD_PREV0=$MOD_LINE
    #For Enable Internet (in the next module after 01-base-system, when resolv.conf was created)
    if [ "$INTERNET" = "yes" ]
    then
      if [ "$(basename $MOD)" = "02-base-core" ]
      then
        mv -f $MOD_ROOTFS_DIR/01-base-system/etc/resolv.conf $MOD_ROOTFS_DIR/01-base-system/etc/resolv.conf.tmp
        cp -f /etc/resolv.conf $MOD_ROOTFS_DIR/01-base-system/etc/
      fi
    fi
    if [ ! "$DIR_KERNEL" = "" ]
    then
         if [ "$(basename $MOD)" = "02-base-core" ]
         then
             urpmi $URPMI_PARAM --urpmi-root=$ROOTFS --root=$ROOTFS --prefer="$PREFER" `cat $MOD|grep -v "#"` ./kernel/* 2>&1| tee -a $MYPATH/work/log_urpmi.txt
         else
             urpmi $URPMI_PARAM --urpmi-root=$ROOTFS --root=$ROOTFS --prefer="$PREFER" `cat $MOD|grep -v "#"` 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
         fi
    else
        if [ ! "$(basename $MOD)" = "21-base-codecs" ]
        then
           urpmi $URPMI_PARAM --urpmi-root=$ROOTFS --root=$ROOTFS --prefer="$PREFER" `cat $MOD|grep -v "#"` 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
        else
           urpmi $URPMI_PARAM_CODECS --urpmi-root=$ROOTFS --root=$ROOTFS --prefer="$PREFER" `cat $MOD|grep -v "#"` 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
        fi
    fi
    #rpm -qa helps to write rpm database on disk
    chroot $ROOTFS rpm -qa > /dev/null 2>&1
    echo -ne \\n "---> OK."\\n
done

if [ "$LISTS_PKGS_MAGICOS" = "yes" ]
then
  chroot $ROOTFS rpm -qa --queryformat '%{NAME}\n'|sort -u > $MYPATH/work/all_name_rpm.txt
  chroot $ROOTFS rpm -qa|sort -u > $MYPATH/work/all_rpm.txt
fi

if [ "$DISTR_KIND" = "edu" ]
then
    for MOD in `ls -1 $MOD_NAMES_DIR/??-edu*` ;do
        echo "Generating rootfs for the module $(basename $MOD)"
        echo "Генерация rootfs для модуля $(basename $MOD)"
        if [ -d $MOD_ROOTFS_DIR/$(basename $MOD) ] ;then
            echo "...directory already created"
            echo "...директория уже создана"
        else
            mkdir -p $MOD_ROOTFS_DIR/$(basename $MOD)
        fi

        MOD_LINE=$MOD_ROOTFS_DIR/$(basename $MOD)
        if [ "$FS_ROOTFS" = "unionfs" ]
        then
          mount -o remount,rw,add=$MOD_LINE=rw,mode=$MOD_PREV0=ro wiz_fly $ROOTFS
        fi
        if [ "$FS_ROOTFS" = "aufs" ]
        then
          mount -o remount,prepend:$MOD_LINE=rw,mod:$MOD_PREV0=rr wiz_fly $ROOTFS
        fi
        MOD_PREV0=$MOD_LINE
        urpmi $URPMI_PARAM --urpmi-root=$ROOTFS --root=$ROOTFS --prefer="$PREFER" `cat $MOD|grep -v "#"` 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
        #rpm -qa helps to write rpm database on disk
        chroot $ROOTFS rpm -qa > /dev/null 2>&1
        echo -ne \\n "---> OK."\\n
    done
fi

#In the end to remount on empty directory
mkdir -p $MOD_ROOTFS_DIR/empty > /dev/null 2>&1
if [ "$FS_ROOTFS" = "unionfs" ]
then
  mount -o remount,rw,add=$MOD_ROOTFS_DIR/empty=rw,mode=$MOD_PREV0=ro wiz_fly $ROOTFS
fi
if [ "$FS_ROOTFS" = "aufs" ]
then
  mount -o remount,prepend:$MOD_ROOTFS_DIR/empty=rw,mod:$MOD_PREV0=rr wiz_fly $ROOTFS
fi

#Return after Enable Internet
if [ "$INTERNET" = "yes" ]
then
  if [ -f "$MOD_ROOTFS_DIR/01-base-system/etc/resolv.conf.tmp" ]
  then
    rm -f $MOD_ROOTFS_DIR/01-base-system/etc/resolv.conf
    mv -f $MOD_ROOTFS_DIR/01-base-system/etc/resolv.conf.tmp $MOD_ROOTFS_DIR/01-base-system/etc/resolv.conf
  fi
fi

echo "Moving rpms from $MOD_PREV/var/cache/urpmi/rpms into $RPM_CACHE"
echo "Перенос rpms из $MOD_PREV/var/cache/urpmi/rpms в $RPM_CACHE"
mkdir -p $RPM_CACHE
mv -f $MOD_PREV/var/cache/urpmi/rpms/* $RPM_CACHE/ >/dev/null 2>&1

echo "The file work/log_urpmi.txt contains installation log"
echo "В файле work/log_urpmi.txt содержится лог установки"

if [ "$LISTS_PKGS_MAGICOS" = "yes" ]
then
  echo "File work/all_name_rpm.txt contains a list of all installed packages in the distro by name"
  echo "В файле work/all_name_rpm.txt содержится список всех установленных в дистрибутиве пакетов поимённо"
  echo "File work/all_rpm.txt contains a list of all installed packages in the distro"
  echo "В файле work/all_rpm.txt содержится список всех установленных в дистрибутиве пакетов"
fi

if [ "$DISTR_KIND" = "edu" ]
then
  if [ "$LISTS_PKGS_EDUMAGIC" = "yes" ]
  then
    chroot $ROOTFS rpm -qa --queryformat '%{NAME}\n'|sort -u > $MYPATH/work/all_edu_name_rpm.txt
    chroot $ROOTFS rpm -qa|sort -u > $MYPATH/work/all_edu_rpm.txt
    echo "File work/all_edu_name_rpm.txt contains a list of all installed packages in the edu version of distro by name"
    echo "В файле work/all_edu_name_rpm.txt содержится список всех установленных в edu версии дистрибутива пакетов поимённо"
    echo "File work/all_edu_rpm.txt contains a list of all installed packages in the edu version of distro"
    echo "В файле work/all_edu_rpm.txt содержится список всех установленных в edu версии дистрибутива пакетов"
  fi
fi

cp -f /tmp/building/* /var/lib/rpm/
rm -rf /tmp/building

echo "The script has completed work"
echo "Работа скрипта завершена"
exit 0
