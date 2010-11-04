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

CPWebViewScrollAppKit                           = 1;
CPWebViewScrollNative                           = 2;

// FIXME: somehow make CPWebView work with CPScrollView instead of native scrollbars (is this even possible?)

/*!
    @ingroup appkit
*/

@implementation CPWebView : CPView
{
    CPScrollView    _scrollView;
    CPView          _frameView;

    IFrame      _iframe;
    CPString    _mainFrameURL;
    CPArray     _backwardStack;
    CPArray     _forwardStack;

    BOOL        _ignoreLoadStart;
    BOOL        _ignoreLoadEnd;

    id          _downloadDelegate;
    id          _frameLoadDelegate;
    id          _policyDelegate;
    id          _resourceLoadDelegate;
    id          _UIDelegate;

    CPWebScriptObject _wso;

    CPString    _url;
    CPString    _html;

    Function    _loadCallback;

    int         _scrollMode;
    CGSize      _scrollSize;

    int         _loadHTMLStringTimer;
}

- (id)initWithFrame:(CPRect)frameRect frameName:(CPString)frameName groupName:(CPString)groupName
{
    if (self = [self initWithFrame:frameRect])
    {
        _iframe.name = frameName;
    }
    return self
}

- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _mainFrameURL   = nil;
        _backwardStack  = [];
        _forwardStack   = [];
        _scrollMode     = CPWebViewScrollNative;

        [self _initDOMWithFrame:aFrame];
    }

    return self;
}

- (id)_initDOMWithFrame:(CPRect)aFrame
{
    _ignoreLoadStart = YES;
    _ignoreLoadEnd  = YES;

    _iframe = document.createElement("iframe");
    _iframe.name = "iframe_" + Math.floor(Math.random()*10000);
    _iframe.style.width = "100%";
    _iframe.style.height = "100%";
    _iframe.style.borderWidth = "0px";
    _iframe.frameBorder = "0";

    [self setDrawsBackground:YES];

    _loadCallback = function() {
	    // HACK: this block handles the case where we don't know about loads initiated by the user clicking a link
	    if (!_ignoreLoadStart)
	    {
	        // post the start load notification
	        [self _startedLoading];

	        if (_mainFrameURL)
	            [_backwardStack addObject:_mainFrameURL];

	        // FIXME: this doesn't actually get the right URL for different domains. Not possible due to browser security restrictions.
            _mainFrameURL = _iframe.src;
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
	}

	if (_iframe.addEventListener)
	    _iframe.addEventListener("load", _loadCallback, false);
	else if (_iframe.attachEvent)
		_iframe.attachEvent("onload", _loadCallback);


    _frameView = [[CPView alloc] initWithFrame:[self bounds]];
    [_frameView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

    _scrollView = [[CPScrollView alloc] initWithFrame:[self bounds]];
    [_scrollView setAutohidesScrollers:YES];
    [_scrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [_scrollView setDocumentView:_frameView];

    _frameView._DOMElement.appendChild(_iframe);

    [self _setScrollMode:_scrollMode];

    [self addSubview:_scrollView];
}


- (void)setFrameSize:(CPSize)aSize
{
    [super setFrameSize:aSize];
    [self _resizeWebFrame];
}

- (void)_attachScrollEventIfNecessary
{
    if (_scrollMode !== CPWebViewScrollAppKit)
        return;

    var win = null;
    try { win = [self DOMWindow]; } catch (e) {}

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
    }
}

- (void)_resizeWebFrame
{
    if (_scrollMode === CPWebViewScrollAppKit)
    {
        if (_scrollSize)
        {
            [_frameView setFrameSize:_scrollSize];
        }
        else
        {
            var visibleRect = [_frameView visibleRect];
            [_frameView setFrameSize:CGSizeMake(CGRectGetMaxX(visibleRect), CGRectGetMaxY(visibleRect))];

            // try to get the document size so we can correctly set the frame
            var win = null;
            try { win = [self DOMWindow]; } catch (e) {}

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
                CPLog.warn("using default size 800*1600");

                [_frameView setFrameSize:CGSizeMake(800, 1600)];
            }

            [_frameView scrollRectToVisible:visibleRect];
        }
    }
}

- (void)setScrollMode:(int)aScrollMode
{
    if (_scrollMode == aScrollMode)
        return;

    [self _setScrollMode:aScrollMode];
}

- (void)_setScrollMode:(int)aScrollMode
{
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        _scrollMode = CPWebViewScrollNative;
    else
        _scrollMode = aScrollMode;

    _ignoreLoadStart = YES;
    _ignoreLoadEnd  = YES;

    var parent = _iframe.parentNode;
    parent.removeChild(_iframe);

    if (_scrollMode === CPWebViewScrollAppKit)
    {
        [_scrollView setHasHorizontalScroller:YES];
        [_scrollView setHasVerticalScroller:YES];

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
}

- (void)loadHTMLString:(CPString)aString
{
    [self loadHTMLString:aString baseURL:nil];
}

- (void)loadHTMLString:(CPString)aString baseURL:(CPURL)URL
{
    // FIXME: do something with baseURL?

    [self _setScrollMode:CPWebViewScrollAppKit];

    [_frameView setFrameSize:[_scrollView contentSize]];

    [self _startedLoading];

    _ignoreLoadStart = YES;
    _ignoreLoadEnd = NO;

    _url = null;
    _html = aString;

    [self _load];
}

- (void)_loadMainFrameURL
{
    [self _setScrollMode:CPWebViewScrollNative];

    [self _startedLoading];

    _ignoreLoadStart = YES;
    _ignoreLoadEnd = NO;

    _url = _mainFrameURL;
    _html = null;

    [self _load];
}

- (void)_load
{
    if (_url)
    {
        _iframe.src = _url;
    }
    else if (_html)
    {
        // clear the iframe
        _iframe.src = "";

        if (_loadHTMLStringTimer !== nil)
        {
            window.clearTimeout(_loadHTMLStringTimer);
            _loadHTMLStringTimer = nil;
        }

        // need to give the browser a chance to reset iframe, otherwise we'll be document.write()-ing the previous document
        _loadHTMLStringTimer = window.setTimeout(function()
        {
            var win = [self DOMWindow];

            if (win)
                win.document.write(_html);

            window.setTimeout(_loadCallback, 1);
        }, 0);
    }
}

- (void)_startedLoading
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPWebViewProgressStartedNotification object:self];

    if ([_frameLoadDelegate respondsToSelector:@selector(webView:didStartProvisionalLoadForFrame:)])
        [_frameLoadDelegate webView:self didStartProvisionalLoadForFrame:nil]; // FIXME: give this a frame somehow?
}

- (void)_finishedLoading
{
    [self _resizeWebFrame];
    [self _attachScrollEventIfNecessary];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPWebViewProgressFinishedNotification object:self];

    if ([_frameLoadDelegate respondsToSelector:@selector(webView:didFinishLoadForFrame:)])
        [_frameLoadDelegate webView:self didFinishLoadForFrame:nil]; // FIXME: give this a frame somehow?
}

- (CPString)mainFrameURL
{
    return _mainFrameURL;
}

- (void)setMainFrameURL:(CPString)URLString
{
    if (_mainFrameURL)
        [_backwardStack addObject:_mainFrameURL];
    _mainFrameURL = URLString;
    [_forwardStack removeAllObjects];

    [self _loadMainFrameURL];
}

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

- (BOOL)canGoBack
{
    return (_backwardStack.length > 0);
}

- (BOOL)canGoForward
{
    return (_forwardStack.length > 0);
}

- (WebBackForwardList)backForwardList
{
    // FIXME: return a real WebBackForwardList?
    return { back: _backwardStack, forward: _forwardStack };
}

- (void)close
{
    _iframe.parentNode.removeChild(_iframe);
}

- (DOMWindow)DOMWindow
{
    return (_iframe.contentDocument && _iframe.contentDocument.defaultView) || _iframe.contentWindow;
}

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

- (CPString)stringByEvaluatingJavaScriptFromString:(CPString)script
{
    var result = [self objectByEvaluatingJavaScriptFromString:script];
    return result ? String(result) : nil;
}

- (JSObject)objectByEvaluatingJavaScriptFromString:(CPString)script
{
    return [[self windowScriptObject] evaluateWebScript:script];
}

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



- (BOOL)drawsBackground
{
    return _iframe.style.backgroundColor != "";
}

- (void)setDrawsBackground:(BOOL)drawsBackround
{
    _iframe.style.backgroundColor = drawsBackround ? "white" : "";
}



// IBActions

- (IBAction)takeStringURLFrom:(id)sender
{
    [self setMainFrameURL:[sender stringValue]];
}

- (IBAction)goBack:(id)sender
{
    [self goBack];
}

- (IBAction)goForward:(id)sender
{
    [self goForward];
}

- (IBAction)stopLoading:(id)sender
{
    // FIXME: what to do?
}

- (IBAction)reload:(id)sender
{
    [self _loadMainFrameURL];
}

- (IBAction)print:(id)sender
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


@implementation CPWebScriptObject : CPObject
{
    Window _window;
}

- (id)initWithWindow:(Window)aWindow
{
    if (self = [super init])
    {
        _window = aWindow;
    }
    return self;
}

- (id)callWebScriptMethod:(CPString)methodName withArguments:(CPArray)args
{
    // Would using "with" be better here?
    if (typeof _window[methodName] == "function")
    {
        try {
            return _window[methodName].apply(args);
        } catch (e) {
        }
    }
    return undefined;
}

- (id)evaluateWebScript:(CPString)script
{
    try {
        return _window.eval(script);
    } catch (e) {
    }
    return undefined;
}

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
        _scrollMode     = CPWebViewScrollNative;

#if PLATFORM(DOM)
        [self _initDOMWithFrame:[self frame]];
#endif

        [self setBackgroundColor:[CPColor whiteColor]];
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
