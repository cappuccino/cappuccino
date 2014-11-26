// Expected output: 256

/*

START_EXPECTED
Error on line 10778 of file [unknown]
SyntaxError:
@typedef mytype
         ^
ERROR line 4 in file:[__PATH__]: mytype is already declared as class
END_EXPECTED
*/

@import <Foundation/Foundation.j>

@class mytype
@typedef mytype

