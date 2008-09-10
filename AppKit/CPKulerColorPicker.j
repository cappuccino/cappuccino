/*
 * CPApplication.j
 * AppKit
 *
 * Created by Ross Boucher.
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

import <Foundation/Foundation.j>

import "CPView.j"
import "CPButton.j"
import "CPImage.j"
import "CPImageView.j"
import "CPColorPicker.j"
import "CPColorPanel.j"
import "CPTabView.j"
import "CPTabViewItem.j"


/*
    @ignore
*/
@implementation CPKulerColorPicker : CPColorPicker
{    
    CPView            _contentView;
    CPTabView         _tabView;
    
    CPScrollView      _searchView;
    CPScrollView      _popularView;
        
    CPView            _searchView;
    DOMElement        _FIXME_searchField;
    
    CPURLConnection   _searchConnection;
    CPURLConnection   _popularConnection
}

- (id)initWithPickerMask:(int)mask colorPanel:(CPColorPanel)owningColorPanel 
{
    return [super initWithPickerMask:mask colorPanel: owningColorPanel];
}
  
-(id)initView
{
    aFrame = CPRectMake(0, 0, CPColorPickerViewWidth, CPColorPickerViewHeight);    
    _contentView = [[CPView alloc] initWithFrame:aFrame];

    _tabView = [[CPTabView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(aFrame), CGRectGetHeight(aFrame) - 20)];
    [_tabView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tabView setDelegate: self];
    [_contentView addSubview: _tabView];
    
    var label = [[CPButton alloc] initWithFrame:CPRectMake((CPColorPickerViewWidth-150)/2, CPColorPickerViewHeight-20, 150, 20)];
    [label setAutoresizingMask: CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin];
    [label setFont:[CPFont boldSystemFontOfSize:10.0]];
    [label setTextColor: [CPColor whiteColor]];
    [label setTitle: @"Powered by Adobe Kuler"];
    [label setTarget: self];
    [label setAction: @selector(openKulerLink:)];
    [label setBordered: NO];
    [_contentView addSubview: label];
    
    var searchThemeView = [[_CPKulerThemeView alloc] initWithFrame: CPRectMake(0, 0, aFrame.size.width, 0)];
    [searchThemeView setDelegate: self];
    [searchThemeView setAutoresizingMask: CPViewWidthSizable];
    
    _searchView = [[CPScrollView alloc] initWithFrame: CPRectMake(0, 0, aFrame.size.width, CPColorPickerViewHeight - 10)];
    [_searchView setDocumentView: searchThemeView];
    [_searchView setHasHorizontalScroller: NO];
    [_searchView setAutoresizingMask: (CPViewWidthSizable | CPViewHeightSizable)];
    [[_searchView verticalScroller] setControlSize:CPSmallControlSize];
    [_searchView setAutohidesScrollers:YES];
    
    var auxiliarySearchView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, CPColorPickerViewWidth, 26.0)];
    [auxiliarySearchView setAutoresizingMask: (CPViewMinYMargin | CPViewWidthSizable)];

    _FIXME_searchField = document.createElement("input");
    
    if(!window.addEventListener)
        _FIXME_searchField.type = "text";
    else
        _FIXME_searchField.type = "search";
            
    _FIXME_searchField.style.position = "absolute";
    _FIXME_searchField.style.width = "96%";
    _FIXME_searchField.style.left = "2%";
    _FIXME_searchField.style.top = "2px";
    _FIXME_searchField.onkeypress = function(aDOMEvent) 
    { 
        aDOMEvent = aDOMEvent || window.event;
        if (aDOMEvent.keyCode == 13) 
        { 
            [self search]; 
            
            if(aDOMEvent.preventDefault)
                aDOMEvent.preventDefault(); 
            else if(aDOMEvent.stopPropagation)
                aDOMEvent.stopPropagation();
            
            _FIXME_searchField.blur();
        } 
    };

    auxiliarySearchView._DOMElement.appendChild(_FIXME_searchField);    

    var popularThemeView = [[_CPKulerThemeView alloc] initWithFrame: CPRectMake(0, 0, aFrame.size.width, 0)];
    [popularThemeView setDelegate: self];
    [popularThemeView setAutoresizingMask: CPViewWidthSizable];
    
    _popularView = [[CPScrollView alloc] initWithFrame: CPRectMake(0, 0, aFrame.size.width, CPColorPickerViewHeight)];
    [_popularView setDocumentView: popularThemeView];
    [_popularView setHasHorizontalScroller: NO];
    [_popularView setAutoresizingMask: (CPViewWidthSizable | CPViewHeightSizable)];
    [[_popularView verticalScroller] setControlSize:CPSmallControlSize];
    [_popularView setAutohidesScrollers:YES];

    var mostPopularItem = [[CPTabViewItem alloc] initWithIdentifier:@"Popular"];
    var searchItem = [[CPTabViewItem alloc] initWithIdentifier:@"Search"];

    [searchItem setLabel:@"Search"];
    [searchItem setView:_searchView];
    [searchItem setAuxiliaryView: auxiliarySearchView];
    
    [mostPopularItem setLabel:@"Popular"];
    [mostPopularItem setView: _popularView];
        
    [_tabView addTabViewItem: mostPopularItem];
    [_tabView addTabViewItem: searchItem];

    [self popularThemes];
}

- (void)openKulerLink:(id)sender
{
    window.open("http://kuler.adobe.com");
}

- (CPView)provideNewView:(BOOL)initialRequest 
{
    if (initialRequest) 
        [self initView];
    
    return _contentView;
}

- (int)currentMode 
{
    return CPKulerColorPickerMode;
}

- (BOOL)supportsMode:(int)mode 
{
    return (mode == CPKulerColorPickerMode) ? YES : NO;
}

-(void)search
{
    var query = escape(_FIXME_searchField.value);
    
    if(query.replace("%20", "") == "") 
        return;
    
    [_searchConnection cancel];
    
    _searchConnection = nil;
    _searchConnection = [CPURLConnection connectionWithRequest:
                                 [CPURLRequest requestWithURL: BASE_URL + "kuler.php?mode=search&query="+query] 
                                                     delegate: self];
}

-(void)popularThemes
{
    [_popularConnection cancel];
    _popularConnection = nil;
    _popularConnection = [CPURLConnection connectionWithRequest:
                                   [CPURLRequest requestWithURL: BASE_URL + "kuler.php?mode=popular"] delegate: self];
}

/*
-(void)topRatedThemes
{
    _connection = [CPURLConnection connectionWithRequest:
                            [CPURLRequest requestWithURL: BASE_URL + "kuler.php?mode=rating"] delegate:self];
}
*/

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)data
{
    var data = CPJSObjectCreateWithJSON(data);
    
    if(!data)
        var themes = [];
    else  
        var themes = data.result;
        
    if(aConnection == _popularConnection)
        [[_popularView documentView] setThemes: themes];
    
    if(aConnection == _searchConnection)
        [[_searchView documentView] setThemes: themes];
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPError)anError
{
    [self connectionDidFinishLoading:aConnection];
}

-(void)connectionDidFinishLoading:(CPURLConnection)aConnection
{

}

-(void)chooseColor:(CPColor)aColor
{
    [[self colorPanel] setColor: aColor];
}

@end

/* @ignore */
@implementation _CPKulerThemeView : CPView
{
    CPArray     _themes;
    id          _delegate;
    
    CPColor     _alternateBGColor;
}

-(id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    _alternateBGColor = [CPColor colorWithCalibratedRed: 241.0/255.0 green: 245.0/255.0 blue: 250.0/255.0 alpha: 1.0];

    return self;
}

-(id)delegate
{
    return _delegate;
}

-(void)setDelegate:(id)delegate
{
    _delegate = delegate;
}

-(CPArray)themes
{
    return _themes;
}

-(void)setThemes:(CPArray)themes
{
    _themes = themes;
    [self updateDisplay];
}

-(void)updateDisplay
{
    var width = [self frame].size.width;
    
    var subviews = [self subviews];
    for(var i = [subviews count]-1; i >= 0; --i)
        [subviews[i] removeFromSuperview];
        
    for(var i=0, count = [_themes count]; i<count; i++)
    {
        var swatches = _themes[i].swatches;
        var containerView = [[CPView alloc] initWithFrame: CPRectMake(0, 1+ 20*i, width, 20)];
        [containerView setAutoresizingMask: CPViewWidthSizable];

        for(var j=0; j<swatches.length; j++)
        {
            var outerView = [[CPView alloc] initWithFrame: CGRectMake(2+20*j, 1, 18, 18)],
                innerView = [[_CPColorView alloc] initWithFrame: CGRectInset([outerView bounds], 1.0, 1.0)];
                
            [innerView setTarget: self];
            [innerView setAction: @selector(selectedColor:)];
            [innerView setBackgroundColor: [CPColor colorWithHexString: swatches[j].hexColor]];
            
            [outerView setBackgroundColor: [CPColor blackColor]];
            [outerView addSubview: innerView];
            
            [containerView addSubview: outerView];
        }
        
        var label = [[CPTextField alloc] initWithFrame: CPRectMake(102, 0, width - 102, 20)];
        [label setStringValue: _themes[i].title];
        [label setFont: [CPFont systemFontOfSize: 11.0]];
        [label setLineBreakMode: CPLineBreakByTruncatingTail];
        [label setAutoresizingMask: CPViewWidthSizable];

        [containerView addSubview: label];
        
        if(i%2 == 1)
            [containerView setBackgroundColor: _alternateBGColor];
            
        [self addSubview: containerView];
    }

    [self setFrameSize: CPSizeMake(width, (count)*20 + 2)];
}

-(void)selectedColor:(id)sender
{
    [_delegate chooseColor:[sender backgroundColor]];
}

@end

/* @ignore */
@implementation _CPColorView : CPControl
{

}

-(id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame: aFrame];
    
    [self registerForDraggedTypes:[CPArray arrayWithObjects:CPColorDragType]];

    return self;
}

- (void)mouseDragged:(CPEvent)anEvent
{
    [[CPPasteboard pasteboardWithName:CPDragPboard] declareTypes:[CPArray arrayWithObject:CPColorDragType] owner:self];
     
    var bounds = CPRectMake(0, 0, 15, 15),
        point  = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    
    var outerView = [[CPView alloc] initWithFrame: bounds],
        innerView = [[CPView alloc] initWithFrame: CGRectInset([outerView bounds], 1.0, 1.0)];
        
    [innerView setBackgroundColor: [self backgroundColor]];
    [outerView setBackgroundColor: [CPColor blackColor]];
    
    [outerView addSubview: innerView];
    
    [self dragView: outerView
                at: CPPointMake(point.x - bounds.size.width / 2.0, point.y - bounds.size.height / 2.0)
            offset: CPPointMake(0.0, 0.0)
             event: anEvent
        pasteboard: nil
            source: self
         slideBack: YES];
}

- (void)pasteboard:(CPPasteboard)aPasteboard provideDataForType:(CPString)aType
{
    if(aType == CPColorDragType)
        [aPasteboard setData:[self backgroundColor] forType:aType];
}

@end
