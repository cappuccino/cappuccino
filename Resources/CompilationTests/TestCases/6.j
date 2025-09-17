// Expected output: 256

/*

START_EXPECTED
Error on line 10775 of file [unknown]
SyntaxError:
@typedef MyType
         ^
ERROR line 2 in file:[__PATH__]: Duplicate type definition MyType
END_EXPECTED

*/

@typedef MyType
@typedef MyType
