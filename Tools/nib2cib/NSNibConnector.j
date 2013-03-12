/*
 * NSNibConnector.j
 * nib2cib
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

@import <AppKit/CPCibBindingConnector.j>
@import <AppKit/CPCibConnector.j>
@import <AppKit/CPCibControlConnector.j>
@import <AppKit/CPCibOutletConnector.j>
@import <AppKit/CPCibRuntimeAttributesConnector.j>
@import <AppKit/CPCibHelpConnector.j>
@import <AppKit/CPKeyValueBinding.j>

NIB_CONNECTION_EQUIVALENCY_TABLE = {};

@implementation CPCibConnector (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _source = [aCoder decodeObjectForKey:@"NSSource"];
        _destination = [aCoder decodeObjectForKey:@"NSDestination"];
        _label = [aCoder decodeObjectForKey:@"NSLabel"];

        var sourceUID = [_source UID],
            destinationUID = [_destination UID];

        if (sourceUID in NIB_CONNECTION_EQUIVALENCY_TABLE)
        {
            CPLog.debug("NSNibConnector: swapped object: " + _source + " for object: " + NIB_CONNECTION_EQUIVALENCY_TABLE[sourceUID]);
            _source = NIB_CONNECTION_EQUIVALENCY_TABLE[sourceUID];
        }

        if (destinationUID in NIB_CONNECTION_EQUIVALENCY_TABLE)
        {
            CPLog.debug("NSNibConnector: swapped object: " + _destination + " for object: " + NIB_CONNECTION_EQUIVALENCY_TABLE[destinationUID]);
            _destination = NIB_CONNECTION_EQUIVALENCY_TABLE[destinationUID];
        }

        if (_source && _destination)
            CPLog.debug(@"NSNibConnector: connection: " + [_source description] + " " + [_destination description] + " " + _label);
    }

    return self;
}

@end

@implementation NSNibConnector : CPCibConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPCibConnector class];
}

@end

@implementation NSNibControlConnector : CPCibControlConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPCibControlConnector class];
}

@end

@implementation NSNibOutletConnector : CPCibOutletConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPCibOutletConnector class];
}

@end

var NSTransformers = [CPSet setWithObjects:
                        @"NSNegateBoolean",
                        @"NSIsNil",
                        @"NSIsNotNil",
                        @"NSUnarchiveFromData",
                        @"NSKeyedUnarchiveFromData"];

@implementation CPCibBindingConnector (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _binding = [aCoder decodeObjectForKey:@"NSBinding"];
        _keyPath = [aCoder decodeObjectForKey:@"NSKeyPath"];

        _options = @{};

        var NSOptions = [aCoder decodeObjectForKey:@"NSOptions"],
            keyEnumerator = [NSOptions keyEnumerator],
            key;

        while ((key = [keyEnumerator nextObject]) !== nil)
        {
            var CPKey = @"CP" + key.substring(2),
                NSValue = [NSOptions objectForKey:key];

            if (CPKey === CPValueTransformerNameBindingOption && [NSTransformers containsObject:NSValue])
                NSValue = @"CP" + NSValue.substring(2);

            [_options setObject:NSValue forKey:CPKey];
        }

        CPLog.debug(@"NSNibConnector: binding connector: " + [_binding description] + " to: " + _destination + " " + [_keyPath description] + " " + [_options description]);
    }

    return self;
}

@end

@implementation NSNibBindingConnector : CPCibBindingConnector
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPCibBindingConnector class];
}

@end

@implementation CPCibRuntimeAttributesConnector (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _source = [aCoder decodeObjectForKey:@"NSObject"];
        _keyPaths = [aCoder decodeObjectForKey:@"NSKeyPaths"];
        _values = [aCoder decodeObjectForKey:@"NSValues"];

        var count = [_keyPaths count];

        CPLog.debug(@"NSNibConnector: runtime attributes connector: " + [_source description]);

        while (count--)
        {
            var value = _values[count],
                type = typeof(value) === "boolean" ? "BOOL" : [value className];

            CPLog.debug(@"   %s (%s): %s", _keyPaths[count], type, value);
        }
    }

    return self;
}

@end

@implementation NSIBUserDefinedRuntimeAttributesConnector : CPCibRuntimeAttributesConnector

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPCibRuntimeAttributesConnector class];
}

@end

@implementation CPCibHelpConnector (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _destination = [aCoder decodeObjectForKey:@"NSDestination"];
        _file = [aCoder decodeObjectForKey:@"NSFile"];
        _marker = [aCoder decodeObjectForKey:@"NSMarker"];
    }

    return self;
}

@end

@implementation NSIBHelpConnector : CPCibHelpConnector

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPCibHelpConnector class];
}

@end
