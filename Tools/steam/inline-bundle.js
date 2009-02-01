function inlineBundle()
{
    var index = 0,
        count = arguments.length,
        bundlePath = NULL;

    for (; index < count; ++index)
    {
        var argument = arguments[index];
        
        switch (arguments[index])
        {
            case "-d":  directoryPath = arguments[++index];
                        break;
                        
            default:    bundlePath = argument;
        }
    }
 
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