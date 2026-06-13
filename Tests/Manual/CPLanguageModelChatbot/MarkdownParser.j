// Markdown parser
// Markdown & Table Rendering Engine for Cappuccino
//

@import <AppKit/AppKit.j>
@import <Foundation/CPObject.j>

// --- SUBCLASS: TABLE MATRIX VIEW (DYNAMIC TEXT-VIEW ENGINE) ---
@implementation TableMatrixView : CPView
{
    CPArray _headers;
    CPArray _rows;
}

- (id)initWithHeaders:(CPArray)headers rows:(CPArray)rows width:(float)totalWidth
{
    self = [super initWithFrame:CGRectMake(0, 0, totalWidth, 20)];
    if (self)
    {
        _headers = headers;
        _rows = rows;
        
        var numCols = [headers count];

        if (numCols == 0 && [rows count] > 0)
            numCols = [[rows objectAtIndex:0] count];

        // Apply outer borders for collapsed table cell grid rendering
        if (self._DOMElement) {
            self._DOMElement.style.borderTop = "1px solid #e0e0e0";
            self._DOMElement.style.borderLeft = "1px solid #e0e0e0";
        }

        // Initialize header cells
        if ([headers count] > 0) {
            for (var c = 0; c < numCols; c++) {
                var headerText = [headers objectAtIndex:c];
                var cellView = [self createCellWithText:headerText frame:CGRectMakeZero() isHeader:YES];
                [self addSubview:cellView];
            }
        }
        
        // Initialize body rows
        for (var r = 0; r < [rows count]; r++) {
            var rowData = [rows objectAtIndex:r];
            for (var c = 0; c < numCols; c++) {
                var cellText = @"";

                if (c < [rowData count])
                    cellText = [rowData objectAtIndex:c];

                var cellView = [self createCellWithText:cellText frame:CGRectMakeZero() isHeader:NO];
                [self addSubview:cellView];
            }
        }
        
        [self resizeToWidth:totalWidth];
    }
    return self;
}

// --- PUBLIC RTFProducer PROTOCOL METHOD ADDITIONS ---

/**
 * Public getter to expose header values for serialization (e.g., RTF producing)
 */
- (CPArray)headers
{
    return _headers;
}

/**
 * Public getter to expose row values for serialization (e.g., RTF producing)
 */
- (CPArray)rows
{
    return _rows;
}

// ----------------------------------------

- (CPView)createCellWithText:(CPString)text frame:(CGRect)frame isHeader:(BOOL)isHeader
{
    // Prevent zero-width constraints during layout initialization
    var initialWidth = (frame.size.width > 0) ? frame.size.width : 120.0;
    var initialHeight = (frame.size.height > 0) ? frame.size.height : 28.0;

    var cellContainer = [[CPView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, initialWidth, initialHeight)];
    [cellContainer setBackgroundColor:isHeader ? [CPColor colorWithWhite:0.92 alpha:1.0] : [CPColor whiteColor]];
    
    // Draw borders only on the right and bottom edges to avoid double lines in the grid
    var borderView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, initialWidth, initialHeight)];
    [borderView setBackgroundColor:[CPColor clearColor]];
    [borderView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    if (borderView._DOMElement) {
        borderView._DOMElement.style.borderBottom = "1px solid #e0e0e0";
        borderView._DOMElement.style.borderRight = "1px solid #e0e0e0";
        borderView._DOMElement.style.boxSizing = "border-box";
    }
    [cellContainer addSubview:borderView];
    
    // Create CPTextView with vertical expansion support
    var textContainer = [[CPTextContainer alloc] initWithContainerSize:CGSizeMake(initialWidth - 8, 1e7)];
    var textView = [[CPTextView alloc] initWithFrame:CGRectMake(4, 2, initialWidth - 8, initialHeight - 4) textContainer:textContainer];
    [textView setEditable:NO];
    [textView setSelectable:YES];
    [textView setBackgroundColor:[CPColor clearColor]];
    [textView setVerticallyResizable:YES];
    [textView setHorizontallyResizable:NO];
    [[textView textContainer] setWidthTracksTextView:YES];
    
    // Parse nested inline styling (e.g., **bold**) inside cell contents
    var parsedText = [MarkdownParser parseInlineMarkdown:text isHeader:isHeader headerLevel:3];
    
    var storage = [textView textStorage];
    if (storage && [storage respondsToSelector:@selector(setAttributedString:)]) {
        [storage setAttributedString:parsedText];
    } else {
        [textView setEditable:YES];
        [textView setString:@""];
        [textView insertText:parsedText];
        [textView setEditable:NO];
    }
    
    [cellContainer addSubview:textView];
    return cellContainer;
}

// Helper to extract the core CPTextView from a cell container hierarchy
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

// Calculate grid column widths and row heights dynamically based on contents
- (void)resizeToWidth:(float)newWidth
{
    var numCols = [_headers count];
    if (numCols == 0 && [_rows count] > 0) {
        numCols = [[_rows objectAtIndex:0] count];
    }
    if (numCols == 0) return;
    
    var subviews = [self subviews];
    
    // 1. Initialize sizing metrics
    var colNaturalWidths = []; // Ideal width without word wrapping
    var colMinWidths = [];     // Minimum width required to avoid word-level breaking
    for (var c = 0; c < numCols; c++) {
        colNaturalWidths[c] = 80.0; 
        colMinWidths[c] = 60.0;
    }
    
    // Auxiliary text field used to measure layout bounds
    var measureTextField = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 10000.0, 24.0)];
    [measureTextField setFont:[CPFont systemFontOfSize:13.0]];
    
    var measureCell = function(cellText, isHeader, colIndex) {
        var parsedText = [MarkdownParser parseInlineMarkdown:cellText isHeader:isHeader headerLevel:3];
        [measureTextField setFont:isHeader ? [CPFont boldSystemFontOfSize:11.0] : [CPFont systemFontOfSize:11.0]];
        
        // Measure un-wrapped natural width
        [measureTextField setStringValue:[parsedText string]];
        [measureTextField sizeToFit];
        var naturalW = CGRectGetWidth([measureTextField frame]) + 24.0;
        if (naturalW > colNaturalWidths[colIndex]) {
            colNaturalWidths[colIndex] = naturalW;
        }
        
        // Measure strict minimum width boundary dictated by the longest word
        var words = cellText.split(/[\s\-]/); 
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
    
    // Measure header row dimensions
    for (var c = 0; c < [_headers count]; c++) {
        measureCell([_headers objectAtIndex:c], YES, c);
    }
    
    // Measure content rows dimensions
    for (var r = 0; r < [_rows count]; r++) {
        var rowData = [_rows objectAtIndex:r];
        for (var c = 0; c < numCols; c++) {
            var cellText = @"";
            if (c < [rowData count]) {
                cellText = [rowData objectAtIndex:c];
            }
            measureCell(cellText, NO, c);
        }
    }
    
    // 2. Distribute spacing based on minimum-width constraints
    var totalMinWidth = 0.0;
    for (var c = 0; c < numCols; c++) {
        totalMinWidth += colMinWidths[c];
    }
    
    var colWidths = [];
    
    if (newWidth <= totalMinWidth) {
        // Fallback for extremely constrained view widths
        var remainingWidth = newWidth;
        for (var c = 0; c < numCols; c++) {
            var w = Math.floor((colMinWidths[c] / totalMinWidth) * newWidth);
            colWidths[c] = w;
            remainingWidth -= w;
        }
        if (numCols > 0) colWidths[numCols - 1] += remainingWidth;
    } else {
        // Standard flow: Ensure each column receives its minimum width,
        // and distribute surplus space proportionally to expansion capacities.
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
    
    // Dynamic row calculation using LayoutManager metrics
    var layoutRow = function(startIndex) {
        var maxCellHeight = 28.0; 
        
        // Pass 1: Assign column widths and determine wrapped text height limits
        for (var c = 0; c < numCols; c++) {
            var idx = startIndex + c;
            if (idx < [subviews count]) {
                var cellView = [subviews objectAtIndex:idx];
                var textView = [self getTextViewFromCell:cellView];
                if (textView) {
                    var targetWidth = Math.max(10.0, colWidths[c] - 8);
                    [[textView textContainer] setContainerSize:CGSizeMake(targetWidth, 1e7)];
                    
                    var usedRect = [[textView layoutManager] usedRectForTextContainer:[textView textContainer]];
                    var wrappedHeight = CGRectGetHeight(usedRect) + 12.0; 
                    if (wrappedHeight > maxCellHeight) {
                        maxCellHeight = wrappedHeight;
                    }
                }
            }
        }
        
        // Pass 2: Position containers and finalize text view structures
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
    
    // Apply layout constraints to headers
    if ([_headers count] > 0) {
        var headerHeight = layoutRow(cellIndex);
        cellIndex += numCols;
        currentY += headerHeight;
    }
    
    // Apply layout constraints to content rows sequentially
    for (var r = 0; r < [_rows count]; r++) {
        var rowHeight = layoutRow(cellIndex);
        cellIndex += numCols;
        currentY += rowHeight;
    }
    
    [self setFrameSize:CGSizeMake(newWidth, currentY)];
}

@end

// --- MARKDOWN PARSER CLASS ---
@implementation MarkdownParser : CPObject

+ (CPAttributedString)attributedStringFromMarkdown:(CPString)markdown
{
    if (!markdown) {
        return [[CPAttributedString alloc] initWithString:@""];
    }

    var result = [[CPMutableAttributedString alloc] initWithString:@""];
    var lines = markdown.split(/\r?\n/);
    
    var i = 0;
    while (i < lines.length) {
        var line = lines[i];
        
        // Detect structured Markdown tables
        if ([self isTableHeaderLine:line] && i + 1 < lines.length && [self isTableSeparatorLine:lines[i+1]]) {
            var headers = [self parseTableCells:line];
            var rows = [CPMutableArray array];
            
            i += 2;
            while (i < lines.length && [self isTableRowLine:lines[i]]) {
                [rows addObject:[self parseTableCells:lines[i]]];
                i++;
            }
            
            var numCols = [headers count];
            if (numCols == 0 && [rows count] > 0) {
                numCols = [[rows objectAtIndex:0] count];
            }
            
            // Measure column boundaries prior to allocation
            var totalNaturalW = 0.0;
            var colNaturalWidths = [];
            var measureTextField = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 10000.0, 24.0)];
            [measureTextField setFont:[CPFont systemFontOfSize:11.0]];
            
            for (var c = 0; c < numCols; c++) {
                var cellW = 80.0;
                
                if (c < headers.length) {
                    var parsedText = [self parseInlineMarkdown:headers[c] isHeader:YES headerLevel:3];
                    [measureTextField setStringValue:[parsedText string]];
                    [measureTextField sizeToFit];
                    cellW = Math.max(cellW, CGRectGetWidth([measureTextField frame]) + 24.0);
                }
                
                for (var r = 0; r < [rows count]; r++) {
                    var rowData = [rows objectAtIndex:r];
                    if (c < [rowData count]) {
                        var parsedText = [self parseInlineMarkdown:rowData[c] isHeader:NO headerLevel:3];
                        [measureTextField setStringValue:[parsedText string]];
                        [measureTextField sizeToFit];
                        cellW = Math.max(cellW, CGRectGetWidth([measureTextField frame]) + 24.0);
                    }
                }
                colNaturalWidths[c] = cellW;
                totalNaturalW += cellW;
            }
            
            // Generate proportional lineheight estimations to offset rendering sizes
            var estimatedHeight = 36.0; 
            for (var r = 0; r < [rows count]; r++) {
                var rowData = [rows objectAtIndex:r];
                var maxCellHeight = 28.0;
                
                for (var c = 0; c < numCols; c++) {
                    var cellText = @"";
                    if (c < [rowData count]) {
                        cellText = [rowData objectAtIndex:c];
                    }
                    var charCount = cellText.length;
                    
                    var proportion = totalNaturalW > 0 ? (colNaturalWidths[c] / totalNaturalW) : (1.0 / numCols);
                    var estimatedColWidth = proportion * 500.0;
                    var charsPerLine = Math.max(10.0, Math.floor(estimatedColWidth / 6.5)); 
                    
                    var estimatedLines = Math.ceil(charCount / charsPerLine);
                    if (estimatedLines < 1) estimatedLines = 1;
                    
                    var cellHeight = (estimatedLines * 16.0) + 12.0;
                    if (cellHeight > maxCellHeight) {
                        maxCellHeight = cellHeight;
                    }
                }
                estimatedHeight += maxCellHeight;
            }
            
            // Format newline spacing metrics for inline rendering layouts
            var lineCount = Math.ceil(estimatedHeight / 16.0) + 1; 
            var newlineStr = "";
            for (var nl = 0; nl < lineCount; nl++) {
                newlineStr += "\n";
            }
            
            var tableAttrStr = [[CPMutableAttributedString alloc] initWithString:newlineStr];
            var matrixView = [[TableMatrixView alloc] initWithHeaders:headers rows:rows width:500.0];
            
            [tableAttrStr addAttribute:@"TableAttachmentAttribute" value:matrixView range:CPMakeRange(0, [tableAttrStr length])];
            [result appendAttributedString:tableAttrStr];
            continue;
        }
        
        var isHeader = false;
        var headerLevel = 0;
        
        // Parse markdown headers
        var headerMatch = line.match(/^(#{1,6})\s+(.*)$/);
        if (headerMatch) {
            headerLevel = headerMatch[1].length;
            line = headerMatch[2];
            isHeader = true;
        }
        
        // Parse list items
        var isListItem = false;
        var listMatch = line.match(/^(\*|-)\s+(.*)$/);
        if (listMatch) {
            line = "  • " + listMatch[2];
            isListItem = true;
        }
        
        var parsedLine = [self parseInlineMarkdown:line isHeader:isHeader headerLevel:headerLevel];
        [result appendAttributedString:parsedLine];
        
        if (i < lines.length - 1) {
            [result appendAttributedString:[[CPAttributedString alloc] initWithString:@"\n"]];
        }
        
        i++;
    }
    
    return result;
}

+ (BOOL)isTableHeaderLine:(CPString)line
{
    var trimmed = line.trim();
    return trimmed.indexOf('|') !== -1;
}

+ (BOOL)isTableSeparatorLine:(CPString)line
{
    var trimmed = line.trim();
    if (trimmed.indexOf('|') === -1) return NO;
    var stripped = trimmed.replace(/[\s|:\-]/g, '');
    return stripped.length === 0;
}

+ (BOOL)isTableRowLine:(CPString)line
{
    var trimmed = line.trim();
    return trimmed.indexOf('|') !== -1;
}

+ (CPArray)parseTableCells:(CPString)line
{
    var parts = line.split('|');
    var cells = [CPMutableArray array];
    var startIdx = 0;
    var endIdx = parts.length;
    if (parts[0].trim() === "") startIdx = 1;
    if (parts[parts.length - 1].trim() === "") endIdx = parts.length - 1;
    
    for (var j = startIdx; j < endIdx; j++) {
        [cells addObject:parts[j].trim()];
    }
    return cells;
}

+ (CPAttributedString)parseInlineMarkdown:(CPString)text isHeader:(BOOL)isHeader headerLevel:(int)level
{
    var baseFontSize = 11.0;
    var fontSize = baseFontSize;
    var isBold = isHeader;
    var isItalic = NO;
    
    if (isHeader) {
        if (level == 1) fontSize = 15.0;
        else if (level == 2) fontSize = 13.0;
        else fontSize = 12.0;
    }
    
    var result = [[CPMutableAttributedString alloc] initWithString:@""];
    var currentSegment = "";
    var i = 0;
    var len = text.length;
    
    var defaultFont = [CPFont systemFontOfSize:fontSize];
    if (isBold) {
        defaultFont = [CPFont boldSystemFontOfSize:fontSize];
    }
    
    while (i < len) {
        if (i + 2 < len && text.substr(i, 3) === "***") {
            if (currentSegment.length > 0) {
                [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
                currentSegment = "";
            }
            isBold = !isBold;
            isItalic = !isItalic;
            i += 3;
            continue;
        }
        if (i + 1 < len && text.substr(i, 2) === "**") {
            if (currentSegment.length > 0) {
                [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
                currentSegment = "";
            }
            isBold = !isBold;
            i += 2;
            continue;
        }
        if (text.charAt(i) === "*") {
            if (currentSegment.length > 0) {
                [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
                currentSegment = "";
            }
            isItalic = !isItalic;
            i++;
            continue;
        }
        if (text.charAt(i) === "`") {
            if (currentSegment.length > 0) {
                [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
                currentSegment = "";
            }
            var codeText = "";
            i++;
            while (i < len && text.charAt(i) !== "`") {
                codeText += text.charAt(i);
                i++;
            }
            [result appendAttributedString:[self attributedStringWithText:codeText font:defaultFont bold:NO italic:NO code:YES]];
            i++;
            continue;
        }
        
        currentSegment += text.charAt(i);
        i++;
    }
    
    if (currentSegment.length > 0) {
        [result appendAttributedString:[self attributedStringWithText:currentSegment font:defaultFont bold:isBold italic:isItalic code:NO]];
    }
    
    return result;
}

+ (CPAttributedString)attributedStringWithText:(CPString)text font:(CPFont)baseFont bold:(BOOL)b italic:(BOOL)it code:(BOOL)c
{
    var fontName = [baseFont familyName];
    var fontSize = [baseFont size]; 
    var finalFont = baseFont;
    
    if (c) {
        finalFont = [CPFont fontWithName:@"Courier" size:fontSize];
    } else {
        finalFont = [CPFont _fontWithName:fontName size:fontSize bold:b italic:it];
    }
    
    if (!finalFont) {
        finalFont = [CPFont systemFontOfSize:fontSize];
    }
    
    var dict = [CPDictionary dictionaryWithObjectsAndKeys:
        finalFont, CPFontAttributeName,
        [CPColor blackColor], CPForegroundColorAttributeName
    ];
    return [[CPAttributedString alloc] initWithString:text attributes:dict];
}

@end
