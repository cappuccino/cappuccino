/*
 * CPKeyValueCodingTest.j
 * Foundation
 *
 * Created by Alexander Ljungberg.
 * Copyright 2010, WireLoad, LLC.
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

@implementation CPKeyValueCodingTest : OJTestCase
{
}

- (void)testCPNull
{
    var nullObject = [CPNull null];
    [self assert:[CPNull null] equals:[nullObject valueForKey:@"a"] message:@"CPNull valueForKey:X returns nil"];
}

- (void)testValueForKeyPath
{
    var department = [Department departmentWithName:@"Engineering"],
        employee = [Employee employeeWithName:@"Klaas Pieter" department:department];

    [self assert:department equals:[employee valueForKey:@"department"]];
    [self assert:@"Engineering" equals:[employee valueForKeyPath:@"department.name"]];
}

@end

@implementation Employee : CPObject
{
    CPString                    _name @accessors(property=name);
    Department                  _department @accessors(property=department);
}

+ (id)employeeWithName:(CPString)theName department:(Department)theDepartment
{
    return [[self alloc] initWithName:theName department:theDepartment];
}

- (id)initWithName:(CPString)theName department:(Department)theDepartment
{
    if (self = [super init])
    {
        _name = theName;
        _department = theDepartment;
    }

    return self;
}

@end

@implementation Department : CPObject
{
    CPString                _name @accessors(property=name);
}

+ (id)departmentWithName:(CPString)theName
{
    return [[self alloc] initWithName:theName];
}

- (id)initWithName:(CPString)theName
{
    if (self = [super init])
    {
        _name = theName;
    }

    return self;
}

@end