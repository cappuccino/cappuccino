/*
 * NSMenuItem.j
 * nib2cib
 *
 * Created by Thomas Robinson.
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

@import <AppKit/CPMenuItem.j>

@import "NSButton.j"
@import "NSEvent.j"
@import "NSMenu.j"

@implementation CPMenuItem (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _isSeparator = [aCoder decodeBoolForKey:@"NSIsSeparator"];

        _title = [aCoder decodeObjectForKey:"NSTitle"];

//      _font = [aCoder decodeObjectForKey:"NSTitle"];

        _target = [aCoder decodeObjectForKey:"NSTarget"];
        _action = [aCoder decodeObjectForKey:"NSAction"];

        _isEnabled = ![aCoder decodeBoolForKey:"NSIsDisabled"];
        _isHidden = [aCoder decodeBoolForKey:"NSIsHidden"];

        _tag = [aCoder decodeIntForKey:"NSTag"];
        _state = [aCoder decodeIntForKey:"NSState"];

         _image = [aCoder decodeObjectForKey:"NSImage"];
     // _alternateImage = [aCoder decodeObjectForKey:""];
//      _onStateImage = [aCoder decodeObjectForKey:"NSOnImage"];
//      _offStateImage = [aCoder decodeObjectForKey:"NSOffImage"];
//      _mixedStateImage = [aCoder decodeObjectForKey:"NSMixedImage"];

        _submenu = [aCoder decodeObjectForKey:"NSSubmenu"];
        _menu = [aCoder decodeObjectForKey:"NSMenu"];

        _keyEquivalent = [aCoder decodeObjectForKey:"NSKeyEquiv"];
        _keyEquivalentModifierMask = CP_NSMapKeyMask([aCoder decodeObjectForKey:"NSKeyEquivModMask"]);

//      _mnemonicLocation = [aCoder decodeObjectForKey:"NSMnemonicLoc"];

//      _isAlternate = [aCoder decodeBoolForKey:"NSIsAlternate"];
        _indentationLevel = [aCoder decodeIntForKey:"NSIndent"];

//      _toolTip;

        _representedObject = [aCoder decodeObjectForKey:"NSRepObject"];
    }

    return self;
}

- (void)swapCellsForParents:(JSObject)parentsForCellUIDs
{
    var target = [self target];

    if (!target)
        return;

    var parent = parentsForCellUIDs[[[self target] UID]];

    if (parent)
        [self setTarget:parent];
}

@end

@implementation NSMenuItem : CPMenuItem
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPMenuItem class];
}

@end

@implementation NSMenuItemCell : NSButtonCell
{
}

@end
