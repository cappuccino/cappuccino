/* _CPDatePickerBox.j
* AppKit
*
* Created by Alexandre Wilhelm
* Copyright 2012 <alexandre.wilhelmfr@gmail.com>
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

@import <Foundation/Foundation.j>
@import "CPView.j"

@class CPDatePicker

@implementation _CPDatePickerBox : CPView
{
    CPDatePicker _datePicker @accessors(property=datePicker);
}

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    if ([_datePicker isCSSBased])
        return;

    if ([_datePicker isBordered])
    {
        var context = [[CPGraphicsContext currentContext] graphicsPort],
            borderWidth = [_datePicker valueForThemeAttribute:@"border-width"] / 2;

        CGContextBeginPath(context);
        CGContextSetStrokeColor(context, [_datePicker valueForThemeAttribute:@"border-color" inState:[_datePicker themeState]]);
        CGContextSetLineWidth(context,  [_datePicker valueForThemeAttribute:@"border-width"]);

        CGContextMoveToPoint(context, borderWidth, borderWidth);
        CGContextAddLineToPoint(context, aRect.size.width - borderWidth, borderWidth);
        CGContextAddLineToPoint(context, aRect.size.width - borderWidth, aRect.size.height - borderWidth);
        CGContextAddLineToPoint(context, borderWidth, aRect.size.height - borderWidth);
        CGContextAddLineToPoint(context, borderWidth,borderWidth);

        CGContextStrokePath(context);
        CGContextClosePath(context);
    }
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
        return [self bounds];

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
    {
        var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [view setHitTests:NO];

        return view;
    }

    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    if ([_datePicker isCSSBased])
    {
        var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:nil];

        [bezelView setBackgroundColor:[_datePicker currentValueForThemeAttribute:@"bezel-color"]];
    }

    if ([_datePicker drawsBackground])
        [self setBackgroundColor:[_datePicker backgroundColor]];
    else
        [self setBackgroundColor:[CPColor clearColor]];
}

@end
