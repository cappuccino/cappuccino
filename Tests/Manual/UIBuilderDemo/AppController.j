//
//  AppController.j
//  Main application controller. Sets up the window, canvas, palette,
//  and controllers on launch.
//

@import <Foundation/CPObject.j>
@import "UIBuilderController.j"
@import "UICanvasView.j"
@import "UIElementView.j";
@import "InspectorController.j";

@implementation CPColor (StandardColors)

// A standard light gray for control backgrounds, like buttons.
+ (CPColor)controlColor
{
    return [CPColor colorWithCalibratedWhite:0.9 alpha:1.0];
}

// A medium gray for shadows or borders.
+ (CPColor)controlShadowColor
{
    return [CPColor grayColor];
}

// A dark gray for text on light controls.
+ (CPColor)controlDarkShadowColor
{
    return [CPColor darkGrayColor];
}

// The primary color for selected items.
+ (CPColor)selectedControlColor
{
    // Corresponds to the default blue selection color in macOS.
    return [CPColor colorWithCalibratedRed:0.0 green:0.478 blue:1.0 alpha:1.0];
}

// A secondary selection color, often used for inactive windows or rubber-band selections.
+ (CPColor)alternateSelectedControlColor
{
    return [CPColor colorWithCalibratedRed:0.2 green:0.5 blue:0.9 alpha:1.0];
}

// The color for an inactive or secondary selection, like a window title bar.
+ (CPColor)secondarySelectedControlColor
{
    return [CPColor lightGrayColor];
}

// The highlight color for an element that has keyboard focus.
+ (CPColor)keyboardFocusIndicatorColor
{
    return [CPColor colorWithCalibratedRed:0.3 green:0.6 blue:1.0 alpha:1.0];
}

// The standard background color for a window's content area.
+ (CPColor)windowBackgroundColor
{
    return [CPColor colorWithCalibratedWhite:0.93 alpha:1.0];
}

// The background color for text-editing views.
+ (CPColor)textBackgroundColor
{
    return [CPColor whiteColor];
}

@end

// Required additions from original EFView.j for graphics and text handling
@implementation CPString(SizingAddition)
- (CPSize)sizeWithAttributes:(CPDictionary)stringAttributes
{
    var font = [stringAttributes objectForKey:CPFontAttributeName] || [CPFont systemFontOfSize:12];
    // This is a simplified implementation. For more complex text, you might need a more robust solution.
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];
    var oldFont = ctx.font;
    ctx.font = [font cssString];
    var metrics = ctx.measureText(self);
    ctx.font = oldFont;
    return CGSizeMake(metrics.width, [[font fontDescriptor] pointSize]);
}
- (void)drawAtPoint:(CGPoint)aPoint withAttributes:(CPDictionary)attributes
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];
    var font = [attributes objectForKey:CPFontAttributeName] || [CPFont systemFontOfSize:12];
    var color = [attributes objectForKey:CPForegroundColorAttributeName] || [CPColor blackColor];

    ctx.font = [font cssString];
    [color setFill];
    ctx.fillText(self, aPoint.x, aPoint.y + [[font fontDescriptor] pointSize]);
}
@end

@implementation CPBezierPath(RoundedRectangle)
+ (CPBezierPath)bezierPathWithRoundedRect:(CPRect)aRect radius:(float)radius
{
    return [self bezierPathWithRoundedRect:aRect xRadius:radius yRadius:radius];
}
@end


// A simple draggable symbol for the palette
@implementation DraggableSymbolView : CPView
{
    CPString _dragType;
}

- (void)setDragType:(CPString)aType
{
    _dragType = aType;
}
-(BOOL)acceptsFirstMouse:(CPEvent)aEvent
{
    return YES;
}

- (void)mouseDown:(CPEvent)theEvent
{
    // 1. Create a placeholder view that is a visual copy of this one.
    var dragPlaceholder = [[DraggableSymbolView alloc] initWithFrame:[self bounds]];
    [dragPlaceholder setDragType:_dragType]; // Ensure it can draw its title correctly
    [dragPlaceholder setAlphaValue:0.75]; // Make it semi-transparent for good UX

    var pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];
    [pasteboard declareTypes:[_dragType] owner:nil];
    [pasteboard setString:@"1" forType:_dragType];

    [self dragView:dragPlaceholder
                at:[self bounds].origin
            offset:nil
             event:theEvent
        pasteboard:pasteboard
            source:self
         slideBack:YES];
}

// The drawRect: method defines what the view looks like, and therefore
// what the dragged placeholder view will look like.
- (void)drawRect:(CGRect)rect
{
    var bounds = [self bounds];

    // Background
    [[CPColor controlColor] set];
    [CPBezierPath fillRect:bounds];
    [[CPColor controlShadowColor] set];
    [CPBezierPath strokeRect:bounds];

    if ([_dragType isEqualToString:UIWindowDragType])
    {
        // Draw a window
        var windowRect = CGRectInset(bounds, 5, 5);
        var titleBarHeight = 10;

        // Draw the title bar
        var titleBarRect = CGRectMake(windowRect.origin.x, windowRect.origin.y, windowRect.size.width, titleBarHeight);
        [[CPColor grayColor] set];
        [CPBezierPath fillRect:titleBarRect];

        // Draw the content area
        var contentRect = CGRectMake(windowRect.origin.x, windowRect.origin.y + titleBarHeight, windowRect.size.width, windowRect.size.height - titleBarHeight);
        [[CPColor whiteColor] set];
        [CPBezierPath fillRect:contentRect];

        // Draw the border for the whole window
        [[CPColor blackColor] set];
        [CPBezierPath strokeRect:windowRect];
    }
    else if ([_dragType isEqualToString:UIButtonDragType])
    {
        // Draw a button
        var buttonRect = CGRectInset(bounds, 8, 10);
        var path = [CPBezierPath bezierPathWithRoundedRect:buttonRect radius:5];
        [[CPColor whiteColor] set];
        [path fill];
        [[CPColor blackColor] set];
        [path stroke];
    }
    else if ([_dragType isEqualToString:UISliderDragType])
    {
        // Draw a slider
        var sliderY = bounds.size.height / 2;
        var path = [CPBezierPath bezierPath];
        [path moveToPoint:CGPointMake(bounds.origin.x + 5, sliderY)];
        [path lineToPoint:CGPointMake(bounds.origin.x + bounds.size.width - 5, sliderY)];
        [[CPColor blackColor] set];
        [path stroke];

        var knobRect = CGRectMake(bounds.size.width / 2 - 5, sliderY - 5, 10, 10);
        var knobPath = [CPBezierPath bezierPathWithOvalInRect:knobRect];
        [[CPColor whiteColor] set];
        [knobPath fill];
        [[CPColor blackColor] set];
        [knobPath stroke];
    }
    else if ([_dragType isEqualToString:UITextFieldDragType])
    {
        // Draw a text field
        var fieldRect = CGRectInset(bounds, 5, 12);
        [[CPColor whiteColor] set];
        [CPBezierPath fillRect:fieldRect];
        [[CPColor blackColor] set];
        [CPBezierPath strokeRect:fieldRect];

        // Draw an I-beam cursor
        var ibeamX = CGRectGetMidX(fieldRect);
        var ibeamY1 = CGRectGetMinY(fieldRect) + 3;
        var ibeamY2 = CGRectGetMaxY(fieldRect) - 3;

        var ibeamPath = [CPBezierPath bezierPath];
        [ibeamPath moveToPoint:CGPointMake(ibeamX, ibeamY1)];
        [ibeamPath lineToPoint:CGPointMake(ibeamX, ibeamY2)];
        [ibeamPath moveToPoint:CGPointMake(ibeamX - 2, ibeamY1)];
        [ibeamPath lineToPoint:CGPointMake(ibeamX + 2, ibeamY1)];
        [ibeamPath moveToPoint:CGPointMake(ibeamX - 2, ibeamY2)];
        [ibeamPath lineToPoint:CGPointMake(ibeamX + 2, ibeamY2)];
        
        [ibeamPath setLineWidth:0.5];
        [[CPColor blackColor] set];
        [ibeamPath stroke];
    }
    else
    {
        // Fallback to original text drawing
        var title = [[_dragType componentsSeparatedByString:@"DragType"] objectAtIndex:0];
        var textAttributes = @{
            CPFontAttributeName: [CPFont systemFontOfSize:10],
            CPForegroundColorAttributeName: [CPColor blackColor]
        };
        var titleSize = [title sizeWithAttributes:textAttributes];
        var titlePoint = CGPointMake(
                                     (bounds.size.width - titleSize.width) / 2.0,
                                     (bounds.size.height - titleSize.height) / 2.0
                                     );
        [title drawAtPoint:titlePoint withAttributes:textAttributes];
    }
}

@end

@implementation AppController : CPObject
{
    CPWindow _window;
    CPPanel _palette;
    UIBuilderController _builderController;
    UICanvasView _canvasView;
    InspectorController _inspectorController;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // 1. Create the main window and canvas
    _window = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    [_window setTitle:@"Cappuccino UI Builder"];
    [_window setAcceptsMouseMovedEvents:YES];

    _canvasView = [[UICanvasView alloc] initWithFrame:[[_window contentView] bounds]];
    [_canvasView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [[_window contentView] addSubview:_canvasView];

    // 2. Create the controllers
    _builderController = [[UIBuilderController alloc] init];

    // 3. Wire everything together
    [_canvasView setDelegate:_builderController];

    // Bind the canvas to the controller's data model. This is the core of the architecture.
    [_canvasView bind:"dataObjects" toObject:_builderController withKeyPath:@"elementsController.arrangedObjects" options:nil];
    [_canvasView bind:"selectionIndexes" toObject:_builderController withKeyPath:@"elementsController.selectionIndexes" options:nil];
    [_canvasView bind:"connections" toObject:_builderController withKeyPath:@"connectionsController.arrangedObjects" options:nil];
    [_canvasView bind:"selectedConnections" toObject:_builderController withKeyPath:@"connectionsController.selectedObjects" options:nil];
    
    [self createPalette];
    [self createInspector];

    // 5. Create the main menu
    var mainMenuBar = [[CPMenu alloc] initWithTitle:@"MainMenu"];
    var editMenuItem = [[CPMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""];


    var editMenu = [[CPMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenu addItem:[CPMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Delete" action:@selector(delete:) keyEquivalent:@""];

    [editMenuItem setSubmenu:editMenu];

    var fileMenuItem = [[CPMenuItem alloc] initWithTitle:@"File" action:nil keyEquivalent:@""];
    var fileMenu = [[CPMenu alloc] initWithTitle:@"File"];
    [fileMenu addItemWithTitle:@"Run" action:@selector(run:) keyEquivalent:@"r"];
    [fileMenuItem setSubmenu:fileMenu];
    [mainMenuBar addItem:fileMenuItem];

    [mainMenuBar addItem:editMenuItem];

    [CPApp setMainMenu:mainMenuBar];
    [CPMenu setMenuBarVisible:YES];

    [_window makeKeyAndOrderFront:self];
}

- (void)createPalette
{
    var screenWidth = window.innerWidth;
    var paletteWidth = 220;
    var paletteHeight = 60;
    var paletteX = (screenWidth - paletteWidth) / 2;
    var paletteY = 22; // Position near the top of the screen

    _palette = [[CPPanel alloc] initWithContentRect:CGRectMake(paletteX, paletteY, paletteWidth, paletteHeight)
                                          styleMask:CPHUDBackgroundWindowMask | CPTitledWindowMask | CPClosableWindowMask];
    [_palette setTitle:@"Elements"];
    [_palette setFloatingPanel:YES];

    var xPos = 10;
    var types = [UIWindowDragType, UIButtonDragType, UISliderDragType, UITextFieldDragType];

    // Create draggable symbols for each type
    [_canvasView registerForDraggedTypes:types];

    for (var i=0; i < [types count]; i++) {
        var symbol = [[DraggableSymbolView alloc] initWithFrame:CGRectMake(xPos, 10, 40, 40)];
        symbol._dragType = types[i];

        [[_palette contentView] addSubview:symbol];
        xPos += 50;
    }

    [_palette orderFront:self];
}

- (void)createInspector
{
    var inspectorPanel = [[CPPanel alloc] initWithContentRect:CGRectMake(20, 200, 300, 150)
                                                  styleMask:CPTitledWindowMask | CPClosableWindowMask];
    [inspectorPanel setTitle:@"Inspector"];
    [inspectorPanel setFloatingPanel:YES];

    var contentView = [inspectorPanel contentView];

    _inspectorController = [[InspectorController alloc] init];
    [_inspectorController setBuilderController:_builderController];
    [_inspectorController setPanel:inspectorPanel];
    [_inspectorController setView:contentView];

    [_inspectorController awakeFromMarkup]; // Manually call this

    [inspectorPanel orderFront:self];
}

- (void)run:(id)sender
{
    console.log("Run: Starting native UI generation...");
    var canvasSubviews = [_canvasView subviews];
    var nativeElementMap = [CPMutableDictionary dictionary];

    // First pass: create all native elements and map them by their ID
    console.log("Run: Creating native elements and building map...");
    for (var i = 0; i < [canvasSubviews count]; i++)
    {
        var view = [canvasSubviews objectAtIndex:i];
        if ([view isKindOfClass:[UIElementView class]])
        {
            // This will now recursively build the map
            [view nativeUIElementWithMap:nativeElementMap];
        }
    }

    // Second pass: connect the native elements
    console.log("Run: Processing connections...");
    var connections = [[_builderController connectionsController] content];
    for (var i = 0; i < [connections count]; i++)
    {
        var connection = [connections objectAtIndex:i];
        var sourceID = [connection valueForKey:@"sourceID"];
        var targetID = [connection valueForKey:@"targetID"];
        var action = [connection valueForKey:@"action"];

        console.log(" - Connecting: " + sourceID + " -> " + targetID + " (Action: " + action + ")");

        var nativeSource = [nativeElementMap objectForKey:sourceID];
        var nativeTarget = [nativeElementMap objectForKey:targetID];

        if (nativeSource && nativeTarget && action)
        {
            console.log("   - Found native source and target. Applying connection.");
            [nativeSource setTarget:nativeTarget];
            [nativeSource setAction:CPSelectorFromString(action)];
        }
        else
        {
            console.log("   - WARNING: Could not find native source or target for connection.");
        }
    }

    // Third pass: show the windows
    console.log("Run: Showing windows...");
    for (var i = 0; i < [canvasSubviews count]; i++)
    {
        var view = [canvasSubviews objectAtIndex:i];
        if ([view isKindOfClass:[UIWindowView class]])
        {
            var elementID = [[view dataObject] valueForKey:@"id"];
            var nativeWindow = [nativeElementMap objectForKey:elementID];
            if (nativeWindow)
            {
                console.log(" - Showing window for ID: " + elementID);
                [nativeWindow makeKeyAndOrderFront:self];
            }
        }
    }
    console.log("Run: Finished.");
}

@end
