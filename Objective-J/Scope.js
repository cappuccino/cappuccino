
// For now just make these global.
function makeExportsGlobal()
{
    for (var exportName in exports)
        if (hasOwnProperty.apply(exports, [exportName]))
            global[exportName] = exports[exportName];
}

function importablePath(/*String*/ aPath, /*BOOL*/ isLocal, /*String*/ aCWD)
{
    aPath = FILE.normal(aPath);

    if (FILE.isAbsolute(aPath))
        return aPath;

    if (isLocal)
        aPath = FILE.join(aCWD, aPath);

    return aPath;
}

var cachedFileExecutersForPaths = { };

exports.fileExecuterForPath = function(/*String*/ referencePath)
{
    referencePath = FILE.normal(referencePath);

    var fileExecuter = cachedFileExecutersForPaths[referencePath];
    
    if (!fileExecuter)
    {
        fileExecuter = function(/*String*/ aPath, /*BOOL*/ isLocal, /*BOOL*/ shouldForce)
        {
            aPath = importablePath(aPath, isLocal, referencePath);
    
            var fileExecutableSearch = new FileExecutableSearch(aPath, isLocal),
                fileExecutable = fileExecutableSearch.result();
    
            if (0 && !fileExecutable.hasLoadedFileDependencies())
                throw "No executable loaded for file at path " + aPath;
    
            fileExecutable.execute(shouldForce);
        }
    
        cachedFileExecutersForPaths[referencePath] = fileExecuter;
    }

    return fileExecuter;
}

var cachedImportersForPaths = { };

function fileImporterForPath(/*String*/ referencePath)
{
    referencePath = FILE.normal(referencePath);

    var cachedImporter = cachedImportersForPaths[referencePath];

    if (!cachedImporter)
    {
        cachedImporter = function(/*String*/ aPath, /*BOOL*/ isLocal, /*Function*/ aCallback)
        {
            aPath = importablePath(aPath, isLocal, referencePath);
    
            var fileExecutableSearch = new FileExecutableSearch(aPath, isLocal);
    
            function searchComplete(/*FileExecutableSearch*/ aFileExecutableSearch)
            {
                var fileExecutable = aFileExecutableSearch.result(),
                    fileExecuter = exports.fileExecuterForPath(referencePath),
                    executeAndCallback = function ()
                    {
                        fileExecuter(aPath, isLocal);

                        if (aCallback)
                            aCallback();
                    }

                if (!fileExecutable.hasLoadedFileDependencies())
                {
                    fileExecutable.addEventListener("dependenciesload", executeAndCallback);
                    fileExecutable.loadFileDependencies();
                }
                else
                    executeAndCallback();
            }
    
            if (fileExecutableSearch.isComplete())
                searchComplete(fileExecutableSearch);
            else
                fileExecutableSearch.addEventListener("complete", function(/*Event*/ anEvent)
                {
                    searchComplete(anEvent.fileExecutableSearch);
                });
        }

        cachedImportersForPaths[referencePath] = cachedImporter;
    }

    return cachedImporter;
}

exports.fileImporterForPath = fileImporterForPath;
