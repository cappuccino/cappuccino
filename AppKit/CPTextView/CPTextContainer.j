/*
 *  CPTextContainer.j
 *  AppKit
 *
 *  Created by Emmanuel Maillard on 27/02/2010.
 *  Copyright Emmanuel Maillard 2010.
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

@import <Foundation/CPGeometry.j>
@import "CPLayoutManager.j"

@class CPTextView
@class CPLayoutManager

/*
    @global
    @group CPLineSweepDirection
*/
CPLineSweepLeft = 0;
/*
    @global
    @group CPLineSweepDirection
*/
CPLineSweepRight = 1;
/*
    @global
    @group CPLineSweepDirection
*/
CPLineSweepDown = 2;
/*
    @global
    @group CPLineSweepDirection
*/
CPLineSweepUp = 3;

/*
    @global
    @group CPLineMovementDirection
*/
CPLineDoesntMoves = 0;
/*
    @global
    @group CPLineMovementDirection
*/
CPLineMovesLeft = 1;
/*
    @global
    @group CPLineMovementDirection
*/
CPLineMovesRight = 2;
/*
    @global
    @group CPLineMovementDirection
*/
CPLineMovesDown = 3;
/*
    @global
    @group CPLineMovementDirection
*/
CPLineMovesUp = 4;

/*!
    @ingroup appkit
    @class CPTextContainer
*/
@implementation CPTextContainer : CPObject
{
    float           _lineFragmentPadding    @accessors(property=lineFragmentPadding);
    CGSize          _size                   @accessors(property=containerSize);
    CPLayoutManager _layoutManager          @accessors(property=layoutManager);
    CPTextView      _textView               @accessors(property=textView);
    BOOL            _inResizing;
}


#pragma mark -
#pragma mark Init methods

- (id)initWithContainerSize:(CGSize)aSize
{
    self = [super init];

    if (self)
    {
        _size = aSize;
        [self _init];
    }

    return self;
}

- (id)init
{
    return [self initWithContainerSize:CPMakeSize(1e7, 1e7)];
}

- (void)_init
{
    _lineFragmentPadding = 0.0;

    _layoutManager = [[CPLayoutManager alloc] init];
    [_layoutManager addTextContainer:self];
}

#pragma mark -
#pragma mark Setter methods

- (void)setContainerSize:(CGSize)someSize
{
    var oldSize = _size;

    _size = CGSizeMakeCopy(someSize);

    if (oldSize.width != _size.width)
    {
        _inResizing = YES;
        [_layoutManager invalidateLayoutForCharacterRange:CPMakeRange(0, [[_layoutManager textStorage] length])
                                                   isSoft:NO
                                     actualCharacterRange:NULL];

        [_layoutManager _validateLayoutAndGlyphs];
        [_textView sizeToFit]; // this is necessary to adopt the height of CPTextView in case of rewrapping
        _inResizing = NO;
    }
}

// Controls whether the receiver adjusts the width of its bounding rectangle when its text view is resized.
- (void)setWidthTracksTextView:(BOOL)flag
{
    [_textView setPostsFrameChangedNotifications:flag];

    if (flag)
    {
        [[CPNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textViewFrameChanged:)
                                                     name:CPViewFrameDidChangeNotification
                                                   object:_textView];
    }
    else
    {
        [[CPNotificationCenter defaultCenter] removeObserver:self
                                                        name:CPViewFrameDidChangeNotification
                                                      object:_textView];
    }
}

- (void)textViewFrameChanged:(CPNotification)aNotification
{
    var newSize = CGSizeMake([_textView frame].size.width, _size.height);

    [self setContainerSize:newSize];
}

- (void)setTextView:(CPTextView)aTextView
{
    if (_textView)
        [_textView setTextContainer:nil];

    _textView = aTextView;

    if (_textView)
        [_textView setTextContainer:self];

    [_layoutManager textContainerChangedTextView:self];
}

- (BOOL)containsPoint:(CGPoint)aPoint
{
    return CGRectContainsPoint(CGRectMake(0, 0, _size.width, _size.height), aPoint);
}

- (BOOL)isSimpleRectangularTextContainer
{
    return YES;
}

- (CGRect)lineFragmentRectForProposedRect:(CGRect)proposedRect
                           sweepDirection:(CPLineSweepDirection)sweep
                        movementDirection:(CPLineMovementDirection)movement
                            remainingRect:(CGRectPointer)remainingRect
{
    var resultRect = CGRectCreateCopy(proposedRect);

    if (sweep != CPLineSweepRight || movement != CPLineMovesDown)
    {
        CPLog.trace(@"FIXME: unsupported sweep (" + sweep + ") or movement (" + movement + ")");
        return CGRectMakeZero();
    }

    if (resultRect.origin.x + resultRect.size.width > _size.width)
        resultRect.size.width = _size.width - resultRect.origin.x;

    if (resultRect.size.width < 0)
        resultRect = CGRectMakeZero();

    if (remainingRect)
    {
        remainingRect.origin.x = resultRect.origin.x + resultRect.size.width;
        remainingRect.origin.y = resultRect.origin.y;
        remainingRect.size.height =  resultRect.size.height;
        remainingRect.size.width = _size.width - (resultRect.origin.x + resultRect.size.width);
    }

    return resultRect;
}

@end


var CPTextContainerSizeKey  = @"CPTextContainerSizeKey",
    CPTextContainerLayoutManagerKey  = @"CPTextContainerLayoutManagerKey";

@implementation CPTextContainer (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        [self _init];

        _size = [aCoder decodeSizeForKey:CPTextContainerSizeKey];

        _layoutManager = [aCoder decodeObjectForKey:CPTextContainerLayoutManagerKey];
        [_layoutManager addTextContainer:self];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeSize:_size forKey:CPTextContainerSizeKey];
    [aCoder encodeObject:_layoutManager forKey:CPTextContainerLayoutManagerKey];
}

@end
