/*
 * CPVisualEffectView.j
 * AppKit
 *
 * Created by Antoine Mercadal.
 * Copyright 2015, 280 Cappuccino Project.
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
@import "CPAppearance.j"
@import "CPView.j"

@typedef CPVisualEffectMaterial
CPVisualEffectMaterialAppearanceBased       = 0;
CPVisualEffectMaterialLight                 = 1;
CPVisualEffectMaterialDark                  = 2;
CPVisualEffectMaterialTitlebar              = 3;

@typedef CPVisualEffectBlendingMode
CPVisualEffectBlendingModeBehindWindow      = 0;
CPVisualEffectBlendingModeWithinWindow      = 1;

@typedef CPVisualEffectState
CPVisualEffectStateFollowsWindowActiveState = 0;
CPVisualEffectStateActive                   = 1;
CPVisualEffectStateInactive                 = 2;


/*! @ingroup appkit

    Very naive implementation of CPVisualEffectView. This view allows
    to use vibrancy effect. This is only working with Safari 9+ and the
    support in Chrome/ium should come quite soon.
    Using this class with a browser that doesn't support backdrop-filter
    While still work, but you will not get the blurry effect.
*/
@implementation CPVisualEffectView : CPView
{
    CPImage                     _maskImage                  @accessors(property=maskImage);
    CPVisualEffectBlendingMode  _blendingMode               @accessors(property=blendingMode);
    CPVisualEffectMaterial      _material                   @accessors(property=material);
    CPVisualEffectState         _state                      @accessors(property=state);
}


#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _material                = CPVisualEffectMaterialAppearanceBased;
        _blendingMode            = CPVisualEffectBlendingModeWithinWindow;
        _state                   = CPVisualEffectStateFollowsWindowActiveState;
        _appearance              = [CPAppearance appearanceNamed:CPAppearanceNameVibrantDark];
    }

    return self;
}


#pragma mark -
#pragma mark CPVisualEffectView API

/*! Sets the appearance of the CPVisualEffectView.

    Only CPAppearance named CPAppearanceNameVibrantDark or CPAppearanceNameVibrantLight are valid

    @param anAppearance the CPAppearance.
*/
- (void)setAppearance:(CPAppearance)anAppearance
{
    if (![self _validAppearance:anAppearance])
        [CPException raise:CPInvalidArgumentException reason:"Appearance can only be CPAppearanceNameVibrantDark or CPAppearanceNameVibrantLight in CPVisualEffectView, but is " + anAppearance];

    [super setAppearance:anAppearance];

    [self setNeedsLayout:YES];
}

/*! Sets the received effect state.
    Possible values:
    <pre>
    CPVisualEffectStateFollowsWindowActiveState (default)
    CPVisualEffectStateActive
    CPVisualEffectStateInactive
    </pre>
*/
- (void)setState:(CPVisualEffectState)aState
{
    if (_state == aState)
        return;

    [self willChangeValueForKey:"state"];
    _state = aState;
    [self didChangeValueForKey:"state"];

    [self setNeedsLayout:YES];
}


#pragma mark -
#pragma mark Utilities

- (void)_setEffectEnabled:(BOOL)shouldEnable
{
    var dark       = [[self appearance] isEqual:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]],
        prop       = CPBrowserStyleProperty("backdrop-filter"),
        color      = (dark ? [CPColor colorWithHexString:@"1e1e1e"] : [CPColor whiteColor]),
        finalColor = shouldEnable ? [color colorWithAlphaComponent:0.6] : color;

    [self setBackgroundColor:finalColor];

#if PLATFORM(DOM)
    self._DOMElement.style[prop] = shouldEnable ? "blur(30px)" : nil;
#endif

}

- (void)layoutSubviews
{
    switch (_state)
    {
        case CPVisualEffectStateFollowsWindowActiveState:
            [self _setEffectEnabled:[self hasThemeState:CPThemeStateKeyWindow]];
            break;

        case CPVisualEffectStateActive:
            [self _setEffectEnabled:YES];
            break;

        case CPVisualEffectStateInactive:
            [self _setEffectEnabled:NO];
            break;
    }
}

- (BOOL)_validAppearance:(CPAppearance)anAppearance
{
    return [anAppearance isEqual:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]] || [anAppearance isEqual:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
}


#pragma mark -
#pragma mark CPCoding

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _blendingMode = [aCoder decodeIntForKey:@"_blendingMode"] || CPVisualEffectBlendingModeWithinWindow;
        _maskImage    = [aCoder decodeObjectForKey:@"_maskImage"];
        _material     = [aCoder decodeIntForKey:@"_material"] || CPVisualEffectMaterialAppearanceBased;
        _state        = [aCoder decodeIntForKey:@"_state"] || CPVisualEffectStateFollowsWindowActiveState;
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_maskImage forKey:@"_maskImage"];
    [aCoder encodeInt:_blendingMode forKey:@"_blendingMode"];
    [aCoder encodeInt:_material forKey:@"_material"];
    [aCoder encodeInt:_state forKey:@"_state"];
}


@end