/*
 * AppController.j
 * MultipleValueBindings
 *
 * Created by Aparajita Fishman on February 12, 2013.
 * Copyright 2013, Cappuccino Foundation. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPAlert.j>

@import "Transformers.j"


@implementation AppController : CPObject
{
    @outlet CPWindow            theWindow;
    @outlet CPSlider            slider1 @accessors;
    @outlet CPSlider            slider2 @accessors;
    CPObject                    foo @accessors;
    CPString                    currentDate @accessors;
    CPString                    currentTime @accessors;
    CPArray                     people @accessors;
    @outlet CPArrayController   peopleController;
    BOOL                        allowColorChange @accessors;
    BOOL                        canEditPeople @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        foo = nil;
        [self setNow];
        [self setAllowColorChange:NO];
        [self setCanEditPeople:YES];
        people = [
            [CPDictionary dictionaryWithObjectsAndKeys:@"tom", @"firstname", @"jones", @"lastname", 27, @"age", 0, @"numberOfChildren"],
            [CPDictionary dictionaryWithObjectsAndKeys:@"dick", @"firstname", @"clark", @"lastname", 31, @"age", 4, @"numberOfChildren"],
            [CPDictionary dictionaryWithObjectsAndKeys:@"harry", @"firstname", @"james", @"lastname", 47, @"age", 2, @"numberOfChildren"]
        ];
    }

    return self;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [CPTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setNow) userInfo:nil repeats:YES];
}

- (void)awakeFromCib
{
}

- (@action)setNullArgument:(id)sender
{
    [self setFoo:[sender state] === CPOnState ? nil : self];
}

- (void)showValueForSlider1:(int)slider1Value andSlider2:(int)slider2Value foo:(id)foo
{
    [[CPAlert alertWithMessageText:[CPString stringWithFormat:@"Slider1: %d\nSlider2: %d", slider1Value, slider2Value]
                     defaultButton:@"OK"
                   alternateButton:nil
                       otherButton:nil
         informativeTextWithFormat:nil] runModal];
}

- (void)sayHello
{
    [[CPAlert alertWithMessageText:@"Hello!"
                     defaultButton:@"OK"
                   alternateButton:nil
                       otherButton:nil
         informativeTextWithFormat:nil] runModal];
}

- (void)showHelp
{
    [[CPAlert alertWithMessageText:@"So you want some help?"
                     defaultButton:@"Help!"
                   alternateButton:nil
                       otherButton:nil
         informativeTextWithFormat:nil] runModal];
}

- (void)setNow
{
    var now = [CPDate date];

    [self setCurrentDate:[CPString stringWithFormat:@"%d/%d/%d", now.getMonth() + 1, now.getDate(), now.getFullYear()]];
    [self setCurrentTime:[CPString stringWithFormat:@"%02d:%02d:%02d", now.getHours(), now.getMinutes(), now.getSeconds()]];
}

@end
