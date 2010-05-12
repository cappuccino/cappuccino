/*
 * AppController.j
 * TestApp
 *
 * Created by You on May 11, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

// @import <Foundation/Foundation.j>

var url = window.location.toString();
var dir = url.substring(0, url.lastIndexOf("/"));

var testNames = [
    "absolute",
    "cyclic",
    "determinism", // failing
    "exactExports",
    "hasOwnProperty", // failing
    "method",
    "missing", // failing
    "monkeys",
    "nested",
    "relative",
    "transitive"
];

// ObjectiveJ.asyncLoader = false;

print = function() {
    console.warn.apply(console, arguments);
}

function main(args, namedArgs)
{
    var index = parseInt(window.location.hash.substring(1));
    if (isNaN(index))
        index = 0;
    
    var testName = testNames[index];
    
    function next() {
        window.clearNativeTimeout(timeout);
        if (index < testNames.length - 1) {
            window.location.hash = "#" + (index+1);
            window.location.reload();
        }
    }
    
    var timeout = window.setNativeTimeout(function() {
        alert(testName + ": timed out")
        next();
    }, 2000);
    
    try {
        console.log("running: " + testName);
        
        var testDir = dir + "/tests/" + testName;
        require.paths.unshift(dir + "/lib", testDir);
        require.async(testDir + "/program", function() {
            alert(testName + ": completed");
            next();
        });

    } catch (e) {
        console.error(testName+ ": exception=" + e);
    }
}
