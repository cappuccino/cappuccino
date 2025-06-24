/**
 * cib-analysis-tools.j
 *
 * This file contains tools for analyzing Cappuccino Interface Builder (.cib) files.
 * Its logic is based on the Cappuccino frameworks (Foundation/AppKit) and is
 * compatible with being run in a Node.js environment, provided the Objective-J
 * runtime has been properly initialized.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

/**
 * Finds all class dependencies within a given .cib file.
 * It works by temporarily "monkey-patching" the global CPClassFromString function
 * to record every class that is requested during the nib instantiation process.
 *
 * @param {string} cibPath - The file path to the .cib file.
 * @returns {string[]} An array of class names that the .cib file depends on.
 */
function findCibClassDependencies(cibPath) {
    const cib = [[CPCib alloc] initWithContentsOfURL:cibPath];
    const dependencies = {};
    const CPClassFromStringOriginal = CPClassFromString;

    // Temporarily replace the global function to intercept class lookups.
    CPClassFromString = function(aClassName) {
        const result = CPClassFromStringOriginal(aClassName);

        // Record the class name as a dependency.
        dependencies[aClassName] = true;

        return result;
    };

    // Ensure the CPApplication singleton is initialized, as it's needed by the unarchiver.
    [CPApplication sharedApplication];

    try {
        // Use the custom 'pressInstantiate' method which only goes as far as
        // decoding objects, which is sufficient to trigger the class lookups.
        [cib pressInstantiate];
    } catch (e) {
        CPLog.warn("Exception thrown when instantiating " + cibPath + ": " + e);
    } finally {
        // IMPORTANT: Always restore the original function.
        CPClassFromString = CPClassFromStringOriginal;
    }

    return Object.keys(dependencies);
}

/**
 * This Objective-J category adds a specialized 'pressInstantiate' method to CPCib.
 *
 * It's a stripped-down version of the full 'instantiateCibWithExternalNameTable:' method.
 * It performs just enough of the unarchiving process to force the lookup of custom
 * classes, but stops before trying to establish UI connections or display windows,
 * which would fail in a non-browser (Node.js) environment.
 */
@implementation CPCib (Press)

- (BOOL)pressInstantiate
{
    let bundle = _bundle;
    const owner = nil; // We don't have an owner in this context.

    if (!bundle && owner) {
        bundle = [CPBundle bundleForClass:[owner class]];
    }

    const unarchiver = [[_CPCibKeyedUnarchiver alloc] initForReadingWithData:_data bundle:bundle awakenCustomResources:_awakenCustomResources];
    const replacementClasses = nil;

    if (replacementClasses) {
        let key = nil;
        const keyEnumerator = [replacementClasses keyEnumerator];

        while ((key = [keyEnumerator nextObject]) !== nil) {
            [unarchiver setClass:[replacementClasses objectForKey:key] forClassName:key];
        }
    }

    [unarchiver setExternalObjectsForProxyIdentifiers:nil];

    const objectData = [unarchiver decodeObjectForKey:"CPCibObjectDataKey"];

    if (!objectData || ![objectData isKindOfClass:[_CPCibObjectData class]]) {
        return NO;
    }

    const topLevelObjects = nil;

    // This is the key step that triggers CPClassFromString calls for custom classes.
    [objectData instantiateWithOwner:owner topLevelObjects:topLevelObjects];

    // We deliberately OMIT the following steps as they are not needed for
    // dependency analysis and would fail in a non-browser environment:
    // [objectData establishConnectionsWithOwner:owner topLevelObjects:topLevelObjects];
    // [objectData awakeWithOwner:owner topLevelObjects:topLevelObjects];
    // [objectData displayVisibleWindows];

    return YES;
}

@end