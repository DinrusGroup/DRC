set this=%DINRUS%\..\dev\DINRUS\DRC
dinrusex
:::d:\dinrus\bin\dsss build -full

:b
if exist %this%\objs.rsp del %this%\objs.rsp

%DINRUS%\ls2 %this%\src\*.d %this%\src\util\*.d %this%\src\drc\*.d %this%\src\drc\ast\*.d %this%\src\drc\code\*.d %this%\src\drc\doc\*.d %this%\src\drc\lexer\*.d %this%\src\drc\parser\*.d %this%\src\drc\semantic\*.d %this%\src\drc\translator\*.d %this%\src\cmd\*d>>%this%\objs.rsp

%DINRUS%\dmd -release -O -of%this%\drc2.exe -d @%this%\objs.rsp %this%\..\base\Exe\Resources\dinrus.res DinrusTango.lib
upx %this%\drc2.exe
copy %this%\drc2.exe %this%\bin\drc.exe
pause
exit
:goto b
:ren drc.exe дирк.exe
