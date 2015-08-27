//
//  NSMutableArray+moveIndexes.m
//  XcodeCapp
//
//  Created by Antoine Mercadal on 6/2/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "NSMutableArray+moveIndexes.h"

@implementation NSMutableArray (MoveIndexes)

- (void)moveIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)insertIndex
{
    NSUInteger aboveCount = 0;
    id  object;
    NSUInteger removeIndex;
    
    NSUInteger index = [indexes lastIndex];
    
    while (index != NSNotFound)
    {
        if (index >= insertIndex)
        {
            removeIndex = index + aboveCount;
            aboveCount ++;
        }
        else
        {
            removeIndex = index;
            insertIndex --;
        }
        
        object = self[removeIndex];
        
        [self removeObjectAtIndex:removeIndex];
        [self insertObject:object atIndex:insertIndex];
        
        index = [indexes indexLessThanIndex:index];
    }
}

@end
