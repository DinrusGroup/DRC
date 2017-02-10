:go
%DINRUS%\dmmake -f makefile.win32.dmd
pause
@if not exist *.lib (goto go)