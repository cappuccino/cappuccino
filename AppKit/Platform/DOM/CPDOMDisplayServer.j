/*
 * CPDOMDisplayServer.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
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

@import <Foundation/CPRunLoop.j>

#include "../../CoreGraphics/CGAffineTransform.h"
#include "CPDOMDisplayServer.h"


var CPDOMDisplayRunLoop    = nil;
    
CPDOMDisplayServerInstructions          = [];
CPDOMDisplayServerInstructionCount      = 0;

CPDOMDisplayServerViews                 = [];
CPDOMDisplayServerViewsCount            = 0;
CPDOMDisplayServerViewsContext          = {};
    
@implementation CPDOMDisplayServer : CPObject
{
}

+ (void)start
{
    CPDOMDisplayRunLoop = [CPRunLoop currentRunLoop];
    
    [CPDOMDisplayRunLoop performSelector:@selector(run) target:CPDOMDisplayServer argument:nil order:0 modes:[CPDefaultRunLoopMode]];
}

+ (void)run
{
    while (CPDOMDisplayServerInstructionCount || CPDOMDisplayServerViewsCount)
    {
        var index = 0;
    
        while (index < CPDOMDisplayServerInstructionCount)
        {
            var instruction = CPDOMDisplayServerInstructions[index++];
    try{
            switch (instruction)
            {
                case SetStyleLeftTop:
                case SetStyleRightTop:
                case SetStyleLeftBottom:
                case SetStyleRightBottom:   var element = CPDOMDisplayServerInstructions[index],
                                                style = element.style,
                                                x = (instruction == SetStyleLeftTop || instruction == SetStyleLeftBottom) ? "left" : "right",
                                                y = (instruction == SetStyleLeftTop || instruction == SetStyleRightTop) ? "top" : "bottom";
                                        
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            
                                            var transform = CPDOMDisplayServerInstructions[index++];
                                            
                                            if (transform)
                                            {
                                                var point = _CGPointMake(CPDOMDisplayServerInstructions[index++], CPDOMDisplayServerInstructions[index++]),
                                                    transformed = _CGPointApplyAffineTransform(point, transform);
                                                    
                                                style[x] = ROUND(transformed.x) + "px";
                                                style[y] = ROUND(transformed.y) + "px";
    
                                            }
                                            else
                                            {
                                                style[x] = ROUND(CPDOMDisplayServerInstructions[index++]) + "px";
                                                style[y] = ROUND(CPDOMDisplayServerInstructions[index++]) + "px";
                                            }
                                            
                                            element.CPDOMDisplayContext[SetStyleOrigin] = -1;
                                            
                                            break;
                        
                case SetStyleSize:          var element = CPDOMDisplayServerInstructions[index],
                                                style = element.style;
                                            
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            
                                            element.CPDOMDisplayContext[SetStyleSize] = -1;
                                            
                                            style.width = MAX(0.0, ROUND(CPDOMDisplayServerInstructions[index++])) + "px";
                                            style.height = MAX(0.0, ROUND(CPDOMDisplayServerInstructions[index++])) + "px";
                                            
                                            break;

                case SetSize:               var element = CPDOMDisplayServerInstructions[index];
                                            
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            
                                            element.CPDOMDisplayContext[SetSize] = -1;
                                            
                                            element.width = MAX(0.0, ROUND(CPDOMDisplayServerInstructions[index++]));
                                            element.height = MAX(0.0, ROUND(CPDOMDisplayServerInstructions[index++]));
                                        
                                            break;
                        
                case AppendChild:           CPDOMDisplayServerInstructions[index].appendChild(CPDOMDisplayServerInstructions[index + 1]);
                    
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            
                                            break;
                                    
                case InsertBefore:          CPDOMDisplayServerInstructions[index].insertBefore(CPDOMDisplayServerInstructions[index + 1], CPDOMDisplayServerInstructions[index + 2]);
                                            
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            
                                            break;
                    
                case RemoveChild:           CPDOMDisplayServerInstructions[index].removeChild(CPDOMDisplayServerInstructions[index + 1]);
                                            
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            CPDOMDisplayServerInstructions[index++] = nil;
                                            
                                            break;
                }}catch(e) { CPLog("here?" + instruction) }
        }
        
        CPDOMDisplayServerInstructionCount = 0;
    
        var views = CPDOMDisplayServerViews,
            index = 0,
            count = CPDOMDisplayServerViewsCount;

        // We don't reset CPDOMDisplayServerViewsContext because it can serve for displays that are coming...
        CPDOMDisplayServerViews = [];
        CPDOMDisplayServerViewsCount = 0;
    
        for (; index < count; ++index)
        {
            var view = views[index];
            
            delete CPDOMDisplayServerViewsContext[[view hash]];
            
            [view displayIfNeeded];
        }
    }

    [CPDOMDisplayRunLoop performSelector:@selector(run) target:CPDOMDisplayServer argument:nil order:0 modes:[CPDefaultRunLoopMode]];
}

@end

[CPDOMDisplayServer start];
