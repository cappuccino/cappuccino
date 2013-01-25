/*
 * This file is a part of program XcodeCapp
 * Copyright (C) 2013  Antoine Mercadal (<primalmotion@archipelproject.org>)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "TNErrorDataView.h"

@implementation TNErrorDataView

@synthesize fieldMessage;

/*!
 Set the data view's object value
 @param aValue the dictionary representing the error
 */
- (void)setObjectValue:(NSDictionary *)aValue
{
    [fieldMessage setStringValue:[aValue valueForKey:@"message"]];
    [fieldFileName setStringValue:[aValue valueForKey:@"file"]];
    _fullPath = [aValue valueForKey:@"path"];
}


#pragma -
#pragma Actions

/*!
 Open the errored file in default editor
 @param aSender the sender of the action
 */
- (IBAction)openFile:(id)aSender
{
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    [workspace openFile:_fullPath];
}


#pragma -
#pragma CPCoding

- (id)initWithCoder:(NSCoder*)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        fieldFileName = [aCoder decodeObjectForKey:@"fieldFileName"];
        fieldMessage = [aCoder decodeObjectForKey:@"fieldMessage"];
        buttonOpenFile = [aCoder decodeObjectForKey:@"buttonOpenFile"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:fieldFileName forKey:@"fieldFileName"];
    [aCoder encodeObject:fieldMessage forKey:@"fieldMessage"];
    [aCoder encodeObject:buttonOpenFile forKey:@"buttonOpenFile"];
}

@end
