
function ObjectiveJLoader() {
    var loader = {};
    var factories = {};
    
    loader.reload = function(topId, path) {
        if (!global.ObjectiveJ) 
            global.ObjectiveJ = require("objective-j");
        
        //print("loading objective-j: " + topId + " (" + path + ")");
        factories[topId] = ObjectiveJ.make_narwhal_factory(path);
        factories[topId].path = path;
    }
    
    loader.load = function(topId, path) {
        if (!factories.hasOwnProperty(topId))
            loader.reload(topId, path);
        return factories[topId];
    }
    
    return loader;
};

require.loader.loaders.unshift([".j", ObjectiveJLoader()]);
