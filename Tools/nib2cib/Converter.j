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

var path = require("path");
var fs = require("fs");
var child_process = require("child_process");

/* var FILE = require("file"),
    OS = require("os"), */

var SharedConverter = nil;

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
    if (path.extname(inputPath) !== ".nib" && fs.lstatSync(inputPath).isFile() &&
        fs.readFileSync(inputPath, { encoding: "utf8" }).indexOf("<archive type=\"com.apple.InterfaceBuilder3.CocoaTouch.XIB\"") !== -1)
        //FILE.read(inputPath, { charset:"UTF-8" }).indexOf("<archive type=\"com.apple.InterfaceBuilder3.CocoaTouch.XIB\"") !== -1)
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
        [CPException raise:ConverterConversionException reason:@"nib2cib does not understand this nib format."];

    if ([outputPath length])
        fs.writeFileSync(outputPath, [convertedData rawString], { encoding: "utf8" });
        //FILE.write(outputPath, [convertedData rawString], { charset:"UTF-8" });

    CPLog.info("Conversion successful");

    return convertedData;
}

- (CPData)CPCompliantNibDataAtFilePath:(CPString)aFilePath
{
    var temporaryNibFilePath = "",
        temporaryPlistFilePath = "";

    try
    {
        if ([outputPath length])
        {
            // Compile xib or nib to make sure we have a non-new format nib.
            temporaryNibFilePath = path.join("/tmp", path.basename(aFilePath) + ".tmp.nib");
            //temporaryNibFilePath = FILE.join("/tmp", FILE.basename(aFilePath) + ".tmp.nib");

            try {
                child_process.execSync("/usr/bin/ibtool" + " " + aFilePath + " " + "--compile" + " " + temporaryNibFilePath);
            } catch(err) {
                [CPException raise:ConverterConversionException reason:@"Could not compile file: " + aFilePath];
            }

/*             try
            {
                var p = OS.popen(["/usr/bin/ibtool", aFilePath, "--compile", temporaryNibFilePath]);
                if (p.wait() === 1)
                    [CPException raise:ConverterConversionException reason:@"Could not compile file: " + aFilePath];
            }
            finally
            {
                p.stdin.close();
                p.stdout.close();
                p.stderr.close();
            } */

        }
        else
        {
            temporaryNibFilePath = aFilePath;
        }

        // Convert from binary plist to XML plist
        var temporaryPlistFilePath = path.join("/tmp", path.basename(aFilePath) + ".tmp.plist");

        try {
            child_process.execSync("/usr/bin/plutil" + " " + "-convert" + " " + "xml1" + " " + temporaryNibFilePath + " " + "-o" + " " +  temporaryPlistFilePath);
        } catch(err) {
            [CPException raise:ConverterConversionException reason:@"Could not convert to xml plist for file: " + aFilePath];
        }

/*         try
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
        } */

        function isReadable(p) {
            try {
                fs.accessSync(p, constants.R_OK);
                return true;
            } catch (err) {
                return false;
            }
        }

        function isWritable(p) {
            try {
                fs.accessSync(p, constants.W_OK);
                return true;
            } catch (err) {
                return false;
            }
        }

        if (!isReadable(temporaryPlistFilePath))
            [CPException raise:ConverterConversionException reason:@"Unable to convert nib file."];

        var plistContents = fs.readFileSync(temporaryPlistFilePath, { encoding: "UTF-8" });
        //var plistContents = FILE.read(temporaryPlistFilePath, { charset: "UTF-8" });

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
        if (temporaryNibFilePath !== "" && isWritable(temporaryNibFilePath))
            fs.rmSync(temporaryNibFilePath);
            //FILE.remove(temporaryNibFilePath);

        if (temporaryPlistFilePath !== "" && isWritable(temporaryPlistFilePath))
            fs.rmSync(temporaryNibFilePath);
            //FILE.remove(temporaryPlistFilePath);
    }

    return [CPData dataWithRawString:plistContents];
}

@end

//@import "Converter+Mac.j"
