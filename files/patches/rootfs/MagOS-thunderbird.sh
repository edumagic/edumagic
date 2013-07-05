#!/bin/bash
PFP=$(ls -d1 usr/lib/thunderbird-* | tail -1)
[ -d "$PFP"/defaults ] || exit 0
mkdir -p "$PFP"/defaults/profile
ln -sf /usr/share/magos/mozilla/thunderbird-prefs.js "$PFP"/defaults/profile/prefs.js
LIGHTNINGP='usr/lib/mozilla/extensions/{3550f703-e582-4d05-9a08-453d09bdfdc6}/{e2fda1a4-762b-4020-b5ad-a41df1933103}'
if [ -f $LIGHTNINGP/chrome/lightning-ru.jar ] ;then
  if ! grep -q lightning-ru $LIGHTNINGP/chrome.manifest ;then
cat >>$LIGHTNINGP/chrome.manifest <<EOF 
locale calendar ru jar:chrome/calendar-ru.jar!/locale/ru/calendar/
locale lightning ru jar:chrome/lightning-ru.jar!/locale/ru/lightning/
EOF
  fi
fi
exit 0