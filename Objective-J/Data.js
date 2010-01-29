
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

exports.Data = Data;
exports.CFData = Data;

exports.MutableData = MutableData;
exports.CFMutableData = MutableData;
