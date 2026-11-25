/*
 * MaskImage.j
 * People
 *
 * Created by David Richardson.
 * Copyright 2026, The Cappuccino Project.
 *
 * Icons drawn as CSS masks, in the style of the Aristo3 button bar icons: the mask
 * is an SVG data URL, and the colour shows through it. The Edit button of the
 * detail pane and the notes column of the people table use them.
 *
 * Material icons are not used, because the framework does not load the Material
 * Icons font; the browser would draw the icon's name as text.
 */

@import <AppKit/AppKit.j>

/*
    Returns an image of aSize that paints aColor through aMask, a CSS url() of an SVG.
*/
function MaskImage(aMask, aSize, aColor)
{
    return [CPImage imageWithCSSDictionary:@{
                "-webkit-mask-image": aMask,
                "mask-image": aMask,
                "background-color": aColor,
                "-webkit-mask-size": "contain",
                "mask-size": "contain",
                "-webkit-mask-repeat": "no-repeat",
                "mask-repeat": "no-repeat",
                "-webkit-mask-position": "center",
                "mask-position": "center"
            }
            size:aSize];
}
