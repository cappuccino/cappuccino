// Expected output: 256

/*

START_EXPECTED
Error on line 10778 of file [unknown]
SyntaxError:
int myIvar;
    ^
ERROR line 12 in file:[__PATH__]: Instance variable 'myIvar' is already declared for class MySubclass in superclass MySuperclass
END_EXPECTED
*/

@import <Foundation/Foundation.j>

@implementation MySuperclass : CPObject
{
	int myIvar;
}

@end

@implementation MySubclass : MySuperclass
{
	int myIvar;
}

@end