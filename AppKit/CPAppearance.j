/*
 * CPAppearance.j
 * AppKit
 *
 * Created by Antoine Mercadal.
 * Copyright 2015, Cappuccino Project.
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
@import "CPTheme.j"

CPAppearanceNameAqua         = @"CPAppearanceNameAqua";
CPAppearanceNameLightContent = @"CPAppearanceNameLightContent";
CPAppearanceNameVibrantDark  = @"CPAppearanceNameVibrantDark";
CPAppearanceNameVibrantLight = @"CPAppearanceNameVibrantLight";

var _CPAppearanceCurrent = nil,
    _CPAppearancesRegistry = @{};


@protocol CPAppearanceCustomization <CPObject>

@required
- (CPAppearance)appearance;
- (void)setAppearance:(CPAppearance)appearance;
- (CPAppearance)effectiveAppearance;
- (void)setEffectiveAppearance:(CPAppearance)appearance;

@end

CPThemeStateAppearanceAqua             = CPThemeState("appearance-aqua");
CPThemeStateAppearanceLightContent     = CPThemeState("appearance-light-content");
CPThemeStateAppearanceVibrantLight     = CPThemeState("appearance-vibrant-light");
CPThemeStateAppearanceVibrantDark      = CPThemeState("appearance-vibrant-dark");


/*!
    @ingroup appkit

    A CPAppareance represents the appearance of an to a subset of UI elements.
    This is a very lightweight implementation of the NSAppearance system, but
    We are using it for compliance, and especially for the CPVisualEffectView
*/
@implementation CPAppearance : CPObject
{
    BOOL            _allowsVibrancy     @accessors(property=allowsVibrancy);

    CPString        _name;
}


#pragma mark -
#pragma mark Class Methods

/*! Returns the current default CPAppearance
*/
+ (CPAppearance)currentAppearance
{
    if (!_CPAppearanceCurrent)
        _CPAppearanceCurrent = [CPAppearance appearanceNamed:CPAppearanceNameAqua];

    return _CPAppearanceCurrent;
}

/*! Sets the current default CPAppearance
    @param appearance the new current appearance
*/
+ (void)setCurrentAppearance:(CPAppearance)anAppearance
{
    _CPAppearanceCurrent = anAppearance;
}

/*! Returns the CPAppearance object with the given name
    @param name the name of the appearance
*/
+ (CPAppearance)appearanceNamed:(CPString)aName
{
    if (![_CPAppearancesRegistry containsKey:aName])
    {
        [_CPAppearancesRegistry setObject:[[CPAppearance alloc] initWithAppearanceNamed:aName bundle:nil]
                                   forKey:aName];
    }

    return [_CPAppearancesRegistry objectForKey:aName];
}


#pragma mark -
#pragma mark Initialization

/*! Creates a CPAppearance object initialized to the specified appearance file in the specified bundle
    This method does actually nothing special. It just creates a default appearance object
*/
- (id)initWithAppearanceNamed:(CPString)aName bundle:(CPBundle)bundle
{
    if (self = [super init])
    {
        _name = aName;
        _allowsVibrancy = YES;

        if ([_CPAppearancesRegistry containsKey:aName])
            [CPException raise:CPInternalInconsistencyException reason:"Appearance with name '" + aName + "' is already declared."];

        [_CPAppearancesRegistry setObject:self forKey:aName];
    }

    return self;
}


#pragma mark -
#pragma mark Implementation

- (BOOL)isEqual:(id)anObject
{
    if (![anObject isKindOfClass:CPAppearance])
        return NO;

    return self._name == anObject._name;
}

- (CPString)description
{
    return @"<CPAppearance @" + [self UID] + @" name: " + _name + ">";
}


#pragma mark -
#pragma mark CPCoding

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _name           = [aCoder decodeObjectForKey:@"_name"];
        _allowsVibrancy = [aCoder decodeBoolForKey:@"_allowsVibrancy"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_name forKey:@"_name"];
    [aCoder encodeBool:_allowsVibrancy forKey:@"_allowsVibrancy"];
}

@end