
importPackage(java.lang);

importClass(java.io.File);
importClass(java.io.BufferedReader);
importClass(java.io.FileReader);
importClass(java.io.BufferedWriter);
importClass(java.io.FileWriter);


function main()
{
    var index = 0,
        count = arguments.length,
        bundlePath = NULL;

    for (; index < count; ++index)
        bundlePath = arguments[index];
alert(bundlePath)
    var bundleFile = new File(bundlePath).getCanonicalFile(),
        bundlePath = String(bundleFile.getCanonicalPath()),
        inlinedBundle = readBundle(bundleFile, true),
        inlinedFiles = [],
        replacedFiles = [],
        staticContent = "";
        
    // Find all internal bundles.
    var bundleCandidates = getFiles(bundleFile, "plist"),
        bundleCandidatesCount = bundleCandidates.length;

    while (bundleCandidatesCount--)
    {
        var bundleCandidate = bundleCandidates[bundleCandidatesCount];
        
        // We only care about Info.plists, specifically the ones that aren't us.
        if (String(bundleCandidate.getName()) !== "Info.plist" || String(bundleCandidate.getCanonicalPath()) === inlinedBundle.path)
            continue;
        
        var infoDictionary = readPlist(bundleCandidate);
        
        // At least one of these two has to be present for this to be a real deal bundle.
        if (!dictionary_getValue(infoDictionary, "CPBundleIdentifier") && !dictionary_getValue(infoDictionary, "CPBundleName"))
            continue;
        
        java.lang.System.out.println(" Examining " + pathRelativeTo(bundleCandidate.getCanonicalPath(), bundlePath));
        
        dictionary_removeValue(infoDictionary, "CPBundleExecutable");
        
        var bundle = readBundle(bundleCandidate.getParentFile(), true);
        
        bundle.path = pathRelativeTo(bundle.path, bundlePath);
        
        // We want to inline the info plist too.
        var inlinedFiles = [makeOBJJPlistFile(infoDictionary, bundleCandidate, bundle)].concat(bundle.files),
            index = 0,
            count = inlinedFiles.length;
        
        for (; index < count; ++index)
        {
            var file = inlinedFiles[index];
            
            file.path = pathRelativeTo(String(file.path), bundlePath);
            
            java.lang.System.out.println("  Inlining " + file.path);
            
            replacedFiles.push(file.path);
            staticContent += fileToMarkedString(inlinedFiles[index], true);
        }
    }
    
    var index = 0,
        existingStaticFiles = inlinedBundle.files,
        count = existingStaticFiles.length,
        topLevelContent = "@STATIC;1.0;";
    
    for (; index < count; ++index)
    {
        var file = existingStaticFiles[index];
        
        // If this isn't actually part of our bundle, drop it!
        if (file.bundle !== inlinedBundle)
            continue;
            
        file.path = pathRelativeTo(String(file.path), bundlePath);
        
        replacedFiles.push(file.path);
        topLevelContent += fileToMarkedString(file, false);
    }
    
    dictionary_setValue(inlinedBundle.info, "CPBundleReplacedFiles", replacedFiles);
    
    writeContentsToFile(CPPropertyListCreateXMLData(inlinedBundle.info).string, inlinedBundle.path);
    writeContentsToFile(topLevelContent + staticContent, inlinedBundle._staticContentPath);
}

function fileToMarkedString(anOBJJFile, encodeBundle)
{
    var markedString = "";
    
    markedString += MARKER_PATH + ';' + anOBJJFile.path.length + ';' + anOBJJFile.path;
    
    if (encodeBundle)
        markedString += MARKER_BUNDLE + ';' + anOBJJFile.bundle.path.length + ';' + anOBJJFile.bundle.path;
    
    var fragments = anOBJJFile.fragments;
    
    if (fragments && fragments.length > 0)
    {
        var fragmentIndex = 0,
            fragmentCount = fragments.length;
        
        for (; fragmentIndex < fragmentCount; ++fragmentIndex)
            markedString += fragments[fragmentIndex].toMarkedString();
    }
    
    else
        markedString += MARKER_TEXT + ';' + anOBJJFile.contents.length + ';' + anOBJJFile.contents;
        
    return markedString;
}

function makeOBJJPlistFile(aDictionary, aFile, aBundle)
{
    var file = new objj_file();
    
    file.path = typeof aFile === "string" ? aFile : aFile.getCanonicalPath();
    file.bundle = aBundle;
    file.contents = CPPropertyListCreate280NorthData(aDictionary).string;
    
    return file;
}

function pathRelativeTo(target, relativeTo)
{
    var components = [],
        targetParts = target.split("/"),
        relativeParts = relativeTo ? relativeTo.split("/") : [];

    var i = 0;
    while (i < targetParts.length)
    {
        if (targetParts[i] != relativeParts[i])
            break;
        i++;
    }
    
    for (var j = i; j < relativeParts.length; j++)
        components.push("..");
    
    for (var j = i; j < targetParts.length; j++)
        components.push(targetParts[j]);
    
    var result = components.join("/");
    
    return result;
}

function readPlist(/*File*/ aFile)
{
    var fileContents = readFile(aFile);

    var data = new objj_data();
    data.string = fileContents;

    return new CPPropertyListCreateFromData(data);
}

function readBundle(/*File*/ aFile, /*Boolean*/ shouldDecompile)
{
    var bundlePath = typeof aFile === "string" ? new File(aFile).getCanonicalPath() : aFile.getCanonicalPath(),
        infoPath = bundlePath + "/Info.plist";
    
    //err
    var bundle = new objj_bundle();
    
    bundle.path = infoPath;
    bundle.info = readPlist(infoPath);
    bundle._staticFilePaths = dictionary_getValue(bundle.info, "CPBundleReplacedFiles");

    if (bundle._staticFilePaths.length)
    {
        bundle._staticContentPath = staticContentPath = bundlePath + '/' + dictionary_getValue(bundle.info, "CPBundleExecutable");
   
        //err
        
        bundle._staticContent = readFile(staticContentPath);
        
        if (shouldDecompile)
            bundle.files = objj_decompile(bundle._staticContent, bundle);
    }
    else
        bundle._staticContent = "";
    
    return bundle;
}

function getFiles(/*File*/ sourceDirectory, /*nil|String|Array<String>*/ extensions, /*Array*/ exclusions)
{
    var matches = [],
        files = sourceDirectory.listFiles(),
        hasMultipleExtensions = typeof extensions !== "string";

    if (files)
    {
        var index = 0,
            count = files.length;
        
        for (; index < count; ++index)
        {
            var file = files[index].getCanonicalFile(),
                name = String(file.getName()),
                isValidExtension = !extensions;
            
            if (exclusions && fileArrayContainsFile(exclusions, file))
                continue;
            
            if (!isValidExtension)
                if (hasMultipleExtensions)
                {
                    var extensionCount = extensions.length;
                    
                    while (extensionCount-- && !isValidExtension)
                    {
                        var extension = extensions[extensionCount];
                        
                        if (name.substring(name.length - extension.length - 1) === ("." + extension))
                            isValidExtension = true;
                    }
                }
                else if (name.substring(name.length - extensions.length - 1) === ("." + extensions))
                    isValidExtension = true;
                
            if (isValidExtension)
                matches.push(file);
            
            if (file.isDirectory())
                matches = matches.concat(getFiles(file, extensions, exclusions));
        }
    }
    
    return matches;
}

function writeContentsToFile(/*String*/ contents, /*File*/ aFile)
{
    var writer = new BufferedWriter(new FileWriter(aFile));

    writer.write(contents);

    writer.close();
}

main.apply(main, arguments);
