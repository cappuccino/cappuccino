@import "CPView.j"

// A subclass of CPView that is transparent except for its subviews and is
// optimized to not draw unless told
@implementation SCTransparentView : CPView
{ }

- (CPView)hitTest:(CPPoint)aPoint
{
  var hitTestView = [super hitTest:aPoint];
  if (hitTestView === self)
    hitTestView = nil;
  return hitTestView;
}
@end
