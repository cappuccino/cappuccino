/* _CPTableTextAttachment.j
 * A self-contained, renderable text attachment representation of a table.
 *
 * Copyright (C) 2026 Daniel Boehringer
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

@import "CPView.j"
@import "CPTextView.j"
@import "CPTextField.j"
@import <Foundation/CPAttributedString.j>

@implementation _CPTableTextAttachment : CPView
{
    CPArray _headers;
    CPArray _rows;
    BOOL    _isResizing;
    BOOL    _isEditable;
    BOOL    _acceptsRichText;
}

- (id)initWithHeaders:(CPArray)headers rows:(CPArray)rows
{
    return [self initWithHeaders:headers rows:rows width:500.0 isEditable:YES acceptsRichText:YES];
}

- (id)initWithHeaders:(CPArray)headers rows:(CPArray)rows width:(float)totalWidth
{
    return [self initWithHeaders:headers rows:rows width:totalWidth isEditable:YES acceptsRichText:NO];
}

- (id)initWithHeaders:(CPArray)headers rows:(CPArray)rows width:(float)totalWidth isEditable:(BOOL)isEditable acceptsRichText:(BOOL)acceptsRichText
{
    self = [super initWithFrame:CGRectMake(0, 0, totalWidth, 20)];
    if (self)
    {
        _headers = headers;
        _rows = rows;
        _isEditable = isEditable;
        _acceptsRichText = acceptsRichText;
        _isResizing = NO;
        
        [self _rebuildTableWithWidth:totalWidth];
    }

    return self;
}

- (void)_rebuildTableWithWidth:(float)totalWidth
{
    var numCols = _headers ? [_headers count] : 0;

    if (numCols == 0 && _rows && [_rows count] > 0)
        numCols = [[_rows objectAtIndex:0] count];

    // Apply borders on the outer left and top container edges
    if (self._DOMElement) {
        self._DOMElement.style.borderTop = "1px solid #e0e0e0";
        self._DOMElement.style.borderLeft = "1px solid #e0e0e0";
        self._DOMElement.style.boxSizing = "border-box";
    }

    // Initialize header cells
    if (_headers && [_headers count] > 0) {
        for (var c = 0; c < numCols; c++) {
            var headerText = [_headers objectAtIndex:c];
            var cellView = [self createCellWithText:headerText frame:CGRectMakeZero() isHeader:YES];
            [self addSubview:cellView];
        }
    }
    
    // Initialize body rows
    if (_rows) {
        for (var r = 0; r < [_rows count]; r++) {
            var rowData = [_rows objectAtIndex:r];
            for (var c = 0; c < numCols; c++) {
                var cellText = @"";

                if (c < [rowData count])
                    cellText = [rowData objectAtIndex:c];

                var cellView = [self createCellWithText:cellText frame:CGRectMakeZero() isHeader:NO];
                [self addSubview:cellView];
            }
        }
    }
    
    [self resizeToWidth:totalWidth];

    // Trigger parent layout engine re-calculation
    var textView = [self superview];

    if (textView && [textView isKindOfClass:[CPTextView class]])
    {
        var layoutManager = [textView layoutManager];

        if (layoutManager)
        {
            var charRange = [self _findCharacterRangeInLayoutManager:layoutManager];
            if (charRange && charRange.location !== CPNotFound)
            {
                [layoutManager invalidateLayoutForCharacterRange:charRange isSoft:NO actualCharacterRange:nil];
                [layoutManager invalidateDisplayForGlyphRange:charRange];
                [layoutManager _validateLayoutAndGlyphs];
                [textView sizeToFit];
            }
        }
    }
}

- (CPRange)_findCharacterRangeInLayoutManager:(CPLayoutManager)layoutManager
{
    var lineFragments = layoutManager._lineFragments;
    if (lineFragments)
    {
        var l = lineFragments.length;
        for (var i = 0; i < l; i++)
        {
            var fragment = lineFragments[i];
            var runs = fragment._runs;
            if (runs)
            {
                var rc = runs.length;
                for (var j = 0; j < rc; j++)
                {
                    if (runs[j].view === self)
                    {
                        return runs[j]._range;
                    }
                }
            }
        }
    }
    return CPMakeRange(CPNotFound, 0);
}

- (CPArray)headers
{
    var numCols = _headers ? [_headers count] : 0;
    if (numCols == 0 && _rows && [_rows count] > 0)
        numCols = [[_rows objectAtIndex:0] count];

    if (numCols == 0)
        return _headers;

    var subviews = [self subviews];
    if ([subviews count] < numCols)
        return _headers; // Subviews are not yet rendered, return cached fallback

    var currentHeaders = [CPMutableArray array];
    for (var c = 0; c < numCols; c++)
    {
        var cellView = [subviews objectAtIndex:c];
        var textView = [self getTextViewFromCell:cellView];
        var text = @"";
        if (textView)
        {
            text = _acceptsRichText ? [[textView textStorage] copy] : [textView string];
        }
        [currentHeaders addObject:text];
    }

    _headers = currentHeaders;
    return _headers;
}

- (CPArray)rows
{
    var numCols = _headers ? [_headers count] : 0;
    if (numCols == 0 && _rows && [_rows count] > 0)
        numCols = [[_rows objectAtIndex:0] count];

    if (numCols == 0 || !_rows)
        return _rows;

    var subviews = [self subviews];
    var headerOffset = (_headers && [_headers count] > 0) ? numCols : 0;
    var expectedCount = headerOffset + ([_rows count] * numCols);

    if ([subviews count] < expectedCount)
        return _rows; // Subviews are not yet rendered, return cached fallback

    var currentRows = [CPMutableArray array];
    var cellIndex = headerOffset;

    for (var r = 0; r < [_rows count]; r++)
    {
        var rowData = [CPMutableArray array];
        for (var c = 0; c < numCols; c++)
        {
            var cellView = [subviews objectAtIndex:cellIndex++];
            var textView = [self getTextViewFromCell:cellView];
            var text = @"";
            if (textView)
            {
                text = _acceptsRichText ? [[textView textStorage] copy] : [textView string];
            }
            [rowData addObject:text];
        }
        [currentRows addObject:rowData];
    }

    _rows = currentRows;
    return _rows;
}

- (CPView)viewForWidth:(float)width
{
    [self resizeToWidth:width];
    return self;
}

- (CPView)createCellWithText:(id)text frame:(CGRect)frame isHeader:(BOOL)isHeader
{
    var initialWidth = (frame.size.width > 0) ? frame.size.width : 120.0;
    var initialHeight = (frame.size.height > 0) ? frame.size.height : 28.0;

    var cellContainer = [[CPView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, initialWidth, initialHeight)];
    [cellContainer setBackgroundColor:isHeader ? [CPColor colorWithWhite:0.92 alpha:1.0] : [CPColor whiteColor]];
    
    // Bottom and right edge borders to construct the grid
    var borderView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, initialWidth, initialHeight)];
    [borderView setBackgroundColor:[CPColor clearColor]];
    [borderView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    if (borderView._DOMElement)
    {
        borderView._DOMElement.style.borderBottom = "1px solid #e0e0e0";
        borderView._DOMElement.style.borderRight = "1px solid #e0e0e0";
        borderView._DOMElement.style.boxSizing = "border-box";
    }
    [cellContainer addSubview:borderView];
    
    var textContainer = [[CPTextContainer alloc] initWithContainerSize:CGSizeMake(initialWidth - 8, 1e7)];
    var textView = [[CPTextView alloc] initWithFrame:CGRectMake(4, 2, initialWidth - 8, initialHeight - 4) textContainer:textContainer];
    [textView setEditable:_isEditable];
    [textView setSelectable:YES];
    [textView setBackgroundColor:[CPColor clearColor]];
    [textView setVerticallyResizable:YES];
    [textView setHorizontallyResizable:NO];
    [[textView textContainer] setWidthTracksTextView:YES];
    
    // Configure cell rich text mode
    [textView setRichText:_acceptsRichText];
    
    // Intercept changes within cell TextViews to notify the table
    [textView setDelegate:self];
    
    // Configure cell text style using standard CPTextView APIs
    var cellFont = isHeader ? [CPFont boldSystemFontOfSize:11.0] : [CPFont systemFontOfSize:11.0];
    [textView setFont:cellFont];
    [textView setTextColor:[CPColor blackColor]];
    
    // Populate either rich text or plain text safely
    if (text && [text isKindOfClass:[CPAttributedString class]])
    {
        [[textView textStorage] setAttributedString:text];
    }
    else if (text)
    {
        [textView setString:String(text)];
    }
    else
    {
        [textView setString:@""];
    }
    
    [cellContainer addSubview:textView];
    return cellContainer;
}

- (void)textDidChange:(CPNotification)aNotification
{
    // Live update cell layouts and heights when changes are typed
    [self resizeToWidth:CGRectGetWidth([self frame])];
}

- (CPTextView)getTextViewFromCell:(CPView)cellView
{
    var subviews = [cellView subviews];
    for (var i = 0; i < [subviews count]; i++) {
        var sub = [subviews objectAtIndex:i];
        if ([sub isKindOfClass:[CPTextView class]]) {
            return sub;
        }
    }
    return nil;
}

- (void)resizeToWidth:(float)newWidth
{
    if (_isResizing)
        return;

    _isResizing = YES;

    // Use dynamic getters to fetch live edited strings
    var currentHeaders = [self headers];
    var currentRows = [self rows];

    var numCols = currentHeaders ? [currentHeaders count] : 0;
    if (numCols == 0 && currentRows && [currentRows count] > 0) {
        numCols = [[currentRows objectAtIndex:0] count];
    }
    if (numCols == 0) {
        _isResizing = NO;
        return;
    }
    
    var subviews = [self subviews];
    var colNaturalWidths = [];
    var colMinWidths = [];
    for (var c = 0; c < numCols; c++) {
        colNaturalWidths[c] = 80.0; 
        colMinWidths[c] = 60.0;
    }
    
    var measureTextField = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 10000.0, 24.0)];
    [measureTextField setFont:[CPFont systemFontOfSize:13.0]];
    
    var measureCell = function(cellText, isHeader, colIndex) {
        var cellFont = isHeader ? [CPFont boldSystemFontOfSize:11.0] : [CPFont systemFontOfSize:11.0];
        [measureTextField setFont:cellFont];
        
        var plainText = (cellText && typeof cellText.string === "function") ? [cellText string] : (cellText || @"");
        plainText = String(plainText);

        if (cellText && typeof cellText.string === "function") {
            if ([measureTextField respondsToSelector:@selector(setAttributedStringValue:)]) {
                [measureTextField setAttributedStringValue:cellText];
            } else {
                [measureTextField setStringValue:plainText];
            }
        } else {
            [measureTextField setStringValue:plainText];
        }
        
        [measureTextField sizeToFit];
        var naturalW = CGRectGetWidth([measureTextField frame]) + 24.0;
        if (naturalW > colNaturalWidths[colIndex]) {
            colNaturalWidths[colIndex] = naturalW;
        }
        
        var words = plainText.split(/[\s\-]/); 
        var maxWordW = 50.0;
        for (var w = 0; w < words.length; w++) {
            var word = words[w].trim();
            if (word.length === 0) continue;
            [measureTextField setStringValue:word];
            [measureTextField sizeToFit];
            var wordW = CGRectGetWidth([measureTextField frame]) + 30.0; 
            if (wordW > maxWordW) {
                maxWordW = wordW;
            }
        }
        if (maxWordW > colMinWidths[colIndex]) {
            colMinWidths[colIndex] = maxWordW;
        }
    };
    
    if (currentHeaders) {
        for (var c = 0; c < [currentHeaders count]; c++) {
            measureCell([currentHeaders objectAtIndex:c], YES, c);
        }
    }
    
    if (currentRows) {
        for (var r = 0; r < [currentRows count]; r++) {
            var rowData = [currentRows objectAtIndex:r];
            for (var c = 0; c < numCols; c++) {
                var cellText = @"";
                if (c < [rowData count]) {
                    cellText = [rowData objectAtIndex:c];
                }
                measureCell(cellText, NO, c);
            }
        }
    }
    
    var totalMinWidth = 0.0;
    for (var c = 0; c < numCols; c++) {
        totalMinWidth += colMinWidths[c];
    }
    
    var colWidths = [];
    
    if (newWidth <= totalMinWidth) {
        var remainingWidth = newWidth;
        for (var c = 0; c < numCols; c++) {
            var w = Math.floor((colMinWidths[c] / totalMinWidth) * newWidth);
            colWidths[c] = w;
            remainingWidth -= w;
        }
        if (numCols > 0) colWidths[numCols - 1] += remainingWidth;
    } else {
        for (var c = 0; c < numCols; c++) {
            colWidths[c] = colMinWidths[c];
        }
        
        var totalGrowthCapacity = 0.0;
        var growthCapacities = [];
        for (var c = 0; c < numCols; c++) {
            var capacity = Math.max(0.0, colNaturalWidths[c] - colMinWidths[c]);
            growthCapacities[c] = capacity;
            totalGrowthCapacity += capacity;
        }
        
        var extraWidth = newWidth - totalMinWidth;
        var remainingExtra = extraWidth;
        
        for (var c = 0; c < numCols; c++) {
            if (totalGrowthCapacity > 0) {
                var w = Math.floor((growthCapacities[c] / totalGrowthCapacity) * extraWidth);
                colWidths[c] += w;
                remainingExtra -= w;
            }
        }
        if (numCols > 0) {
            colWidths[numCols - 1] += remainingExtra;
        }
    }
    
    var cellIndex = 0;
    var currentY = 0;
    
    var layoutRow = function(startIndex) {
        var maxCellHeight = 28.0; 
        
        for (var c = 0; c < numCols; c++) {
            var idx = startIndex + c;
            if (idx < [subviews count]) {
                var cellView = [subviews objectAtIndex:idx];
                var textView = [self getTextViewFromCell:cellView];
                if (textView) {
                    var targetWidth = Math.max(10.0, colWidths[c] - 8);
                    [[textView textContainer] setContainerSize:CGSizeMake(targetWidth, 1e7)];
                    
                    var layoutManager = [textView layoutManager];
                    var usedRect = layoutManager ? [layoutManager usedRectForTextContainer:[textView textContainer]] : nil;
                    var wrappedHeight = (usedRect ? CGRectGetHeight(usedRect) : 0.0) + 12.0; 
                    if (wrappedHeight > maxCellHeight) {
                        maxCellHeight = wrappedHeight;
                    }
                }
            }
        }
        
        var currentX = 0;
        for (var c = 0; c < numCols; c++) {
            var idx = startIndex + c;
            if (idx < [subviews count]) {
                var cellView = [subviews objectAtIndex:idx];
                [cellView setFrame:CGRectMake(currentX, currentY, colWidths[c], maxCellHeight)];
                
                var textView = [self getTextViewFromCell:cellView];
                if (textView) {
                    var targetWidth = Math.max(10.0, colWidths[c] - 8);
                    var textY = 4.0;
                    var finalTextViewHeight = maxCellHeight - 8.0;
                    [textView setFrame:CGRectMake(4, textY, targetWidth, finalTextViewHeight)];
                }
                
                var cellSubviews = [cellView subviews];
                if ([cellSubviews count] > 0) {
                    [[cellSubviews objectAtIndex:0] setFrame:CGRectMake(0, 0, colWidths[c], maxCellHeight)];
                }
            }
            currentX += colWidths[c];
        }
        
        return maxCellHeight;
    };
    
    if (currentHeaders && [currentHeaders count] > 0) {
        var headerHeight = layoutRow(cellIndex);
        cellIndex += numCols;
        currentY += headerHeight;
    }
    
    if (currentRows) {
        for (var r = 0; r < [currentRows count]; r++) {
            var rowHeight = layoutRow(cellIndex);
            cellIndex += numCols;
            currentY += rowHeight;
        }
    }
    
    // GUARD FRAME SIZE MUTATIONS
    var currentSize = [self frame].size;
    if (ABS(currentSize.width - newWidth) > 0.1 || ABS(currentSize.height - currentY) > 0.1)
    {
        [self setFrameSize:CGSizeMake(newWidth, currentY)];

        // we need to re-layout the textview here.
        // but this is not easy as the layout engine is not re-entrant
        // this does not work: (delay does not matter), layout is always off
// setTimeout(function() {
//            var textView = [self superview];
//
//            if (textView && [textView isKindOfClass:[CPTextView class]])
//            {
//                var layoutManager = [textView layoutManager];
//
//                if (layoutManager)
//                {
//                    var charRange = [self _findCharacterRangeInLayoutManager:layoutManager];
//
//                    if (charRange && charRange.location !== CPNotFound)
//                    {
//                        [layoutManager invalidateLayoutForCharacterRange:charRange isSoft:NO actualCharacterRange:nil];
//                        [layoutManager invalidateDisplayForGlyphRange:charRange];
//                        [layoutManager _validateLayoutAndGlyphs];
//                        [textView sizeToFit];
//                    }
//                }
//            }
//  }, 0);

    }

    _isResizing = NO;
}

@end
