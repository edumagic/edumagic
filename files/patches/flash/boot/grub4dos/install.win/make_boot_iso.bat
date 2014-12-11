@ECHO OFF

REM  ----------------------------------------------------
REM  Batch file to create bootable ISO in Windows
REM  author: Tomas M. <http://www.linux-live.org>
REM  ----------------------------------------------------

cd ..\..\..\
set CDLABEL=MagicOSboot
set ISOPATH=..
if exist "..\MagicOS" set ISOPATH=c:
boot\tools\WIN\mkisofs.exe @boot\grub4dos\iso_conf -o "%ISOPATH%\%CDLABEL%.iso" -A "%CDLABEL%" -V "%CDLABEL%" MagicOS/vmlinuz=MagicOS\vmlinuz MagicOS/initrd.gz=MagicOS\initrd.gz boot=boot magicos.ldr=boot\grub4dos\magicos.ldr
echo.
echo New ISO should be created now. See %ISOPATH%\%CDLABEL%.iso

pause
