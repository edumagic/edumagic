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
    #For Enable Internet (in next module after 02-base-core, when resolv.conf was created)
    if [ "$INTERNET" = "yes" ]
    then
      if [ "$(basename $MOD)" = "03-base-kernel-dkms" ]
      then
	mv -f $MOD_ROOTFS_DIR/02-base-core/etc/resolv.conf $MOD_ROOTFS_DIR/02-base-core/etc/resolv.conf.tmp
	cp -f /etc/resolv.conf $MOD_ROOTFS_DIR/02-base-core/etc/
      fi
    fi
    if [ ! "$DIR_KERNEL" = "" ]
    then
         if [ "$(basename $MOD)" = "02-base-core" ]
         then
             urpmi $URPMI_PARAM --urpmi-root=$ROOTFS --root=$ROOTFS --prefer="$PREFER" `cat $MOD|grep -v kernel-magos|grep -v "#"` ./kernel/* 2>&1| tee -a $MYPATH/work/log_urpmi.txt
         else
             urpmi $URPMI_PARAM --urpmi-root=$ROOTFS --root=$ROOTFS --prefer="$PREFER" `cat $MOD|grep -v "#"` 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
         fi
    else
        urpmi $URPMI_PARAM --urpmi-root=$ROOTFS --root=$ROOTFS --prefer="$PREFER" `cat $MOD|grep -v "#"` 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
    fi
    if [ "$(basename $MOD)" = "03-base-kernel-dkms" ]
    then
      chroot $ROOTFS autokmods clean 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
      chroot $ROOTFS autokmods make 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
      chroot $ROOTFS autokmods urpme_dkms 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
      chroot $ROOTFS autokmods install 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
      chroot $ROOTFS autokmods clean 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
      chroot $ROOTFS auto_gl_conf 2>&1 | tee -a $MYPATH/work/log_urpmi.txt
    fi
    echo -ne \\n "---> OK."\\n
done

chroot $ROOTFS rpm -qa --queryformat '%{NAME}\n'|sort -u > $MYPATH/work/all_name_rpm.txt
chroot $ROOTFS rpm -qa|sort -u > $MYPATH/work/all_rpm.txt


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
	echo -ne \\n "---> OK."\\n
    done
fi

#Return after Enable Internet
if [ "$INTERNET" = "yes" ]
then
  if [ -f "$MOD_ROOTFS_DIR/02-base-core/etc/resolv.conf.tmp" ]
  then
    mv -f $MOD_ROOTFS_DIR/02-base-core/etc/resolv.conf.tmp $MOD_ROOTFS_DIR/02-base-core/etc/resolv.conf
  fi
fi

echo "Moving rpms from $MOD_PREV/var/cache/urpmi/rpms into $RPM_CACHE"
echo "Перенос rpms из $MOD_PREV/var/cache/urpmi/rpms в $RPM_CACHE"
mkdir -p $RPM_CACHE
mv -f $MOD_PREV/var/cache/urpmi/rpms/* $RPM_CACHE/ >/dev/null 2>&1

#echo "Moving rpms from $ROOTFS/var/cache/urpmi/rpms into $RPM_CACHE"
#echo "Перенос rpms из $ROOTFS/var/cache/urpmi/rpms в $RPM_CACHE"
#mkdir -p $RPM_CACHE
#mv -f $ROOTFS/var/cache/urpmi/rpms/* $RPM_CACHE/ >/dev/null 2>&1

echo "Cut out unnecessary into an separate module"
echo "Вырезаем лишнее в отдельный модуль"
for MOD in `ls -1 $MOD_NAMES_DIR/??-base*` ;do
    echo "Cut out unnecessary into an separate module $ADD_MOD_NAME for the module $(basename $MOD)"
    echo "Вырезаем лишнее в отдельный модуль $ADD_MOD_NAME для модуля $(basename $MOD)"
    MOD_LINE=$MOD_ROOTFS_DIR/$(basename $MOD)
    #Clear /tmp
    rm -rf $MOD_LINE/tmp/*
    MOV_DIR=usr/share/locale
    if [ -d "$ROOTFS/$MOV_DIR" ]
    then
      mkdir -p $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR
      for A in `ls -1 $ROOTFS/$MOV_DIR|grep -v ru|grep -v locale|grep -v l10n|grep -v CP1251|grep -v currency|grep -v KOI8-R|grep -v KOI8-U|grep -v ISO-8859-5|grep -v UTF-8` ;do
	if [ -d $MOD_LINE/$MOV_DIR/$A ]
	then
	    cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR/
	    rm -rf $MOD_LINE/$MOV_DIR/$A
	fi
      done
    fi
    MOV_DIR=usr/share/man
    if [ -d "$ROOTFS/$MOV_DIR" ]
    then
      mkdir -p $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR
      for A in `ls -1 $ROOTFS/$MOV_DIR|grep -v ru|grep -v locale|grep -v l10n|grep -v CP1251|grep -v currency|grep -v KOI8-R|grep -v KOI8-U|grep -v ISO-8859-5|grep -v UTF-8` ;do
	if [ -d $MOD_LINE/$MOV_DIR/$A ]
	then
	    cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR/
	    rm -rf $MOD_LINE/$MOV_DIR/$A
	fi
      done
    fi
    MOV_DIR=usr/share/doc
    if [ -d "$ROOTFS/$MOV_DIR" ]
    then
      mkdir -p $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR
      for A in `ls -1 $ROOTFS/$MOV_DIR` ;do
	if [ -d $MOD_LINE/$MOV_DIR/$A ]
	then
	    cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR/
	    rm -rf $MOD_LINE/$MOV_DIR/$A
	fi
      done
    fi
    MOV_DIR=usr/share/locale/locale
    if [ -d "$ROOTFS/$MOV_DIR" ]
    then
      mkdir -p $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR
      for A in `ls -1 $ROOTFS/$MOV_DIR|grep -v ru|grep -v locale|grep -v l10n|grep -v CP1251|grep -v currency|grep -v KOI8-R|grep -v KOI8-U|grep -v ISO-8859-5|grep -v UTF-8` ;do
	if [ -d $MOD_LINE/$MOV_DIR/$A ]
	then
	    cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR/
	    rm -rf $MOD_LINE/$MOV_DIR/$A
	fi
      done
    fi
    MOV_DIR=usr/share/locale/l10n
    if [ -d "$ROOTFS/$MOV_DIR" ]
    then
      mkdir -p $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR
      for A in `ls -1 $ROOTFS/$MOV_DIR|grep -v ru|grep -v locale|grep -v l10n|grep -v CP1251|grep -v currency|grep -v KOI8-R|grep -v KOI8-U|grep -v ISO-8859-5|grep -v UTF-8` ;do
	if [ -d $MOD_LINE/$MOV_DIR/$A ]
	then
	    cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_MOD_NAME/$MOV_DIR/
	    rm -rf $MOD_LINE/$MOV_DIR/$A
	fi
      done
    fi
    echo -ne \\n "---> OK."\\n
done

if [ "$DISTR_KIND" = "edu" ]
then
    echo "Cut out unnecessary into an separate module"
    echo "Вырезаем лишнее в отдельный модуль"
    for MOD in `ls -1 $MOD_NAMES_DIR/??-edu*` ;do
        echo "Cut out unnecessary into an separate module $ADD_EDU_MOD_NAME for the module $(basename $MOD)"
	echo "Вырезаем лишнее в отдельный модуль $ADD_EDU_MOD_NAME для модуля $(basename $MOD)"
	MOD_LINE=$MOD_ROOTFS_DIR/$(basename $MOD)
	#Clear /tmp
        rm -rf $MOD_LINE/tmp/*
	MOV_DIR=usr/share/locale
	if [ -d "$ROOTFS/$MOV_DIR" ]
	then
	  mkdir -p $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR
	  for A in `ls -1 $ROOTFS/$MOV_DIR|grep -v ru|grep -v locale|grep -v l10n|grep -v CP1251|grep -v currency|grep -v KOI8-R|grep -v KOI8-U|grep -v ISO-8859-5|grep -v UTF-8` ;do
	    if [ -d $MOD_LINE/$MOV_DIR/$A ]
	    then
		cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR/
		rm -rf $MOD_LINE/$MOV_DIR/$A
	    fi
	  done
	fi
	MOV_DIR=usr/share/man
	if [ -d "$ROOTFS/$MOV_DIR" ]
	then
	  mkdir -p $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR
	  for A in `ls -1 $ROOTFS/$MOV_DIR|grep -v ru|grep -v locale|grep -v l10n|grep -v CP1251|grep -v currency|grep -v KOI8-R|grep -v KOI8-U|grep -v ISO-8859-5|grep -v UTF-8` ;do
	    if [ -d $MOD_LINE/$MOV_DIR/$A ]
	    then
		cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR/
		rm -rf $MOD_LINE/$MOV_DIR/$A
	    fi
	  done
	fi
	MOV_DIR=usr/share/doc
	if [ -d "$ROOTFS/$MOV_DIR" ]
	then
	  mkdir -p $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR
	  for A in `ls -1 $ROOTFS/$MOV_DIR` ;do
	    if [ -d $MOD_LINE/$MOV_DIR/$A ]
	    then
		cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR/
		rm -rf $MOD_LINE/$MOV_DIR/$A
	    fi
	  done
	fi
	MOV_DIR=usr/share/locale/locale
	if [ -d "$ROOTFS/$MOV_DIR" ]
	then
	  mkdir -p $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR
	  for A in `ls -1 $ROOTFS/$MOV_DIR|grep -v ru|grep -v locale|grep -v l10n|grep -v CP1251|grep -v currency|grep -v KOI8-R|grep -v KOI8-U|grep -v ISO-8859-5|grep -v UTF-8` ;do
	    if [ -d $MOD_LINE/$MOV_DIR/$A ]
	    then
		cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR/
		rm -rf $MOD_LINE/$MOV_DIR/$A
	    fi
	  done
	fi
	MOV_DIR=usr/share/locale/l10n
	if [ -d "$ROOTFS/$MOV_DIR" ]
	then
	  mkdir -p $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR
	  for A in `ls -1 $ROOTFS/$MOV_DIR|grep -v ru|grep -v locale|grep -v l10n|grep -v CP1251|grep -v currency|grep -v KOI8-R|grep -v KOI8-U|grep -v ISO-8859-5|grep -v UTF-8` ;do
	    if [ -d $MOD_LINE/$MOV_DIR/$A ]
	    then
		cp -pfR $MOD_LINE/$MOV_DIR/$A $MOD_ROOTFS_DIR/$ADD_EDU_MOD_NAME/$MOV_DIR/
		rm -rf $MOD_LINE/$MOV_DIR/$A
	    fi
	  done
	fi
	echo -ne \\n "---> OK."\\n
    done
fi

echo "The file work/log_urpmi.txt contains installation log"
echo "В файле work/log_urpmi.txt содержится лог установки"
echo "File work/all_name_rpm.txt contains a list of all installed packages in the distro by name"
echo "В файле work/all_name_rpm.txt содержится список всех установленных в дистрибутиве пакетов поимённо"
echo "File work/all_rpm.txt contains a list of all installed packages in the distro"
echo "В файле work/all_rpm.txt содержится список всех установленных в дистрибутиве пакетов"

if [ "$DISTR_KIND" = "edu" ]
then
  chroot $ROOTFS rpm -qa --queryformat '%{NAME}\n'|sort -u > $MYPATH/work/all_edu_name_rpm.txt
  chroot $ROOTFS rpm -qa|sort -u > $MYPATH/work/all_edu_rpm.txt
  echo "File work/all_edu_name_rpm.txt contains a list of all installed packages in the edu version of distro by name"
  echo "В файле work/all_edu_name_rpm.txt содержится список всех установленных в edu версии дистрибутива пакетов поимённо"
  echo "File work/all_edu_rpm.txt contains a list of all installed packages in the edu version of distro"
  echo "В файле work/all_edu_rpm.txt содержится список всех установленных в edu версии дистрибутива пакетов"
fi

echo "The script has completed work"
echo "Работа скрипта завершена"
exit 0
