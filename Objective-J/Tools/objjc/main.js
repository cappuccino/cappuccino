
importPackage(java.lang);

importClass(java.io.File);
importClass(java.io.BufferedReader);
importClass(java.io.FileReader);
importClass(java.io.BufferedWriter);
importClass(java.io.FileWriter);



OBJJ_PREPROCESSOR_PREPROCESS    = 1 << 10;
OBJJ_PREPROCESSOR_COMPRESS      = 1 << 11;
OBJJ_PREPROCESSOR_SYNTAX        = 1 << 12;

function exec(/*Array*/ command, /*Boolean*/ showOutput)
{
    var line = "",
        output = "",
        
        process = Packages.java.lang.Runtime.getRuntime().exec(command),//jsArrayToJavaArray(command));
        reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(process.getInputStream()));
    
    while (line = reader.readLine())
    {
        if (showOutput)
            System.out.println(line);
        
        output += line + '\n';
    }
    
    reader = new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(process.getErrorStream()));
    
    while (line = reader.readLine())
        System.out.println(line);

    try
    {
        if (process.waitFor() != 0)
            System.err.println("exit value = " + process.exitValue());
    }
    catch (anException)
    {
        System.err.println(anException);
    }
    
    return output;
}

function compress(/*String*/ aCode, /*Object*/ flags, /*File*/ tmpFile)
{
    var writer = new BufferedWriter(new FileWriter(tmpFile));
    
    writer.write(aCode);
    
    writer.close();

    return exec(["java", "-jar", OBJJ_HOME + "/lib/objjc/shrinksafe.jar", "-c", tmpFile.getCanonicalPath()]);
}

//#define SET_CONTEXT(aFragment, aContext) aFragment.context = aContext
//#define GET_CONTEXT(aFragment) aFragment.context

//#define SET_TYPE(aFragment, aType) aFragment.type = (aType)
//#define GET_TYPE(aFragment) aFragment.type

function GET_CODE(aFragment) { return aFragment.info; }
//#define SET_CODE(aFragment, aCode) aFragment.info = (aCode)

function GET_PATH(aFragment) { return aFragment.info; }
//#define SET_PATH(aFragment, aPath) aFragment.info = aPath

//#define GET_BUNDLE(aFragment) aFragment.bundle
//#define SET_BUNDLE(aFragment, aBundle) aFragment.bundle = aBundle

//#define GET_FILE(aFragment) aFragment.file
//#define SET_FILE(aFragment, aFile) aFragment.file = aFile

function IS_FILE(aFragment) { return (aFragment.type & FRAGMENT_FILE); }
function IS_LOCAL(aFragment) { return (aFragment.type & FRAGMENT_LOCAL); }
//#define IS_IMPORT(aFragment) (aFragment.type & FRAGMENT_IMPORT)

function preprocess(aFilePath, outFilePath, gccArgs, flags)
{
    print("Statically Preprocessing " + aFilePath);
    
    var shouldObjjPreprocess = flags & OBJJ_PREPROCESSOR_PREPROCESS,
        shouldCheckSyntax = flags & OBJJ_PREPROCESSOR_SYNTAX,
        shouldCompress = flags & OBJJ_PREPROCESSOR_COMPRESS;
    
    // FIXME: figure out why this doesn't work on Windows/Cygwin
    //var tmpFile = java.io.File.createTempFile("OBJJC", "");
    var tmpFile = new java.io.File(outFilePath + ".tmp");
    tmpFile.deleteOnExit();
    
    // -E JUST preprocess.
    // -x c Interpret language as C -- closest thing to JavaScript.
    // -P Don't generate #line directives
    var gccComponents = ["gcc", "-E", "-x", "c", "-P", aFilePath, "-o", shouldObjjPreprocess ? tmpFile.getAbsolutePath() : outFilePath],
        index = gccArgs.length;
    
    // Add custom gcc arguments.
    while (index--)
        gccComponents.splice(5, 0, gccArgs[index]);
    
    exec(gccComponents);
    
    if (!shouldObjjPreprocess)
        return;
    
    // Read file and preprocess it.
    var reader = new BufferedReader(new FileReader(tmpFile)),
        fileContents = "";
    
    // Get contents of the file
    while (reader.ready())
        fileContents += reader.readLine() + '\n';
        
    reader.close();
    
    // Preprocess contents into fragments.
    var filePath = new String(new File(aFilePath).getName()),
        fragments = objj_preprocess(fileContents, { path:"/x" }, {path:filePath}, flags),
        index = 0,
        count = fragments.length,
        preprocessed = "";

    // Writer preprocessed fragments out.
    for (; index < count; ++index)
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
                    var lines = e.fragment.info.split("\n"),
                        PAD = 3;
                        
                    System.out.println(
                            "Syntax error in "+e.fragment.file.path+
                            " on preprocessed line number "+e.lineNumber+"\n"+
                            "\t"+lines.slice(e.lineNumber-1-PAD<0 ? 0 : e.lineNumber-1-PAD, e.lineNumber+PAD).join("\n\t"));
                        
                    System.exit(1);
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
    var writer = new BufferedWriter(new FileWriter(outFilePath));
    writer.write(preprocessed);
    writer.close();
}

function main()
{
    var filePaths = [],
        outFilePaths = [],
        
        index = 0,
        count = arguments.length,
        
        gccArgs = [],
        
        flags = OBJJ_PREPROCESSOR_PREPROCESS | OBJJ_PREPROCESSOR_SYNTAX;
    
        
    for (; index < count; ++index)
    {
        var argument = String(arguments[index]);
        
        if (argument === "-o")
        {
            if (++index < count)
                outFilePaths.push(String(arguments[index]));
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
        preprocess(filePaths[index], outFilePaths[index], gccArgs, flags);
}

main.apply(main, arguments);
