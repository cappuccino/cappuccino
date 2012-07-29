@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

function findCibClassDependencies(cibPath) {
    var cib = [[CPCib alloc] initWithContentsOfURL:cibPath],
        dependencies = {},
        CPClassFromStringOriginal = CPClassFromString;

    CPClassFromString = function(aClassName)
    {
        var result = CPClassFromStringOriginal(aClassName);

        // print("CPClassFromString: " + Array.prototype.slice.call(arguments) + " => " + result);
        dependencies[aClassName] = true;

        return result;
    };

    // make sure CPApp is init'd
    [CPApplication sharedApplication];

    try {
        var x = [cib pressInstantiate];
    } catch (e) {
        CPLog.warn("Exception thrown when instantiating " + cibPath + ": " + e);
    } finally {
        CPClassFromString = CPClassFromStringOriginal;
    }

    return Object.keys(dependencies);
}

// this is copied from CPCib's "instantiateCibWithExternalNameTable:"
@implementation CPCib (Press)

- (BOOL)pressInstantiate
{
    var bundle = _bundle,
        owner = nil;//[anExternalNameTable objectForKey:CPCibOwner];

    if (!bundle && owner)
        bundle = [CPBundle bundleForClass:[owner class]];

    var unarchiver = [[_CPCibKeyedUnarchiver alloc] initForReadingWithData:_data bundle:bundle awakenCustomResources:_awakenCustomResources],
        replacementClasses = nil;//[anExternalNameTable objectForKey:CPCibReplacementClasses];

    if (replacementClasses)
    {
        var key = nil,
            keyEnumerator = [replacementClasses keyEnumerator];

        while ((key = [keyEnumerator nextObject]) !== nil)
            [unarchiver setClass:[replacementClasses objectForKey:key] forClassName:key];
    }

    [unarchiver setExternalObjectsForProxyIdentifiers:nil/*[anExternalNameTable objectForKey:CPCibExternalObjects]*/];

    var objectData = [unarchiver decodeObjectForKey:"CPCibObjectDataKey"];

    if (!objectData || ![objectData isKindOfClass:[_CPCibObjectData class]])
        return NO;

    var topLevelObjects = nil;//[anExternalNameTable objectForKey:CPCibTopLevelObjects];

    [objectData instantiateWithOwner:owner topLevelObjects:topLevelObjects];
    // [objectData establishConnectionsWithOwner:owner topLevelObjects:topLevelObjects];
    // [objectData awakeWithOwner:owner topLevelObjects:topLevelObjects];

    // Display Visible Windows.
    // [objectData displayVisibleWindows];

    return YES;
}

@end
