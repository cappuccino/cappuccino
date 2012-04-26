/*
 * BorderView.j
 * UserlandNSTest
 *
 * Created by aparajita on April 11, 2012.
 * Copyright 2012, The Cappuccino Foundation. All rights reserved.
 */

@import "BorderView.j"

@implementation BorderView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
   self = [super NS_initWithCoder:aCoder];

   if (self)
   {
       borderWidth = BorderViewDefaultBorderWidth;
       borderColor = BorderViewDefaultBorderColor;
   }

   return self;
}

@end

@implementation NS_BorderView : BorderView

+ (Class)classForKeyedArchiver
{
   return [BorderView class];
}

- (id)initWithCoder:(CPCoder)aCoder
{
   return [self NS_initWithCoder:aCoder];
}

@end
