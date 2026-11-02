/*
 *  CSVParser.j
 *  CSVImportTest
 *
 *  Created by David Richardson on 2026-11-02.
 *  Copyright David Richardson 2026.
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

@import <Foundation/CPObject.j>

var CSVParserCandidateDelimiters = [",", ";", "\t", "|"],
    CSVParserQuote = 0x22,
    CSVParserCarriageReturn = 0x0D,
    CSVParserLineFeed = 0x0A;

/*
    Parses comma-separated values as RFC 4180 describes them, with any one-character delimiter:

    - A field may be quoted. A quoted field may hold the delimiter, line breaks, and quotes,
      which are doubled.
    - A record ends at CR LF, LF or CR.
    - A final line break does not start an empty record, and empty lines are skipped.

    The parser works in chunks, so that an application can parse a large file between run loop
    passes. That keeps the user interface responsive, lets it show progress, and lets the user
    cancel. Call -parseNextChunkOfLength: until it returns YES.

    Each field is cut from the text with one substring call, rather than built a character at a
    time. With millions of fields, building strings character by character costs far more time
    and memory than the parse itself.
*/
@implementation CSVParser : CPObject
{
    CPString    _string;
    CPString    _delimiter;
    int         _delimiterCode;
    int         _position;
    CPArray     _records;
}

/*
    Returns the delimiter that occurs most often outside quotes in the first record, of comma,
    semicolon, tab and vertical bar. Returns a comma when none occurs.
*/
+ (CPString)detectedDelimiterForString:(CPString)aString
{
    var counts = {},
        isQuoted = NO;

    for (var i = 0, count = aString.length; i < count; i++)
    {
        var character = aString.charAt(i);

        if (character === "\"")
            isQuoted = !isQuoted;
        else if (!isQuoted && (character === "\n" || character === "\r"))
            break;
        else if (!isQuoted && CSVParserCandidateDelimiters.indexOf(character) >= 0)
            counts[character] = (counts[character] || 0) + 1;
    }

    var delimiter = ",",
        highestCount = 0;

    for (var i = 0; i < CSVParserCandidateDelimiters.length; i++)
    {
        var candidate = CSVParserCandidateDelimiters[i];

        if ((counts[candidate] || 0) > highestCount)
        {
            delimiter = candidate;
            highestCount = counts[candidate];
        }
    }

    return delimiter;
}

/*
    Returns every record of a string at once. For small strings.
*/
+ (CPArray)recordsFromString:(CPString)aString delimiter:(CPString)aDelimiter
{
    var parser = [[self alloc] initWithString:aString delimiter:aDelimiter];

    while (![parser parseNextChunkOfLength:aString.length + 1]);

    return [parser records];
}

- (id)initWithString:(CPString)aString delimiter:(CPString)aDelimiter
{
    if (self = [super init])
    {
        _string = aString;
        _delimiter = aDelimiter;
        _delimiterCode = aDelimiter.charCodeAt(0);
        _position = aString.charCodeAt(0) === 0xFEFF ? 1 : 0;
        _records = [];
    }

    return self;
}

/*
    Returns the records parsed so far, each an array of field strings.
*/
- (CPArray)records
{
    return _records;
}

/*
    Returns the position in the text that parsing has reached.
*/
- (int)position
{
    return _position;
}

/*
    Returns the length of the text.
*/
- (int)length
{
    return _string.length;
}

/*
    Parses whole records until about aLength more characters have been read, or the text ends.
    Returns YES when the text has ended.
*/
- (BOOL)parseNextChunkOfLength:(int)aLength
{
    var string = _string,
        length = string.length,
        end = MIN(length, _position + aLength),
        position = _position;

    while (position < length && position < end)
    {
        var record = [];

        while (YES)
        {
            var field;

            if (string.charCodeAt(position) === CSVParserQuote)
            {
                var parts = [];

                position++;

                while (YES)
                {
                    var closingQuote = string.indexOf("\"", position);

                    if (closingQuote < 0)
                    {
                        parts.push(string.substring(position));
                        position = length;
                        break;
                    }

                    parts.push(string.substring(position, closingQuote));

                    if (string.charCodeAt(closingQuote + 1) === CSVParserQuote)
                    {
                        parts.push("\"");
                        position = closingQuote + 2;
                        continue;
                    }

                    position = closingQuote + 1;
                    break;
                }

                field = parts.join("");
            }
            else
                field = "";

            /*
                Read up to the next delimiter or line break. For a quoted field, this keeps any
                characters after the closing quote, which RFC 4180 does not allow, rather than
                losing them.
            */
            var fieldStart = position;

            while (position < length)
            {
                var code = string.charCodeAt(position);

                if (code === _delimiterCode || code === CSVParserCarriageReturn || code === CSVParserLineFeed)
                    break;

                position++;
            }

            if (position > fieldStart)
                field += string.substring(fieldStart, position);

            record.push(field);

            var terminator = position < length ? string.charCodeAt(position) : -1;

            if (terminator === _delimiterCode)
            {
                position++;
                continue;
            }

            if (terminator === CSVParserCarriageReturn)
            {
                position++;

                if (string.charCodeAt(position) === CSVParserLineFeed)
                    position++;
            }
            else if (terminator === CSVParserLineFeed)
                position++;

            break;
        }

        if (record.length > 1 || record[0] !== "")
            _records.push(record);
    }

    _position = position;

    return position >= length;
}

@end
