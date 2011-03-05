@import <Foundation/CPObject.j>

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
        imageCursorTester = [[CursorTester alloc] initWithText:@"Image cursor"
                                                        origin:CGPointMake(0, 0)
                                                        cursor:[[CPCursor alloc] initWithImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPCursor class]] resourcePath] + @"/CPCursor/openHandCursor.cur"] 
                                                                                       hotSpot:CGPointMakeZero()]],
        arrowCursorTester = [[CursorTester alloc] initWithText:@"Arrow cursor"
                                                        origin:CGPointMake(0, 20)
                                                        cursor:[CPCursor arrowCursor]],
        crosshairCursorTester = [[CursorTester alloc] initWithText:@"Crosshair cursor"
                                                            origin:CGPointMake(0, 40)
                                                            cursor:[CPCursor crosshairCursor]]
        IBeamCursorTester = [[CursorTester alloc] initWithText:@"IBeam cursor"
                                                        origin:CGPointMake(0, 60)
                                                        cursor:[CPCursor IBeamCursor]],
        pointingHandCursorTester = [[CursorTester alloc] initWithText:@"Pointing hand cursor"
                                                               origin:CGPointMake(0, 80)
                                                               cursor:[CPCursor pointingHandCursor]],
        resizeDownCursorTester = [[CursorTester alloc] initWithText:@"Resize down cursor"
                                                             origin:CGPointMake(0, 100)
                                                             cursor:[CPCursor resizeDownCursor]],
        resizeUpCursorTester = [[CursorTester alloc] initWithText:@"Resize up cursor"
                                                           origin:CGPointMake(0, 120)
                                                        cursor:[CPCursor resizeUpCursor]],
        resizeLeftCursorTester = [[CursorTester alloc] initWithText:@"Resize left cursor"
                                                             origin:CGPointMake(0, 140)
                                                             cursor:[CPCursor resizeLeftCursor]],
        resizeRightCursorTester = [[CursorTester alloc] initWithText:@"Resize right cursor"
                                                              origin:CGPointMake(0, 160)
                                                              cursor:[CPCursor resizeRightCursor]],
        resizeLeftRightCursorTester = [[CursorTester alloc] initWithText:@"Resize left-right cursor"
                                                                  origin:CGPointMake(0, 180)
                                                                  cursor:[CPCursor resizeLeftRightCursor]],
        resizeUpDownCursorTester = [[CursorTester alloc] initWithText:@"Resize up-down cursor"
                                                               origin:CGPointMake(0, 200)
                                                               cursor:[CPCursor resizeUpDownCursor]],
        operationNotAllowedCursorTester = [[CursorTester alloc] initWithText:@"Operation not allowed cursor"
                                                                      origin:CGPointMake(0, 220)
                                                                      cursor:[CPCursor operationNotAllowedCursor]],
        dragCopyCursorTester = [[CursorTester alloc] initWithText:@"Drag copy cursor"
                                                           origin:CGPointMake(0, 240)
                                                           cursor:[CPCursor dragCopyCursor]],
        dragLinkCursorTester = [[CursorTester alloc] initWithText:@"Drag link cursor"
                                                           origin:CGPointMake(0, 260)
                                                           cursor:[CPCursor dragLinkCursor]],
        contextualMenuCursorTester = [[CursorTester alloc] initWithText:@"Contextual menu cursor"
                                                                 origin:CGPointMake(0, 280)
                                                                 cursor:[CPCursor contextualMenuCursor]],
        openHandCursorTester = [[CursorTester alloc] initWithText:@"Open hand cursor"
                                                           origin:CGPointMake(0, 300)
                                                        cursor:[CPCursor openHandCursor]],
        closedHandCursorTester = [[CursorTester alloc] initWithText:@"Closed hand cursor"
                                                             origin:CGPointMake(0, 320)
                                                             cursor:[CPCursor closedHandCursor]],
        disappearingItemCursorTester = [[CursorTester alloc] initWithText:@"Disappearing item cursor"
                                                                   origin:CGPointMake(0, 340)
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
