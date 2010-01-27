
var environments = { };

function Environment(/*String*/ aName)
{
    this._name = aName;
    this._compilerFlags = [];
    this._spritesImagesAsMHTML = false;
    this._spritesImagesAsDataURLs = false;
    
    environments[aName] = this;
}

Environment.environmentWithName = function(/*String*/ aName)
{
    return environments[aName];
}

Environment.flattenedEnvironments = function(/*Array*/ environments)
{
    var flattenedEnvironments = [];

    environments.forEach(function(/*Environment*/ anEnvironment)
    {
        Array.prototype.push.apply(flattenedEnvironments, anEnvironment.flattenedEnvironments());
    });

    return flattenedEnvironments;
}

Environment.prototype.name = function()
{
    return this._name;
}

Environment.prototype.toString = function()
{
    return this._name;
}

Environment.prototype.flattenedEnvironments = function()
{
    return [this];
}

Environment.prototype.compilerFlags = function()
{
    return this._compilerFlags;
}

Environment.prototype.setCompilerFlags = function(flags)
{
    this._compilerFlags = flags;
}

Environment.prototype.setSpritesImagesAsMHTML = function(/*Boolean*/ shouldSpriteImagesAsMHTML)
{
    this._spritesImagesAsMHTML = !!shouldSpriteImagesAsMHTML;
}

Environment.prototype.spritesImagesAsMHTML = function()
{
    return this._spritesImagesAsMHTML;
}

Environment.prototype.setSpritesImagesAsDataURLs = function(/*Boolean*/ shouldSpriteImagesAsDataURLs)
{
    this._spritesImagesAsDataURLs = !!shouldSpriteImagesAsDataURLs;
}

Environment.prototype.spritesImagesAsDataURLs = function()
{
    return this._spritesImagesAsDataURLs;
}

Environment.prototype.spritesImages = function()
{
    return this.spritesImagesAsMHTML() || this.spritesImagesAsDataURLs();
}

exports.Environment = Environment;

exports.ObjJ = new Environment("ObjJ");

var CommonJS = new Environment("CommonJS");

CommonJS.setCompilerFlags(["-DPLATFORM_COMMONJS"]);

exports.CommonJS = CommonJS;

var Browser = new Environment("Browser");

Browser.setCompilerFlags(["-DPLATFORM_BROWSER", "-DPLATFORM_DOM"]);
//Browser.setSpritesImagesAsDataURLs(true);

exports.Browser = Browser;

function EnvironmentCollection(/*String*/ aName, /*Array*/ environments)
{
    this._name = aName;
    this._environments = environments;

    environments[aName] = this;
}

EnvironmentCollection.prototype.name = function()
{
    return this._name;
}

EnvironmentCollection.prototype.toString = function()
{
    return this._name;
}

EnvironmentCollection.prototype.flattenedEnvironments = function()
{
    var environments = [];

    this._environments.forEach(function(anEnvironment)
    {
        Array.prototype.push.apply(environments, anEnvironment.flattenedEnvironments());
    });

    return environments;
}
