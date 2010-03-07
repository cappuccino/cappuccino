
var OS = require("os");
var FILE = require("file");
var ByteString = require("binary").ByteString;

var javaImageSize = function (aFilePath)
{
    var imageStream = javax.imageio.ImageIO.createImageInputStream(new Packages.java.io.File(aFilePath).getCanonicalFile()),
        readers = javax.imageio.ImageIO.getImageReaders(imageStream),
        reader = null;

    if(readers.hasNext())
        reader = readers.next();

    else
    {
        imageStream.close();
        //can't read image format... what do you want to do about it,
        //throw an exception, return ?
    }

    reader.setInput(imageStream, true, true);

    // Now we know the size (yay!)
    var size = {width:reader.getWidth(0), height:reader.getHeight(0)};

    reader.dispose();
    imageStream.close();

    return size;
}

var server = null;

var serverImageSize = function (aFilePath)
{
    if (!server) 
    {
        var cmd = "NARWHAL_ENGINE_HOME='' NARWHAL_ENGINE=rhino narwhal "+OS.enquote(module.path);
        server = OS.popen(cmd, { charset : "UTF-8" });
    }

    var request = aFilePath.toByteString("UTF-8");
    sendLengthPrefixMessage(server.stdin.raw, request);

    var response = receiveLengthPrefixMessage(server.stdout.raw);
    return JSON.parse(response.decodeToString("UTF-8"));
}

if (system.engine == "rhino")
    exports.sizeOfImageAtPath = javaImageSize;
else
    exports.sizeOfImageAtPath = serverImageSize;

// TODO: move these methods somewhere else?

var bytesToNumberLE = function(bytes) {
    var acc = 0;
    for (var i = 0; i < bytes.length; i++)
        acc += bytes.get(i) << (8*i);
    return acc;
}

var bytesToNumberBE = function(bytes) {
    var acc = 0;
    for (var i = 0; i < bytes.length; i++)
        acc = (acc << 8) + bytes.get(i);
    return acc;
}

var numberToBytesLE = function(number, length) {
    var bytes = [];
    for (var i = 0; i < length; i++)
        bytes[i] = (number >> (8*i)) & 0xFF;
    return new ByteString(bytes);
}

var numberToBytesBE = function(number, length) {
    var bytes = [];
    for (var i = 0; i < length; i++)
        bytes[length-i-1] = (number >> (8*i)) & 0xFF;
    return new ByteString(bytes);
}

var lengthPrefixServer = function(stream, callback, prefixLength) {
    var bytes;
    do {
        bytes = receiveLengthPrefixMessage(stream, prefixLength);
        callback(bytes);
    } while (bytes);
}

var receiveLengthPrefixMessage = function(stream, prefixLength) {
    var prefixBytes = stream.read(prefixLength || 4);
    var length = bytesToNumberBE(prefixBytes);
    var bytes = stream.read(length);
    return bytes;
}

var sendLengthPrefixMessage = function(stream, bytes, prefixLength) {
    var lengthBytes = numberToBytesBE(bytes.length, prefixLength || 4);
    stream.write(lengthBytes).write(bytes).flush();
}

if (module == require.main)
{
    var bytes; 
    while (bytes = receiveLengthPrefixMessage(require("system").stdin.raw))
    {
        var fileName = bytes.decodeToString("UTF-8");
        var size = javaImageSize(fileName);

        sendLengthPrefixMessage(require("system").stdout.raw, JSON.stringify(size).toByteString("UTF-8"));
    }
}

/*
    //ASYNCHRONOUS, so not useful to us
    
function jscImageSize(aFilePath)
{
    var MIME_TYPES =    {
                            ".png"  : "image/png",
                            ".jpg"  : "image/jpeg",
                            ".jpeg" : "image/jpeg",
                            ".gif"  : "image/gif",
                            ".tif"  : "image/tiff",
                            ".tiff" : "image/tiff"
                        },
        FILE = require("file");

    var image = new Image();

    image.src = "data:" + MIME_TYPES[FILE.extension(aFilePath)] + ";base64," + require("base64").encode(FILE.read(aFilePath, { mode : 'b'}));

    return CGSizeMake(image.width, image.height);
}

*/

