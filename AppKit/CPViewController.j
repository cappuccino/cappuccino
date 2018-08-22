/*
 * CPViewController.j
 * AppKit
 *
 * Created by Nicholas Small and Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPArray.j>

@import "CPCib.j"
@import "CPResponder.j"

@class CPDocument

@global CPApp


var CPViewControllerCachedCibs;

/*!
    @ingroup appkit
    @class CPViewController

    The CPViewController class provides the fundamental view-management
    controller for Cappuccino applications. The basic view controller class
    supports the presentation of an associated view in addition to basic
    support for managing modal views and, in the future, animations.
    Subclasses such as CPNavigationController and CPTabBarController provide
    additional behavior for managing complex hierarchies of view controllers
    and views.

    You use each instance of CPViewController to manage a single view (and
    hierarchy). For a simple view controller, this entails managing the view
    hierarchy responsible for presenting your application content. A typical
    view hierarchy consists of a root view, a reference to which is available
    in the view property of this class, and one or more subviews presenting
    the actual content. In the case of navigation and tab bar controllers, the
    view controller manages not only the high-level view hierarchy (which
    provides the navigation controls) but also one or more additional view
    controllers that handle the presentation of the application content.

    Unlike UIViewController in Cocoa Touch, a CPViewController does not
    represent an entire screen of content. You will add your root view to an
    existing view or window's content view. You can manage many view
    controllers on screen at once. CPViewController is also the preferred way
    of working with Cibs.

    Subclasses can override -loadView to create their custom view hierarchy,
    or specify a cib name to be loaded automatically. It has methods that are
    called when a view appears or disappears. This class is also a good place
    for delegate & datasource methods, and other controller stuff.
*/
@implementation CPViewController : CPResponder
{
    CPView          _view @accessors(property=view);
    BOOL            _isLoading;
    BOOL            _isLazy;
    BOOL            _isViewLoaded @accessors(getter=isViewLoaded);

    id              _representedObject @accessors(property=representedObject);
    CPString        _title @accessors(property=title);

    CPString        _cibName @accessors(property=cibName, readonly);
    CPBundle        _cibBundle @accessors(property=cibBundle, readonly);
    CPDictionary    _cibExternalNameTable @accessors(property=cibExternalNameTable, readonly);
}

+ (void)initialize
{
    if (self !== [CPViewController class])
        return;

    CPViewControllerCachedCibs = @{};
}

/*!
    Convenience initializer calls -initWithCibName:bundle: with nil for both parameters.
*/
- (id)init
{
    return [self initWithCibName:nil bundle:nil];
}

- (id)initWithCibName:(CPString)aCibNameOrNil bundle:(CPBundle)aCibBundleOrNil
{
    return [self initWithCibName:aCibNameOrNil bundle:aCibBundleOrNil externalNameTable:nil];
}

- (id)initWithCibName:(CPString)aCibNameOrNil bundle:(CPBundle)aCibBundleOrNil owner:(id)anOwner
{
    return [self initWithCibName:aCibNameOrNil bundle:aCibBundleOrNil externalNameTable:@{ CPCibOwner: anOwner }];
}

/*!
    The designated initializer. If you subclass CPViewController, you must
    call the super implementation of this method, even if you aren't using a
    Cib.

    In the specified Cib, the File's Owner proxy should have its class set to
    your view controller subclass, with the view outlet connected to the main
    view. If you pass in a nil Cib name, then you must either call -setView:
    before -view is invoked, or override -loadView to set up your views.

    @param cibNameOrNil The path to the cib to load for the root view or nil to programmatically create views.
    @param cibBundleOrNil The bundle that the cib is located in or nil for the main bundle.
*/
- (id)initWithCibName:(CPString)aCibNameOrNil bundle:(CPBundle)aCibBundleOrNil externalNameTable:(CPDictionary)anExternalNameTable
{
    self = [super init];

    if (self)
    {
        // Don't load the cib until someone actually requests the view. The user may just be intending to use setView:.
        _cibName = aCibNameOrNil;
        _cibBundle = aCibBundleOrNil || [CPBundle mainBundle];
        _cibExternalNameTable = anExternalNameTable || @{ CPCibOwner: self };

        _isLoading = NO;
        _isLazy = NO;
    }

    return self;
}

/*!
    Programmatically creates the view that the controller manages. You should
    never call this method directly. The view controller calls this method
    when the view property is requested but is nil.

    If you create your views manually, you must override this method and use
    it to create your view and assign it to the view property. The default
    implementation for programmatic views is to create a plain, zero width & height
    view. You can invoke super to utilize this view.

    If you use Interface Builder to create your views, and you initialize the
    controller using the initWithCibName:bundle: methods, then you MUST NOT override
    this method.

    @note When using this method, the cib loading system is synchronous.
    See the loadViewWithCompletionHandler: method for an asynchronous loading.
*/
- (void)loadView
{
    if (_view)
        return;

    if (_cibName)
    {
        // check if a cib is already cached for the current _cibName
        var cib = [CPViewControllerCachedCibs objectForKey:_cibName];

        if (!cib)
        {
            // if the cib isn't cached yet : fetch it and cache it
            cib = [[CPCib alloc] initWithCibNamed:_cibName bundle:_cibBundle];
            [CPViewControllerCachedCibs setObject:cib forKey:_cibName];
        }

        [cib instantiateCibWithExternalNameTable:_cibExternalNameTable];
    }
    else
        _view = [CPView new];
}

/*!
    Asynchronously load the cib and create the view that the controller manages.

    @param aHandler a function which will be passed the loaded view as the first
    argument and a network error or nil as the second argument: function(view, error).

    @note If the view has already been loaded, the completion handler is run immediatly
    and the process is synchronous.
*/
- (void)loadViewWithCompletionHandler:(Function/*(view, error)*/)aHandler
{
    if (_view)
        return;

    if (_cibName)
    {
        // check if a cib is already cached for the current _cibName
        var cib = [CPViewControllerCachedCibs objectForKey:_cibName];

        if (!cib)
        {
            var cibName = _cibName;

            if (![cibName hasSuffix:@".cib"])
                cibName = [cibName stringByAppendingString:@".cib"];

            // If aBundle is nil, use mainBundle, but ONLY for searching for the nib, not for resources later.
            var bundle = _cibBundle || [CPBundle mainBundle],
                url = [bundle _cibPathForResource:cibName];

            // if the cib isn't cached yet : fetch it and cache it
            [CPURLConnection sendAsynchronousRequest:[CPURLRequest requestWithURL:url] queue:[CPOperationQueue mainQueue] completionHandler:function(aResponse, aData, anError)
            {
                if (anError == nil)
                {
                    var data = [CPData dataWithRawString:aData],
                          aCib = [[CPCib alloc] _initWithData:data bundle:_cibBundle cibName:_cibName];

                    [CPViewControllerCachedCibs setObject:aCib forKey:_cibName];
                    [aCib instantiateCibWithExternalNameTable:_cibExternalNameTable];
                    [self _viewDidLoadWithCompletionHandler:aHandler];
                }
                else
                {
                    aHandler(nil, anError);
                }
            }];
        }
        else
        {
            [cib instantiateCibWithExternalNameTable:_cibExternalNameTable];
            [self _viewDidLoadWithCompletionHandler:aHandler];
        }
    }
    else
    {
        _view = [CPView new];
        [self _viewDidLoadWithCompletionHandler:aHandler];
    }
}

/*!
    Returns the view that the controller manages.

    If this property is nil, the controller sends loadView to itself to create
    the view that it manages. Subclasses should override the loadView method
    to create any custom views. The default value is nil.
*/
- (CPView)view
{
    if (!_view)
    {
        _isLoading = YES;

        var cibOwner = [_cibExternalNameTable objectForKey:CPCibOwner];

        if ([cibOwner respondsToSelector:@selector(viewControllerWillLoadCib:)])
            [cibOwner viewControllerWillLoadCib:self];

        [self loadView];

        if (_view === nil && [cibOwner isKindOfClass:[CPDocument class]])
            [self setView:[cibOwner valueForKey:@"view"]];

        if (!_view)
        {
            var reason = [CPString stringWithFormat:@"View for %@ could not be loaded from Cib or no view specified. Override loadView to load the view manually.", self];

            [CPException raise:CPInternalInconsistencyException reason:reason];
        }

        if ([cibOwner respondsToSelector:@selector(viewControllerDidLoadCib:)])
            [cibOwner viewControllerDidLoadCib:self];

        _isLoading = NO;
        _isLazy = NO;
        [self _viewDidLoad];
    }
    else if (_isLazy)
    {
        _isLazy = NO;
        [self _viewDidLoad];
    }

    return _view;
}

- (void)_viewDidLoad
{
    [self willChangeValueForKey:"isViewLoaded"];
    [self viewDidLoad];
    _isViewLoaded = YES;
    [self didChangeValueForKey:"isViewLoaded"];
}

- (void)_viewDidLoadWithCompletionHandler:(Function)aHandler
{
    [self _registerOrUnregister:YES notificationsForView:_view];

    [self willChangeValueForKey:"isViewLoaded"];
    aHandler(_view, nil);
    _isViewLoaded = YES;
    [self didChangeValueForKey:"isViewLoaded"];
}

/*!
    This method is called after the view controller has loaded its associated views into memory.

    This method is called regardless of whether the views were stored in a nib
    file or created programmatically in the loadView method, but NOT when setView
    is invoked. This method is most commonly used to perform additional initialization
    steps on views that are loaded from cib files.
*/
- (void)viewDidLoad
{

}

/*!
    Called after the view controller’s view has been loaded into memory is about to be added to the
    view hierarchy in the window.

    @discussion You can override this method to perform tasks prior to a view controller’s view
    getting added to view hierarchy, such as setting the view’s highlight color. This method is called when:

        • The view is about to be added to the view hierarchy of the view controller

    If you override this method, call this method on super at some point in your implementation in case
    a superclass also overrides this method.

    The default implementation of this method does nothing.
*/
- (void)viewWillAppear
{

}

/*!
    Called when the view controller’s view is fully transitioned onto the screen.

    @discussion This method is called after the completion of any drawing and animations
    involved in the initial appearance of the view. You can override this method to
    perform tasks appropriate for that time, such as work that should not interfere
    with the presentation animation, or starting an animation that you want to begin
    after the view appears.

    If you override this method, call this method on super at some point in your
    implementation in case a superclass also overrides this method.

    The default implementation of this method does nothing.
*/
- (void)viewDidAppear
{

}

/*!
    Called when the view controller’s view is about to be removed from the view hierarchy in the window.

    @discussion You can override this method to perform tasks that are to precede the disappearance
    of the view controller’s view, such as stopping a continuous animation that you
    started in response to the viewDidAppear method call. This method is called when:

        • The view is about to be removed from the view hierarchy of the window

    If you override this method, call this method on super at some point in your
    implementation in case a superclass also overrides this method.

    The default implementation of this method does nothing.
*/
- (void)viewWillDisappear
{

}

/*!
    Called after the view controller’s view is removed from the view hierarchy in a window.

    @discussion You can override this method to perform tasks associated with removing the view
    controller’s view from the window’s view hierarchy, such as releasing resources
    not needed when the view is not visible or no longer part of the window.

    If you override this method, call this method on super at some point in your
    implementation in case a superclass also overrides this method.

    The default implementation of this method does nothing.
*/
- (void)viewDidDisappear
{

}

/*!
    Manually sets the view that the controller manages.

    Setting to nil will cause -loadView to be called on all subsequent calls
    of -view.

    @param aView The view this controller should represent.
*/
- (void)setView:(CPView)aView
{
    var willChangeIsViewLoaded = (_isViewLoaded == NO && aView != nil) || (_isViewLoaded == YES && aView == nil);

    [self _registerOrUnregister:NO notificationsForView:_view];
    [self _registerOrUnregister:YES notificationsForView:aView];

    if (willChangeIsViewLoaded)
        [self willChangeValueForKey:"isViewLoaded"];

    _view = aView;
    _isViewLoaded = aView !== nil;

    if (willChangeIsViewLoaded)
        [self didChangeValueForKey:"isViewLoaded"];
}

- (BOOL)automaticallyNotifiesObserversOfIsViewLoaded
{
    return NO;
}

- (void)_registerOrUnregister:(BOOL)shouldRegister notificationsForView:(CPView)aView
{
    if (aView === nil)
        return;

    var center = [CPNotificationCenter defaultCenter],
        notifs_to_sel = @{_CPViewWillAppearNotification : @"viewWillAppear",
                          _CPViewDidAppearNotification : @"viewDidAppear",
                          _CPViewWillDisappearNotification : @"viewWillDisappear",
                          _CPViewDidDisappearNotification : @"viewDidDisappear"};

    [notifs_to_sel enumerateKeysAndObjectsUsingBlock:function(notif, selString, stop)
    {
        var selector = CPSelectorFromString(selString);
        if ([self implementsSelector:selector])
        {
            if (shouldRegister)
                [center addObserver:self selector:selector name:notif object:aView];
            else
                [center removeObserver:self name:notif object:aView];
        }
    }];
}

@end


var CPViewControllerViewKey     = @"CPViewControllerViewKey",
    CPViewControllerTitleKey    = @"CPViewControllerTitleKey",
    CPViewControllerCibNameKey  = @"CPViewControllerCibNameKey",
    CPViewControllerBundleKey   = @"CPViewControllerBundleKey";

@implementation CPViewController (CPCoding)

/*!
    Initializes the view controller by unarchiving data from a coder.
    @param aCoder the coder from which the data will be unarchived
    @return the initialized view controller
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _view = [aCoder decodeObjectForKey:CPViewControllerViewKey];
        _title = [aCoder decodeObjectForKey:CPViewControllerTitleKey];
        _cibName = [aCoder decodeObjectForKey:CPViewControllerCibNameKey];

        var bundlePath = [aCoder decodeObjectForKey:CPViewControllerBundleKey];
        _cibBundle = bundlePath ? [CPBundle bundleWithPath:bundlePath] : [CPBundle mainBundle];

        _cibExternalNameTable = @{ CPCibOwner: self };
        _isLazy = YES;
    }

    return self;
}

/*!
    Archives the view controller to the provided coder.
    @param aCoder the coder to which the view controller should be archived
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_view forKey:CPViewControllerViewKey];
    [aCoder encodeObject:_title forKey:CPViewControllerTitleKey];
    [aCoder encodeObject:_cibName forKey:CPViewControllerCibNameKey];
    [aCoder encodeObject:[_cibBundle bundlePath] forKey:CPViewControllerBundleKey];
}

@end
