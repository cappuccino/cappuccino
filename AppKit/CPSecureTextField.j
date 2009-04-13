@import "CPTextField.j"

#include "Platform/Platform.h"

@implementation CPSecureTextField : CPTextField
{
}

- (BOOL)isSecure
{
    return YES;
}

@end
