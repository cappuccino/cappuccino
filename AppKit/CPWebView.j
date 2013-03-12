/*
 * CPWebView.j
 * AppKit
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
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

@import "CPView.j"
@import "CPScrollView.j"


// FIXME: implement these where possible:
/*
CPWebViewDidBeginEditingNotification            = "CPWebViewDidBeginEditingNotification";
CPWebViewDidChangeNotification                  = "CPWebViewDidChangeNotification";
CPWebViewDidChangeSelectionNotification         = "CPWebViewDidChangeSelectionNotification";
CPWebViewDidChangeTypingStyleNotification       = "CPWebViewDidChangeTypingStyleNotification";
CPWebViewDidEndEditingNotification              = "CPWebViewDidEndEditingNotification";
CPWebViewProgressEstimateChangedNotification    = "CPWebViewProgressEstimateChangedNotification";
*/
CPWebViewProgressStartedNotification            = "CPWebViewProgressStartedNotification";
CPWebViewProgressFinishedNotification           = "CPWebViewProgressFinishedNotification";

/*!
    Automatically choose between AppKit (Cappuccino style) scrollbars and
    native scrollbars. In this mode AppKit scrollbars are always used except
    when the web view is loaded with a URL which does not appear to pass the
    same origin policy.
*/
CPWebViewScrollAuto                             = 0;
/*!
    Always use AppKit scrollbars. If a URL is loaded whcih does not appear to
    pass the same origin policy, native scrollbars will be used but a warnning
    will be logged.
*/
CPWebViewScrollAppKit                           = 1;
/*!
    Always use native (platform dependent) scrollbars.
*/
CPWebViewScrollNative                           = 2;
/*!
    Never display scrollbars.
*/
CPWebViewScrollNone                             = 3;

/*!
    How frequently the size of the document will be checked at page load time
    when AppKit scrollbars are used.
*/
CPWebViewAppKitScrollPollInterval               = 1.0;

/*!
    How many times the size of the size of the document will be checked at
    page load time when AppKit scrollbars are used.

    AppKit scrollbars must check the size of the document to display the
    correct size of scrollbars. To improve performance the checks are only
    performed a limited number of times per reload.
*/
CPWebViewAppKitScrollMaxPollCount                  = 3;

/*!
    @ingroup appkit

    @class CPWebView

    CPWebView allows you to display arbitrary HTML or embed a
    webpage inside your application.

    It's important to note that the same origin policy applies to this view.
    That is, if the web page being displayed is not located in the same origin
    (protocol, domain, and port) as the application, you will have limited
    control over the view and no access to its contents. Furthermore,
    Cappuccino style scrollbars can't be used to scroll it.
*/
@implementation CPWebView : CPView
{
    CPScrollView        _scrollView;
    CPView              _frameView;

    IFrame              _iframe;
    CPString            _mainFrameURL;
    CPArray             _backwardStack;
    CPArray             _forwardStack;

    BOOL                _ignoreLoadStart;
    BOOL                _ignoreLoadEnd;
    BOOL                _isLoading;

    id                  _downloadDelegate;
    id                  _frameLoadDelegate;
    id                  _policyDelegate;
    id                  _resourceLoadDelegate;
    id                  _UIDelegate;

    CPWebScriptObject   _wso;

    CPString            _url;
    CPString            _html;

    Function            _loadCallback;

    int                 _scrollMode;
    int                 _effectiveScrollMode;
    BOOL                _contentIsAccessible;
    CPTimer             _contentSizeCheckTimer;
    int                 _contentSizePollCount;

    int                 _loadHTMLStringTimer;

    BOOL                _drawsBackground;
}

- (id)initWithFrame:(CGRect)frameRect frameName:(CPString)frameName groupName:(CPString)groupName
{
    if (self = [self initWithFrame:frameRect])
    {
        _iframe.name = frameName;
    }

    return self;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _mainFrameURL           = nil;
        _backwardStack          = [];
        _forwardStack           = [];
        _scrollMode             = CPWebViewScrollAuto;
        _contentIsAccessible    = YES;
        _isLoading              = NO;

        _drawsBackground        = YES;

        [self setBackgroundColor:[CPColor whiteColor]];

        [self _initDOMWithFrame:aFrame];
    }

    return self;
}

- (id)_initDOMWithFrame:(CGRect)aFrame
{
    _ignoreLoadStart = YES;
    _ignoreLoadEnd  = YES;

    _iframe = document.createElement("iframe");
    _iframe.name = "iframe_" + FLOOR(RAND() * 10000);
    _iframe.style.width = "100%";
    _iframe.style.height = "100%";
    _iframe.style.borderWidth = "0px";
    _iframe.frameBorder = "0";

    [self _applyBackgroundColor];

    _loadCallback = function()
    {
        // HACK: this block handles the case where we don't know about loads initiated by the user clicking a link
        if (!_ignoreLoadStart)
        {
            // post the start load notification
            [self _startedLoading];

            if (_mainFrameURL)
                [_backwardStack addObject:_mainFrameURL];

            // FIXME: this doesn't actually get the right URL for different domains. Not possible due to browser security restrictions.
            _mainFrameURL = _iframe.src;

            // clear the forward
            [_forwardStack removeAllObjects];
        }
        else
            _ignoreLoadStart = NO;

        if (!_ignoreLoadEnd)
        {
            [self _finishedLoading];
        }
        else
            _ignoreLoadEnd = NO;

        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };

    if (_iframe.addEventListener)
        _iframe.addEventListener("load", _loadCallback, false);
    else if (_iframe.attachEvent)
        _iframe.attachEvent("onload", _loadCallback);

    _frameView = [[CPView alloc] initWithFrame:[self bounds]];
    [_frameView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    _scrollView = [[CPScrollView alloc] initWithFrame:[self bounds]];
    [_scrollView setAutohidesScrollers:YES];
    [_scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_scrollView setDocumentView:_frameView];

    _frameView._DOMElement.appendChild(_iframe);

    [self _updateEffectiveScrollMode];

    [self addSubview:_scrollView];
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    [self _resizeWebFrame];
}

- (void)viewDidUnhide
{
    // Sizing cannot properly happen while we're hidden because the iframe is inaccessible.
    // So now that it is accessible again, make sure to catch up.
    [_frameView setFrameSize:[_scrollView contentSize]];
    [self _resizeWebFrame];
    [self _scheduleContentSizeCheck];
}

- (void)_attachScrollEventIfNecessary
{
    if (_effectiveScrollMode !== CPWebViewScrollAppKit)
        return;

    var win = [self DOMWindow];

    if (win && win.addEventListener)
    {
        var scrollEventHandler = function(anEvent)
        {
            var frameBounds = [self bounds],
                frameCenter = CGPointMake(CGRectGetMidX(frameBounds), CGRectGetMidY(frameBounds)),
                windowOrigin = [self convertPoint:frameCenter toView:nil],
                globalOrigin = [[self window] convertBaseToBridge:windowOrigin];

            anEvent._overrideLocation = globalOrigin;
            [[[self window] platformWindow] scrollEvent:anEvent];
        };

        win.addEventListener("DOMMouseScroll", scrollEventHandler, false);
        win.addEventListener("wheel", scrollEventHandler, false);
    }
}

- (void)_resizeWebFrame
{
    // When a webview is not in the DOM we can't inspect its contents for sizing information.
    // If we try, we might end up setting the fallback frame size which will then become
    // somewhat sticky.
    if (![self _isVisible])
    {
        return;
    }

    if (_effectiveScrollMode === CPWebViewScrollAppKit)
    {
        var visibleRect = [_frameView visibleRect];
        [_frameView setFrameSize:CGSizeMake(CGRectGetMaxX(visibleRect), CGRectGetMaxY(visibleRect))];

        // try to get the document size so we can correctly set the frame
        var win = [self DOMWindow];

        if (win && win.document && win.document.body)
        {
            var width = win.document.body.scrollWidth,
                height = win.document.body.scrollHeight;

            _iframe.setAttribute("width", width);
            _iframe.setAttribute("height", height);

            [_frameView setFrameSize:CGSizeMake(width, height)];
        }
        else
        {
            // If we do have access to the content, it might be that the 'body' element simply hasn't loaded yet.
            // The size will be updated by the content size timer in this case.
            if (!win || !win.document)
            {
                CPLog.warn("using default size 800*1600");
                [_frameView setFrameSize:CGSizeMake(800, 1600)];
            }
        }

        [_frameView scrollRectToVisible:visibleRect];
    }
}

/*!
    Sets the scroll mode of the receiver.

    Valid values are:
        CPWebViewScrollAuto
        CPWebViewScrollAppKit
        CPWebViewScrollNative
        CPWebViewScrollNone

    CPWebViewScrollAuto
*/
- (void)setScrollMode:(int)aScrollMode
{
    if (_scrollMode == aScrollMode)
        return;

    _scrollMode = aScrollMode;

    [self _updateEffectiveScrollMode];
}

/*!
    Returns the effective scroll mode of the receiver.

    Valied values are:
        CPWebViewScrollAuto
        CPWebViewScrollAppKit
        CPWebViewScrollNative
        CPWebViewScrollNone
*/
- (int)effectiveScrollMode
{
    return _effectiveScrollMode;
}

- (void)_updateEffectiveScrollMode
{
    var _newScrollMode = CPWebViewScrollAppKit;

    if (_scrollMode == CPWebViewScrollNative
        || (_scrollMode == CPWebViewScrollAuto && !_contentIsAccessible)
        || CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
    {
        _newScrollMode = CPWebViewScrollNative;
    }
    else if (_scrollMode == CPWebViewScrollAppKit && !_contentIsAccessible)
    {
        // Same behaviour as the previous case except that a warning is logged when AppKit
        // scrollers can't be used.
        CPLog.warn(self + " unable to use CPWebViewScrollAppKit scroll mode due to same origin policy.");
        _newScrollMode = CPWebViewScrollNative;
    }

    if (_newScrollMode !== _effectiveScrollMode)
        [self _setEffectiveScrollMode:_newScrollMode];
}

- (void)_setEffectiveScrollMode:(int)aScrollMode
{
    _effectiveScrollMode = aScrollMode;

    _ignoreLoadStart = YES;
    _ignoreLoadEnd  = YES;

    var parent = _iframe.parentNode;
    // FIXME "scrolling" can't be changed without readding the iframe. Unfortunately this causes a reload.
    parent.removeChild(_iframe);

    if (_effectiveScrollMode === CPWebViewScrollAppKit)
    {
        [_scrollView setHasHorizontalScroller:YES];
        [_scrollView setHasVerticalScroller:YES];

        _iframe.setAttribute("scrolling", "no");
    }
    else if (_effectiveScrollMode === CPWebViewScrollNone)
    {
        [_scrollView setHasHorizontalScroller:NO];
        [_scrollView setHasVerticalScroller:NO];

        _iframe.setAttribute("scrolling", "no");
    }
    else
    {
        [_scrollView setHasHorizontalScroller:NO];
        [_scrollView setHasVerticalScroller:NO];

        _iframe.setAttribute("scrolling", "auto");

        [_frameView setFrameSize:[_scrollView bounds].size];
    }

    parent.appendChild(_iframe);
    [self _applyBackgroundColor];

    [self _resizeWebFrame];
}

- (void)_maybePollWebFrameSize
{
    if (CPWebViewAppKitScrollMaxPollCount == 0 || _contentSizePollCount++ < CPWebViewAppKitScrollMaxPollCount)
        [self _resizeWebFrame];
    else
        [_contentSizeCheckTimer invalidate];
}

/*!
    Loads a string of HTML into the receiver.

    @param CPString - The string to load.
*/
- (void)loadHTMLString:(CPString)aString
{
    [self loadHTMLString:aString baseURL:nil];
}

/*!
    Loads a string of HTML into the receiver.

    @param CPString - The string to load.
    @param CPURL - The base url of the string. (not implemented)
*/
- (void)loadHTMLString:(CPString)aString baseURL:(CPURL)URL
{
    // FIXME: do something with baseURL?
    [_frameView setFrameSize:[_scrollView contentSize]];

    [self _startedLoading];

    _ignoreLoadStart = YES;

    _url = nil;
    _html = aString;

    [self _load];
}

- (void)_loadMainFrameURL
{
    [self _startedLoading];

    _ignoreLoadStart = YES;

    _url = _mainFrameURL;
    _html = nil;

    [self _load];
}

- (void)_load
{
    if (_url)
    {
        // Try to figure out if this URL will pass the same origin policy and hence allow us to potentially
        // use appkit scrollbars.
        var cpurl = [CPURL URLWithString:_url];
        _contentIsAccessible = [cpurl _passesSameOriginPolicy];
        [self _updateEffectiveScrollMode];

        _ignoreLoadEnd = NO;

        _iframe.src = _url;
    }
    else if (_html !== nil)
    {
        // clear the iframe
        _iframe.src = "";

        _contentIsAccessible = YES;
        [self _updateEffectiveScrollMode];

        _ignoreLoadEnd = NO;

        if (_loadHTMLStringTimer !== nil)
        {
            window.clearTimeout(_loadHTMLStringTimer);
            _loadHTMLStringTimer = nil;
        }

        // need to give the browser a chance to reset iframe, otherwise we'll be document.write()-ing the previous document
        _loadHTMLStringTimer = window.setTimeout(function()
        {
            var win = [self DOMWindow];

            /*
            If _html is the empty string, subtitute in an empty HTML structure. Just leaving the contents entirely empty prompts the browser to subtitute in a white page which would interfere with any custom background colours in use by this web view.
            */
            if (win)
                win.document.write(_html || "<html><body></body></html>");

            window.setTimeout(_loadCallback, 1);
        }, 0);
    }
}

- (void)_startedLoading
{
    _isLoading = YES;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWebViewProgressStartedNotification object:self];

    if ([_frameLoadDelegate respondsToSelector:@selector(webView:didStartProvisionalLoadForFrame:)])
        [_frameLoadDelegate webView:self didStartProvisionalLoadForFrame:nil]; // FIXME: give this a frame somehow?
}

- (void)_finishedLoading
{
    _isLoading = NO;

    [self _resizeWebFrame];
    [self _attachScrollEventIfNecessary];

    [self _scheduleContentSizeCheck];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWebViewProgressFinishedNotification object:self];

    if ([_frameLoadDelegate respondsToSelector:@selector(webView:didFinishLoadForFrame:)])
        [_frameLoadDelegate webView:self didFinishLoadForFrame:nil]; // FIXME: give this a frame somehow?
}

- (void)_scheduleContentSizeCheck
{
    [_contentSizeCheckTimer invalidate];
    if (_effectiveScrollMode == CPWebViewScrollAppKit)
    {
        /*
        FIXME Need better method.
        We don't know when the content of the iframe changes size (e.g. a
        picture finishes loading, dynamic content is loaded). Often when a
        page has initially 'loaded', it does not yet have its final size. In
        lieu of any resize events we will simply check back in a few times
        some time after loading.

        We run these checks only a limited number of times as to not deplete
        battery life and slow down the software needlessly. This does mean
        there are situations where the content changes size and the AppKit
        scrollbars will be out of sync. Users who have dynamic content
        in their web view will, for now, have to implement domain specific
        fixes.
        */

        _contentSizePollCount = 0;
        _contentSizeCheckTimer = [CPTimer scheduledTimerWithTimeInterval:CPWebViewAppKitScrollPollInterval target:self selector:@selector(_maybePollWebFrameSize) userInfo:nil repeats:YES];
    }
}

/*!
    Returns whether the web view is loading. Note: due to browser limitations
    this value is not particularly reliable.
*/
- (BOOL)isLoading
{
    return _isLoading;
}

/*!
    Returns the URL of the main frame.

    @return CPString - The URL of the main frame.
*/
- (CPString)mainFrameURL
{
    return _mainFrameURL;
}

/*!
    Sets the URL of the main frame.

    @param CPString - the url to set.
*/
- (void)setMainFrameURL:(CPString)URLString
{
    if (_mainFrameURL)
        [_backwardStack addObject:_mainFrameURL];

    _mainFrameURL = URLString;
    [_forwardStack removeAllObjects];

    [self _loadMainFrameURL];
}

/*!
    Tells the webview to navigate to the previous page.

    @return BOOL - YES if the receiver was able to go back, otherwise NO.
*/
- (BOOL)goBack
{
    if (_backwardStack.length > 0)
    {
        if (_mainFrameURL)
            [_forwardStack addObject:_mainFrameURL];

        _mainFrameURL = [_backwardStack lastObject];
        [_backwardStack removeLastObject];

        [self _loadMainFrameURL];

        return YES;
    }

    return NO;
}

/*!
    Tells the receiver to go forward in page history.

    @return - YES if the receiver was able to go forward, otherwise NO.
*/
- (BOOL)goForward
{
    if (_forwardStack.length > 0)
    {
        if (_mainFrameURL)
            [_backwardStack addObject:_mainFrameURL];

        _mainFrameURL = [_forwardStack lastObject];
        [_forwardStack removeLastObject];

        [self _loadMainFrameURL];

        return YES;
    }

    return NO;
}

/*!
    Checks to see if the webview has a history stack you can navigate back
    through.

    @return BOOL - YES if the receiver can navigate backward through history, otherwise NO.
*/
- (BOOL)canGoBack
{
    return (_backwardStack.length > 0);
}

/*!
    Checks to see if the webview has a history stack you can navigate forward
    through.

    @return BOOL - YES if the receiver can navigate forward through history, otherwise NO.
*/
- (BOOL)canGoForward
{
    return (_forwardStack.length > 0);
}

- (WebBackForwardList)backForwardList
{
    // FIXME: return a real WebBackForwardList?
    return { back: _backwardStack, forward: _forwardStack };
}

/*!
    Closes the webview by unloading the webpage. The webview will no longer
    respond to load requests or delegate methods once this is called.
*/
- (void)close
{
    _iframe.parentNode.removeChild(_iframe);
}

/*!
    Returns the window object of the webview.

    @return DOMWindow - The window object.
*/
- (DOMWindow)DOMWindow
{
    try
    {
        return (_iframe.contentDocument && _iframe.contentDocument.defaultView) || _iframe.contentWindow;
    }
    catch (e)
    {
        return nil;
    }
}

/*!
    Returns the root Object of the webview as a CPWebScriptObject.

    @return CPWebScriptObject - the Object of the webview.
*/
- (CPWebScriptObject)windowScriptObject
{
    var win = [self DOMWindow];

    if (!_wso || win != [_wso window])
    {
        if (win)
            _wso = [[CPWebScriptObject alloc] initWithWindow:win];
        else
            _wso = nil;
    }

    return _wso;
}

/*!
    Evaluates a javascript string in the webview and returns the result of
    that evaluation as a string.

    @param script - A string of javascript.
    @return CPString - The result of the evaluation.
*/
- (CPString)stringByEvaluatingJavaScriptFromString:(CPString)script
{
    var result = [self objectByEvaluatingJavaScriptFromString:script];
    return result ? String(result) : nil;
}

/*!
    Evaluates a string of javascript in the webview and returns the result.

    @param script - A string of javascript.
    @return JSObject - A JSObject resulting from the evaluation.
*/
- (JSObject)objectByEvaluatingJavaScriptFromString:(CPString)script
{
    return [[self windowScriptObject] evaluateWebScript:script];
}

/*!
    Gets the computed style for an element.

    @param DOMElement - An Element.
    @param pseudoElement - A pseudoElement.
    @return DOMCSSStyleDeclaration - The computed style for an element.
*/
- (DOMCSSStyleDeclaration)computedStyleForElement:(DOMElement)element pseudoElement:(CPString)pseudoElement
{
    var win = [[self windowScriptObject] window];

    if (win)
    {
        // FIXME: IE version?
        return win.document.defaultView.getComputedStyle(element, pseudoElement);
    }
    return nil;
}


/*!
    @return BOOL - YES if the webview draws its own background, otherwise NO.
*/
- (BOOL)drawsBackground
{
    return _drawsBackground;
}

/*!
    Sets whether the webview draws its own background when the displayed contents do not.

    If you are trying to create a transparent iframe:

    A) call this method with NO
    A) call setBackground:[CPColor transparent]
    B) ensure the content does not draw a background, e.g. it has <body style="background-color: transparent;">

    @param BOOL - YES if the webview should draw its background, otherwise NO.
*/
- (void)setDrawsBackground:(BOOL)drawsBackground
{
    if (drawsBackground == _drawsBackground)
        return;

    _drawsBackground = drawsBackground;

    [self _applyBackgroundColor];
}

- (void)setBackgroundColor:(CPColor)aColor
{
    [super setBackgroundColor:aColor];
    [self _applyBackgroundColor];
}

- (void)_applyBackgroundColor
{
    if (_iframe)
    {
        var bgColor = [self backgroundColor] || [CPColor whiteColor];
        _iframe.allowtransparency = !_drawsBackground;
        _iframe.style.backgroundColor = _drawsBackground ? [bgColor cssString] : "transparent";
    }
}

// IBActions

/*!
    Used with the target/action mechanism to automatically set the webviews
    mainFrameURL to the senders stringValue.

    @param sender - the sender of the action. Should respond to -stringValue.
*/
- (@action)takeStringURLFrom:(id)sender
{
    [self setMainFrameURL:[sender stringValue]];
}

/*!
    Same as -goBack but takes a sender as a param.

    @param sender - the sender of the action.
*/
- (@action)goBack:(id)sender
{
    [self goBack];
}

/*!
    Same as -goForward but takes a sender as a param.

    @param sender - the sender of the action.
*/
- (@action)goForward:(id)sender
{
    [self goForward];
}

/*!
    Stops loading the webview. (not yet implemented)

    @param sender - the sender of the action.
*/
- (@action)stopLoading:(id)sender
{
    // FIXME: what to do?
}

/*!
    Reloads the webview.

    @param sender - the sender of the action.
*/
- (@action)reload:(id)sender
{
    // If we're displaying pure HTML, redisplay it.
    if (!_url && (_html !== nil))
        [self loadHTMLString:_html];
    else
        [self _loadMainFrameURL];
}

/*!
    Tells the webview to print. If the webview is unable to print due to
    browser restrictions the user is alerted to print from the file menu.

    @param sender - the sender of the receiver.
*/
- (@action)print:(id)sender
{
    try
    {
        [self DOMWindow].print();
    }
    catch (e)
    {
        alert('Please click the webpage and select "Print" from the "File" menu');
    }
}


// Delegates:

// FIXME: implement more delegates, though most of these will likely never work with the iframe implementation

- (id)downloadDelegate
{
    return _downloadDelegate;
}

- (void)setDownloadDelegate:(id)anObject
{
    _downloadDelegate = anObject;
}

- (id)frameLoadDelegate
{
    return _frameLoadDelegate;
}

- (void)setFrameLoadDelegate:(id)anObject
{
    _frameLoadDelegate = anObject;
}

- (id)policyDelegate
{
    return _policyDelegate;
}

- (void)setPolicyDelegate:(id)anObject
{
    _policyDelegate = anObject;
}

- (id)resourceLoadDelegate
{
    return _resourceLoadDelegate;
}

- (void)setResourceLoadDelegate:(id)anObject
{
    _resourceLoadDelegate = anObject;
}

- (id)UIDelegate
{
    return _UIDelegate;
}

- (void)setUIDelegate:(id)anObject
{
    _UIDelegate = anObject;
}

@end

/*!
    @class CPWebScriptObject

    A CPWebScriptObject is an Objective-J wrapper around a scripting object.
*/
@implementation CPWebScriptObject : CPObject
{
    Window _window;
}

/*!
    Initializes the scripting object with the scripting Window object.
*/
- (id)initWithWindow:(Window)aWindow
{
    if (self = [super init])
    {
        _window = aWindow;
    }

    return self;
}

/*!
    Call a method with arguments on the receiver.

    @param methodName - The method that should be called.
    @param args - An array of arguments to pass to the method call.
*/
- (id)callWebScriptMethod:(CPString)methodName withArguments:(CPArray)args
{
    // Would using "with" be better here?
    if (typeof _window[methodName] == "function")
    {
        try
        {
            return _window[methodName].apply(_window, args);
        }
        catch (e)
        {
        }
    }
    return undefined;
}

/*!
    Evaluates a string of javascript and returns the result.

    @param script - The script to run.
    @return - The result of the evaluation, which may be 'undefined'.
*/
- (id)evaluateWebScript:(CPString)script
{
    try
    {
        return _window.eval(script);
    }
    catch (e)
    {
        // FIX ME: if we fail inside here, shouldn't we return an exception?
    }

    return undefined;
}

/*!
    Returns the receivers Window object.
*/
- (Window)window
{
    return _window;
}

@end


@implementation CPWebView (CPCoding)

/*!
    Initializes the web view from the data in a coder.

    @param aCoder the coder from which to read the data
    @return the initialized web view
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        // FIXME: encode/decode these?
        _mainFrameURL   = nil;
        _backwardStack  = [];
        _forwardStack   = [];
        _scrollMode     = CPWebViewScrollAuto;

#if PLATFORM(DOM)
        [self _initDOMWithFrame:[self frame]];
#endif

        if (![self backgroundColor])
            [self setBackgroundColor:[CPColor whiteColor]];

        [self _updateEffectiveScrollMode];
    }

    return self;
}

/*!
    Writes out the web view's instance information to a coder.

    @param aCoder the coder to which to write the data
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    var actualSubviews = _subviews;
    _subviews = [];
    [super encodeWithCoder:aCoder];
    _subviews = actualSubviews;
}

@end

@implementation CPURL(SOP)

/*!
    Private API.

    Returns YES if the receiver URL would pass the same origin policy if loaded by the current runtime environment.

    Since Cappuccino runs in the browser, it is often restricted from accessing URLs from outside of its own origin (protocol, domain, port). This method tries to determine if the URL represented by the receiver is of the same origin, or if other circumstances will allow the content at the URL to be interacted with.
*/
- (BOOL)_passesSameOriginPolicy
{
    var documentURL = [CPURL URLWithString:window.location.href];

    if ([documentURL isFileURL] && CPFeatureIsCompatible(CPSOPDisabledFromFileURLs))
        return YES;

    // Relative URLs always pass the SOP.
    if (![self scheme] && ![self host] && ![self port])
        return YES;

    return ([documentURL scheme] == [self scheme] && [documentURL host] == [self host] && [documentURL port] == [self port]);
}

@end
