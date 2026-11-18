/*
 * HelpViewController.j
 * TextEditor
 *
 * Copyright (c) 2026 David Richardson
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

@import <AppKit/AppKit.j>

/*
    The text of the help popover: a title and paragraphs, shown in this order. There are more
    paragraphs than fit in the popover, so its text scrolls.
*/
var HelpTitle       = @"Help for 'TextEdit by Cappuccino'",
    HelpParagraphs  = [
        @"Type in the window to edit the document. The ruler above the text sets the indents and the tab stops of the paragraph at the selection. Click the ruler to add a tab stop, and drag a tab stop off the ruler to remove it.",
        @"Control-click a tab stop to change its type: left, centre, right or decimal. Format > Text > Copy Ruler and Paste Ruler apply the indents and tab stops of one paragraph to others.",
        @"Format > Font changes the font, its size and the baseline. Bigger and Smaller, Command-+ and Command--, change the size step by step. Copy Style and Paste Style apply the style of one part of the text to another.",
        @"Format > Text aligns and justifies paragraphs.",
        @"Format > List makes bulleted and numbered lists. Press Return to start the next item, and press Return in an empty item to end the list. Press Tab at the start of an item to nest it, and Shift-Tab to return it.",
        @"Edit > Insert Image… inserts a JPEG or PNG image. Edit > Insert Lorem Ipsum and Edit > Insert Table Example add sample text.",
        @"Edit > Copy, Cut and Paste move plain text to and from other applications. Inside TextEdit by Cappuccino, copied text keeps its style, its images, its tables and its lists.",
        @"View > Zoom Level, Zoom In, Zoom Out and Actual Size change the magnification of the text.",
        @"TextEdit by Cappuccino > Settings… chooses a light or a dark appearance, or Auto, which follows the system.",
        @"To show this help, choose Help > TextEdit by Cappuccino Help, press Command-?, or choose Help in the context menu of the text."
    ],
    HelpWidth       = 360.0,
    HelpHeight      = 300.0,
    HelpMargin      = 16.0,
    HelpSpacing     = 10.0;


/*!
    Supplies the content of the help popover.

    A popover shows the view of its content view controller, and takes its
    size from that view. This controller makes its view in code, in
    loadView, so it needs no cib. The view controller is made once for each
    document window and kept, so the view is also made only once.

    The view has a fixed size. The title stays at the top, and the
    paragraphs are in a scroll view below it. The paragraphs are taller than
    the scroll view, so the help scrolls, as long help does in AppKit.

    The labels use the theme's colours and set none of their own. So the text
    follows the popover's appearance: dark text in a light popover, light
    text in a dark one.
*/
@implementation HelpViewController : CPViewController

- (void)loadView
{
    var view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, HelpWidth, HelpHeight)],
        textWidth = HelpWidth - 2 * HelpMargin,
        titleLabel = [self labelWithText:HelpTitle font:[CPFont boldSystemFontOfSize:15.0] width:textWidth];

    [titleLabel setFrameOrigin:CGPointMake(HelpMargin, HelpMargin)];
    [view addSubview:titleLabel];

    /*
        The scroll view fills the rest of the view and reaches its right
        edge, so that the vertical scroller sits at the edge of the popover.
        It has no border and no horizontal scroller, and its scroller hides
        when the text is not scrolled.
    */
    var scrollTop = CGRectGetMaxY([titleLabel frame]) + HelpSpacing,
        scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(HelpMargin, scrollTop, HelpWidth - HelpMargin, HelpHeight - scrollTop - HelpMargin)];

    [scrollView setBorderType:CPNoBorder];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setDocumentView:[self paragraphViewWithWidth:textWidth]];
    [view addSubview:scrollView];

    [self setView:view];
}

/*!
    Returns a view that holds the paragraphs, one below the other, aWidth
    wide and as tall as the paragraphs. The view's coordinates start at the
    top left, so y grows downwards.
*/
- (CPView)paragraphViewWithWidth:(float)aWidth
{
    var paragraphView = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        bodyFont = [CPFont systemFontOfSize:13.0],
        y = 0.0;

    for (var i = 0; i < HelpParagraphs.length; i++)
    {
        var label = [self labelWithText:HelpParagraphs[i] font:bodyFont width:aWidth];

        [label setFrameOrigin:CGPointMake(0.0, y)];
        [paragraphView addSubview:label];

        y += CGRectGetHeight([label frame]) + HelpSpacing;
    }

    [paragraphView setFrameSize:CGSizeMake(aWidth, y - HelpSpacing)];

    return paragraphView;
}

/*!
    Returns a label that shows aText in aFont, wrapped to aWidth. The label
    is as tall as the wrapped text. A few points are added to the measured
    height, so that the last line is not clipped.
*/
- (CPTextField)labelWithText:(CPString)aText font:(CPFont)aFont width:(float)aWidth
{
    var label = [CPTextField labelWithTitle:aText],
        height = [aText sizeWithFont:aFont inWidth:aWidth].height + 4.0;

    [label setFont:aFont];
    [label setLineBreakMode:CPLineBreakByWordWrapping];
    [label setFrameSize:CGSizeMake(aWidth, height)];

    return label;
}

@end
