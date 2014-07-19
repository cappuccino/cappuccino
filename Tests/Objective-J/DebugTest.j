var SEEN_MESSAGES = [];

objj_test_decorator = function(msgSend)
{
    return function(aReceiverOrSuper, aSelector)
    {
        if (aSelector === @selector(intify:))
            SEEN_MESSAGES.push([aReceiverOrSuper, aSelector]);
        return msgSend.apply(this, arguments);
    };
}

@implementation TestClass0 : CPObject

- (CPInteger)intify:(CPInteger)anInput
{
    return anInput * 2; // now twice as int
}

@end

@implementation TestClass1 : CPObject

- (CPInteger)intify:(CPInteger)anInput
{
    return anInput * 2; // now twice as int
}

@end


@implementation DebugTest : OJTestCase

- (void)setUp
{
    SEEN_MESSAGES = [];
}

- (void)tearDown
{
    objj_msgSend_reset();
}

- (void)test_objj_msgSend_decorate_should_replace_fast_msgSend_for_unitialised_class
{
    objj_msgSend_decorate(objj_test_decorator);
    var a = [TestClass0 new];
    [self assert:[a intify:3] equals:6];
    [self assert:SEEN_MESSAGES equals:[[a, @selector(intify:)]]];
}

- (void)test_objj_msgSend_decorate_should_replace_fast_msgSend_for_initialised_class
{
    var a = [TestClass1 new];
    [a intify:5];

    objj_msgSend_decorate(objj_test_decorator);
    [self assert:[a intify:3] equals:6];
    [self assert:SEEN_MESSAGES equals:[[a, @selector(intify:)]]];
}

- (void)test_objj_msgSend_reset_should_reset
{
    objj_msgSend_decorate(objj_test_decorator);
    var a = [TestClass1 new];
    [self assert:[a intify:3] equals:6];
    objj_msgSend_reset();
    [self assert:[a intify:3] equals:6];
    [self assert:SEEN_MESSAGES equals:[[a, @selector(intify:)]]];
}

@end
