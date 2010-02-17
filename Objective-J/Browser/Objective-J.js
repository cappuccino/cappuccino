
var global = { },
    ObjectiveJ = { };

(function (global, exports, namespace)
{
    var GLOBAL_NAMESPACE = namespace;
#include "Includes.js"
})(global, ObjectiveJ, window);

var hasOwnProperty = Object.prototype.hasOwnProperty;

// If we can't trust the host object, don't treat it as global
// and fall back to inferred global through eval. In IE this
// make a difference.
if (window.window !== window)
{
    for (key in global)
        if (hasOwnProperty.call(global, key))
            eval(key + " = global[\"" + key + "\"];");
}
else
{
    for (key in global)
        if (hasOwnProperty.call(global, key))
            window[key] = global[key];
}
