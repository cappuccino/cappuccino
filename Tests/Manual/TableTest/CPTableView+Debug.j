
@implementation CPTableView (Patcher)

+ (void)profileViewLoading
{
    after.c = after.t = after.tpr = 0;
    [[self class] patchMethod:@selector(_loadDataViewsInRows:columns:) beforeFunction:before afterFunction:after];
}

@end

var before = function (receiver, selector, args)
{
    before.s = new Date();
};

var after = function(receiver, selector, args)
{
    var d = (new Date() - before.s);
    var rc = [args[0] count];
    if (d > 0 && rc > 0)
    {
        after.t += d;
        after.c ++;
        after.tpr += d/rc;
    }

    console.log (after.c + " _loadDataViewsInRows:columns: " + rc + " rows in " + d + " ms ; avg since start / per row = " + (ROUND(100 * after.tpr/after.c) / 100) + " ms");
};

@implementation CPObject (Patcher)

+ (void)debugMethod:(SEL)aSelector
{
    var before = function (receiver, selector, args)
    {
        CPLogConsole("BEFORE : " + receiver + " " + selector + " " + args);
    };

    var after = function (receiver, selector, args)
    {
        CPLogConsole("AFTER : " + receiver + " " + selector + " " + args);
    };

    [self patchMethod:aSelector beforeFunction:before afterFunction:after];
}

+ (void)patchMethod:(SEL)aSelector beforeFunction:(Function)before afterFunction:(Function)after
{
    if (before == nil) before = function(){}; 
    if (after == nil) after = function(){}; 
    
    var patched_sel = CPSelectorFromString("patched_" + CPStringFromSelector(aSelector));
    class_addMethod(self, patched_sel, function()
    {
        var orig_arguments = arguments,
            receiver = orig_arguments[0],
            cmd = orig_arguments[1];
            
            var args = [];
            for (var i = 2; i < orig_arguments.length; i++)
                args.push(orig_arguments[i]);

        orig_arguments[1] = patched_sel;

        before(receiver, cmd, args);
        objj_msgSend.apply(objj_msgSend, orig_arguments);
        after(receiver, cmd, args);
    }, "");

    Swizzle(self, aSelector, patched_sel);
}

@end

function Swizzle (aClass, orig_sel, new_sel)
{
    var origMethod = class_getInstanceMethod(aClass, orig_sel),
        newMethod = class_getInstanceMethod(aClass, new_sel);

// This check should be in class_addMethod : Don't add and return NO and if method already exists.
    var method_list = aClass.method_list,
        count = method_list.length,
        shouldAddMethod = YES;

    while (count--)
        if (method_list[count].name == orig_sel)
        {
            shouldAddMethod = NO;
            break;
        }

    if (shouldAddMethod)
    {
        class_addMethod(aClass, orig_sel, method_getImplementation(newMethod), "");
        class_replaceMethod(aClass, new_sel, method_getImplementation(origMethod), "");
    }
    else
        method_exchangeImplementations(origMethod, newMethod);
}
