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

const fs                      = require('fs');
const os                      = require('os');
const path                    = require('path');
const { execSync, spawnSync } = require('child_process');
const child_process           = require("child_process");
const utilsFile               = ObjectiveJ.utils.file;

var SharedConverter           = nil;

NibFormatUndetermined         = 0;
NibFormatMac                  = 1;
NibFormatIPhone               = 2;

ConverterModeLegacy           = 0;
ConverterModeNew              = 1;

ConverterConversionException  = @"ConverterConversionException";

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

    CPLog.info("Conversion successful");

    return convertedData;
}

- (CPData)CPCompliantNibDataAtFilePath:(CPString)aFilePath
{
    var temporaryNibFilePath = "",
        temporaryPlistFilePath = "";


    function isReadable(p) {
        try {
            fs.accessSync(p, fs.constants.R_OK);
            return true;
        } catch (err) {
            return false;
        }
    }

    function isWritable(p) {
        try {
            fs.accessSync(p, fs.constants.W_OK);
            return true;
        } catch (err) {
            return false;
        }
    }

    try
    {
        var tmpdir = fs.mkdtempSync(path.join(os.tmpdir(), 'nib2cib-'));

        if ([outputPath length])
        {
            // Compile xib or nib to make sure we have a legacy format nib.
            
            // Use temporary paths for intermediate products.
            temporaryNibFilePath = path.join(tmpdir, path.basename(aFilePath) + ".tmp.nib");
            temporaryXibFilePath = path.join(tmpdir, path.basename(aFilePath));
            
            
            // Ensure that source xib's <deployment /> tag targets deployment version 10.10
            var xibContent = fs.readFileSync(aFilePath, { encoding: 'utf8' });
            
            // Perform the in-memory modification of the deployment tag
            //
            // Remove existing <deployment /> tag, if present
            // xib's with Xcode 14 or later do not have a <deployment /> element at all.
            // It is simpler to ensure no <deployment /> element is present,
            // then add what we want.
            //
            // Add a new <deployment /> element as the first child of the <dependencies /> element.
            // This is the placement expected when Xcode adds the <deployment /> element.
            // Target version 10.10 as the deployment version.
            if (xibContent.includes('<deployment '))
            {
                xibContent = xibContent.replace(/<deployment .*\/>/g, '');
            }
            // Where will the <deployment /> element be inserted in the string?
            var deploymentTag     = '\n        <deployment version="10.10" identifier="macosx"/>';
            var insertPosition    = xibContent.indexOf("<dependencies>") + "<dependencies>".length;
            
            // Slice the string representing the source xib and insert the new <deployment /> element.
            var updatedXIBContent = xibContent.slice(0, insertPosition) + deploymentTag + xibContent.slice(insertPosition);

            fs.writeFileSync(temporaryXibFilePath, updatedXIBContent, 'utf8');
            try
            {
                child_process.execSync("/usr/bin/ibtool" + " '" + temporaryXibFilePath + "' " + "--compile" + " '" + temporaryNibFilePath + "'", {stdio: 'inherit'});
            }
            catch(err)
            {
                [CPException raise:ConverterConversionException reason:@"Could not compile file: " + temporaryXibFilePath];
            }
        }
        else
        {
            temporaryNibFilePath = aFilePath;
        }

        // From around Xcode 12.5.1 ibtool starts to create a folder with two files.
        // They are a little different but we can't find any documentation about what.
        if (fs.lstatSync(temporaryNibFilePath).isDirectory())
        {
            var temporaryNibFilePathInDirectoryFile = path.join(temporaryNibFilePath,"keyedobjects.nib");
        }

        // Convert from binary plist to XML plist
        var temporaryPlistFilePath = path.join(tmpdir, path.basename(aFilePath) + ".tmp.plist");

        try
        {
            child_process.execSync("/usr/bin/plutil" + " " + "-convert" + " " + "xml1" + " '" + (temporaryNibFilePathInDirectoryFile || temporaryNibFilePath) + "' " + "-o" + " '" +  temporaryPlistFilePath + "'", {stdio: 'inherit'});
        }
        catch(err)
        {
            [CPException raise:ConverterConversionException reason:@"Could not convert to xml plist for file: " + aFilePath];
        }

        if (!isReadable(temporaryPlistFilePath))
            [CPException raise:ConverterConversionException reason:@"Unable to convert nib file."];

        var plistContents = fs.readFileSync(temporaryPlistFilePath, { encoding: "utf8" });

        // Minor NS keyed archive to CP keyed archive conversion.
        // Use Java directly because rhino's string.replace is *so slow*. 4 seconds vs. 1 millisecond.
        // plistContents = plistContents.replace(/\<key\>\s*CF\$UID\s*\<\/key\>/g, "<key>CP$UID</key>");
        
        plistContents = plistContents.replace(new RegExp("\\<key\\>\\s*CF\\$UID\\s*\\<\\/key\\>", "g"), "<key>CP$UID</key>");
        
        plistContents = plistContents.replace(new RegExp("<string>[\\u0000-\\u0008\\u000B\\u000C\\u000E-\\u001F]<\\/string>", "g"), function(c)
        {
            CPLog.warn("Warning: converting character 0x" + c.charCodeAt(8).toString(16) + " to base64 representation");
            return "<string type=\"base64\">" + CFData.encodeBase64String(c.charAt(8)) + "</string>";
        });
    }
    finally
    {
        if (temporaryNibFilePathInDirectoryFile && temporaryNibFilePathInDirectoryFile !=="" && isWritable(temporaryNibFilePathInDirectoryFile))
        {
            utilsFile.rm_rf(temporaryNibFilePathInDirectoryFile);
        }
        else
        {
            if (temporaryNibFilePath !== "" && isWritable(temporaryNibFilePath))
                fs.rmSync(temporaryNibFilePath);
        }

        if (temporaryPlistFilePath !== "" && isWritable(temporaryPlistFilePath))
            fs.rmSync(temporaryPlistFilePath);
    }

    return [CPData dataWithRawString:plistContents];
}

@end

//@import "Converter+Mac.j"
