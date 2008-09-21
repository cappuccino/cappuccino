/*
 * main.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

import <Foundation/Foundation.j>

import <AppKit/CPCib.j>

import "NSFoundation.j"
import "NSAppKit.j"

importClass(java.io.FileWriter);
importClass(java.io.BufferedWriter);

CPLogRegister(CPLogPrint);

function exec(command)
{
	var p = Packages.java.lang.Runtime.getRuntime().exec(jsArrayToJavaArray(command));
	var result = p.waitFor();
	
	var reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getInputStream()));
	while (s = reader.readLine())
		print(s);

	var reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getErrorStream()));
	while (s = reader.readLine())
		print(s);
		
	return result;
}

// Make sure we can read the file
if (!(new Packages.java.io.File(args[0])).canRead())
{
    print("Could not read file at " + args[0]);
    return;
}

// Compile xib or nib to make sure we have a non-new format nib.
var temporaryNibFile = Packages.java.io.File.createTempFile("temp", ".nib"),
    temporaryNibFilePath = temporaryNibFile.getAbsolutePath();

temporaryNibFile.deleteOnExit();

if (exec(["/usr/bin/ibtool", args[0], "--compile", temporaryNibFilePath]))
{
    print("Could not compile file at " + args[0]);
    return;
}

// Convert from binary plist to XML plist
var temporaryPlistFile = Packages.java.io.File.createTempFile("temp", ".plist"),
    temporaryPlistFilePath = temporaryPlistFile.getAbsolutePath();

temporaryPlistFile.deleteOnExit();

if (exec(["/usr/bin/plutil", "-convert", "xml1", temporaryNibFilePath, "-o", temporaryPlistFilePath]))
{
    print("Could not convert to xml plist for file at " + args[0]);
    return;
}

var data = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestWithURL:temporaryPlistFilePath] returningResponse:nil error:nil];

// Minor NSKeyedArchive to CPKeyedArchive conversion.
[data setString:[data string].replace(/\<key\>\s*CF\$UID\s*\<\/key\>/g, "<key>CP$UID</key>")];

// Unarchive the NS data
var unarchiver = [[CPKeyedUnarchiver alloc] initForReadingWithData:data],
    objectData = [unarchiver decodeObjectForKey:@"IB.objectdata"],
    
    data = [CPData data],
    archiver = [[CPKeyedArchiver alloc] initForWritingWithMutableData:data];

// Re-archive the CP data.
[archiver encodeObject:objectData forKey:@"CPCibObjectDataKey"];
[archiver finishEncoding];

var writer = new BufferedWriter(new FileWriter("MainMenu.cib"));//outputPath + name.substring(0, args[0].indexOf(".")) + ".o"));

writer.write([data string]);

writer.close();


