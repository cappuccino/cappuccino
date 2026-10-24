/*
 * TableExample.j
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

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


/*!
    Supplies a short sample document that contains a table.

    AppKit has no public table class for text yet. Tables in a text view come
    from CPMarkdownParser, which turns Markdown into an attributed string.
    When the parser finds a Markdown table, it builds a table view, holds it
    in one attachment character, and lays it out in the text like a single
    large character. Each cell of the table is a text view of its own.

    The sample is kept as Markdown in the application itself, so inserting it
    needs no network access and no resource file. It also shows the Markdown
    that the parser understands: headings, bold and italic text, and tables.
*/
@implementation TableExample : CPObject

/*!
    Returns the sample document as Markdown: a heading, a sentence, a table
    with a header row, and a closing sentence.

    The empty line after the table is needed. The parser does not end the
    table's line, so without the empty line the closing sentence would follow
    the table on the same line.
*/
+ (CPString)markdown
{
    return @"## Table Example\n" +
           @"The table below comes from Markdown, through CPMarkdownParser.\n" +
           @"| Feature | Status | Notes |\n" +
           @"| --- | --- | --- |\n" +
           @"| **Lists** | Done | Bulleted, numbered and nested |\n" +
           @"| **Images** | Done | Fit the width of the text |\n" +
           @"| **Tables** | *Testing* | Each cell can be edited |\n" +
           @"\n" +
           @"Click in a cell to edit its text.\n";
}

/*!
    Returns the sample document as an attributed string, ready to insert into
    a rich text view.
*/
+ (CPAttributedString)attributedString
{
    return [CPMarkdownParser attributedStringFromMarkdown:[self markdown]];
}

@end
