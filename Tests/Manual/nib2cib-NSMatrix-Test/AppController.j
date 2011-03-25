/*
 * AppController.j
 * test
 *
 * Created by aparajita on March 24, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    CPRadio     one1;
    CPRadio     one2;
}

- (void)radioSelected:(id)sender
{
    console.log("selected " + [sender title]);
}

@end
