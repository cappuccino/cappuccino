var FILE = require("file"),
    OS = require("os"),
    objj = require("./objj"),
    objj_preprocess = objj.objj_preprocess,
    IS_FILE = objj.IS_FILE,
    GET_CODE = objj.GET_CODE,
    IS_LOCAL = objj.IS_LOCAL,
    MARKER_IMPORT_STD = objj.MARKER_IMPORT_STD,
    MARKER_IMPORT_LOCAL = objj.MARKER_IMPORT_LOCAL,
    MARKER_CODE = objj.MARKER_CODE,
    GET_PATH = objj.GET_PATH;

require("objj/regexp-rhino-patch");

var OBJJ_PREPROCESSOR_DEBUG_SYMBOLS   = exports.OBJJ_PREPROCESSOR_DEBUG_SYMBOLS   = objj.OBJJ_PREPROCESSOR_DEBUG_SYMBOLS;
var OBJJ_PREPROCESSOR_TYPE_SIGNATURES = exports.OBJJ_PREPROCESSOR_TYPE_SIGNATURES = objj.OBJJ_PREPROCESSOR_TYPE_SIGNATURES;
var OBJJ_PREPROCESSOR_PREPROCESS      = exports.OBJJ_PREPROCESSOR_PREPROCESS      = 1 << 10;
var OBJJ_PREPROCESSOR_COMPRESS        = exports.OBJJ_PREPROCESSOR_COMPRESS        = 1 << 11;
var OBJJ_PREPROCESSOR_SYNTAX          = exports.OBJJ_PREPROCESSOR_SYNTAX          = 1 << 12;

var SHRINKSAFE_PATH = FILE.join(objj.OBJJ_HOME, "shrinksafe", "shrinksafe.jar"),
    RHINO_PATH = FILE.join(objj.OBJJ_HOME, "shrinksafe", "js.jar")

function compress(/*String*/ aCode, /*String*/ FIXME)
{
    // FIXME: figure out why this doesn't work on Windows/Cygwin
    //var tmpFile = java.io.File.createTempFile("OBJJC", "");
    var tmpFile = new java.io.File(FIXME + ".tmp");
    tmpFile.deleteOnExit();
    tmpFile = tmpFile.getAbsolutePath();

    FILE.write(tmpFile, aCode, { charset:"UTF-8" });

    return OS.command(["java", "-Dfile.encoding=UTF-8", "-classpath", [RHINO_PATH, SHRINKSAFE_PATH].join(":"), "org.dojotoolkit.shrinksafe.Main", tmpFile]);
}

exports.preprocess = function(inFile, outFile, flags, gccArgs)
{
    print("Statically Preprocessing " + inFile);
    
    if (flags === undefined)
        flags = OBJJ_PREPROCESSOR_PREPROCESS | OBJJ_PREPROCESSOR_SYNTAX;
    
    var shouldObjjPreprocess = flags & OBJJ_PREPROCESSOR_PREPROCESS,
        shouldCheckSyntax = flags & OBJJ_PREPROCESSOR_SYNTAX,
        shouldCompress = flags & OBJJ_PREPROCESSOR_COMPRESS;

    var gccCommand = "gcc -E -x c -P " + (gccArgs.join(" ") || "") + " " + inFile;
    
    if (!shouldObjjPreprocess)
    {
        OS.system(gccCommand + " -o" + outFile);
        return;
    }

    var gcc = OS.popen(gccCommand);

    // Read file and preprocess it.
    var fileContents = "",
        chunk = "";

    while (chunk = gcc.stdout.read())
        fileContents += chunk;

    // Preprocess contents into fragments.
    var fragments = objj_preprocess(fileContents, { path : "/x" }, { path: FILE.basename(inFile) }, flags),
        preprocessed = "";

    // Writer preprocessed fragments out.
    for (var index = 0; index < fragments.length; index++)
    {
        var fragment = fragments[index];
        
        if (IS_FILE(fragment))
            preprocessed += (IS_LOCAL(fragment) ? MARKER_IMPORT_LOCAL : MARKER_IMPORT_STD) + ';' + GET_PATH(fragment).length + ';' + GET_PATH(fragment);
        else
        {            
            var code = GET_CODE(fragment);
            
            if (shouldCheckSyntax)
            {
                try
                {
                    new Function(GET_CODE(fragment));
                }
                catch (e)
                {
                    var lines = code.split("\n"),
                        PAD = 3;
                        
                    print("Syntax error in "+GET_FILE(fragment).path+
                            " on preprocessed line number "+e.lineNumber+"\n"+
                            "\t"+lines.slice(Math.max(0, e.lineNumber - 1 - PAD), e.lineNumber+PAD).join("\n\t"));
                        
                    OS.exit(1);
                }
            }
            
            if (shouldCompress)
            {
                code = compress("function(){" + code + '}', outFile);
            
                code = code.substr("function(){".length, code.length - "function(){};\n\n".length);
            }
            
            preprocessed += MARKER_CODE + ';' + code.length + ';' + code;
        }
    }

    // Write file.
    FILE.write(outFile, preprocessed, { charset: "UTF-8" });
}

exports.main = function(args)
{
    // FIXME: ARGS
    args.shift();
    
    var filePaths = [],
        outFilePaths = [],
        
        index = 0,
        count = args.length,
        
        gccArgs = [],
        
        flags = OBJJ_PREPROCESSOR_PREPROCESS | OBJJ_PREPROCESSOR_SYNTAX;
    
        
    for (; index < count; ++index)
    {
        var argument = args[index];
        
        if (argument === "-o")
        {
            if (++index < count)
                outFilePaths.push(args[index]);
        }
        
        else if (argument.indexOf("-D") === 0)
            gccArgs.push(argument)
            
        else if (argument.indexOf("-U") === 0)
            gccArgs.push(argument);
            
        else if (argument.indexOf("-E") === 0)
            flags &= ~OBJJ_PREPROCESSOR_PREPROCESS;
            
        else if (argument.indexOf("-S") === 0)
            flags &= ~OBJJ_PREPROCESSOR_SYNTAX;
            
        else if (argument.indexOf("-g") === 0)
            flags |= OBJJ_PREPROCESSOR_DEBUG_SYMBOLS;
            
        else if (argument.indexOf("-O") === 0)
            flags |= OBJJ_PREPROCESSOR_COMPRESS;
    
        else
            filePaths.push(argument);
    }
    
    for (index = 0, count = filePaths.length; index < count; ++index)
        exports.preprocess(filePaths[index], outFilePaths[index], flags, gccArgs);
}

if (require.main == module.id)
    exports.main(system.args);