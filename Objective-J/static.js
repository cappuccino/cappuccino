
OBJJUnrecognizedFormatException = "OBJJUnrecognizedFormatException";

var STATIC_MAGIC_NUMBER     = "@STATIC",
    MARKER_PATH             = "p",
    MARKER_CODE             = "c",
    MARKER_IMPORT_STD       = 'I',
    MARKER_IMPORT_LOCAL     = 'i';

var STATIC_EXTENSION        = "sj";

function objj_preprocess_file(aFilePath, fileContents, checkSyntax)
{
    // Preprocess contents into fragments.
    var fragments = objj_preprocess(fileContents, { path:"/x" }, { path:aFilePath}),
        index = 0,
        count = fragments.length,
        preprocessed = MARKER_PATH + ';' + aFilePath.length() + ';' + aFilePath;

    // Writer preprocessed fragments out.
    for (; index < count; ++index)
    {
        var fragment = fragments[index];
        
        if (IS_FILE(fragment))
            preprocessed += (IS_LOCAL(fragment) ? MARKER_IMPORT_LOCAL : MARKER_IMPORT_STD) + ';' + GET_PATH(fragment).length + ';' + GET_PATH(fragment);
        else
        {
            if (checkSyntax)
            {
                try
                {
                    new Function(GET_CODE(fragment));
                }
                catch (e)
                {
                    e.fragment = fragment;
                    throw e;
                }
            }
            preprocessed += MARKER_CODE + ';' + GET_CODE(fragment).length + ';' + GET_CODE(fragment);
        }
    }

    return preprocessed;
}

function objj_decompile(aString, bundle)
{
    var stream = new objj_markedStream(aString);
    
    if (stream.magicNumber() != STATIC_MAGIC_NUMBER)
        objj_exception_throw(new objj_exception(OBJJUnrecognizedFormatException, "*** Could not recognize executable code format."));
    
    if (stream.version() != 1.0)
        objj_exception_throw(new objj_exception(OBJJUnrecognizedFormatException, "*** Could not recognize executable code format."));
    
    var file = NULL,
        files = [];
    
    while (marker = stream.getMarker())   
    {
        var text = stream.getString();
        
        switch (marker)
        {
            case MARKER_PATH:           file = new objj_file();
                                        file.path = DIRECTORY(bundle.path) + text;
                                        file.bundle = bundle;
                                        file.fragments = [];
                                        
                                        files.push(file);
                                        break;
            case MARKER_CODE:           file.fragments.push(fragment_create_code(text, bundle, file));
                                        break;
            case MARKER_IMPORT_STD:     file.fragments.push(fragment_create_file(text, bundle, NO, file));
                                        break;
            case MARKER_IMPORT_LOCAL:   file.fragments.push(fragment_create_file(text, bundle, YES, file));
                                        break;
        }
    }
    
    return files;    
}
