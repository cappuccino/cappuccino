
@import <Foundation/Foundation.j>


@implementation RootClass
{
}

+ (id)alloc
{
    return class_createInstance(self);
}

@end

@implementation RootClassWithDoesNotRecognizeSelector
{
}

+ (id)alloc
{
    return class_createInstance(self);
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    throw "ERROR";
}

@end

@implementation Subclass : CPObject
{
}

@end

@implementation RootClassWithForwardingTarget
{
    Class isa;
}

+ (void)initialize
{
}

+ (id)alloc
{
    return class_createInstance(self);
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (aSelector !== @selector(doesNotExist))
        return nil;

    if (class_isMetaClass(isa))
        return GlobalMethodDispatchTest;

    return GlobalMethodDispatchTest;
}

@end

@implementation SubclassWithForwardingTarget : CPObject
{
}

+ (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (aSelector !== @selector(doesNotExist))
        return [super forwardingTargetForSelector:aSelector];

    return GlobalMethodDispatchTest;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (aSelector !== @selector(doesNotExist))
        return [super forwardingTargetForSelector:aSelector];

    return GlobalMethodDispatchTest;
}

@end

@implementation RootClassWithForwardInvocation
{
}

+ (void)initialize
{
}

+ (id)alloc
{
    return class_createInstance(self);
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    if (aSelector === @selector(doesNotExist))
        return 1;

    return nil;
}

- (void)forwardInvocation:(CPInvocation)anInvocation
{
    [anInvocation setTarget:GlobalMethodDispatchTest];
    [anInvocation invoke];
}

@end

@implementation SubclassWithForwardInvocation : CPObject
{
}

+ (CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    if (aSelector === @selector(doesNotExist))
        return 1;

    return nil;
}

+ (void)forwardInvocation:(CPInvocation)anInvocation
{
    [anInvocation setTarget:GlobalMethodDispatchTest];
    [anInvocation invoke];
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    if (aSelector === @selector(doesNotExist))
        return 1;

    return nil;
}

- (void)forwardInvocation:(CPInvocation)anInvocation
{
    [anInvocation setTarget:GlobalMethodDispatchTest];
    [anInvocation invoke];
}

@end

var GlobalMethodDispatchTest;

@implementation MethodDispatchTest : OJTestCase
{
}

- (id)init
{
    self = [super init];

    if (self)
        GlobalMethodDispatchTest = self;

    return self;
}

- (BOOL)doesNotExist
{
    return YES;
}

- (void)test_RootClass_class_doesNotRecognizeSelector_
{
    try
    {
        [RootClass doesNotExist];
    }
    catch (anException)
    {
        [self assert:anException equals:"RootClass does not implement doesNotRecognizeSelector:. Did you forget a superclass for RootClass?"];
    }
}

- (void)test_RootClass_instance_doesNotRecognizeSelector_
{
    var object = [RootClass alloc];

    try
    {
        [object doesNotExist];
    }
    catch (anException)
    {
        [self assert:anException equals:"RootClass does not implement doesNotRecognizeSelector:. Did you forget a superclass for RootClass?"];
    }
}

- (void)test_RootClassWithDoesNotRecognizeSelector_class_doesNotRecognizeSelector_
{
    try
    {
        [RootClassWithDoesNotRecognizeSelector doesNotExist];
    }
    catch (anException)
    {
        [self assert:anException equals:"ERROR"];
    }
}

- (void)test_RootClassWithDoesNotRecognizeSelector_instance_doesNotRecognizeSelector_
{
    var object = [RootClassWithDoesNotRecognizeSelector alloc];

    try
    {
        [object doesNotExist];
    }
    catch (anException)
    {
        [self assert:anException equals:"ERROR"];
    }
}

- (void)test_CPObject_class_doesNotRecognizeSelector_
{
    try
    {
        [CPObject doesNotExist];
    }
    catch (anException)
    {
        [self assert:[anException name] equals:CPInvalidArgumentException];
        [self assert:[anException reason] equals:@"+ [CPObject doesNotExist] unrecognized selector sent to class CPObject"];
    }
}

- (void)test_CPObject_instance_doesNotRecognizeSelector_
{
    var object = [CPObject alloc];

    try
    {
        [object doesNotExist];
    }
    catch (anException)
    {
        [self assert:[anException name] equals:CPInvalidArgumentException];
        [self assert:[anException reason] equals:@"- [CPObject doesNotExist] unrecognized selector sent to instance 0x" + [CPString stringWithHash:[object UID]]];
    }
}

- (void)test_Subclass_class_doesNotRecognizeSelector_
{
    try
    {
        [Subclass doesNotExist];
    }
    catch (anException)
    {
        [self assert:[anException name] equals:CPInvalidArgumentException];
        [self assert:[anException reason] equals:@"+ [Subclass doesNotExist] unrecognized selector sent to class Subclass"];
    }
}

- (void)test_Subclass_instance_doesNotRecognizeSelector_
{
    var object = [Subclass alloc];

    try
    {
        [object doesNotExist];
    }
    catch (anException)
    {
        [self assert:[anException name] equals:CPInvalidArgumentException];
        [self assert:[anException reason] equals:@"- [Subclass doesNotExist] unrecognized selector sent to instance 0x" + [CPString stringWithHash:[object UID]]];
    }
}

- (void)test_RootClassWithForwardingTarget_class_forwardingTargetForSelector_
{
    [self assert:YES equals:[RootClassWithForwardingTarget doesNotExist]];
}

- (void)test_RootClassWithForwardingTarget_instance_forwardingTargetForSelector_
{
    var object = [RootClassWithForwardingTarget alloc];

    [self assert:YES equals:[object doesNotExist]];
}

- (void)test_SubclassWithForwardingTarget_class_forwardingTargetForSelector_
{
    [self assert:YES equals:[SubclassWithForwardingTarget doesNotExist]];
}

- (void)test_SubclassWithForwardingTarget_instance_forwardingTargetForSelector_
{
    var object = [[SubclassWithForwardingTarget alloc] init];

    [self assert:YES equals:[object doesNotExist]];
}

- (void)test_RootClassWithForwardInvocation_class_forwardInvocation_
{
    [self assert:YES equals:[RootClassWithForwardInvocation doesNotExist]];
}

- (void)test_RootClassWithForwardInvocation_instance_forwardInvocation_
{
    var object = [RootClassWithForwardInvocation alloc];

    [self assert:YES equals:[object doesNotExist]];
}

- (void)test_SubclassWithForwardInvocation_class_forwardInvocation_
{
    [self assert:YES equals:[SubclassWithForwardInvocation doesNotExist]];
}

- (void)test_SubclassWithForwardInvocation_instance_forwardInvocation_
{
    var object = [[SubclassWithForwardInvocation alloc] init];

    [self assert:YES equals:[object doesNotExist]];
}

@end
