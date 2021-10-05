/*
 * Converter.j
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

@import <Foundation/CPObject.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPData.j>
@import <Foundation/CPException.j>
@import <Foundation/CPString.j>
@import <BlendKit/BlendKit.j>

@import "NSFoundation.j"
@import "NSAppKit.j"

@class Nib2Cib

@global java

var FILE = require("file"),
    OS = require("os"),
    SYSTEM = require("system"),

    SharedConverter = nil;

NibFormatUndetermined   = 0;
NibFormatMac            = 1;
NibFormatIPhone         = 2;

ConverterModeLegacy   = 0;
ConverterModeNew      = 1;

ConverterConversionException = @"ConverterConversionException";

@implementation Converter : CPObject
{
    CPString inputPath  @accessors(readonly);
    CPString outputPath @accessors;
}

+ (Converter)sharedConverter
{
    return SharedConverter;
}

- (id)initWithInputPath:(CPString)anInputPath outputPath:(CPString)anOutputPath
{
    self = [super init];

    if (self)
    {
        if (!SharedConverter)
            SharedConverter = self;

        inputPath = anInputPath;
        outputPath = anOutputPath;
    }

    return self;
}

- (CPData)convert
{
    // Assume its a Mac file.
    var inferredFormat = NibFormatMac;

    // Some .xibs are iPhone nibs, check the actual contents in this case.
    if (FILE.extension(inputPath) !== ".nib" && FILE.isFile(inputPath) &&
        FILE.read(inputPath, { charset:"UTF-8" }).indexOf("<archive type=\"com.apple.InterfaceBuilder3.CocoaTouch.XIB\"") !== -1)
        inferredFormat = NibFormatIPhone;

    if (inferredFormat === NibFormatMac)
        CPLog.info("Auto-detected Cocoa nib or xib File");
    else
        CPLog.info("Auto-detected CocoaTouch xib File");

    CPLog.info("Converting xib file to plist...");

    var nibData = [self CPCompliantNibDataAtFilePath:inputPath];

    if (inferredFormat === NibFormatMac)
        var convertedData = [self convertedDataFromMacData:nibData];
    else
        // TODO: this is insufficient to fully confirm the xib file is valid.
        // Xcode offers to upgrade older xib file formats when they are opened in Interface Builder
        // but this may not happen if a project is recompiled without opening the xib.
        // We should perform the same check here and offer to upgrade the file format.
        [CPException raise:ConverterConversionException reason:@"nib2cib does not understand this nib format."];

    if ([outputPath length])
        FILE.write(outputPath, [convertedData rawString], { charset:"UTF-8" });

    CPLog.info("Conversion successful");

    return convertedData;
}

- (CPData)CPCompliantNibDataAtFilePath:(CPString)aFilePath
{
    var temporaryNibFilePath = "",
        temporaryPlistFilePath = "";

    var PROJECT_ROOT_DIR = SYSTEM.env["PWD"];
    var PROJECT_BUILD_DIR = FILE.join(PROJECT_ROOT_DIR, "Build");
    var TMP_DIR = FILE.join(PROJECT_BUILD_DIR, "tmp");

    // System /tmp folder was previously used for ephemeral conversion artifacts
    // In more recent versions of macOS, access permissions can be insufficient
    // without using sudo.
    // Additionally, temporary folders and files in /tmp were not being
    // namespaced. This risks collisions
    // between distinct xib files - ones named identically but in different project folders.
    // Using a tmp folder in the project's Build folder resolves both issues.
    // Leaving the tmp folder visible is an advantage when debugging failed conversions.

    // Does Build folder exist? If not, create it
    CPLog.info("\nCreating temporary directories for conversion process:");
    if(!FILE.isDirectory(PROJECT_BUILD_DIR))
    {
        CPLog.info("Create 'Build' directory: " + PROJECT_BUILD_DIR);
        FILE.mkdir(PROJECT_BUILD_DIR);
    }

    // Does tmp folder exist? If not, create it
    if(!FILE.isDirectory(TMP_DIR))
    {
        CPLog.info("Create 'tmp' directory: " + TMP_DIR);
        FILE.mkdir(TMP_DIR);
    }

    // Log environment in verbose mode
    // The conversion process is still less robust than ideal.
    // Logging expanded debugging information may aid in diagnosis of problems.
    CPLog.info("\nCappuccino environment:");
    var environment_keys = Object.keys(SYSTEM.env);
    for (var i = 0; i < environment_keys.length - 1; i++)
    {
        CPLog.info(environment_keys[i] + ": " + SYSTEM.env[environment_keys[i]]);
    }
    CPLog.info("\n");

    try
    {
        if ([outputPath length])
        {
            // Compile xib or nib to make sure we have a non-new format nib.
            temporaryNibFilePath = FILE.join(TMP_DIR, FILE.basename(aFilePath) + ".tmp.nib");

            try
            {
                var p = OS.popen(["/usr/bin/ibtool", aFilePath, "--compile", temporaryNibFilePath]);
                var error;
                while (error = p.stderr.read()) CPLog.info("IBTool error(" + typeof error + "): '" + error + "'");
                var wait = p.wait();
                if (wait === 1) {
                    CPLog.info(error);
                    [CPException raise:ConverterConversionException reason:@"Could not compile file: " + aFilePath];
                }
            }
            finally
            {
                p.stdin.close();
                p.stdout.close();
                p.stderr.close();
            }
        }
        else
        {
            temporaryNibFilePath = aFilePath;
        }

        // Check if output path results in a directory
        if (FILE.isDirectory(temporaryNibFilePath)) {
            temporaryNibFilePath = FILE.join(temporaryNibFilePath, "keyedobjects.nib");
        }

        // Convert from binary plist to XML plist
        var temporaryPlistFilePath = FILE.join("/tmp", FILE.basename(aFilePath) + ".tmp.plist");

        try
        {
            var p = OS.popen(["/usr/bin/plutil", "-convert", "xml1", temporaryNibFilePath, "-o", temporaryPlistFilePath]);
            if (p.wait() === 1)
                [CPException raise:ConverterConversionException reason:@"Could not convert to xml plist for file: " + aFilePath];
        }
        finally
        {
            p.stdin.close();
            p.stdout.close();
            p.stderr.close();
        }

        if (!FILE.isReadable(temporaryPlistFilePath))
            [CPException raise:ConverterConversionException reason:@"Unable to convert nib file."];

        var plistContents = FILE.read(temporaryPlistFilePath, { charset: "UTF-8" });

        // Minor NS keyed archive to CP keyed archive conversion.
        // Use Java directly because rhino's string.replace is *so slow*. 4 seconds vs. 1 millisecond.
        // plistContents = plistContents.replace(/\<key\>\s*CF\$UID\s*\<\/key\>/g, "<key>CP$UID</key>");
        if (system.engine === "rhino")
            plistContents = String(java.lang.String(plistContents).replaceAll("\\<key\\>\\s*CF\\$UID\\s*\\<\/key\\>", "<key>CP\\$UID</key>"));
        else
            plistContents = plistContents.replace(new RegExp("\\<key\\>\\s*CF\\$UID\\s*\\<\\/key\\>", "g"), "<key>CP$UID</key>");

        plistContents = plistContents.replace(new RegExp("<string>[\\u0000-\\u0008\\u000B\\u000C\\u000E-\\u001F]<\\/string>", "g"), function(c)
        {
            CPLog.warn("Warning: converting character 0x" + c.charCodeAt(8).toString(16) + " to base64 representation");
            return "<string type=\"base64\">" + CFData.encodeBase64String(c.charAt(8)) + "</string>";
        });
    }
    finally
    {
        if (temporaryNibFilePath !== "" && FILE.isWritable(temporaryNibFilePath))
            FILE.remove(temporaryNibFilePath);

        if (temporaryPlistFilePath !== "" && FILE.isWritable(temporaryPlistFilePath))
            FILE.remove(temporaryPlistFilePath);
    }

    return [CPData dataWithRawString:plistContents];
}

@end

//@import "Converter+Mac.j"
