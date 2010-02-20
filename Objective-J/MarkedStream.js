
function MarkedStream(/*String*/ aString)
{
    this._string = aString;

    var index = aString.indexOf(";");

    // Grab the magic number.
    this._magicNumber = aString.substr(0, index);

    this._location = aString.indexOf(";", ++index);

    // Grab the version number.
    this._version = aString.substring(index, this._location++);
}

MarkedStream.prototype.magicNumber = function()
{
    return this._magicNumber;
}

MarkedStream.prototype.version = function()
{
    return this._version;
}

MarkedStream.prototype.getMarker = function()
{
    var string = this._string,
        location = this._location;

    if (location >= string.length)
        return null;

    var next = string.indexOf(';', location);

    if (next < 0)
        return null;

    var marker = string.substring(location, next);

    if (marker === 'e')
        return null;

    this._location = next + 1;

    return marker;
}

MarkedStream.prototype.getString = function()
{
    var string = this._string,
        location = this._location;

    if (location >= string.length)
        return null;

    var next = string.indexOf(';', location);

    if (next < 0)
        return null;

    var size = parseInt(string.substring(location, next)),
        text = string.substr(next + 1, size);

    this._location = next + 1 + size;

    return text;
}
