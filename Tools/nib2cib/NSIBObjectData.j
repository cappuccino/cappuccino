
/*#import "NSIBObjectData.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSMutableIndexSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSDebug.h>
#import "NSNibKeyedUnarchiver.h"
#import "NSCustomObject.h"
#import <AppKit/NSNibConnector.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSNib.h>*/

import <Foundation/CPObject.j>

import <AppKit/_CPCibObjectData.j>

@implementation _CPCibObjectData (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [self init];
    
    if (self)
    {
/*        NSNibKeyedUnarchiver *keyed=(NSNibKeyedUnarchiver *)coder;
        NSMutableDictionary  *nameTable=[NSMutableDictionary dictionaryWithDictionary:[keyed externalNameTable]];
        NSArray              *uids=[keyed decodeArrayOfUidsForKey:@"NSNamesKeys"];
        int                   i,count;
        id                    owner;
    
        if((owner=[nameTable objectForKey:NSNibOwner])!=nil)
         [nameTable setObject:owner forKey:@"File's Owner"];
        
        [nameTable setObject:[NSFontManager sharedFontManager] forKey:@"Font Manager"];
      
        

        var count = [_namesValues count];

        for(i=0;i<count;i++){
         NSString *check=[_namesValues objectAtIndex:i];
         id        external=[nameTable objectForKey:check];
              
         if(external!=nil)
          [keyed replaceObject:external atUid:[[uids objectAtIndex:i] intValue]];
        }
*/
        _namesKeys = [aCoder decodeObjectForKey:@"NSNamesKeys"];
        _namesValues = [aCoder decodeObjectForKey:@"NSNamesValues"];

        //_accessibilityConnectors = [aCoder decodeObjectForKey:@"NSAccessibilityConnectors"];
        //_accessibilityOidsKeys = [aCoder decodeObjectForKey:@"NSAccessibilityOidsKeys"];
        //_accessibilityOidsValues = [aCoder decodeObjectForKey:@"NSAccessibilityOidsValues"];
        
        _classesKeys = [aCoder decodeObjectForKey:@"NSClassesKeys"];
        _classesValues = [aCoder decodeObjectForKey:@"NSClassesValues"];
      
        _connections = [aCoder decodeObjectForKey:@"NSConnections"];
        
        //_fontManager = [aCoder decodeObjectForKey:@"NSFontManager"] retain];
        
        _framework = [aCoder decodeObjectForKey:@"NSFramework"];

        _nextOid = [aCoder decodeIntForKey:@"NSNextOid"];

        _objectsKeys = [aCoder decodeObjectForKey:@"NSObjectsKeys"];
        _objectsValues = [aCoder decodeObjectForKey:@"NSObjectsValues"];
        
        _oidKeys = [aCoder decodeObjectForKey:@"NSOidsKeys"];
        _oidValues = [aCoder decodeObjectForKey:@"NSOidsValues"];

        _rootObject = [aCoder decodeObjectForKey:@"NSRoot"];
        _visibleWindows = [aCoder decodeObjectForKey:@"NSVisibleWindows"];
    }

    return self;
}

@end

@implementation NSIBObjectData : _CPCibObjectData
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibObjectData class];
}

@end
