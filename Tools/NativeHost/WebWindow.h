//
//  WebWindow.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 10/18/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum _CPWindowShadowStyle
{
    CPStandardWindowShadowStyle = 0,
    CPMenuWindowShadowStyle     = 1,
    CPPanelWindowShadowStyle    = 2,
    CPCustomWindowShadowStyle   = 3
} CPWindowShadowStyle;

@interface WebWindow : NSWindow
{
    NSView              * leftMouseDownView;
    NSView              * rightMouseDownView;

    WebView             * webView;
    NSView              * shadowView;

    BOOL                hasShadow;
    CPWindowShadowStyle shadowStyle;
}

+ (WebWindow *)webWindow;

- (WebView *)webView;

- (BOOL)hitTest:(NSPoint)aPoint;

- (BOOL)hasShadow;
- (void)setHasShadow:(BOOL)shouldHaveShadow;

- (void)setShadowStyle:(CPWindowShadowStyle)aStyle;
- (CPWindowShadowStyle)shadowStyle;

@end
