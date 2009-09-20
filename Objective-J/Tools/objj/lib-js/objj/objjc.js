var file = require("file"),
    os = require("os")
    objj = require("./objj");

require("objj/regexp-rhino-patch");

var OBJJ_PREPROCESSOR_DEBUG_SYMBOLS   = exports.OBJJ_PREPROCESSOR_DEBUG_SYMBOLS   = objj.OBJJ_PREPROCESSOR_DEBUG_SYMBOLS;
var OBJJ_PREPROCESSOR_TYPE_SIGNATURES = exports.OBJJ_PREPROCESSOR_TYPE_SIGNATURES = objj.OBJJ_PREPROCESSOR_TYPE_SIGNATURES;
var OBJJ_PREPROCESSOR_PREPROCESS      = exports.OBJJ_PREPROCESSOR_PREPROCESS      = 1 << 10;
var OBJJ_PREPROCESSOR_COMPRESS        = exports.OBJJ_PREPROCESSOR_COMPRESS        = 1 << 11;
var OBJJ_PREPROCESSOR_SYNTAX          = exports.OBJJ_PREPROCESSOR_SYNTAX          = 1 << 12;

var SHRINKSAFE_PATH = file.join(objj.OBJJ_HOME, "shrinksafe", "shrinksafe.jar"),
    RHINO_PATH = file.join(objj.OBJJ_HOME, "shrinksafe", "js.jar")

function compress(/*String*/ aCode, /*Object*/ flags, /*String*/ tmpFile)
{
    file.write(tmpFile, aCode, { charset:"UTF-8" });

    return os.command(["java", "-Dfile.encoding=UTF-8", "-classpath", [RHINO_PATH, SHRINKSAFE_PATH].join(":"), "org.dojotoolkit.shrinksafe.Main", tmpFile]);
}

exports.preprocess = function(inFile, outFile, flags, gccArgs)
{
    with(objj)
    {

    print("Statically Preprocessing " + inFile);
    
    if (flags === undefined)
        flags = OBJJ_PREPROCESSOR_PREPROCESS | OBJJ_PREPROCESSOR_SYNTAX;
    
    var shouldObjjPreprocess = flags & OBJJ_PREPROCESSOR_PREPROCESS,
        shouldCheckSyntax = flags & OBJJ_PREPROCESSOR_SYNTAX,
        shouldCompress = flags & OBJJ_PREPROCESSOR_COMPRESS;
    
    // FIXME: figure out why this doesn't work on Windows/Cygwin
    //var tmpFile = java.io.File.createTempFile("OBJJC", "");
    var tmpFile = new java.io.File(outFile + ".tmp");
    tmpFile.deleteOnExit();
    tmpFile = tmpFile.getAbsolutePath();
    
    // -E JUST preprocess.
    // -x c Interpret language as C -- closest thing to JavaScript.
    // -P Don't generate #line directives
    var gccComponents = ["gcc"]
        .concat("-E", "-x", "c", "-P", inFile)
        .concat(gccArgs || [])
        .concat("-o", shouldObjjPreprocess ? tmpFile : outFile);
    
    os.system(gccComponents);
    
    if (!shouldObjjPreprocess)
        return;
    
    // Read file and preprocess it.
    var fileContents = file.read(tmpFile, { charset: "UTF-8" });

    // Preprocess contents into fragments.
    var fragments = objj_preprocess(fileContents, { path : "/x" }, { path: file.basename(inFile) }, flags),
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
                        
                    os.exit(1);
                }
            }
            
            if (shouldCompress)
            {
                code = compress("function(){" + code + '}', 0, tmpFile);
            
                code = code.substr("function(){".length, code.length - "function(){};\n\n".length);
            }
            
            preprocessed += MARKER_CODE + ';' + code.length + ';' + code;
        }
    }
    
    // Write file.
    file.write(outFile, preprocessed, { charset: "UTF-8" });
        
    }
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