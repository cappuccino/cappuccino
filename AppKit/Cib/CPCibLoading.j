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

- (void)loadCibFile:(CPString)aFileName externalNameTable:(CPDictionary)aNameTable
{
    [[[CPCib alloc] initWithContentsOfURL:aFileName] instantiateCibWithExternalNameTable:aNameTable];
}

+ (void)loadCibFile:(CPString)anAbsolutePath externalNameTable:(CPDictionary)aNameTable loadDelegate:aDelegate
{
    [[CPCib alloc]
    initWithContentsOfURL:anAbsolutePath
             loadDelegate:[[_CPCibLoadDelegate alloc]
                initWithLoadDelegate:aDelegate
                   externalNameTable:aNameTable]];
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
    [[CPCib alloc]
        initWithCibNamed:aFileName
                  bundle:self
            loadDelegate:[[_CPCibLoadDelegate alloc]
                initWithLoadDelegate:aDelegate
                   externalNameTable:aNameTable]];
}

@end

@implementation _CPCibLoadDelegate : CPObject
{
    id              _loadDelegate;
    CPDictionary    _externalNameTable;
}

- (id)initWithLoadDelegate:(id)aLoadDelegate externalNameTable:(id)anExternalNameTable
{
    self = [self init];

    if (self)
    {
        _loadDelegate = aLoadDelegate;
        _externalNameTable = anExternalNameTable;
    }

    return self;
}

- (void)cibDidFinishLoading:(CPCib)aCib
{
    [aCib instantiateCibWithExternalNameTable:_externalNameTable];

    [_loadDelegate cibDidFinishLoading:aCib];
}

- (void)cibDidFailToLoad:(CPCib)aCib
{
    [_loadDelegate cibDidFailToLoad:aCib];
}

@end
