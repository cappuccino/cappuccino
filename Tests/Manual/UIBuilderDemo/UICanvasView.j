//
//  UICanvasView.j
//  A full-window canvas for the UI Builder.
//
//  By Daniel Boehringer in 2025.
//  - It acts as a drag-and-drop destination for new UI elements from the palette.
//  - It correctly instantiates different UIElementView subclasses based on the data model.
//

@import "UIBuilderConstants.j";
@import "UIElementView.j";
@import "ConnectionView.j";
@import "UIBuilderConstants.j";

function treshold(value, limit)
{
    return value > 0 ? Math.min(value, limit) : Math.max(value, -limit);
}

@implementation UICanvasView : CPView <CPMenuDelegate>
{
    // Data binding ivars
    id                  _dataObjectsContainer;
    CPString            _dataObjectsKeyPath;
    id                  _selectionIndexesContainer;
    CPString            _selectionIndexesKeyPath;
    CPArray             _oldDataObjects;

    // Connections ivars
    id                  _connectionsContainer;
    CPString            _connectionsKeyPath;
    CPArray             _oldConnections;
    id                  _selectedConnectionsContainer;
    CPString            _selectedConnectionsKeyPath;

    // Rubber-band selection ivars
    CGPoint             _rubberStart;
    CGPoint             _rubberEnd;
    BOOL                _isRubbing;
    
    ConnectionView      _connectionView;
    
    id                  _delegate;

    // Connection Menu ivars
    UIElementView       _connectionSource;
    UIElementView       _connectionTarget;
    BOOL                _connectionMade;
}

-(BOOL)acceptsFirstMouse:(CPEvent)aEvent
{
    return YES;
}

// KVO contexts
var _propertyObservationContext = 1091;
var _dataObjectsObservationContext = 1092;
var _selectionIndexesObservationContext = 1093;
var _connectionsObservationContext = 1094;
var _selectedConnectionsObservationContext = 1095;

- (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];

    if (self)
    {
        // Register to accept drops from the palette
        [self registerForDraggedTypes:[
            UIWindowDragType,
            UIButtonDragType,
            UISliderDragType,
            UITextFieldDragType
        ]];

        _connectionView = [[ConnectionView alloc] initWithFrame:[self bounds]];
        [_connectionView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [self addSubview:_connectionView];
    }
    return self;
}

#pragma mark - Bindings & KVO (Largely from EFLaceView)

+ (void)initialize
{
    [self exposeBinding:"dataObjects"];
    [self exposeBinding:@"selectionIndexes"];
    [self exposeBinding:@"connections"];
    [self exposeBinding:@"selectedConnections"];
}

- (void)bind:(CPString)bindingName toObject:(id)observableObject withKeyPath:(CPString)observableKeyPath options:(CPDictionary)options
{
    if ([bindingName isEqualToString:@"dataObjects"])
    {
        _dataObjectsContainer = observableObject;
        _dataObjectsKeyPath = observableKeyPath;
        [_dataObjectsContainer addObserver:self forKeyPath:_dataObjectsKeyPath options:(CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld) context:_dataObjectsObservationContext];
        [self startObservingDataObjects:[self dataObjects]];
        _oldDataObjects = [[self dataObjects] copy] || @[];
    }
    else if ([bindingName isEqualToString:@"selectionIndexes"])
    {
        _selectionIndexesContainer = observableObject;
        _selectionIndexesKeyPath = observableKeyPath;
        [_selectionIndexesContainer addObserver:self forKeyPath:_selectionIndexesKeyPath options:CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld context:_selectionIndexesObservationContext];
    }
    else if ([bindingName isEqualToString:@"connections"])
    {
        _connectionsContainer = observableObject;
        _connectionsKeyPath = observableKeyPath;
        [_connectionsContainer addObserver:self forKeyPath:_connectionsKeyPath options:(CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld) context:_connectionsObservationContext];
        _oldConnections = [[self connections] copy] || @[];
    }
    else if ([bindingName isEqualToString:@"selectedConnections"])
    {
        _selectedConnectionsContainer = observableObject;
        _selectedConnectionsKeyPath = observableKeyPath;
        [_selectedConnectionsContainer addObserver:self forKeyPath:_selectedConnectionsKeyPath options:CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld context:_selectedConnectionsObservationContext];
    }
    else { [super bind:bindingName toObject:observableObject withKeyPath:observableKeyPath options:options]; }

    [self setNeedsDisplay:YES];
}

- (void)unbind:(CPString)bindingName
{
    if ([bindingName isEqualToString:@"dataObjects"]) {
        [self stopObservingDataObjects:[self dataObjects]];
        [_dataObjectsContainer removeObserver:self forKeyPath:_dataObjectsKeyPath];
        _dataObjectsContainer = nil; _dataObjectsKeyPath = nil;
    } else if ([bindingName isEqualToString:@"selectionIndexes"]) {
        [_selectionIndexesContainer removeObserver:self forKeyPath:_selectionIndexesKeyPath];
        _selectionIndexesContainer = nil; _selectionIndexesKeyPath = nil;
    } else if ([bindingName isEqualToString:@"connections"]) {
        [_connectionsContainer removeObserver:self forKeyPath:_connectionsKeyPath];
        _connectionsContainer = nil; _connectionsKeyPath = nil;
    } else if ([bindingName isEqualToString:@"selectedConnections"]) {
        [_selectedConnectionsContainer removeObserver:self forKeyPath:_selectedConnectionsKeyPath];
        _selectedConnectionsContainer = nil; _selectedConnectionsKeyPath = nil;
    } else { [super unbind:bindingName]; }
    [self setNeedsDisplay:YES];
}

- (CPArray)dataObjects
{
    var result = [_dataObjectsContainer valueForKeyPath:_dataObjectsKeyPath];
    return (result == [CPNull null]) ? @[] : result;
}

- (CPIndexSet)selectionIndexes
{
    return [_selectionIndexesContainer valueForKeyPath:_selectionIndexesKeyPath];
}

- (CPArray)connections
{
    var result = [_connectionsContainer valueForKeyPath:_connectionsKeyPath];
    return (result == [CPNull null]) ? @[] : result;
}

- (CPArray)selectedConnections
{
    var result = [_selectedConnectionsContainer valueForKeyPath:_selectedConnectionsKeyPath];
    return (result == [CPNull null]) ? @[] : result;
}

- (void)setSelectionIndexes:(CPIndexSet)indexes
{
    [_selectionIndexesContainer setValue:indexes forKeyPath:_selectionIndexesKeyPath];
}

- (void)startObservingDataObjects:(CPArray)dataObjects
{
    if (!dataObjects || dataObjects == [CPNull null])
        return;

    for (var i = 0;  i < [dataObjects count]; i++)
    {
        var newDataObject =  dataObjects[i];
        // Only create views for top-level objects. Children are handled by their parents.
        if (![newDataObject valueForKey:@"parentID"])
            [self _createViewForDataObject:newDataObject superview:self];
    }
}

- (void)_createViewForDataObject:(CPDictionary)dataObject superview:(CPView)superview
{
    var type = [dataObject valueForKey:@"type"];
    var newView;

    // Instantiate the correct view based on the data model's 'type'
    if (type === "window")
        newView = [[UIWindowView alloc] init];
    else if (type === "button")
        newView = [[UIButtonView alloc] init];
    else if (type === "slider")
        newView = [[UISliderView alloc] init];
    else if (type === "textfield")
        newView = [[UITextFieldView alloc] init];
    else
        newView = [[UIElementView alloc] init]; // Fallback

    [newView setDataObject:dataObject];

    // Bind view properties to the data model
    [newView bind:@"originX" toObject:dataObject withKeyPath:@"originX" options:nil];
    [newView bind:@"originY" toObject:dataObject withKeyPath:@"originY" options:nil];
    [newView bind:@"width" toObject:dataObject withKeyPath:@"width" options:nil];
    [newView bind:@"height" toObject:dataObject withKeyPath:@"height" options:nil];

    if (type === "window")
    {
        var children = [dataObject valueForKey:@"children"];
        for (var j = 0; j < [children count]; j++)
        {
            [self _createViewForDataObject:children[j] superview:newView];
        }
    }

    [superview addSubview:newView];
    // i have no idea why this is needed, but it is to make the initial click work
    [CPApp._delegate._window makeKeyAndOrderFront:self];
}

- (void)stopObservingDataObjects:(CPArray)dataObjects
{
    if (!dataObjects || dataObjects == [CPNull null]) return;

    var viewsToRemove = [CPMutableArray array];
    [self _findViewsForDataObjects:dataObjects inView:self foundViews:viewsToRemove];
    
    for (var i = 0; i < [viewsToRemove count]; i++) {
        var viewToRemove = viewsToRemove[i];
        [self _removeViewAndChildren:viewToRemove];
    }
}

- (void)_removeViewAndChildren:(UIElementView)viewToRemove
{
    // Unbind everything before removing
    [viewToRemove unbind:@"value"];
    [viewToRemove unbind:@"originX"];
    [viewToRemove unbind:@"originY"];
    [viewToRemove unbind:@"width"];
    [viewToRemove unbind:@"height"];

    var subviews = [[viewToRemove subviews] copy];
    for (var i = 0; i < [subviews count]; i++)
    {
        [self _removeViewAndChildren:subviews[i]];
    }

    [viewToRemove removeFromSuperview];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (context == _dataObjectsObservationContext)
    {
        var newDataObjects = [object valueForKeyPath:_dataObjectsKeyPath];
        var oldDataObjects = _oldDataObjects;

        var added = [newDataObjects mutableCopy];
        [added removeObjectsInArray:oldDataObjects];
        [self startObservingDataObjects:added];

        var removed = [oldDataObjects mutableCopy];
        [removed removeObjectsInArray:newDataObjects];
        [self stopObservingDataObjects:removed];

        _oldDataObjects = [newDataObjects copy];
        [self setNeedsDisplay:YES];
    }
    else if (context == _selectionIndexesObservationContext)
    {
        var allDataObjects = [self dataObjects];
        var newIndexes = [change objectForKey:CPKeyValueChangeNewKey] || [CPIndexSet indexSet];
        var oldIndexes = [change objectForKey:CPKeyValueChangeOldKey] || [CPIndexSet indexSet];

        // Find views for newly selected objects and redraw them
        var newSelectedDataObjects = [allDataObjects objectsAtIndexes:newIndexes];
        var newlySelectedViews = [CPMutableArray array];
        [self _findViewsForDataObjects:newSelectedDataObjects inView:self foundViews:newlySelectedViews];
        [newlySelectedViews makeObjectsPerformSelector:@selector(setNeedsDisplay:) withObject:YES];

        // Find views for deselected objects and redraw them, but only if those objects still exist.
        var previouslySelectedViews = [CPMutableArray array];
        var oldSelectedDataObjects = [CPMutableArray array];
        var lastIndex = [oldIndexes lastIndex];

        if (lastIndex != CPNotFound && lastIndex < [allDataObjects count])
        {
             oldSelectedDataObjects = [allDataObjects objectsAtIndexes:oldIndexes];
        }
        else
        {
            // If the indexes are out of bounds, it likely means the objects were deleted.
            // We need to find the views that were associated with the old indexes another way.
            // This is a tricky state to recover from. For now, we will just redraw all views.
            // A more sophisticated solution might involve caching view-data relationships.
            [[self subviews] makeObjectsPerformSelector:@selector(setNeedsDisplay:) withObject:YES];
            return;
        }

        [self _findViewsForDataObjects:oldSelectedDataObjects inView:self foundViews:previouslySelectedViews];
        [previouslySelectedViews makeObjectsPerformSelector:@selector(setNeedsDisplay:) withObject:YES];
    }
    else if (context == _connectionsObservationContext)
    {
        var newConnections = [object valueForKeyPath:_connectionsKeyPath];
        var oldConnections = _oldConnections;

        // For now, simply redraw all connections. A more optimized approach would be to only redraw changed connections.
        [self setNeedsDisplay:YES];
        _oldConnections = [newConnections copy];
    }
    else if (context == _selectedConnectionsObservationContext)
    {
        [self setNeedsDisplay:YES];
    }
}

#pragma mark - Drawing & Mouse

- (void)drawRect:(CPRect)rect
{
    // === START: Infographic Drawing ===

    var bounds = [self bounds];

    // 1. Define text attributes for the infographic
    var titleFont = [CPFont fontWithName:@"Helvetica-Bold" size:36];
    var subtitleFont = [CPFont fontWithName:@"Helvetica" size:18];
    var featureFont = [CPFont fontWithName:@"Helvetica" size:14];
    var watermarkColor = [CPColor colorWithCalibratedWhite:0.85 alpha:1.0]; // A light gray for the watermark effect

    var titleAttributes = @{
        CPFontAttributeName: titleFont,
        CPForegroundColorAttributeName: watermarkColor
    };
    var subtitleAttributes = @{
        CPFontAttributeName: subtitleFont,
        CPForegroundColorAttributeName: watermarkColor
    };
    var featureAttributes = @{
        CPFontAttributeName: featureFont,
        CPForegroundColorAttributeName: watermarkColor
    };

    // 2. Prepare the text content
    var title = @"Cappuccino JS";
    var subtitle = @"Desktop-Quality Applications in the Browser";
    var features = [
        @"• Drag-and-Drop UI Creation",
        @"• Direct Manipulation: Move & Resize (Keyboard / Mouse)",
        @"• Undo/Redo & Keyboard Navigation",
        @"• Control-Draggin  -> Target-Action & Outlet Connections",
        @"• Context sensitive inspector panel",
        @"• Run the 'real thing' in a separate native window",
        @"• Source: https://github.com/daboe01/UIBuilder"

    ];

    // 3. Calculate positions and draw the text, centering it on the canvas
    var titleSize = [title sizeWithAttributes:titleAttributes];
    var subtitleSize = [subtitle sizeWithAttributes:subtitleAttributes];
    var totalHeight = titleSize.height + subtitleSize.height + ([features count] * 20) + 40; // Approximate total height
    var currentY = (bounds.size.height - totalHeight) / 2.0;

    // Draw Title
    var titlePoint = CGPointMake((bounds.size.width - titleSize.width) / 2.0, currentY);
    [title drawAtPoint:titlePoint withAttributes:titleAttributes];
    currentY += titleSize.height + 10;

    // Draw Subtitle
    var subtitlePoint = CGPointMake((bounds.size.width - subtitleSize.width) / 2.0, currentY);
    [subtitle drawAtPoint:subtitlePoint withAttributes:subtitleAttributes];
    currentY += subtitleSize.height + 30;

    // Draw Feature List
    for (var i = 0; i < [features count]; i++) {
        var feature = features[i];
        var featureSize = [feature sizeWithAttributes:featureAttributes];
        var featurePoint = CGPointMake((bounds.size.width - featureSize.width) / 2.0, currentY);
        [feature drawAtPoint:featurePoint withAttributes:featureAttributes];
        currentY += featureSize.height + 5;
    }

    // === END: Infographic Drawing ===

    // The background is drawn by the window. We only draw the rubber-band.
    if (_isRubbing)
    {
        var rubber = CGRectUnion(CGRectMake(_rubberStart.x, _rubberStart.y, 0.1, 0.1), CGRectMake(_rubberEnd.x, _rubberEnd.y, 0.1, 0.1));
        [[[[CPColor alternateSelectedControlColor] colorWithAlphaComponent:0.2] setFill]];
        [CPBezierPath fillRect:rubber];
        [[CPColor alternateSelectedControlColor] setStroke];
        [CPBezierPath setDefaultLineWidth:1.0];
        [CPBezierPath strokeRect:rubber];
    }

    // Draw existing connections that are selected in the connections controller.
    var selectedConnections = [self selectedConnections];

    if (selectedConnections && [selectedConnections count] > 0)
    {
        for (var i = 0; i < [selectedConnections count]; i++)
        {
            var connection = [selectedConnections objectAtIndex:i];
            var sourceID = [connection valueForKey:@"sourceID"];
            var targetID = [connection valueForKey:@"targetID"];
            var sourceView = [self viewForElementWithID:sourceID];
            var targetView = [self viewForElementWithID:targetID];

            if (sourceView && targetView)
            {
                var startPoint = [sourceView convertPoint:CGPointMake(CGRectGetMidX([sourceView bounds]), CGRectGetMidY([sourceView bounds])) toView:self];
                var endPoint;
                var connectionPoint = [connection valueForKey:@"atPoint"];

                if (connectionPoint) {
                    endPoint = CGPointMake(connectionPoint.x, connectionPoint.y);
                } else {
                    endPoint = [targetView convertPoint:CGPointMake(CGRectGetMidX([targetView bounds]), CGRectGetMidY([targetView bounds])) toView:self];
                }

                // Draw the link with a distinct color, like blue.
                [self drawLinkFrom:startPoint to:endPoint color:[CPColor blueColor]];
            }
        }
    }
}

- (void)drawLinkFrom:(CGPoint)startPoint to:(CGPoint)endPoint color:(CPColor)insideColor
{

    var dist = Math.sqrt(Math.pow(startPoint.x - endPoint.x, 2) + Math.pow(startPoint.y - endPoint.y, 2));

    // a lace is made of an outside gray line of width 5, and a inside insideColor(ed) line of width 3
    var p0 = CGPointMake(startPoint.x, startPoint.y);
    var p3 = CGPointMake(endPoint.x, endPoint.y);

    var p1 = CGPointMake(startPoint.x + treshold((endPoint.x - startPoint.x) / 2, 50), startPoint.y);
    var p2 = CGPointMake(endPoint.x -   treshold((endPoint.x - startPoint.x) / 2, 50), endPoint.y);

    // p0 and p1 are on the same horizontal line
    // distance between p0 and p1 is set with the treshold fuction
    // the same holds for p2 and p3

    var path = [CPBezierPath bezierPath];
    [path setLineWidth:0];
    [[CPColor grayColor] set];
    [path appendBezierPathWithOvalInRect:CGRectMake(startPoint.x-2.5,startPoint.y-2.5,5,5)];
    [path fill];

    path = [CPBezierPath bezierPath];
    [path setLineWidth:0];
    [insideColor set];
    [path appendBezierPathWithOvalInRect:CGRectMake(startPoint.x-1.5,startPoint.y-1.5,3,3)];
    [path fill];

    path = [CPBezierPath bezierPath];
    [path setLineWidth:0];
    [[CPColor grayColor] set];
    [path appendBezierPathWithOvalInRect:CGRectMake(endPoint.x-2.5,endPoint.y-2.5,5,5)];
    [path fill];

    path = [CPBezierPath bezierPath];
    [path setLineWidth:0];
    [insideColor set];
    [path appendBezierPathWithOvalInRect:CGRectMake(endPoint.x-1.5,endPoint.y-1.5,3,3)];
    [path fill];

    // if the line is rather short, draw a straight line. the curve would look rather odd in this case.
    if (dist < 40)
    {
        path = [CPBezierPath bezierPath];
        [path setLineWidth:5];
        [path moveToPoint:startPoint];
        [path lineToPoint:endPoint];
        [[CPColor grayColor] set];
        [path stroke];

        path = [CPBezierPath bezierPath];
        [path setLineWidth:3];
        [path moveToPoint:startPoint];
        [path lineToPoint:endPoint];
        [insideColor set];
        [path stroke];

        return;
    }

    path = [CPBezierPath bezierPath];
    [path setLineWidth:5];
    [path moveToPoint:p0];
    [path curveToPoint:p3 controlPoint1:p1 controlPoint2:p2];
    [[CPColor grayColor] set];
    [path stroke];

    path = [CPBezierPath bezierPath];
    [path setLineWidth:3];
    [path moveToPoint:p0];
    [path curveToPoint:p3 controlPoint1:p1 controlPoint2:p2];
    [insideColor set];
    [path stroke];
}

#pragma mark - View Lookup

// Private recursive helper method to search the entire view hierarchy.
- (UIElementView)_findViewForElementWithID:(CPString)elementID inView:(CPView)aView
{
    // Iterate through all subviews of the current view
    var subviews = [aView subviews];
    for (var i = 0; i < [subviews count]; i++)
    {
        var subview = subviews[i];

        // We are only interested in UIElementView subclasses
        if (![subview isKindOfClass:[UIElementView class]])
            continue;

        // 1. Check if the current subview is the one we are looking for.
        if ([[subview dataObject] valueForKey:@"id"] === elementID)
        {
            return subview; // Found it!
        }

        // 2. If not, and this subview has children, recurse into it.
        //    This is the key step to search inside containers like UIWindowView.
        if ([[subview subviews] count] > 0)
        {
            var foundView = [self _findViewForElementWithID:elementID inView:subview];
            if (foundView)
            {
                return foundView; // Found it in a nested hierarchy.
            }
        }
    }

    // If we've searched this entire branch and found nothing, return nil.
    return nil;
}

// Public method to start the search from the canvas itself.
- (UIElementView)viewForElementWithID:(CPString)elementID
{
    if (!elementID)
        return nil;

    // Start the recursive search from the top-level canvas view.
    return [self _findViewForElementWithID:elementID inView:self];
}

- (void)drawConnectionFrom:(CGPoint)startPoint to:(CGPoint)endPoint
{
    [_connectionView setStartPoint:startPoint];
    [_connectionView setEndPoint:endPoint];
    [_connectionView setHidden:NO]; // Ensure it's visible when drawing
    [self addSubview:_connectionView]; // Bring to front
    [_connectionView setNeedsDisplay:YES];
}

- (void)clearConnection
{
    [_connectionView setHidden:YES];
    [_connectionView setNeedsDisplay:YES]; // Request redraw to clear old line
}

- (UIElementView)viewAtPoint:(CGPoint)aPoint
{
    return [self _findDeepestUIElementViewAtPoint:aPoint inView:self];
}

- (UIElementView)_findDeepestUIElementViewAtPoint:(CGPoint)aPoint inView:(CPView)currentView
{
    // Iterate through subviews in reverse order to get the topmost view
    for (var i = [[currentView subviews] count] - 1; i >= 0; i--)
    {
        var subview = [[currentView subviews] objectAtIndex:i];
        
        // Convert the point to the subview's coordinate system
        var localPoint = [subview convertPoint:aPoint fromView:currentView];

        if ([subview isKindOfClass:[UIElementView class]])
        {
            if (CGRectContainsPoint([subview bounds], localPoint))
            {
                // If this is a container view, recursively search its subviews
                if (subview._isContainer)
                {
                    var deepestView = [self _findDeepestUIElementViewAtPoint:localPoint inView:subview];

                    if (deepestView)
                        return deepestView;
                }
                // If not a container, or no deeper view found, return this view
                return subview;
            }
        }
    }

    return nil;
}

- (void)mouseDown:(CPEvent)theEvent
{
    if (_connectionSource)
    {
        [self menuDidEndTracking:nil];
        return;
    }
    // A click on the canvas background starts a rubber-band selection.
    [self deselectViews];
    _isRubbing = YES;
    _rubberStart = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    _rubberEnd = _rubberStart;

    [CPApp setTarget:self selector:@selector(_dragOpenSpaceWithEvent:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)_dragOpenSpaceWithEvent:(CPEvent)theEvent
{
    var mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    _rubberEnd = mouseLoc;
    var rubberRect = CGRectUnion(CGRectMake(_rubberStart.x, _rubberStart.y, 1, 1), CGRectMake(_rubberEnd.x, _rubberEnd.y, 1, 1));
    
    switch ([theEvent type])
    {
        case CPLeftMouseDragged:
            var indexesToSelect = [CPMutableIndexSet indexSet];
            var allDataObjects = [self dataObjects];
            for (var i = 0; i < [[self subviews] count]; i++) {
                var aView = [self subviews][i];
                if ([aView isKindOfClass:[UIElementView class]] && CGRectIntersectsRect([aView frame], rubberRect)) {
                    var dataIndex = [allDataObjects indexOfObject:[aView dataObject]];
                    if (dataIndex != CPNotFound) {
                        [indexesToSelect addIndex:dataIndex];
                    }
                }
            }
            [_selectionIndexesContainer setValue:indexesToSelect forKeyPath:_selectionIndexesKeyPath];
            [self setNeedsDisplay:YES];
            [CPApp setTarget:self selector:@selector(_dragOpenSpaceWithEvent:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
            break;
        
        case CPLeftMouseUp:
            _isRubbing = NO;
            [self setNeedsDisplay:YES];
            break;
    }
}

- (void)delete:(id)sender
{
    // Forward the delete action to the delegate/controller
    if (_delegate && [_delegate respondsToSelector:@selector(removeSelectedElements)]) {
        [_delegate removeSelectedElements];
    }
}

- (void)cut:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(cut:)]) {
        [_delegate cut:sender];
    }
}

- (void)copy:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(copy:)]) {
        [_delegate copy:sender];
    }
}

- (void)paste:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(paste:)]) {
        [_delegate paste:sender];
    }
}

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];

    if ([self window])
    {
        [[self window] makeFirstResponder:self];
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

/*
- (BOOL)validateMenuItem:(CPMenuItem)aMenuItem
{
    var action = [aMenuItem action];

    if (action == @selector(copy:) || action == @selector(cut:) || action == @selector(delete:))
    {
        return [[self selectionIndexes] count] > 0;
    }

    if (action == @selector(paste:))
    {
        return [[[CPPasteboard generalPasteboard] types] containsObject:UIBuilderElementPboardType];
    }

    if (action == @selector(createTargetActionConnection:) || action == @selector(createOutletConnection:))
    {
        return YES;
    }

    var undoManager = [[self window] undoManager];

    if (action == @selector(undo:))
    {
        return [undoManager canUndo];
    }

    if (action == @selector(redo:))
    {
        return [undoManager canRedo];
    }

    return [super validateMenuItem:aMenuItem];
}
*/

- (void)keyDown:(CPEvent)theEvent
{
    var characters = [theEvent characters];
    var flags = [theEvent modifierFlags];
    var selectors = [CPKeyBinding selectorsForKey:characters modifierFlags:flags];
    var delegate = [self delegate];
    var handled = NO;

    if (selectors && delegate)
    {
        for (var i = 0; i < [selectors count]; i++)
        {
            var selectorName = selectors[i];
            if ([delegate respondsToSelector:selectorName])
            {
                [delegate performSelector:selectorName withObject:self];
                handled = YES;
                break;
            }
        }
    }

    if (!handled)
        [super keyDown:theEvent];
}

#pragma mark - Drag and Drop Destination

- (CPDragOperation)draggingEntered:(CPDraggingInfo)sender
{
    // We accept any of the registered types
    return CPDragOperationCopy;
}

- (BOOL)performDragOperation:(CPDraggingInfo)sender
{
    var dropPoint = [self convertPoint:[sender draggingLocation] fromView:nil];
    var pasteboard = [sender draggingPasteboard];
    var types = [pasteboard types];
    var draggedType = types[0]; // Assuming only one type is being dragged
    var elementType;

    if      (draggedType === UIWindowDragType) elementType = "window";
    else if (draggedType === UIButtonDragType) elementType = "button";
    else if (draggedType === UISliderDragType) elementType = "slider";
    else if (draggedType === UITextFieldDragType) elementType = "textfield";

    if (elementType && _delegate)
    {
        if (elementType === "window") {
            if ([_delegate respondsToSelector:@selector(addNewElementOfType:atPoint:)])
            {
                [_delegate addNewElementOfType:elementType atPoint:dropPoint];
                [self setNeedsDisplay:YES];
                return YES;
            }
        } else {
            if ([_delegate respondsToSelector:@selector(addNewElementOfType:inNewWindowAtPoint:)])
            {
                [_delegate addNewElementOfType:elementType inNewWindowAtPoint:dropPoint];
                [self setNeedsDisplay:YES];
                return YES;
            }
        }
    }

    return NO;
}

#pragma mark - Delegate & Selection Management

- (id)delegate { return _delegate; }
- (void)setDelegate:(id)newDelegate { _delegate = newDelegate; }

- (void)deselectViews
{
    [_selectionIndexesContainer setValue:nil forKeyPath:_selectionIndexesKeyPath];
}

- (void)selectView:(UIElementView)aView state:(BOOL)select
{
    var selection = [[self selectionIndexes] mutableCopy] || [CPMutableIndexSet indexSet];
    var dataObjectIndex = [[self dataObjects] indexOfObject:[aView dataObject]];

    

    if (dataObjectIndex != CPNotFound)
    {
        if (select)
            [selection addIndex:dataObjectIndex];

        else [selection removeIndex:dataObjectIndex];
    }
    
    [_selectionIndexesContainer setValue:selection forKeyPath:_selectionIndexesKeyPath];
}

- (CPArray)selectedSubViews
{
    var selectedDataObjects = [[self dataObjects] objectsAtIndexes:[self selectionIndexes]];
    var selectedViews = [CPMutableArray array];

    [self _findViewsForDataObjects:selectedDataObjects inView:self foundViews:selectedViews];

    return selectedViews;
}

- (BOOL)isViewSelected:(CPView)aView
{
    var selected = [self selectedSubViews];

    return [selected containsObject:aView];
}

- (void)_findViewsForDataObjects:(CPArray)dataObjects inView:(CPView)aView foundViews:(CPMutableArray)foundViews
{
    var subviews = [aView subviews];

    for (var i = 0; i < [subviews count]; i++)
    {
        var subview = subviews[i];

        // Skip the connection view and any other non-UIElementView instances
        if (![subview isKindOfClass:[UIElementView class]])
            continue;

        var contains = [dataObjects containsObject:[subview dataObject]];

        if (contains)
        {
            [foundViews addObject:subview];
        }

        // Recurse into subviews
        [self _findViewsForDataObjects:dataObjects inView:subview foundViews:foundViews];
    }
}

// These methods are called by the UIElementView children to notify the controller
- (void)elementDidMove:(UIElementView)anElement
{
    if (_delegate && [_delegate respondsToSelector:@selector(canvasView:didMoveElement:)]) {
        [_delegate canvasView:self didMoveElement:anElement];
    }
}

- (void)elementDidResize:(UIElementView)anElement
{
    if (_delegate && [_delegate respondsToSelector:@selector(canvasView:didResizeElement:)]) {
        [_delegate canvasView:self didResizeElement:anElement];
    }
}

- (void)elementDidConnect:(UIElementView)sourceElement to:(UIElementView)targetElement atPoint:(CGPoint)aPoint
{
    if (_delegate && [_delegate respondsToSelector:@selector(canvasView:didConnectElement:toElement:atPoint:)]) {
        [_delegate canvasView:self didConnectElement:sourceElement toElement:targetElement atPoint:aPoint];
    }
}

#pragma mark - Connection Menu

- (void)showConnectionMenuForSource:(UIElementView)sourceView target:(UIElementView)targetView at:(CGPoint)aPoint
{
    _connectionSource = sourceView;
    _connectionTarget = targetView;
    _connectionMade = NO;

    var menu = [[CPMenu alloc] initWithTitle:@"Connection Menu"];
    [menu setDelegate:self];

    // 1. Add Target's Actions
    var targetActions = [[_connectionTarget dataObject] valueForKey:@"actions"];
    if (targetActions && [targetActions length] > 0)
    {
        var actionsArray = [targetActions componentsSeparatedByString:@", "];
        for (var i = 0; i < [actionsArray count]; i++)
        {
            var actionName = actionsArray[i];
            var menuItem = [[CPMenuItem alloc] initWithTitle:actionName action:@selector(createTargetActionConnection:) keyEquivalent:@""];
            [menu addItem:menuItem];
        }
    }

    // 2. Add Separator
    if ([menu numberOfItems] > 0)
        [menu addItem:[CPMenuItem separatorItem]];

    // 3. Add Source's Outlets
    var sourceOutlets = [[_connectionSource dataObject] valueForKey:@"outlets"];
    if (sourceOutlets && [sourceOutlets length] > 0)
    {
        var outletsArray = [sourceOutlets componentsSeparatedByString:@", "];
        for (var i = 0; i < [outletsArray count]; i++)
        {
            var outletName = outletsArray[i];
            if (outletName === @"target") continue; // Skip 'target' outlet as requested
            var menuItem = [[CPMenuItem alloc] initWithTitle:outletName action:@selector(createOutletConnection:) keyEquivalent:@""];
            [menu addItem:menuItem];
        }
    }

    if ([menu numberOfItems] > 0)
    {
        [CPMenu popUpContextMenu:menu withEvent:[CPApp currentEvent] forView:self];
    }
    else
    {
        [self menuDidEndTracking:menu]; // No items, so clean up immediately
    }
}

- (void)createTargetActionConnection:(CPMenuItem)sender
{
    var actionName = [sender title];
    if (_delegate && [_delegate respondsToSelector:@selector(canvasView:didConnectElement:toElement:asTargetAction:)])
    {
        _connectionMade = YES;
        [self clearConnection];
        if (_connectionTarget)
            [_connectionTarget setAsDropTarget:NO];

        [_delegate canvasView:self didConnectElement:_connectionSource toElement:_connectionTarget asTargetAction:actionName];
    }
}

- (void)createOutletConnection:(CPMenuItem)sender
{
    var outletName = [sender title];
    if (_delegate && [_delegate respondsToSelector:@selector(canvasView:didConnectElement:toElement:asOutlet:)])
    {
        _connectionMade = YES;
        [self clearConnection];
        if (_connectionTarget)
            [_connectionTarget setAsDropTarget:NO];

        [_delegate canvasView:self didConnectElement:_connectionSource toElement:_connectionTarget asOutlet:outletName];
    }
}

- (void)menuDidEndTracking:(CPMenu)aMenu
{
    // This delegate method is called after a menu item is selected OR the menu is cancelled.
    if (!_connectionMade)
    {
        [self clearConnection];
        if (_connectionTarget)
            [_connectionTarget setAsDropTarget:NO];
    }

    // Reset state
    _connectionSource = nil;
    _connectionTarget = nil;
    _connectionMade = NO;

    [self setNeedsDisplay:YES];
}

@end
