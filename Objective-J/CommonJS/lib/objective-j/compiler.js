
var FILE = require("file"),
    OS = require("os"),
    ObjectiveJ = require("objective-j"),
    JAKE = require("jake");

require("objective-j/rhino/regexp-rhino-patch");

var compressors = {
    ss  : { id : "minify/shrinksafe" }
    //,yui : { id : "minify/yuicompressor" }
    // ,cc  : { id : "minify/closure-compiler" }
};

var compressorStats = {};
function compressor(code)
{
    var winner, winnerName;
    compressorStats['original'] = (compressorStats['original'] || 0) + code.length;
    for (var name in compressors)
    {
        var aCompressor = require(compressors[name].id),
            result = aCompressor.compress(code, { charset : "UTF-8", useServer : true });
        compressorStats[name] = (compressorStats[name] || 0) + result.length;
        if (!winner || result < winner.length) {
            winner = result;
            winnerName = name;
        }
    }
    // print("winner="+winnerName+" compressorStats="+JSON.stringify(compressorStats));
    return winner;
}

function compileWithResolvedFlags(aFilePath, objjcFlags, gccFlags, asPlainJavascript)
{
    var shouldObjjPreprocess = true,
        shouldCompress = objjcFlags.compress,
        fileContents = "",
        executable,
        code;

    if (!shouldObjjPreprocess)
    {
        try
        {
            var p = OS.popen("which gcc");

            if (p.stdout.read().length === 0)
            {
                fileContents = FILE.read(aFilePath, { charset:"UTF-8" });
            }
            else
            {
                try
                {
                    var gcc = OS.popen("gcc -E -x c -P " + (gccFlags ? gccFlags.join(" ") : "") + " " + OS.enquote(aFilePath), { charset:"UTF-8" }),
                        chunk = "";

                    while (chunk = gcc.stdout.read())
                        fileContents += chunk;
                }
                finally
                {
                    gcc.stdin.close();
                    gcc.stdout.close();
                    gcc.stderr.close();
                }
            }
        }
        finally
        {
            p.stdin.close();
            p.stdout.close();
            p.stderr.close();
        }

        return fileContents;
    }

    // Preprocess contents into fragments.
    // FIXME: should calculate relative path, etc.
    try
    {
        var sources = new JAKE.FileList("**/*.j"),
            translateFilenameToPath = {},
            otherwayTranslateFilenameToPath = {};

        // Create a filename to filename path dictionary. (For example: CPArray.j -> CPArray/CPArray.j)
        sources.forEach(function(/*String*/ aFilename)
        {
            translateFilenameToPath[FILE.basename(aFilename)] = aFilename;
            otherwayTranslateFilenameToPath[aFilename] = FILE.basename(aFilename);
        }, this);

        var translatedFilename = translateFilenameToPath[aFilePath] ? translateFilenameToPath[aFilePath] : aFilePath,
            otherwayTranslatedFilename = otherwayTranslateFilenameToPath[aFilePath] ? otherwayTranslateFilenameToPath[aFilePath] : aFilePath,
            theTranslatedFilename = otherwayTranslatedFilename ? otherwayTranslatedFilename : translatedFilename,
            absolutePath = FILE.absolute(theTranslatedFilename),
            basePath = absolutePath.substring(0, absolutePath.length - theTranslatedFilename.length);

        // This ugly fix to make Cappuccino compile with rhino can be removed when the compiler is not loading classes into the runtime
        var rhinoUglyFix = false;
        if (system.engine === "rhino")
        {
            if (typeof document == "undefined") {
                document = { createElement: function(x) { return { innerText: "", style: {}}}};
                rhinoUglyFix = true;
            }
            if (typeof navigator == "undefined")
            {
                navigator =  { "userAgent": "fakenavigator" };
                rhinoUglyFix = true;
            }
        }

        ObjectiveJ.FileExecutable.setCurrentCompilerFlags(objjcFlags);
        ObjectiveJ.make_narwhal_factory(absolutePath, basePath, translateFilenameToPath)(require, {}, module, system, print);

        executable = new ObjectiveJ.FileExecutable(FILE.basename(aFilePath));

        if (rhinoUglyFix)
            delete document;
    }
    catch (anException)
    {
        print(anException);
        return;
    }

    if (shouldCompress)
    {
        code = executable.code();
        code = compressor("function(){" + code + "}");
        // more robust function wrapper stripping
        code = code.replace(/^\s*function\s*\(\s*\)\s*{|}\s*;?\s*$/g, "");
        executable.setCode(code);
    }

    return asPlainJavascript ? executable.code() : executable.toMarkedString();
}

function resolveFlags(args)
{
    var filePaths = [],
        outputFilePaths = [],

        index = 0,
        count = args.length,

        gccFlags = [],
        objjcFlags = {};

    for (; index < count; ++index)
    {
        var argument = args[index];

        if (argument === "-o")
        {
            if (++index < count)
                outputFilePaths.push(args[index]);
        }

        else if (argument.indexOf("-D") === 0)
            gccFlags.push(argument);

        else if (argument.indexOf("-U") === 0)
            gccFlags.push(argument);

        else if (argument === "--include")
        {
            if (++index < count)
            {
                gccFlags.push(argument);
                gccFlags.push(args[index]);
            }
        }

        else if (argument.indexOf("-T") === 0)
        {
            objjcFlags.includeIvarTypeSignatures = false;
            objjcFlags.includeMethodArgumentTypeSignatures = false;
        }
        else if (argument.indexOf("-g") === 0)
            objjcFlags.includeMethodFunctionNames = true;

        else if (argument.indexOf("-O") === 0) {
            objjcFlags.compress = true;
            // FIXME: currently we are sending in '-O2' when we want InlineMsgSend. Here we only check if we it is '-O...'
            if (argument.length > 2)
                objjcFlags.inlineMsgSendFunctions = true;
        }

        else if (argument.indexOf("-G") === 0)
            objjcFlags.generate = true;

        else
            filePaths.push(argument);
    }

    return { filePaths:filePaths, outputFilePaths:outputFilePaths, objjcFlags:objjcFlags, gccFlags:gccFlags };
}

exports.compile = function(aFilePath, flags)
{
    if (flags.split)
        flags = flags.split(/\s+/);

    var resolvedFlags = resolveFlags(flags);

    return compileWithResolvedFlags(aFilePath, resolvedFlags.objjcFlags, resolvedFlags.gccFlags);
};

exports.main = function(args)
{
    var shouldPrintOutput = false,
        asPlainJavascript = false,
        objjcFlags = {};

    var argv = args.slice(1);

    while(argv.length)
    {
        if (argv[0] === '--')
        {
            argv.shift();
            break;
        }

        if (argv[0] === "-p" || argv[0] === "--print")
        {
            shouldPrintOutput = YES;
            argv.shift();
            continue;
        }

        if (argv[0] === "--unmarked")
        {
            asPlainJavascript = true;
            argv.shift();
            continue;
        }

        if (argv[0] === "-T" || argv[0] === "--includeTypeSignatures")
        {
            objjcFlags.includeIvarTypeSignatures = true;
            objjcFlags.includeMethodArgumentTypeSignatures = true;
            argv.shift();
            continue;
        }

        if (argv[0] === "--help" || argv[0].substr(0, 1) == '-')
        {
            print("Usage (objjc 2.0): " + args[0] + " [options] [--] file...");
            print("  -p, --print                         print the output directly to stdout");
            print("  --unmarked                          don't tag the output with @STATIC header");
            print("");
            print("  -T, --dont-include-type-signatures  include type signatures in the compiled output");
            print("  -g, --include-debug-symbols         include debug symbols in the compiled output");
            print("  -T, --include-type-signatures       include type signatures in the compiled output");
            print("  -O, --compress                      compress the compiled output");
            print("  -O2, --inline-msg-send              inline objj_msgSend function in the compiled output");
            print("");
            print("  --help                              print this help");
            return;
        }

        // Current argument doesn't begin with - so it's not an argument but the
        // first filename.
        // TODO Full GNU getopt parsing which doesn't stop on the first non-argument.
        break;
    }

    var resolved = resolveFlags(argv),
        outputFilePaths = resolved.outputFilePaths,
        gccFlags = resolved.gccFlags,
        resolvedObjjcFlags = resolved.objjcFlags;

    // Merge resolved keys into objjcFlags
    for (var key in resolvedObjjcFlags)
    {
        if (resolvedObjjcFlags.hasOwnProperty(key))
        {
            if (resolvedObjjcFlags[key])
                objjcFlags[key] = resolvedObjjcFlags[key];
        }
    }

    resolved.filePaths.forEach(function(filePath, index)
    {
        if (!shouldPrintOutput)
            print("Statically Compiling " + filePath);
        var output = compileWithResolvedFlags(filePath, objjcFlags, gccFlags, asPlainJavascript);

        // Only write the output if the compilation didn't fail.
        if (output !== undefined)
        {
            if (shouldPrintOutput)
                print(output);
            else
                FILE.write(outputFilePaths[index], output, { charset: "UTF-8" });
        }
    });
};

if (require.main == module.id)
    exports.main(system.args);
