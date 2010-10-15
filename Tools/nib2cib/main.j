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

var FILE = require("file");
var OS = require("os");

var parser = new (require("narwhal/args").Parser)();

parser.usage("INPUT_FILE [OUTPUT_FILE]");

parser.option("-F", "framework", "frameworks")
    .push()
    .help("Add a framework to load");

parser.option("-R", "resources")
    .set()
    .help("Set the Resources directory");

parser.option("--mac", "format")
    .set(NibFormatMac)
    .def(NibFormatUndetermined)
    .help("Set format to Mac");

// parser.option("--iphone", "format")
//     .set(NibFormatIPhone)
//     .help("Set format to iPhone");

parser.option("-v", "--verbose", "verbose")
    .inc()
    .help("Increase verbosity level");

parser.option("-q", "--quiet", "quiet")
    .set(true)
    .help("No output");

parser.helpful();

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
    var options = parser.parse(args, null, null, true);

    if (options.args.length < 1 || options.args.length > 2) {
        parser.printUsage(options);
        OS.exit(1);
    }

    if (options.quiet) {}
    else if (options.verbose === 0)
        CPLogRegister(CPLogPrint, "warn");
    else if (options.verbose === 1)
        CPLogRegister(CPLogPrint, "info");
    else
        CPLogRegister(CPLogPrint);

    CPLog.debug("Input:      " + options.args[0]);
    CPLog.debug("Output:     " + (options.args[1]||""));
    CPLog.debug("Format:     " + ["Auto","Mac","iPhone"][options.format]);
    CPLog.debug("Resources:  " + (options.resources||""));
    CPLog.debug("Frameworks: " + options.frameworks);

    var converter = [[Converter alloc] init];

    if (options.resources)
        [converter setResourcesPath:options.resources];

    [converter setFormat:options.format];

    [converter setInputPath:options.args[0]];

    if (options.args.length > 1)
        [converter setOutputPath:options.args[1]];

    loadFrameworks(options.frameworks, function()
    {
        [converter convert];
    });
}
