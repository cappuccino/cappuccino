
var environments = { };

function Environment(/*String*/ aName)
{
    this._name = aName;
    this._compilerFlags = [];
    this._spritesImages = false;

    environments[aName] = this;
}

Environment.environmentWithName = function(/*String*/ aName)
{
    return environments[aName];
}

Environment.prototype.name = function()
{
    return this._name;
}

Environment.prototype.toString = function()
{
    return this._name;
}

Environment.prototype.compilerFlags = function()
{
    return this._compilerFlags;
}

Environment.prototype.setCompilerFlags = function(flags)
{
    this._compilerFlags = flags;
}

Environment.prototype.setSpritesImages = function(/*Boolean*/ shouldSpriteImages)
{
    this._spritesImages = !!shouldSpriteImages;
}

Environment.prototype.spritesImages = function()
{
    return this._spritesImages;
}

exports.Environment = Environment;

exports.ObjJ = new Environment("ObjJ");

var CommonJS = new Environment("CommonJS");

CommonJS.setCompilerFlags(["-DPLATFORM_COMMONJS"]);

exports.CommonJS = CommonJS;

var Browser = new Environment("Browser");

Browser.setCompilerFlags(["-DPLATFORM_BROWSER", "-DPLATFORM_DOM"]);
Browser.setSpritesImages(true);

exports.Browser = Browser;
