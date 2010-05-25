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
    test.logs.push(Array.prototype.join.apply(arguments, [","]));
    console.warn.apply(console, arguments);
}

var tests = [];
var test = { pass : true, logs : [] };
var pause = false;

function main(args, namedArgs)
{
    var hash = window.location.hash.substring(1);
    if (hash) {
        tests = JSON.parse(decodeURIComponent(hash))
    }

    var index = tests.length;

    test.name = testNames[index];

    function next() {
        window.clearNativeTimeout(timeout);

        tests.push(test);
        if (index < testNames.length - 1) {
            window.location.hash = "#" + encodeURIComponent(JSON.stringify(tests));
            window.location.reload();
        } else {
            alert(tests.map(function(test) {
                return test.logs.map(function(log) {
                    return test.name + ": " + log;
                }).join("\n") + "\n" +
                "== " + (test.pass ? "PASS" : "FAIL") + " ==\n";
            }).join("\n"));
        }
    }

    var timeout = window.setNativeTimeout(function() {
        test.pass = false;
        if (pause) alert(test.name + ": timed out")
        next();
    }, 1000);

    try {
        console.log("running: " + test.name);

        var testDir = dir + "/tests/" + test.name;
        require.paths.unshift(dir + "/lib", testDir);
        require.async(testDir + "/program", function() {
            if (pause) alert(test.name + ": completed");
            next();
        });

    } catch (e) {
        test.pass = false;
        print(test.name+ ": exception=" + e);
    }
}
