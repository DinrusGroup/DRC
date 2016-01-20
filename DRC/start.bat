ruladaex
:::d:\dinrus\bin\dsss build -full
if exist objs.rsp del objs.rsp

set D="e:\dinrus\bin"
%D%\ls2 src\*.d src\util\*.d src\drc\*.d src\drc\ast\*.d src\drc\code\*.d src\drc\doc\*.d src\drc\lexer\*.d src\drc\parser\*.d src\drc\semantic\*.d src\drc\translator\*.d src\cmd\*d>>objs.rsp

%D%\dmd -ofdrc.exe -d @objs.rsp tango.lib ..\Exe\Resources\dinrus.res
:ren drc.exe дирк.exe
pause