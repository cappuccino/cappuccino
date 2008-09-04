importClass(java.util.ArrayList);
importClass(java.util.List);
importClass(java.util.regex.Matcher);
importClass(java.util.regex.Pattern);
importClass(java.util.regex.PatternSyntaxException);

var CachedRegexData = [];

function regexDataFromRegex(aRegex)
{
    var source = "",
        flags = "";
            
    if (typeof aRegex == "string")
    {
        if (CachedRegexData[aRegex])
            return CachedRegexData[aRegex];
            
        string = aRegex;
        source = aRegex;
    }
    else
    {
        string = aRegex.toString();
    
        if (CachedRegexData[string])
            return CachedRegexData[string];
    
        var index = string.lastIndexOf('/');
        
        source = string.substr(0, index);
        flags = string.substr(index + 1);
    }
    
    source = source.replace("\\[\\^\\\\\\d\\]", ".", "g");
    source = source.replace("\\[([^\\]]*)\\\\b([^\\]]*)\\]", "[$1\\\\cH$2]", "g") // [...\b...] -> [...\cH...]
    source = source.replace("(?<!\\\\)\\{(?!\\d)", "\\\\{", "g");
    source = source.replace("(?<!(\\d,?|\\\\))\\}", "\\\\}", "g");
            
    return CachedRegexData[string] = { pattern:Pattern.compile(source, 0), flags:flags };
}

String.prototype.match = function(regex)
{
    var regexData = regexDataFromRegex(regex);
    
    var matcher = regexData.pattern.matcher(new java.lang.String(this)),
        flags = regexData.flags;
        
    if (!matcher.find())
        return [];

    var index = matcher.start(0),
        groups = [];
        
    if (flags.indexOf('g') != -1)
    {
        do
        {
            groups.push(matcher.group(0) + "");
        }
        while (matcher.find());
    }
    else
    {
        for (index = 0; index <= matcher.groupCount(); ++index)
        {
            var group = matcher.group(index);
            
            if (group != null)
                groups[i] = group;
        }
    }
    
    return groups;
}
