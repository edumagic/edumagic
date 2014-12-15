#!/bin/bash

# License: GPL latest version
# Лицензия: GPL последней версии
# Description: Generate files with requires for modules
# Описание: Генерирует файлы с зависимостями пакетов модулей
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
  echo "Не вижу файла config" ; exit 1
fi

A=`which urpmi`
if [ "$A" = "" ]
then
  echo "No found buldrequires urpmi"
  echo "Не найдено сборочной зависимости urpmi"
  exit 1
fi

if [ ! -d "$MOD_PREV" ]
then
  echo "$MOD_PREV does not exists. Run script 0_urpmi_root.sh first"
  echo "$MOD_PREV не существует. Запустите сначала скрипт 0_urpmi_root.sh"
  exit 1
fi

DEPS_DIR=deps
mkdir -p $DEPS_DIR

for mod in `ls -1 $MOD_NAMES_DIR/??-*` ;do
echo "Generating file with requires for the module $(basename $mod)"
echo "Генерация файла зависимостей для модуля $(basename $mod)"
#--------------
     [ -f $DEPS_DIR/deps_$(basename $mod) ] && rm $DEPS_DIR/deps_$(basename $mod)

     urpmq -d --no-recommends --urpmi-root=$MOD_PREV --root=$MOD_PREV `cat $mod|grep -v "#"` |sort -u > $DEPS_DIR/deps_$(basename $mod)
#--------------
    echo -ne \\n "---> OK."\\n
done
cat $DEPS_DIR/deps_* |sort -u > $DEPS_DIR/full_deps

echo "The script has completed work. See requires in directory $DEPS_DIR"
echo "Работа скрипта завершена. Смотрите зависимости в директории $DEPS_DIR"
exit 0
