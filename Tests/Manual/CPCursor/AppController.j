@import <Foundation/CPObject.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPCursor.j>

@implementation CursorTester : CPView
{ 
    CPCursor testCursor;
    CPTextField label;
}

- (id)initWithText:(CPString)aLabel
            origin:(CGPoint)anOrigin
            cursor:(CPCursor)aCursor
{
    self = [super init];
    if (self)
    {
        testCursor = aCursor;
        label = [CPTextField labelWithTitle:aLabel];
        [label setBackgroundColor:[CPColor redColor]];
        [label setTextColor:[CPColor whiteColor]];
        [self addSubview:label];
        [self setFrame:CGRectMake(anOrigin.x,
                                  anOrigin.y,
                                  [label frame].size.width,
                                  [label frame].size.height)];
    }
    return self;
}

- (void)mouseEntered:(CPEvent)anEvent
{
    [testCursor set];
}

- (void)mouseExited:(CPEvent)anEvent
{
    [[CPCursor arrowCursor] set];
}
@end



@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    [theWindow setAcceptsMouseMovedEvents:YES];
    var contentView = [theWindow contentView],
    	x = 20,
    	y = 20,
    	yInc = 25,
        imageCursorTester = [[CursorTester alloc] initWithText:@"Image cursor"
                                                        origin:CGPointMake(x, y)
                                                        cursor:[[CPCursor alloc] initWithImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] resourcePath] + @"spinner.gif"] 
                                                                                       hotSpot:CGPointMakeZero()]],
        arrowCursorTester = [[CursorTester alloc] initWithText:@"Arrow cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor arrowCursor]],
        crosshairCursorTester = [[CursorTester alloc] initWithText:@"Crosshair cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor crosshairCursor]],
        IBeamCursorTester = [[CursorTester alloc] initWithText:@"IBeam cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor IBeamCursor]],
        pointingHandCursorTester = [[CursorTester alloc] initWithText:@"Pointing hand cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor pointingHandCursor]],
        resizeDownCursorTester = [[CursorTester alloc] initWithText:@"Resize down cursor"
                                                        origin:CGPointMake(x, y+=yInc)
														cursor:[CPCursor resizeDownCursor]],
        resizeUpCursorTester = [[CursorTester alloc] initWithText:@"Resize up cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor resizeUpCursor]],
        resizeLeftCursorTester = [[CursorTester alloc] initWithText:@"Resize left cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor resizeLeftCursor]],
        resizeRightCursorTester = [[CursorTester alloc] initWithText:@"Resize right cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor resizeRightCursor]],
        resizeLeftRightCursorTester = [[CursorTester alloc] initWithText:@"Resize left-right cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor resizeLeftRightCursor]],
        resizeUpDownCursorTester = [[CursorTester alloc] initWithText:@"Resize up-down cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor resizeUpDownCursor]],
        operationNotAllowedCursorTester = [[CursorTester alloc] initWithText:@"Operation not allowed cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor operationNotAllowedCursor]],
        dragCopyCursorTester = [[CursorTester alloc] initWithText:@"Drag copy cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor dragCopyCursor]],
        dragLinkCursorTester = [[CursorTester alloc] initWithText:@"Drag link cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor dragLinkCursor]],
        contextualMenuCursorTester = [[CursorTester alloc] initWithText:@"Contextual menu cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor contextualMenuCursor]],
        openHandCursorTester = [[CursorTester alloc] initWithText:@"Open hand cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor openHandCursor]],
        closedHandCursorTester = [[CursorTester alloc] initWithText:@"Closed hand cursor"
                                                        origin:CGPointMake(x, y+=yInc)
                                                        cursor:[CPCursor closedHandCursor]],
        disappearingItemCursorTester = [[CursorTester alloc] initWithText:@"Disappearing item cursor"
                                                        origin:CGPointMake(x, y+=yInc)
 													    cursor:[CPCursor disappearingItemCursor]];
        
    [contentView addSubview:imageCursorTester];
    [contentView addSubview:arrowCursorTester];
    [contentView addSubview:crosshairCursorTester];
    [contentView addSubview:IBeamCursorTester];
    [contentView addSubview:pointingHandCursorTester];
    [contentView addSubview:resizeDownCursorTester];
    [contentView addSubview:resizeUpCursorTester];
    [contentView addSubview:resizeLeftCursorTester];
    [contentView addSubview:resizeRightCursorTester];
    [contentView addSubview:resizeLeftRightCursorTester];
    [contentView addSubview:resizeUpDownCursorTester];
    [contentView addSubview:operationNotAllowedCursorTester];
    [contentView addSubview:dragCopyCursorTester];
    [contentView addSubview:dragLinkCursorTester];
    [contentView addSubview:contextualMenuCursorTester];
    [contentView addSubview:openHandCursorTester];
    [contentView addSubview:closedHandCursorTester];
    [contentView addSubview:disappearingItemCursorTester];

    [theWindow orderFront:self];
}

@end
