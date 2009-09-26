var objj = null;

function ObjectiveJLoader() {
    var loader = {};
    var factories = {};
    
    loader.reload = function(topId, path) {
        if (!objj) objj = require("objj/objj");
        
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
