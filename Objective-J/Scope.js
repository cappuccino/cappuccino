
var cachedExportedNames     = [],
    cachedExportedValues    = [];

function cacheExportedNamesAndValues()
{
    for (var exportName in exports)
        if (hasOwnProperty.apply(exports, [exportName]))
        {
            cachedExportedNames.push(exportName);
            cachedExportedValues.push(exports[exportName]);
        }
alert(cachedExportedNames);
    exportedNames = function()
    {
        return cachedExportedNames;
    }

    exportedValues = function()
    {
        return cachedExportedValues;
    }
}

function exportedNames()
{
    cacheExportedNamesAndValues();
    return exportedNames();
}

function exportedValues()
{
    cacheExportedNamesAndValues();
    return exportedValues();
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

function fileExecuterForPath(/*String*/ referencePath)
{
    var fileExecuter = cachedFileExecutersForPaths[referencePath];
    
    if (!fileExecuter)
    {
        var dirname = FILE.dirname(referencePath);

        fileExecuter = function(/*String*/ aPath, /*BOOL*/ isLocal, /*BOOL*/ shouldForce)
        {
            aPath = importablePath(aPath, isLocal, dirname);
    
            var fileExecutableSearch = new FileExecutableSearch(aPath, isLocal),
                fileExecutable = fileExecutableSearch.result();
    
            if (0 && !fileExecutable.hasLoadedFileDependencies())
                throw "No executable loaded for file at path " + aPath;
        console.log("executing " + aPath);
        //console.log(aPath + " " + (isLocal ? 1 : 0) + " " + executable.isLoaded() + " " + executable.hasLoadedDependencies());
    
    
            fileExecutable.execute(shouldForce);
        }
    
        cachedFileExecutersForPaths[referencePath] = fileExecuter;
    }

    return fileExecuter;
}

var cachedImportersForPaths = { };

function fileImporterForPath(/*String*/ referencePath)
{
    var cachedImporter = cachedImportersForPaths[referencePath];

    if (!cachedImporter)
    {
        var dirname = FILE.dirname(referencePath);

        cachedImporter = function(/*String*/ aPath, /*BOOL*/ isLocal, /*Function*/ aCallback)
        {
            aPath = importablePath(aPath, isLocal, dirname);
    
            var fileExecutableSearch = new FileExecutableSearch(aPath, isLocal);
    
            function searchComplete(/*FileExecutableSearch*/ aFileExecutableSearch)
            {console.log("search complete: " + aFileExecutableSearch);
                var fileExecutable = aFileExecutableSearch.result(),
                    fileExecuter = fileExecuterForPath(referencePath);
        
                if (!fileExecutable.hasLoadedFileDependencies())
                {
                    fileExecutable.loadFileDependencies();
        
                    fileExecutable.addEventListener("dependenciesload", function()
                    {
                        fileExecuter(aPath, isLocal);
                    });
                }
                else
                    fileExecuter(aPath, isLocal);
            }
    
            if (fileExecutableSearch.isComplete())
                searchComplete(search);
            else
                fileExecutableSearch.addEventListener("complete", function(/*Event*/ anEvent)
                {
                    console.log("completed...");
                    searchComplete(anEvent.fileExecutableSearch);
                });
        }

        cachedImportersForPaths[referencePath] = cachedImporter;
    }

    return cachedImporter;
}
