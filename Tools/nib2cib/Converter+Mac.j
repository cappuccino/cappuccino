/*
 * Converter+Mac.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
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


@import "Converter.j"


@implementation Converter (Mac)

- (void)convertedDataFromMacData:(CPData)data resourcesPath:(CPString)aResourcesPath
{
    // Unarchive the NS data
    var unarchiver = [[Nib2CibKeyedUnarchiver alloc] initForReadingWithData:data resourcesPath:aResourcesPath],
        objectData = [unarchiver decodeObjectForKey:@"IB.objectdata"];

    // Perform a bit of post-processing on fonts and views since all CP views are flipped.
    // It's better to do this here (instead of say, in NSView::initWithCoder:),
    // because at this point all the objects an mappings are stabilized.
    var objects = [unarchiver allObjects],
        count = [objects count];

    while (count--)
    {
        var object = objects[count];

        if ([object respondsToSelector:@selector(font)] &&
            [object respondsToSelector:@selector(setFont:)] &&
            [object font] != nil)
        {
            var nibFont = [object font],
                cibFont = nil;

            if ([object respondsToSelector:@selector(cibFontForNibFont)])
                cibFont = [object cibFontForNibFont];
            else
                cibFont = [NSFont cibFontForNibFont:[object font]];

            if (![cibFont isEqual:nibFont])
            {
                var source = "";

                if (!cibFont)
                {
                    cibFont = [theme valueForAttributeWithName:@"font" inState:[object themeState] forClass:[object class]];

                    if ([cibFont familyName] === "Arial, sans-serif")
                    {
                        var size = [cibFont size];

                        cibFont = [cibFont isBold] ? [CPFont boldSystemFontOfSize:size] : [CPFont systemFontOfSize:size];
                        source = " (from theme)"
                    }
                }

                [object setFont:cibFont];

                CPLog.debug("%s: substituted <%s>%s for <%fpx %s>", [object className], cibFont ? [cibFont cssString] : "theme default", source, [nibFont size], [nibFont familyName]);
            }
        }

        if (![object isKindOfClass:[CPView class]])
            continue;

        var superview = [object superview];

        if (!superview || [superview NS_isFlipped])
            continue;

        var superviewHeight = CGRectGetHeight([superview bounds]),
            frame = [object frame];

        [object setFrameOrigin:CGPointMake(CGRectGetMinX(frame), superviewHeight - CGRectGetMaxY(frame))];

        var NS_autoresizingMask = [object autoresizingMask];

        autoresizingMask = NS_autoresizingMask & ~(CPViewMaxYMargin | CPViewMinYMargin);

        if (!(NS_autoresizingMask & (CPViewMaxYMargin | CPViewMinYMargin | CPViewHeightSizable)))
            autoresizingMask |= CPViewMinYMargin;
        else
        {
            if (NS_autoresizingMask & CPViewMaxYMargin)
                autoresizingMask |= CPViewMinYMargin;
            if (NS_autoresizingMask & CPViewMinYMargin)
                autoresizingMask |= CPViewMaxYMargin;
        }

        [object setAutoresizingMask:autoresizingMask];
    }

    // Re-archive the CP data.
    var convertedData = [CPData data],
        archiver = [[CPKeyedArchiver alloc] initForWritingWithMutableData:convertedData];

    [archiver setDelegate:self];
    [archiver encodeObject:objectData forKey:@"CPCibObjectDataKey"];
    [archiver finishEncoding];

    return convertedData;
}

// For some reason, occasionally an attempt is made to archive NSMatrix. That will fail, so prevent it here.
- (id)archiver:(CPKeyedArchiver)archiver willEncodeObject:(id)object
{
    if ([object isKindOfClass:[NSMatrix class]])
        return nil;
    else
        return object;
}

@end
