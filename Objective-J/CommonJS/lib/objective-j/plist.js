var FILE = require("file"),
    OBJJ = require("objective-j"),
    CPPropertyListCreateData = OBJJ.CPPropertyListCreateData,
    kCFPropertyListXMLFormat_v1_0 = OBJJ.kCFPropertyListXMLFormat_v1_0;

exports.readPlist = function(aPath)
{
    var plistData = new OBJJ.objj_data();
    plistData.string = FILE.read(aPath, { charset:"UTF-8" });
    return OBJJ.CPPropertyListCreateFromData(plistData);
}

exports.writePlist = function(aPath, plist, format)
{
    format = format || OBJJ.kCFPropertyListXMLFormat_v1_0;
    FILE.write(aPath, OBJJ.CPPropertyListCreateData(plist, format).string, { charset:"UTF-8" });
}
