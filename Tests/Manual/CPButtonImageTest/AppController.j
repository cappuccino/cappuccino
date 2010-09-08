/*
 * AppController.j
 * CPButtonImageTest
 *
 * Created by Aparajita Fishman on August 31, 2010.
 */

@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);


@implementation AppController : CPObject
{
    CPWindow                theWindow;

    @outlet CPButton        button;
    @outlet CPButton        imageButton;
    @outlet CPCheckBox      checkbox;
    @outlet CPCheckBox      multiCheckbox;
    @outlet CPRadio         radio1;
    @outlet CPRadio         radio2;
    @outlet CPPopUpButton   positionMenu;

    CPArray buttons;
    CPArray checksAndRadios;
}

- (void)awakeFromCib
{
    var path = [[CPBundle bundleForClass:[CPView class]] pathForResource:@"action_button.png"];
    [imageButton setImage:[[CPImage alloc] initWithContentsOfFile:path size:CGSizeMake(22.0, 14.0)]];

    [self _setImagePosition:CPImageLeft];
    [positionMenu selectItemAtIndex:CPImageLeft];
    [self _setupButtons];
}

- (void)_setupButtons
{
    buttons = [button, imageButton];
    checksAndRadios = [checkbox, multiCheckbox, radio1, radio2];

    var checkboxHeight = [checkbox frameSize].height,
        radioHeight = [radio1 frameSize].height;

    [buttons makeObjectsPerformSelector:@selector(sizeToFit)];
    [checksAndRadios makeObjectsPerformSelector:@selector(sizeToFit)];

    [checkbox setFrameSize:CGSizeMake([checkbox frameSize].width, checkboxHeight)];
    [multiCheckbox setFrameSize:CGSizeMake([multiCheckbox frameSize].width, checkboxHeight)];

    [radio1 setFrameSize:CGSizeMake([radio1 frameSize].width, radioHeight)];
    [radio2 setFrameSize:CGSizeMake([radio2 frameSize].width, radioHeight)];

    [multiCheckbox setState:CPMixedState];
}

- (void)setImagePosition:(id)sender
{
    [self _setImagePosition:[sender indexOfSelectedItem]];
}

- (void)_setImagePosition:(unsigned)position
{
    [buttons makeObjectsPerformSelector:@selector(setImagePosition:) withObject:position];
    [checksAndRadios makeObjectsPerformSelector:@selector(setImagePosition:) withObject:position];

    var alignment;

    switch (position)
    {
        case CPImageOnly:
            return;

        case CPNoImage:
        case CPImageAbove:
        case CPImageBelow:
        case CPImageOverlaps:
            alignment = CPCenterTextAlignment;
            break;

        case CPImageLeft:
            alignment = CPLeftTextAlignment;
            break;

        case CPImageRight:
            alignment = CPRightTextAlignment;
            break;
    }

    [checksAndRadios makeObjectsPerformSelector:@selector(setAlignment:) withObject:alignment];
}

@end

@implementation BezelView : CPView

- (void)drawRect:(CGRect)dirtyRect
{
    var sides = [CPMinYEdge, CPMaxYEdge, CPMinXEdge, CPMaxXEdge],
        grays = [0.75, 1.0, 0.75, 1.0];

    CPDrawTiledRects(dirtyRect, dirtyRect, sides, grays);
}

@end
