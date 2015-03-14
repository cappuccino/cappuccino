// Expected output: 256

/*

START_EXPECTED
Error on line 10001 of file [unknown]
SyntaxError:
@implementation MyType : CPObject
                ^
ERROR line 5 in file:[__PATH__]: MyType is already declared as a type
END_EXPECTED

*/

@import <Foundation/Foundation.j>

@typedef MyType

@implementation MyType : CPObject
@end
