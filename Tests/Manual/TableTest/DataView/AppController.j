/*
 * AppController.j
 * DataView
 *
 * Created by You on February 12, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPArray.j>

@import <AppKit/CPTableView.j>
@import <AppKit/CPWindow.j>


var AppControllerInstance = nil;


/*
    This app is a complete example of how to program complex
    custom data views in a table view, using bindings in Xcode as much
    as possible. Unfortunately the contents of a custom data view
    in a cell-based table cannot be bound to row data. For that
    we need view-based tables.

    A lot of the behavior is specified in Xcode through bindings
    and formatters. Inspect each object closely to see how the magic works.
*/
@implementation AppController : CPObject
{
    @outlet CPWindow            theWindow;
    @outlet CPTableView         tableView;
    @outlet CustomDataView      dataView;
    @outlet CPArrayController   rowController;
    BOOL                        uploading @accessors;
    CPArray                     rows;
    CPArray                     progressIncrements;
}

+ (AppController)sharedAppController
{
    return AppControllerInstance;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        AppControllerInstance = self;
        rows = [];
        progressIncrements = [];
    }

    return self;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    [[tableView tableColumns][0] setDataView:dataView];

    rows = [
        [CPDictionary dictionaryWithJSObject:{ id:1, filename: "Jack.png", size:1327, uploading:NO, progress:0 }],
        [CPDictionary dictionaryWithJSObject:{ id:2, filename: "Jill.png", size:827193133061, uploading:NO, progress:0 }],
        [CPDictionary dictionaryWithJSObject:{ id:3, filename: "Up the hill.html", size:4131964, uploading:NO, progress:0 }],
        [CPDictionary dictionaryWithJSObject:{ id:4, filename: "Alice.pdf", size:72731, uploading:NO, progress:0 }],
        [CPDictionary dictionaryWithJSObject:{ id:5, filename: "Wonderland.mov", size:1234567890, uploading:NO, progress:0 }],
        [CPDictionary dictionaryWithJSObject:{ id:6, filename: "Mad Hatter.psd", size:3113713, uploading:NO, progress:0 }],
        [CPDictionary dictionaryWithJSObject:{ id:7, filename: "Down the Rabbit Hole.mkv", size:93847229, uploading:NO, progress:0 }],
    ];

    // Simulate different upload speeds
    for (var i = 0; i < rows.length; ++i)
        [progressIncrements addObject:FLOOR(RAND() * (10 - 3 + 1)) + 3];  // Random number 3-10

    [rowController setContent:rows];
}

// Don't allow files to be selected during an upload
- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)index
{
    return !uploading;
}

- (@action)start:(id)sender
{
    // Note we use setUploading:YES instead of uploading = YES.
    // This allows controls bound to that value to be updated.
    [self setUploading:YES];

    [rowController setSelectionIndexes:[CPIndexSet indexSet]];

    // Here is a good example of using a method to wrap a block of code with other code.
    [self updateRowsWithBlock:function()
        {
            [rows setValue:YES forKey:@"uploading"];
            [rows setValue:0 forKey:@"progress"];
        }];

    [CPTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(updateProgress:)
                                   userInfo:nil
                                    repeats:YES];
}

- (@action)stop:(id)sender
{
    [self updateRowsWithBlock:function()
        {
            [rows setValue:NO forKey:@"uploading"];
            [rows setValue:0 forKey:@"progress"];
        }];

    [self setUploading:NO];
}

- (@action)removeFiles:(id)sender
{
    [rowController removeObjectsAtArrangedObjectIndexes:[rowController selectionIndexes]];
}

- (void)updateProgress:(CPTimer)timer
{
    var updater = function()
        {
            var allDone = YES;

            for (var i = 0, count = [rows count]; i < count; ++i)
            {
                var info = [rows objectAtIndex:i],
                    progress = [info valueForKey:@"progress"],
                    fileUploading = [info valueForKey:@"uploading"];

                if (fileUploading)
                {
                    progress = MIN(progress + progressIncrements[i], 100);
                    [info setValue:progress forKey:@"progress"];

                    if (progress < 100)
                        allDone = NO;
                    else
                        [info setValue:NO forKey:@"uploading"];
                }
            }

            return allDone;
        },

        allDone = [self updateRowsWithBlock:updater];

    if (allDone)
    {
        [timer invalidate];
        [self setUploading:NO];
    }
}

- (void)abortFileWithId:(int)anId
{
    var info = [rows objectAtIndex:[rows indexOfObjectPassingTest:function(object)
                {
                    return [object valueForKey:@"id"] === anId;
                }]];

    if (![info valueForKey:@"uploading"])
        return;

    [self updateRowsWithBlock:function()
        {
            [info setValue:NO forKey:@"uploading"];
            [info setValue:0 forKey:@"progress"];
        }
    ];

    [[CPAlert alertWithMessageText:[CPString stringWithFormat:@"Transfer of “%@” has been aborted.", [info valueForKey:@"filename"]]
                     defaultButton:@"OK"
                   alternateButton:nil
                       otherButton:nil
         informativeTextWithFormat:nil] runModal];
}

- (id)updateRowsWithBlock:(Function)block
{
    /*
        We can't bind directly to the contents of the row array, but we did bind
        the table contents to the row array. By wrapping a change to the array
        with willChange/didChange, we notify observers of the array that a change has occurred.
    */
    [self willChangeValueForKey:@"rows"];

    var result = block();

    [self didChangeValueForKey:@"rows"];

    return result;
}

@end


/*
    This is the data view class. The prototype for the data view
    was created in Xcode and is loaded as an instance variable
    of AppController. To use a data view, you must create outlets
    to the views you want to update with dynamic data and connect
    them in the prototype view within Xcode.

    In the data view class you MUST implement the following:

    - (void)setObjectValue:(id)aValue
    - (id)initWithCoder:(CPCoder)aCoder
    - (void)encodeWithCoder:(CPCoder)aCoder
*/
@implementation CustomDataView : CPView
{
    // From row data, but not part of the view
    int                         fileId;

    // The fields we need to update with row data.
    // Note the size field has a CPByteCountFormatter attached.
    @outlet CPTextField         filename;
    @outlet CPTextField         size;
    @outlet CPProgressIndicator progressBar;
    @outlet CPButton            abortButton;
}

/*
    This is called once for each row in the table's data array whenever
    you modify the array through the array controller or use willChange/didChange
    on the array. aValue is the array object for the current table row.
*/
- (void)setObjectValue:(id)aValue
{
    fileId = [aValue valueForKey:@"id"];

    [filename setStringValue:[aValue valueForKey:@"filename"]];

    // Because the size field has a CPByteCountFormatter attached,
    // we can use setObjectValue with a number to set a formatted string.
    [size setObjectValue:[aValue valueForKey:@"size"]];

    [progressBar setDoubleValue:[aValue valueForKey:@"progress"]];
    [abortButton setEnabled:[aValue valueForKey:@"uploading"]];
}

/*
    The abort button in connected to this method in Xcode.
*/
- (@action)abort:(id)sender
{
    [[AppController sharedAppController] abortFileWithId:fileId];
}

@end

@implementation CustomDataView (CPCoding)

/*
    You MUST decode every view within your custom data view.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        filename = [aCoder decodeObjectForKey:@"filename"];
        size = [aCoder decodeIntForKey:@"size"];
        progressBar = [aCoder decodeObjectForKey:@"progressBar"];
        abortButton = [aCoder decodeObjectForKey:@"abortButton"];
    }

    return self;
}

/*
    You MUST encode every view within your custom data view.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:filename forKey:@"filename"];
    [aCoder encodeInt:size forKey:@"size"];
    [aCoder encodeObject:progressBar forKey:@"progressBar"];
    [aCoder encodeObject:abortButton forKey:@"abortButton"];
}

@end
