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
@import <Foundation/CPData.j>

var FILE = require("file"),
    OS = require("os");


NibFormatUndetermined           = 0,
NibFormatMac                    = 1,
NibFormatIPhone                 = 2;

ConverterConversionException    = @"ConverterConversionException";

@implementation Converter : CPObject
{
    NibFormat   format @accessors;
    CPString    inputPath @accessors;
    CPString    outputPath @accessors;
    CPString    resourcesPath @accessors;
}

- (id)init
{
    self = [super init];

    if (self)
        [self setFormat:NibFormatUndetermined];

    return self;
}

- (void)convert
{   
    try
    {
        if ([resourcesPath length] && !FILE.isReadable(resourcesPath))
            [CPException raise:ConverterConversionException reason:@"Could not read Resources at path \"" + resourcesPath + "\""];

        var inferredFormat = format;

        if (inferredFormat === NibFormatUndetermined)
        {
            // Assume its a Mac file.
            inferredFormat = NibFormatMac;

            // Some .xibs are iPhone nibs, check the actual contents in this case.
            if (FILE.extension(inputPath) !== ".nib" && FILE.isFile(inputPath) &&
                FILE.read(inputPath, { charset:"UTF-8" }).indexOf("<archive type=\"com.apple.InterfaceBuilder3.CocoaTouch.XIB\"") !== -1)
                inferredFormat = NibFormatIPhone;

            if (inferredFormat === NibFormatMac)
                CPLog.info("Auto-detected Cocoa Nib or Xib File");
            else
                CPLog.info("Auto-detected CocoaTouch Xib File");
        }

        var nibData = [self CPCompliantNibDataAtFilePath:inputPath];

        if (inferredFormat === NibFormatMac)
            var convertedData = [self convertedDataFromMacData:nibData resourcesPath:resourcesPath];
        else
            [CPException raise:ConverterConversionException reason:@"nib2cib does not understand this nib format."];

        if (![outputPath length])
            outputPath = inputPath.substr(0, inputPath.length - FILE.extension(inputPath).length) + ".cib";

        FILE.write(outputPath, [convertedData rawString], { charset:"UTF-8" });
    }
    catch(anException)
    {
        CPLog.fatal(anException);
    }
}

- (CPData)CPCompliantNibDataAtFilePath:(CPString)aFilePath
{
    // Compile xib or nib to make sure we have a non-new format nib.
    var temporaryNibFilePath = FILE.join("/tmp", FILE.basename(aFilePath) + ".tmp.nib");

    if (OS.popen(["/usr/bin/ibtool", aFilePath, "--compile", temporaryNibFilePath]).wait() === 1)
        throw "Could not compile file at " + aFilePath;

    // Convert from binary plist to XML plist
    var temporaryPlistFilePath = FILE.join("/tmp", FILE.basename(aFilePath) + ".tmp.plist");

    if (OS.popen(["/usr/bin/plutil", "-convert", "xml1", temporaryNibFilePath, "-o", temporaryPlistFilePath]).wait() === 1)
        throw "Could not convert to xml plist for file at " + aFilePath;

    if (!FILE.isReadable(temporaryPlistFilePath))
        [CPException raise:ConverterConversionException reason:@"Unable to convert nib file."];

    var plistContents = FILE.read(temporaryPlistFilePath, { charset:"UTF-8" });

    // Minor NS keyed archive to CP keyed archive conversion.
    // Use Java directly because rhino's string.replace is *so slow*. 4 seconds vs. 1 millisecond.
    // plistContents = plistContents.replace(/\<key\>\s*CF\$UID\s*\<\/key\>/g, "<key>CP$UID</key>");
    if (system.engine === "rhino")
        plistContents = String(java.lang.String(plistContents).replaceAll("\\<key\\>\\s*CF\\$UID\\s*\\<\/key\\>", "<key>CP\\$UID</key>"));
    else
        plistContents = plistContents.replace(/\<key\>\s*CF\$UID\s*\<\/key\>/g, "<key>CP$UID</key>");

    plistContents = plistContents.replace(/\u001b/g, function(c) {
        CPLog.warn("Warning: Stripping character 0x"+c.charCodeAt(0).toString(16));
        return "";
    });

    return [CPData dataWithRawString:plistContents];
}

@end

@import "Converter+Mac.j"
