/*
 * AppController.j
 * CPFormatterTest
 *
 * Created by aparajita on July 6, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPFormatter.j>


@implementation DateFormatter : CPFormatter
{
    CPString    displayFormat;
    CPString    editingFormat;
    BOOL        emptyIsValid @accessors(getter=isEmptyValid);
}

+ (DateFormatter)formatterWithDisplayFormat:(CPString)aDisplayFormat editingFormat:(CPString)anEditingFormat emptyIsValid:(BOOL)emptyValid
{
    return [[self alloc] initWithDisplayFormat:aDisplayFormat editingFormat:anEditingFormat emptyIsValid:emptyValid];
}

- (id)initWithDisplayFormat:(CPString)aDisplayFormat editingFormat:(CPString)anEditingFormat emptyIsValid:(BOOL)emptyValid
{
    self = [super init];

    if (self)
    {
        displayFormat = aDisplayFormat;
        editingFormat = anEditingFormat;
        emptyIsValid = emptyValid;
    }

    return self;
}

- (CPString)stringForObjectValue:(id)anObject
{
    var result;

    if ([anObject isKindOfClass:[CPDate class]])
        result = anObject.dateFormat(displayFormat);
    else
        result = nil;

    console.log("stringForObjectValue:%s ==> %s", [anObject description], result);
    return result;
}

- (CPString)editingStringForObjectValue:(id)anObject
{
    var result;

    if ([anObject isKindOfClass:[CPDate class]])
        result = anObject.dateFormat(editingFormat);
    else
        result = nil;

    console.log("editingStringForObjectValue:%s ==> %s", [anObject description], result);
    return result;
}

- (BOOL)getObjectValue:(CPStringRef)anObject forString:(CPString)aString errorDescription:(CPStringRef)anError
{
    var result;

    if (anError)
        anError(nil);

    if (aString.length === 0)
    {
        anObject(nil);
        result = emptyIsValid;

        if (anError)
            anError(@"Please enter a date.");
    }
    else
    {
        var date = Date.parseDate(aString, editingFormat);

        anObject(date);

        if (date === nil && anError)
            anError(@"Invalid date format.");

        result = date !== nil;
    }

    console.log("getObjectValue:forString:%s ==> %s", aString, result);
    return result;
}

@end

var DateFormatterDisplayFormatKey = @"DateFormatterDisplayFormatKey",
    DateFormatterEditingFormatKey = @"DateFormatterEditingFormatKey",
    DateFormatterEmptyIsValidKey = @"DateFormatterEmptyIsValidKey";

@implementation DateFormatter (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        displayFormat = [aCoder decodeObjectForKey:DateFormatterDisplayFormatKey];
        editingFormat = [aCoder decodeObjectForKey:DateFormatterEditingFormatKey];
        emptyIsValid = [aCoder decodeObjectForKey:DateFormatterEmptyIsValidKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:displayFormat forKey:DateFormatterDisplayFormatKey];
    [aCoder encodeObject:editingFormat forKey:DateFormatterEditingFormatKey];
    [aCoder encodeObject:emptyIsValid forKey:DateFormatterEmptyIsValidKey];
}

@end
