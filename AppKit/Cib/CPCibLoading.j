/*
 * _CPCibLoading.j
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

@import <Foundation/CPBundle.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString.j>


var CPCibOwner = @"CPCibOwner";

var LoadInfoForCib = {};

@implementation CPObject (CPCibLoading)

- (void)awakeFromCib
{
}

@end

@implementation CPBundle (CPCibLoading)

+ (void)loadCibFile:(CPString)anAbsolutePath externalNameTable:(CPDictionary)aNameTable
{
    [[[CPCib alloc] initWithContentsOfURL:anAbsolutePath] instantiateCibWithExternalNameTable:aNameTable];
}

+ (void)loadCibNamed:(CPString)aName owner:(id)anOwner
{
    if (![aName hasSuffix:@".cib"])
        aName = [aName stringByAppendingString:@".cib"];

    // Path is based solely on anOwner:
    var bundle = anOwner ? [CPBundle bundleForClass:[anOwner class]] : [CPBundle mainBundle],
        path = [bundle pathForResource:aName];

    [self loadCibFile:path externalNameTable:[CPDictionary dictionaryWithObject:anOwner forKey:CPCibOwner]];
}

- (void)loadCibFile:(CPString)aFileName externalNameTable:(CPDictionary)aNameTable loadDelegate:(id)aDelegate
{
    [[[CPCib alloc] initWithCibNamed:aFileName bundle:self] instantiateCibWithExternalNameTable:aNameTable];
}

+ (void)loadCibFile:(CPString)anAbsolutePath externalNameTable:(CPDictionary)aNameTable loadDelegate:aDelegate
{
    var cib = [[CPCib alloc] initWithContentsOfURL:anAbsolutePath loadDelegate:self];

    LoadInfoForCib[[cib UID]] = { loadDelegate:aDelegate, externalNameTable:aNameTable };
}

+ (void)loadCibNamed:(CPString)aName owner:(id)anOwner loadDelegate:(id)aDelegate
{
    if (![aName hasSuffix:@".cib"])
        aName = [aName stringByAppendingString:@".cib"];

    // Path is based solely on anOwner:
    var bundle = anOwner ? [CPBundle bundleForClass:[anOwner class]] : [CPBundle mainBundle],
        path = [bundle pathForResource:aName];
    
    [self loadCibFile:path externalNameTable:[CPDictionary dictionaryWithObject:anOwner forKey:CPCibOwner] loadDelegate:aDelegate];
}

- (void)loadCibFile:(CPString)aFileName externalNameTable:(CPDictionary)aNameTable loadDelegate:(id)aDelegate
{
    var cib = [[CPCib alloc] initWithCibNamed:aFileName bundle:self loadDelegate:[self class]];

    LoadInfoForCib[[cib UID]] = { loadDelegate:aDelegate, externalNameTable:aNameTable };
}

+ (void)cibDidFinishLoading:(CPCib)aCib
{
    var loadInfo = LoadInfoForCib[[aCib UID]];
    
    delete LoadInfoForCib[[aCib UID]];
    
    [aCib instantiateCibWithExternalNameTable:loadInfo.externalNameTable];
    
    [loadInfo.loadDelegate cibDidFinishLoading:aCib];
}

@end
