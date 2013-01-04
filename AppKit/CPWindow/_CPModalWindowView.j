/*
*   Filename:         _CPModalWindowView.j
*   Created:          Thu Jan  3 18:01:51 PST 2013
*   Author:           Alexandre Wilhelm <alexandre.wilhelm@alcatel-lucent.com>
*   Description:      CNA Dashboard
*   Project:          Cloud Network Automation - Nuage - Data Center Service Delivery - IPD
*
* Copyright (c) 2011-2012 Alcatel, Alcatel-Lucent, Inc. All Rights Reserved.
*
* This source code contains confidential information which is proprietary to Alcatel.
* No part of its contents may be used, copied, disclosed or conveyed to any party
* in any manner whatsoever without prior written permission from Alcatel.
*
* Alcatel-Lucent is a trademark of Alcatel-Lucent, Inc.
*
*/

@implementation _CPModalWindowView : _CPWindowView
{
}

+ (CPString)defaultThemeClass
{
    return @"modal-window-view";
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self setBackgroundColor:[self valueForThemeAttribute:@"bezel-color"]];
}

@end
