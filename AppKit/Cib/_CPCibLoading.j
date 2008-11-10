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

-(void)awakeFromCib
{
}

@end

@implementation CPBundle (CPCibLoading)

+ (BOOL)loadCibFile:(CPString)aPath externalNameTable:(CPDictionary)aNameTable
{
    return [[[CPCib alloc] initWithContentsOfFile:aPath] instantiateCibWithExternalNameTable:aNameTable];
}

+ (BOOL)loadCibNamed:(CPString)aName owner:(id)anOwner
{
    var bundle = [CPBundle bundleForClass:[anOwner class]];
    
    /*NSString     *path;

   path=[bundle pathForResource:name ofType:@"cib"];
   if(path==nil)
    path=[[NSBundle mainBundle] pathForResource:name ofType:@"cib"];

   if(path==nil)
    return NO;
    */
    var path = [bundle pathForResource:aName];
    
    return [CPBundle loadCibFile:aPath externalNameTable:[CPDictionary dictionaryWithObject:anOwner forKey:CPCibOwner]];
}

- (BOOL)loadCibFile:(CPString)aPath externalNameTable:(CPDictionary)aNameTable
{
    return [[[CPCib alloc] initWithContentsOfFile:aPath] instantiateCibWithExternalNameTable:aNameTable];
}

@end

