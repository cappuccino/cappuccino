//
//  OperationError.m
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/21/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import "XCCOperationError.h"

static NSCharacterSet * XCCOperationErrorNonASCIICharactersSet;

NSArray * parseCommandXMLString(NSString * aString)
{
    if (!XCCOperationErrorNonASCIICharactersSet)
    {
        NSMutableString *ASCIICharacters = [NSMutableString string];

        for (NSInteger i = 32; i < 127; i++)
            [ASCIICharacters appendFormat:@"%c", (char)i];

        [ASCIICharacters appendString:@"\n\t"];

        XCCOperationErrorNonASCIICharactersSet = [[NSCharacterSet characterSetWithCharactersInString:ASCIICharacters] invertedSet];

    }
    aString = [[aString componentsSeparatedByCharactersInSet:XCCOperationErrorNonASCIICharactersSet] componentsJoinedByString:@""];
    aString = [aString stringByReplacingOccurrencesOfString:@"[0m" withString:@""];

    NSInteger i = 0;
    while ((i < [aString length]) && [[NSCharacterSet newlineCharacterSet] characterIsMember:[aString characterAtIndex:i]])
        i++;

    NSArray *info;

    @try
    {
        info = [aString propertyList];
    }
    @catch (NSException *exception)
    {
        info = @[
                 @{
                     @"lineNumber": @"0",
                     @"sourcePath": @"/Unknown",
                     @"message": [NSString stringWithFormat:@"Unable to parse: %@", aString]
                }
                ];
    }

    return info;
}



@implementation XCCOperationError

#pragma mark - Class Methods

+ (instancetype)_operationErrorWithInfo:(NSDictionary*)info type:(int)type
{
    XCCOperationError *operationError = [self new];

    operationError.fileName     = info[@"sourcePath"];
    operationError.errorType    = type;

    switch (type)
    {
        case XCCObjj2ObjcSkeletonOperationErrorType:
            operationError.command      = @"objj2objc2skeleton";
            operationError.lineNumber   = info[@"line"];
            operationError.message      = info[@"message"];
            break;

        case XCCObjjOperationErrorType:
            operationError.command      = @"objj";
            operationError.lineNumber   = info[@"line"];
            operationError.message      = info[@"message"];
            break;

        case XCCNib2CibOperationErrorType:
            operationError.command      = @"nib2cib";
            operationError.message      = info[@"errors"];
            break;

        case XCCCappLintOperationErrorType:
            operationError.command      = @"capp_lint";
            operationError.message      = info[@"message"];
            operationError.lineNumber   = info[@"line"];
            break;
    }

    return operationError;
}

+ (NSArray*)operationErrorsFromObjj2ObjcSkeletonInfo:(NSDictionary*)info
{
    NSArray         *errors = parseCommandXMLString(info[@"errors"]);
    NSMutableArray  *ret    = [@[] mutableCopy];

    for (NSDictionary *error in errors)
        [ret addObject:[XCCOperationError _operationErrorWithInfo:error type:XCCObjj2ObjcSkeletonOperationErrorType]];
    
    return ret;
}

+ (NSArray*)operationErrorsFromObjjInfo:(NSDictionary*)info
{
    NSArray         *errors = parseCommandXMLString(info[@"errors"]);
    NSMutableArray  *ret    = [@[] mutableCopy];

    for (NSDictionary *error in errors)
        [ret addObject:[XCCOperationError _operationErrorWithInfo:error type:XCCObjjOperationErrorType]];

    return ret;
}

+ (NSArray*)operationErrorsFromCappLintInfo:(NSDictionary *)info
{
    NSString        *response           = info[@"errors"];
    NSString        *sourcePath         = info[@"sourcePath"];
    NSMutableArray  *operationErrors    = [@[] mutableCopy];
    NSMutableArray  *errors             = [[response componentsSeparatedByString:@"\n\n"] mutableCopy];

    // We need to remove the first object who is the number of errors and the last object who is an empty line
    [errors removeLastObject];
    [errors removeObjectAtIndex:0];

    for (int i = 0; i < [errors count]; i++)
    {
        NSString            *line;
        NSMutableString     *error      = (NSMutableString*)errors[i];
        NSString            *firstChar  = [NSString stringWithFormat:@"%c" ,[error characterAtIndex:0]];

        if ([[NSScanner scannerWithString:firstChar] scanInt:nil])
            error = (NSMutableString*)[NSString stringWithFormat:@"%@:%@", sourcePath, error];

        NSInteger positionOfFirstColon = [error rangeOfString:@":"].location;

        NSString *errorWithoutPath = [error substringFromIndex:(positionOfFirstColon + 1)];
        NSInteger positionOfSecondColon = [errorWithoutPath rangeOfString:@":"].location;
        line = [errorWithoutPath substringToIndex:positionOfSecondColon];

        NSString *message = [NSString stringWithFormat:@"Code style issue at line %@ of file %@:\n%@", line, sourcePath.lastPathComponent, errorWithoutPath];

        NSDictionary *info = @{@"line": line,
                               @"message": message,
                               @"sourcePath": sourcePath};

        XCCOperationError *operationError = [XCCOperationError _operationErrorWithInfo:info type:XCCCappLintOperationErrorType];

        [operationErrors addObject:operationError];
    }

    return operationErrors;
}

+ (XCCOperationError *)operationErrorFromNib2CibInfo:(NSDictionary*)info
{
    return [XCCOperationError _operationErrorWithInfo:info type:XCCNib2CibOperationErrorType];
}


#pragma mark - Overrides

- (BOOL)isEqualTo:(XCCOperationError*)object
{
    return object.errorType == self.errorType && [object.fileName isEqualToString:self.fileName];
}

- (NSString*)description
{
    if (self.errorType == XCCNib2CibOperationErrorType)
        return @"Converting Interface Files has failed";
    
    if (self.errorType == XCCObjjOperationErrorType)
        return @"Verifying compilation Warnings has failed";

    if (self.errorType == XCCCappLintOperationErrorType)
        return @"Verifying coding style has failed";
    
    if (self.errorType == XCCObjj2ObjcSkeletonOperationErrorType)
        return @"Creating Objective-C Class Pair has failed";
    
    return @"An Unknown Error has been caught"; 
}

@end
