/*
 *  CPDynamicImageLoadTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-11.
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

@import <AppKit/AppKit.j>

@implementation CPDynamicImageLoadTest : OJTestCase
{
    CPTheme     _previousTheme;
    CPArray     _views;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _previousTheme = [CPTheme defaultTheme];
    _views = [];
}

/*
    The add image is one shared object, so each view stops observing it.
*/
- (void)tearDown
{
    for (var i = 0; i < _views.length; i++)
        [[CPNotificationCenter defaultCenter] removeObserver:_views[i]];

    [CPTheme setDefaultTheme:_previousTheme];
}

/*
    A theme whose add image is anImage in every appearance and aDarkImage in DarkAqua.
*/
- (CPTheme)themeWithAddImage:(CPImage)anImage darkImage:(CPImage)aDarkImage
{
    var theme = [[CPTheme alloc] initWithName:@"CPDynamicImageLoadTest"],
        template = [[CPImage alloc] init];

    [template setValue:anImage forThemeAttribute:@"add-template"];

    if (aDarkImage)
        [template setValue:aDarkImage forThemeAttribute:@"add-template" inState:CPThemeStateAppearanceDarkAqua];

    [theme takeThemeFromObject:template];

    return theme;
}

- (CPImage)addImage
{
    return [CPImage imageNamed:CPImageNameAddTemplate];
}

/*
    Returns an image whose size is unknown until it loads, as an image file that the browser
    still loads.
*/
- (CPImage)loadingImage:(CPString)aFilename
{
    return [[CPImage alloc] initByReferencingFile:aFilename size:CGSizeMake(-1, -1)];
}

/*
    Completes the load of anImage as the browser does: the image element gets its size, and the
    image posts CPImageDidLoadNotification.
*/
- (void)completeLoadOf:(CPImage)anImage
{
    anImage._image = {width: 10, height: 10};
    [anImage _imageDidLoad];
}

- (CPImageView)imageView
{
    var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];

    _views.push(imageView);

    return imageView;
}

/*
    Returns the objects of the load notifications that anImage posts while aFunction runs.
*/
- (CPArray)notificationsFrom:(CPImage)anImage during:(Function)aFunction
{
    var objects = [],
        observer = [[CPNotificationCenter defaultCenter] addObserverForName:CPImageDidLoadNotification object:anImage queue:nil usingBlock:function(aNotification)
        {
            objects.push([aNotification object]);
        }];

    aFunction();

    [[CPNotificationCenter defaultCenter] removeObserver:observer];

    return objects;
}

- (void)testASizeQueryWaitsForTheResolvedImage
{
    var resolvedImage = [self loadingImage:@"later.png"],
        image = [self addImage];

    [CPTheme setDefaultTheme:[self themeWithAddImage:resolvedImage darkImage:nil]];

    var posted = [self notificationsFrom:image during:function()
    {
        [self assert:-1 equals:[image size].width];
        [self completeLoadOf:resolvedImage];
    }];

    [self assert:[image] equals:posted];
}

- (void)testEachResolvedImagePostsWhenItLoads
{
    var lightImage = [self loadingImage:@"light.png"],
        darkImage = [self loadingImage:@"dark.png"],
        image = [self addImage];

    [CPTheme setDefaultTheme:[self themeWithAddImage:lightImage darkImage:darkImage]];

    var posted = [self notificationsFrom:image during:function()
    {
        [image size];

        [[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua] performAsCurrentDrawingAppearance:function()
        {
            [image size];
        }];

        [self completeLoadOf:darkImage];
        [self completeLoadOf:lightImage];
    }];

    [self assert:[image, image] equals:posted];
}

- (void)testAnImageViewShowsAnImageThatLoadsLater
{
    var resolvedImage = [self loadingImage:@"later.png"],
        imageView = [self imageView];

    [CPTheme setDefaultTheme:[self themeWithAddImage:resolvedImage darkImage:nil]];
    [imageView setImage:[self addImage]];
    [imageView layoutIfNeeded];

    [self assertFalse:[imageView needsLayout] message:@"The image view waits while the image loads"];

    [self completeLoadOf:resolvedImage];

    [self assertTrue:[imageView needsLayout] message:@"The image view lays the image out once it loads"];
}

/*
    Another view resolves the add image in Aqua, the application's appearance, and that image
    loads first.
*/
- (void)testAnImageViewWaitsForTheImageOfItsOwnAppearance
{
    var lightImage = [self loadingImage:@"light.png"],
        darkImage = [self loadingImage:@"dark.png"],
        image = [self addImage],
        imageView = [self imageView];

    [CPTheme setDefaultTheme:[self themeWithAddImage:lightImage darkImage:darkImage]];
    [imageView setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua]];
    [imageView setImage:image];
    [imageView layoutIfNeeded];

    [image size];
    [self completeLoadOf:lightImage];

    [self assertFalse:[imageView needsLayout] message:@"The load of the Aqua image leaves the DarkAqua image view waiting"];

    [self completeLoadOf:darkImage];

    [self assertTrue:[imageView needsLayout] message:@"The load of the DarkAqua image lays the image view out"];
}

/*
    The image has loaded in Aqua, where the view receives it, and still loads in DarkAqua, the
    appearance in which the view lays out.
*/
- (void)testAnImageAndTextViewWaitsForTheImageOfItsOwnAppearance
{
    var lightImage = [[CPImage alloc] initByReferencingFile:@"light.png" size:CGSizeMake(10, 10)],
        darkImage = [[CPImage alloc] initByReferencingFile:@"dark.png" size:CGSizeMake(10, 10)],
        view = [[_CPImageAndTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];

    _views.push(view);
    [lightImage _imageDidLoad];

    [CPTheme setDefaultTheme:[self themeWithAddImage:lightImage darkImage:darkImage]];
    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameDarkAqua]];
    [view setImage:[self addImage]];
    [view layoutIfNeeded];

    [self assertFalse:[view needsLayout] message:@"The view waits while its image loads"];

    [darkImage _imageDidLoad];

    [self assertTrue:[view needsLayout] message:@"The load of the DarkAqua image lays the view out"];
}

@end
