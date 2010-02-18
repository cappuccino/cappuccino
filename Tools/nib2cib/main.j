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

CPLogRegister(CPLogPrint, "fatal");

var FILE = require("file"),
    OS = require("os");

function printUsage()
{
    print("usage: nib2cib INPUT_FILE [OUTPUT_FILE] [-F /path/to/required/framework] [-R path/to/resources]");
    OS.exit(1);
}

function loadFrameworks(frameworkPaths, aCallback)
{
    if (!frameworkPaths || frameworkPaths.length === 0)
        return aCallback();

    frameworkPaths.forEach(function(aFrameworkPath)
    {
        print("Loading " + aFrameworkPath);

        var frameworkBundle = [[CPBundle alloc] initWithPath:aFrameworkPath];

        [frameworkBundle loadWithDelegate:nil];

        require("browser/timeout").serviceTimeouts();
    });

    aCallback();
}

function main(args)
{
    // TODO: args parser
    args.shift();
    
    var count = args.length;

    if (count < 1)
        return printUsage();

    var index = 0,

        frameworkPaths = [],
        converter = [[Converter alloc] init];

    for (; index < count; ++index)
    {
        switch(args[index])
        {
            case "-help":
            case "--help":      printUsage();
                                break;

            case "--mac":       [converter setFormat:NibFormatMac];
                                break;

            case "-F":          frameworkPaths.push(args[++index]);
                                break;

            case "-R":          [converter setResourcesPath:args[++index]];
                                break;

            case "-v":          CPLogRegister(CPLogPrint, "warn");
                                break;

            case "-vv":
            case "--verbose":   CPLogRegister(CPLogPrint, "trace");
                                break;

            default:            if ([converter inputPath])
                                    [converter setOutputPath:args[index]];
                                else
                                    [converter setInputPath:args[index]];
        }
    }

    loadFrameworks(frameworkPaths, function()
    {
        [converter convert];
    });
}
