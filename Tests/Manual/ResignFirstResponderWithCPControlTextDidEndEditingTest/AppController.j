/*
 * AppController.j
 * resignFirstResponder-CPControlTextDidEndEditing
 *
 * Created by aparajita on September 2, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPTextField field1;
    @outlet CPTextField field2;
    @outlet CPTextField status;
}

- (void)awakeFromCib
{
    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(showNote:) name:CPControlTextDidBeginEditingNotification object:field1];
    [center addObserver:self selector:@selector(showNote:) name:CPControlTextDidEndEditingNotification object:field1];
    [center addObserver:self selector:@selector(showNote:) name:CPControlTextDidBeginEditingNotification object:field2];
    [center addObserver:self selector:@selector(showNote:) name:CPControlTextDidEndEditingNotification object:field2];

    [status setStringValue:@""];
}

- (void)showNote:(CPNotification)note
{
    var fieldName = [note object] === field1 ? "field1" : "field2";
    [status setStringValue:[CPString stringWithFormat:@"%@\n%@", fieldName, [note name]]];
}

@end
