@import <OJUnit/OJTestCase.j>

#include "../../AppKit/Platform/DOM/CPDOMDisplayServer.h"

@implementation CPDOMDisplayServerTest : OJTestCase
{
    JSObject DOMElement;
    BOOL     aTransform;
}

- (void)setUp
{
    // set up a dummy DOM element.
    DOMElement = {
        style: {
        }
    };

    aTransform = NO;
}

- (void)testSetStyleRightBottom
{
    var aRight = 10,
        aBottom = 10;

    CPDOMDisplayServerSetStyleRightBottom(DOMElement, aTransform, aRight, aBottom);
    [self assert:DOMElement.style.right equals:"10px"];
    [self assert:DOMElement.style.bottom equals:"10px"];
}

- (void)testSetStyleLeftBottom
{
    var aLeft = 10,
        aBottom = 10;

    CPDOMDisplayServerSetStyleLeftBottom(DOMElement, aTransform, aLeft, aBottom);

    [self assert:DOMElement.style.bottom equals:"10px"];
    [self assert:DOMElement.style.left equals:"10px"];

}

- (void)testSetStyleLeftTop
{
    var aTop = 10,
        aLeft = 10;

    CPDOMDisplayServerSetStyleLeftTop(DOMElement, aTransform, aLeft, aTop);

    [self assert:DOMElement.style.top equals:"10px"];
    [self assert:DOMElement.style.left equals:"10px"];
}

- (void)testSetStyleRightTop
{
    var aTop = 10,
        aRight = 10;

    CPDOMDisplayServerSetStyleRightTop(DOMElement, aTransform, aRight, aTop);

    [self assert:DOMElement.style.top equals:"10px"];
    [self assert:DOMElement.style.right equals:"10px"];
}

- (void)testSetStyleWithTransform
{
    aTransform = CGAffineTransformMakeTranslation(10, 10);

    CPDOMDisplayServerSetStyleRightTop(DOMElement, aTransform, 10, 10)

    [self assert:DOMElement.style.top equals:"20px"];
    [self assert:DOMElement.style.right equals:"20px"];
}

- (void)testSetStyleSize
{
    var width = 10,
        height = 10;

    CPDOMDisplayServerSetStyleSize(DOMElement, width, height);

    [self assert:DOMElement.style.width equals:"10px"];
    [self assert:DOMElement.style.height equals:"10px"];
}

- (void)testSetElementSize
{
    var width = 10,
        height = 10;

    CPDOMDisplayServerSetSize(DOMElement, width, height);

    [self assert:DOMElement.width equals:10];
    [self assert:DOMElement.height equals:10];
}

@end