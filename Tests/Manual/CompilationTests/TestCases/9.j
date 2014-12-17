// Expected output: 256

/*

START_EXPECTED
Error on line 10014 of file [unknown]
SyntaxError:
@implementation MyType : CPObject
                ^
ERROR line 6 in file:[__PATH__]: Duplicate class MyType
END_EXPECTED

*/

@import <Foundation/Foundation.j>

@implementation MyType : CPObject
@end

@implementation MyType : CPObject
@end

