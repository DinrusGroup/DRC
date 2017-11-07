#!/bin/sh
# This has exactly the same semantics as the old buildscript,
# but supports extra optional command line arguments.
# Too see the supported args, run: ./build.sh --help

rdmd buildHelper.d "$@"

# Old buildscript:
##i686-unknown-linux-gnu-g++ -c bridge/bridge.cpp -obridge.o
#g++ -c bridge/bridge.cpp -obridge.o
#dmd -debug -gc @commands.linux.txt && dmd -release -O -inline @commands.linux.txt #|& head
