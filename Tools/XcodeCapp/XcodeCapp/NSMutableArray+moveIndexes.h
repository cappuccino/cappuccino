//
//  NSMutableArray+moveIndexes.h
//  XcodeCapp
//
//  Created by Antoine Mercadal on 6/2/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (MoveIndexes)

- (void)moveIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)insertIndex;

@end