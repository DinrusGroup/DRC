dinrusex
:::d:\dinrus\bin\dsss build -full

:b
if exist objs.rsp del objs.rsp

%DINRUS%\ls2 src2\*.d src2\util\*.d src2\drc\*.d src2\drc\ast\*.d src2\drc\code\*.d src2\drc\doc\*.d src2\drc\lexer\*.d src2\drc\parser\*.d src2\drc\semantic\*.d src2\drc\translator\*.d src2\cmd\*d>>objs.rsp

%DINRUS%\dmd -release -O -ofdrc.exe -d @objs.rsp ..\Exe\Resources\dinrus.res
upx drc.exe
copy .\drc.exe .\bin\drc.exe
pause
exit
:goto b
:ren drc.exe дирк.exe
