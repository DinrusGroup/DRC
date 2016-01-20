#!/usr/bin/build -run

import utils.Script;

void main(){
	auto packageName = "../downloads/enki.sdk." ~ enkiSrcVersion ~ ".zip";
	
	writefln("\n* Building Enki SDK");
	removeFile(packageName);
	
	char[][] fileListing = listdir("enki","*.d");
	fileListing ~= "buildenkisdk.d";
	fileListing ~= "utils/ArgParser.d";
	fileListing ~= "utils/Script.d";
	
	zip(packageName,fileListing);
	
	writefln("\n* Done");
}