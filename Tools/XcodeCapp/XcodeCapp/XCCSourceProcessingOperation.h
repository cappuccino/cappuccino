//
//  ProcessSourceOperation.h
//  XcodeCapp
//
//  Created by Aparajita on 4/27/13.
//  Copyright (c) 2013 Cappuccino Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCCAbstractOperation.h"

@class XCCCappuccinoProject;
@class XCCTaskLauncher;

extern NSString * const XCCConversionDidStartNotification;
extern NSString * const XCCConversionDidEndNotification;
extern NSString * const XCCObjjDidStartNotification;
extern NSString * const XCCObjjDidEndNotification;
extern NSString * const XCCCappLintDidStartNotification;
extern NSString * const XCCCappLintDidEndNotification;
extern NSString * const XCCObjj2ObjcSkeletonDidStartNotification;
extern NSString * const XCCObjj2ObjcSkeletonDidEndNotification;
extern NSString * const XCCNib2CibDidStartNotification;
extern NSString * const XCCNib2CibDidEndNotification;
extern NSString * const XCCObjjDidGenerateErrorNotification;
extern NSString * const XCCCappLintDidGenerateErrorNotification;
extern NSString * const XCCObjj2ObjcSkeletonDidGenerateErrorNotification;
extern NSString * const XCCNib2CibDidGenerateErrorNotification;


@interface XCCSourceProcessingOperation : XCCAbstractOperation
{
    NSTask          *task;
}

@property NSString  *sourcePath;

- (instancetype)initWithCappuccinoProject:(XCCCappuccinoProject *)aCappuccinoProject taskLauncher:(XCCTaskLauncher*)aTaskLauncher sourcePath:(NSString *)sourcePath;

@end
