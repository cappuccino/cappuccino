/*
 * AppController.j
 * CPFormatterTest
 *
 * Created by aparajita on June 30, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "DateFormatter.j"

var RecordData = [
        {name:"Tom", age:34},
        {name:"Dick", age:27},
        {name:"Harry", age:50}
    ];

var randomFromTo = function(from, to)
{
    return FLOOR(RAND() * (to - from + 1) + from);
};

@implementation AppController : CPObject
{
    CPWindow        theWindow;
    CPTextField     dateField1;
    CPTextField     dateField2;
    CPTextField     error1;
    CPTextField     textField;
    CPTextField     error2;
    CPTextField     recordField;
    CPPopUpButton   recordMenu;
}

- (void)awakeFromCib
{
    [theWindow setInitialFirstResponder:dateField1];
    [dateField1 setFormatter:[DateFormatter formatterWithDisplayFormat:@"D M jS, Y" editingFormat:@"m/j/Y" emptyIsValid:NO]];
    [dateField2 setFormatter:[DateFormatter formatterWithDisplayFormat:@"m-d-Y" editingFormat:@"m-d-Y" emptyIsValid:YES]];
    [dateField2 setDelegate:self];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetErrorMessage:)
                                                 name:CPTextFieldDidFocusNotification
                                               object:nil];

    [textField setFormatter:[TextFormatter new]];
    [textField setDelegate:self];

    [error1 setStringValue:@""];
    [error2 setStringValue:@""];

    [recordField setFormatter:[ContactFormatter new]];
    [recordField setObjectValue:RecordData[0]];
}

- (void)selectRecord:(id)sender
{
    var record = RecordData[[sender selectedIndex]];

    [recordField setObjectValue:record];
}

- (void)setDate1:(id)sender
{
    [self setDate:dateField1];
}

- (void)setDate2:(id)sender
{
    [self setDate:dateField2];
}

- (void)setDate:(CPTextField)field
{
    var date = new Date(randomFromTo(1931, 2012), randomFromTo(0, 11), randomFromTo(1, 31));

    [field setObjectValue:date];
}

- (void)objectValue1:(id)sender
{
    CPLog.info("Date 1: %s", [[dateField1 objectValue] description]);
}

- (void)objectValue2:(id)sender
{
    CPLog.info("Date 2: %s", [[dateField2 objectValue] description]);
}

- (void)setNil:(id)sender
{
    [dateField1 setStringValue:nil];  // should log a warning and do nothing
}

- (void)setEmptyOK:(id)sender
{
    [[dateField2 formatter] setEmptyIsValid:[sender state] === CPOnState];
}

- (void)controlTextDidChange:(CPNotification)aNotification
{
    var field = [aNotification object],
        error;

    if (field === dateField2)
        error = error1;
    else if (field === textField)
        error = error2;

    [error setStringValue:@""];
}

- (BOOL)control:(CPControl)aControl didFailToFormatString:(CPString)aString errorDescription:(CPString)anError
{
    CPLog.info("control:didFailToFormatString:%s errorDescription:%s", aString, anError);

    if (anError)
    {
        var error;

        if (aControl === dateField2)
            error = error1;
        else if (aControl === textField)
            error = error2;

        [error setStringValue:anError];
    }

    return NO;
}

- (void)resetErrorMessage:(CPNotification)aNotification
{
    [error2 setStringValue:@""];
}

@end


@implementation TextFormatter : CPFormatter

- (CPString)stringForObjectValue:(id)anObject
{
    var result;

    if ([anObject isKindOfClass:[CPString class]])
        result = [self errorDescriptionForString:anObject] === nil ? anObject : nil;
    else
        result = nil;

    CPLog.info("stringForObjectValue:%s ==> %s", [anObject description], result);
    return result;
}

- (BOOL)getObjectValue:(CPStringRef)anObject forString:(CPString)aString errorDescription:(CPStringRef)anError
{
    var error = [self errorDescriptionForString:aString];

    if (error)
    {
        anObject(nil);

        if (anError)
            anError(error);
    }
    else
        anObject(aString);

    result = error === nil;

    CPLog.info("getObjectValue:forString:%s ==> %s", aString, result);
    return result;
}

- (CPString)errorDescriptionForString:(CPString)aString
{
    if (aString.length > 7)
        return @"Maximum length is 7 characters.";
    else if (!/^[a-zA-Z0-9]*$/.test(aString))
        return @"Invalid characters in string.";
    else
        return nil;
}

@end


@implementation ContactFormatter : CPFormatter

- (CPString)stringForObjectValue:(id)anObject
{
    if (anObject && typeof(anObject) === "object" && anObject.hasOwnProperty("name"))
        return [CPString stringWithFormat:@"%s (age %d)", anObject.name, anObject.age];
    else
        return nil;
}

- (BOOL)getObjectValue:(CPStringRef)anObject forString:(CPString)aString errorDescription:(CPStringRef)anError
{
    // We don't support reverse conversion
    return NO;
}

@end
