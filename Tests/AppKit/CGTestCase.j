/*
  Used for comparing geometry forms. Otherwise each unit test would repeat these
  comparisons.
*/
@implementation CGTestCase : OJTestCase

- (void)compareRect:(CGRect)aRect
               with:(id)anotherRect
            message:(CPString)aMsg
{
    aMsg += " (via cmp. rect)";
    [self comparePoint:aRect.origin with:anotherRect.origin message:aMsg];
    [self  compareSize:aRect.size   with:anotherRect.size   message:aMsg];
}

- (void)compareSize:(CGSize)aSize
               with:(id)anotherSize
            message:(CPString)aMsg
{
    [self assert:anotherSize.width  equals:aSize.width  message:aMsg + ": Failed for width"];
    [self assert:anotherSize.height equals:aSize.height message:aMsg + ": Failed for height"];
}

- (void)comparePoint:(CGPoint)aPoint
                with:(id)anotherPoint
             message:(CPString)aMsg
{
    [self assert:anotherPoint.x equals:aPoint.x message:aMsg + ": Failed for x"];
    [self assert:anotherPoint.y equals:aPoint.y message:aMsg + ": Failed for y"];
}

- (void)compareTransform:(CGAffineTransform)aTransform
                    with:(id)aDataSet
                 message:(CPString)aMsg
{
    [self assert:aDataSet.a  equals:aTransform.a  message:aMsg + ": Failed for a"];
    [self assert:aDataSet.b  equals:aTransform.b  message:aMsg + ": Failed for b"];
    [self assert:aDataSet.c  equals:aTransform.c  message:aMsg + ": Failed for c"];
    [self assert:aDataSet.d  equals:aTransform.d  message:aMsg + ": Failed for d"];
    [self assert:aDataSet.tx equals:aTransform.tx message:aMsg + ": Failed for tx"];
    [self assert:aDataSet.ty equals:aTransform.ty message:aMsg + ": Failed for ty"];
}

@end
