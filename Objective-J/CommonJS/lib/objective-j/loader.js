var objj = null;
print("objj loader~");
function ObjectiveJLoader() {
    var loader = {};
    var factories = {};
    
    loader.reload = function(topId, path) {
        if (!objj) objj = require("objective-j");
        
        //print("loading objective-j: " + topId + " (" + path + ")");
        factories[topId] = objj.make_narwhal_factory(system.fs.read(path), path);
    }
    
    loader.load = function(topId, path) {
        if (!factories.hasOwnProperty(topId))
            loader.reload(topId, path);
        return factories[topId];
    }
    
    return loader;
};

require.loader.loaders.unshift([".j", ObjectiveJLoader()]);
