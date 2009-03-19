/*
 * CAMediaTimingFunction.j
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

@import <Foundation/CPObject.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString.j>


kCAMediaTimingFunctionLinear        = @"kCAMediaTimingFunctionLinear";
kCAMediaTimingFunctionEaseIn        = @"kCAMediaTimingFunctionEaseIn";
kCAMediaTimingFunctionEaseOut       = @"kCAMediaTimingFunctionEaseOut";
kCAMediaTimingFunctionEaseInEaseOut = @"kCAMediaTimingFunctionEaseInEaseOut";

var CAMediaNamedTimingFunctions = nil;

@implementation CAMediaTimingFunction : CPObject
{
    float _c1x;
    float _c1y;
    float _c2x;
    float _c2y;
}

+ (id)functionWithName:(CPString)aName
{
    if (!CAMediaNamedTimingFunctions)
    {
        CAMediaNamedTimingFunctions = [CPDictionary dictionary];
        
        [CAMediaNamedTimingFunctions setObject:[CAMediaTimingFunction functionWithControlPoints:0.0 :0.0 :1.0 :1.0] forKey:kCAMediaTimingFunctionLinear];
        [CAMediaNamedTimingFunctions setObject:[CAMediaTimingFunction functionWithControlPoints:0.42 :0.0 :1.0 :1.0] forKey:kCAMediaTimingFunctionEaseIn];
        [CAMediaNamedTimingFunctions setObject:[CAMediaTimingFunction functionWithControlPoints:0.0 :0.0 :0.58 :1.0] forKey:kCAMediaTimingFunctionEaseOut];
        [CAMediaNamedTimingFunctions setObject:[CAMediaTimingFunction functionWithControlPoints:0.42 :0.0 :0.58 :1.0] forKey:kCAMediaTimingFunctionEaseInEaseOut];
    }
    
    return [CAMediaNamedTimingFunctions objectForKey:aName];
}

+ (id)functionWithControlPoints:(float)c1x :(float)c1y :(float)c2x :(float)c2y
{
    return [[self alloc] initWithControlPoints:c1x :c1y :c2x :c2y];
}

- (id)initWithControlPoints:(float)c1x :(float)c1y :(float)c2x :(float)c2y
{
    self = [super init];
    
    if (self)
    {
        _c1x = c1x;
        _c1y = c1y;
        _c2x = c2x;
        _c2y = c2y;
    }
    
    return self;
}

- (void)getControlPointAtIndex:(unsigned)anIndex values:(float[2])reference
{
    if (anIndex == 0)
    {
        reference[0] = 0;
        reference[1] = 0;
    }
    else if (anIndex == 1)
    {
        reference[0] = _c1x;
        reference[1] = _c1y;
    }
    else if (anIndex == 2)
    {
        reference[0] = _c2x;
        reference[1] = _c2y;
    }
    else
    {
        reference[0] = 1.0;
        reference[1] = 1.0;
    }
}

@end
