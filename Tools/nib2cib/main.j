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

@import <Foundation/Foundation.j>

@import <AppKit/CPCib.j>

@import "NSFoundation.j"
@import "NSAppKit.j"

@import "Nib2CibKeyedUnarchiver.j"
@import "Converter.j"

var File = require("file");

importPackage(java.io);

CPLogRegister(CPLogPrint);

function printUsage()
{
    print("usage: nib2cib INPUT_FILE [OUTPUT_FILE] [-F /path/to/required/framework] [-R path/to/resources]");
    java.lang.System.exit(1);
}

function loadFrameworks(frameworkPaths, aCallback)
{
    if (!frameworkPaths || frameworkPaths.length === 0)
        return aCallback();
    
    var frameworkPath = frameworkPaths.shift(),
        
        infoPlist = new java.io.File(frameworkPath + "/Info.plist");
        
    if (!infoPlist.exists())
    {
        java.lang.System.out.println("'" + frameworkPath + "' is not a framework or could not be found.");
        java.lang.System.exit(1);
    }
    
    var infoDictionary = CPPropertyListCreateFromData([CPData dataWithString:File.read(frameworkPath + "/Info.plist", { charset:"UTF-8" })]);
    
    if ([infoDictionary objectForKey:@"CPBundlePackageType"] !== "FMWK")
    {
        java.lang.System.out.println("'" + frameworkPath + "' is not a framework.");
        java.lang.System.exit(1);
    }
    
    print("Loading " + [infoDictionary objectForKey:@"CPBundleName"]);
    
    var files = [infoDictionary objectForKey:@"CPBundleReplacedFiles"],
        count = files.length;
    
    if (count)
    {
        var context = new objj_context();

        context.didCompleteCallback = function() { loadFrameworks(frameworkPaths, aCallback) };
print("2he");
        while (count--)
        {
            print(frameworkPath + '/' + files[count]);
            context.pushFragment(fragment_create_file(frameworkPath + '/' + files[count], new objj_bundle(""), YES, NULL));
        }
print("hmmm");
        context.evaluate();print("wha???");
    }
    else
        loadFrameworks(frameworkPaths, aCallback);
print("so far so good...");
}

function main()
{
    var count = arguments.length;
    
    if (count < 1)
        return printUsage();
    
    var index = 0,

        frameworkPaths = [],
        converter = [[Converter alloc] init];
    
    for (; index < count; ++index)
    {
        switch(arguments[index])
        {
            case "-help":
            case "--help":      printUsage();
                                break;

            case "--mac":       [converter setFormat:NibFormatMac];
                                break;

            case "-F":          frameworkPaths.push(arguments[++index]);
                                break;

            case "-R":          [converter setResourcesPath:arguments[++index]];
                                break;

            default:            if ([converter inputPath])
                                    [converter setOutputPath:arguments[index]];
                                else
                                    [converter setInputPath:arguments[index]];
        }
    }

    loadFrameworks(frameworkPaths, function()
    {
        [converter convert];
    });
}
