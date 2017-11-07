@echo off
rem  This has exactly the same semantics as the old buildscript,
rem  but supports extra optional command line arguments.
rem  Too see the supported args, run: build.bat --help

rem Pre-build 'buildHelper.d' as a workaround for RDMD issue #4688
rdmd --build-only -ofbuildHelper -unittest buildHelper.d && buildHelper.exe %*

rem Old buildscript:
rem cls && dmc.exe bridge\bridge.cpp -c && dmd -debug -g @commands.txt && dmd -release -O -inline @commands.txt
