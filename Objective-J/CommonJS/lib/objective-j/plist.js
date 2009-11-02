var file = require("file"),
    objj = require("objective-j"),
    CPPropertyListCreateData = objj.CPPropertyListCreateData,
    kCFPropertyListXMLFormat_v1_0 = objj.kCFPropertyListXMLFormat_v1_0;

exports.readPlist = function(path) {
    var plistData = new objj.objj_data();
    plistData.string = file.read(path);
    return objj.CPPropertyListCreateFromData(plistData);
}

exports.writePlist = function(path, plist, format) {
    format = format || objj.kCFPropertyListXMLFormat_v1_0;
    file.write(path, objj.CPPropertyListCreateData(plist, format).string);
}
