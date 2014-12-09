// Expected output: 256

/*

START_EXPECTED
Error on line 10778 of file [unknown]
SyntaxError:
@typedef MyType
         ^
ERROR line 6 in file:[__PATH__]: MyType is already declared as class
END_EXPECTED

*/

@import <Foundation/Foundation.j>

@implementation MyType : CPObject
@end

@typedef MyType
