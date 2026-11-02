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

var CSVParserCandidateDelimiters = [",", ";", "\t", "|"];

/*
    Parses comma-separated values as RFC 4180 describes them, with any one-character delimiter:

    - A field may be quoted. A quoted field may hold the delimiter, line breaks, and quotes,
      which are doubled.
    - A record ends at CR LF, LF or CR.
    - A final line break does not start an empty record.
*/
@implementation CSVParser : CPObject
{
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
    Returns the records of a string, each an array of field strings.
*/
+ (CPArray)recordsFromString:(CPString)aString delimiter:(CPString)aDelimiter
{
    var records = [],
        record = [],
        field = "",
        isQuoted = NO,
        fieldStarted = NO,
        count = aString.length,
        i = 0;

    if (aString.charCodeAt(0) === 0xFEFF)
        i = 1;

    for (; i < count; i++)
    {
        var character = aString.charAt(i);

        if (isQuoted)
        {
            if (character !== "\"")
                field += character;
            else if (aString.charAt(i + 1) === "\"")
            {
                field += "\"";
                i++;
            }
            else
                isQuoted = NO;

            continue;
        }

        if (character === "\"" && !fieldStarted)
        {
            isQuoted = YES;
            fieldStarted = YES;
        }
        else if (character === aDelimiter)
        {
            record.push(field);
            field = "";
            fieldStarted = NO;
        }
        else if (character === "\r" || character === "\n")
        {
            if (character === "\r" && aString.charAt(i + 1) === "\n")
                i++;

            record.push(field);
            records.push(record);
            record = [];
            field = "";
            fieldStarted = NO;
        }
        else
        {
            field += character;
            fieldStarted = YES;
        }
    }

    if (fieldStarted || record.length)
    {
        record.push(field);
        records.push(record);
    }

    return records;
}

@end
