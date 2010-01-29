
function Data()
{
    this._encodedString = NULL;
    this._serializedPropertyList = NULL;

    this._bytes = NULL;
    this._base64 = NULL;
}

Data.prototype.serializedPropertyList = function()
{
    if (!this._serializedPropertyList)
        this._serializedPropertyList = PropertyList.propertyListFromString(this.encodedString());

    return this._serializedPropertyList;
}

Data.prototype.encodedString = function()
{
    if (this._encodedString === NULL)
    {
        var serializedPropertyList = this._serializedPropertyList;

        if (this._serializedPropertyList)
            this._encodedString = PropertyList.stringFromPropertyList(serializedPropertyList);

//        Ideally we would convert these bytes or base64 into a string.
//        else if (this._bytes)
//        else if (this._base64)

        else
            throw "Can't convert data to string.";
    }

    return this._encodedString;
}

Data.prototype.bytes = function()
{
    return this._bytes;
}

Data.prototype.base64 = function()
{
    return this._base64;
}

function MutableData()
{
    Data.call(this);
}

MutableData.prototype = new Data();

function clearMutableData(/*MutableData*/ aData)
{
    this._encodedString = NULL;
    this._serializedPropertyList = NULL;

    this._bytes = NULL;
    this._base64 = NULL;
}

MutableData.prototype.setSerializedPropertyList = function(/*PropertyList*/ aPropertyList)
{
    clearMutableData(this);

    this._serializedPropertyList = aPropertyList;
}

MutableData.prototype.setEncodedString = function(/*String*/ aString)
{
    clearMutableData(this);

    this._encodedString = aString;
}

MutableData.prototype.setBytes = function(/*Array*/ bytes)
{
    clearMutableData(this);

    this._bytes = bytes;
}

MutableData.prototype.setBase64String = function(/*String*/ aBase64String)
{
    clearMutableData(this);

    this._base64 = aBase64String;
}

// Base64 encoding and decoding

var base64_map_to = [
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "0","1","2","3","4","5","6","7","8","9","+","/","="],
    base64_map_from = [];

for (var i = 0; i < base64_map_to.length; i++)
    base64_map_from[base64_map_to[i].charCodeAt(0)] = i;

function base64_decode_to_array(input, strip)
{
    if (strip)
        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

    var pad = (input[input.length-1] == "=" ? 1 : 0) + (input[input.length-2] == "=" ? 1 : 0),
        length = input.length,
        output = [];

    var i = 0;
    while (i < length)
    {
        var bits =  (base64_map_from[input.charCodeAt(i++)] << 18) |
                    (base64_map_from[input.charCodeAt(i++)] << 12) |
                    (base64_map_from[input.charCodeAt(i++)] << 6) |
                    (base64_map_from[input.charCodeAt(i++)]);

        output.push((bits & 0xFF0000) >> 16);
        output.push((bits & 0xFF00) >> 8);
        output.push(bits & 0xFF);
    }

    // strip "=" padding from end
    if (pad > 0)
        return output.slice(0, -1 * pad);

    return output;
}

function base64_encode_array(input)
{
    var pad = (3 - (input.length % 3)) % 3,
        length = input.length + pad,
        output = [];

    // pad with nulls
    if (pad > 0) input.push(0);
    if (pad > 1) input.push(0);

    var i = 0;
    while (i < length)
    {
        var bits =  (input[i++] << 16) |
                    (input[i++] << 8)  |
                    (input[i++]);

        output.push(base64_map_to[(bits & 0xFC0000) >> 18]);
        output.push(base64_map_to[(bits & 0x3F000) >> 12]);
        output.push(base64_map_to[(bits & 0xFC0) >> 6]);
        output.push(base64_map_to[bits & 0x3F]);
    }

    // pad with "=" and revert array to previous state
    if (pad > 0)
    {
        output[output.length-1] = "=";
        input.pop();
    }
    if (pad > 1)
    {
        output[output.length-2] = "=";
        input.pop();
    }

    return output.join("");
}

function base64_decode_to_string(input, strip)
{
    return bytes_to_string(base64_decode_to_array(input, strip));
}

function bytes_to_string(bytes)
{
    // This is relatively efficient, I think:
    return String.fromCharCode.apply(null, bytes);
}

exports.bytes_to_string = bytes_to_string;

function base64_encode_string(input)
{
    var temp = [];
    for (var i = 0; i < input.length; i++)
        temp.push(input.charCodeAt(i));

    return base64_encode_array(temp);
}

exports.Data = Data;
exports.CFData = Data;

exports.MutableData = MutableData;
exports.CFMutableData = MutableData;
