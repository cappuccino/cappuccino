//
//  OperationError.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/21/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, XCCOperationErrorType)
{
    XCCDefaultOperationErrorType,
    XCCCappLintOperationErrorType,
    XCCObjjOperationErrorType,
    XCCObjj2ObjcSkeletonOperationErrorType,
    XCCNib2CibOperationErrorType
};


@interface XCCOperationError : NSObject

@property (copy) NSString  *fileName;
@property (copy) NSString  *message;
@property (copy) NSString  *command;
@property (copy) NSString  *lineNumber;
@property int              errorType;

+ (NSArray *)operationErrorsFromObjj2ObjcSkeletonInfo:(NSDictionary*)info;
+ (NSArray *)operationErrorsFromObjjInfo:(NSDictionary*)info;
+ (NSArray *)operationErrorsFromCappLintInfo:(NSDictionary *)info;
+ (XCCOperationError *)operationErrorFromNib2CibInfo:(NSDictionary*)info;

@end
