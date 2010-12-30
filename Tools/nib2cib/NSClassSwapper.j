
var NSClassSwapperClassNames                = {},
    NSClassSwapperOriginalClassNames        = {};

var _CPCibClassSwapperClassNameKey          = @"_CPCibClassSwapperClassNameKey",
    _CPCibClassSwapperOriginalClassNameKey  = @"_CPCibClassSwapperOriginalClassNameKey";

@implementation NSClassSwapper : _CPCibClassSwapper
{
}

+ (id)swapperClassForClassName:(CPString)aClassName originalClassName:(CPString)anOriginalClassName
{
    var swapperClassName = "$NSClassSwapper_" + aClassName + "_" + anOriginalClassName,
        swapperClass = objj_lookUpClass(swapperClassName);

    if (!swapperClass)
    {
        var originalClass = objj_lookUpClass(anOriginalClassName);

        swapperClass = objj_allocateClassPair(originalClass, swapperClassName);

        objj_registerClassPair(swapperClass);

        class_addMethod(swapperClass, @selector(initWithCoder:), function(self, _cmd, aCoder)
        {
            self = objj_msgSendSuper({super_class:originalClass, receiver:self}, _cmd, aCoder);

            if (self)
            {
                var UID = [self UID];

                NSClassSwapperClassNames[UID] = aClassName;
                NSClassSwapperOriginalClassNames[UID] = anOriginalClassName;
            }

            return self;
        }, "");

        class_addMethod(swapperClass, @selector(classForKeyedArchiver), function(self, _cmd)
        {
            return [_CPCibClassSwapper class];
        }, "");

        class_addMethod(swapperClass, @selector(encodeWithCoder:), function(self, _cmd, aCoder)
        {
            objj_msgSendSuper({super_class:originalClass, receiver:self}, _cmd, aCoder);

            // FIXME: map class name as well?
            [aCoder encodeObject:aClassName forKey:_CPCibClassSwapperClassNameKey];
            [aCoder encodeObject:CP_NSMapClassName(anOriginalClassName) forKey:_CPCibClassSwapperOriginalClassNameKey];
        }, "");
    }

    return swapperClass;
}

+ (id)allocWithCoder:(CPCoder)aCoder
{
    var className = [aCoder decodeObjectForKey:@"NSClassName"],
        originalClassName = [aCoder decodeObjectForKey:@"NSOriginalClassName"];

    return [[self swapperClassForClassName:className originalClassName:originalClassName] alloc];
}

@end
