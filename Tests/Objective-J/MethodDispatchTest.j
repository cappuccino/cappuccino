
@import <Foundation/Foundation.j>


@implementation RootClass
{
}

+ (id)alloc
{
    return class_createInstance(self);
}

@end

@implementation RootClassWithInitialize
{
}

+ (id)alloc
{
    return class_createInstance(self);
}

+ (void)initialize
{
    throw "Initialize";
}

@end

@implementation RootClassWithInitialize2
{
}

+ (id)alloc
{
    return class_createInstance(self);
}

+ (void)initialize
{
    throw "Initialize";
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
    throw "ERROR: " + sel_getName(aSelector);
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
        [self assert:anException equals:"RootClass does not implement doesNotRecognizeSelector: when sending doesNotExist. Did you forget a superclass for RootClass?"];
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
        [self assert:anException equals:"RootClass does not implement doesNotRecognizeSelector: when sending doesNotExist. Did you forget a superclass for RootClass?"];
    }
}
- (void)test_RootClassWithInitialize_class_initialize
{
    try
    {
        [RootClassWithInitialize doesNotExist];
    }
    catch (anException)
    {
        [self assert:anException equals:"Initialize"];
    }
}

- (void)test_RootClassWithInitialize_instance_initialize
{
    // Here we create a new instance with Runtime function to not trigger the +initialize method.
    // We also have to use a fresh new class or the +initialize method would have already been triggered.
    var object = class_createInstance(RootClassWithInitialize2);

    try
    {
        [object doesNotExist];
    }
    catch (anException)
    {
        [self assert:anException equals:"Initialize"];
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
        [self assert:anException equals:"ERROR: doesNotExist"];
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
        [self assert:anException equals:"ERROR: doesNotExist"];
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
