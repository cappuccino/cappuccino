// Expected output: 0

/*

START_EXPECTED
    MyType property1;
           ^
WARNING line 7 in file:[__PATH__]: Unknown type 'MyType' for ivar 'property1'
END_EXPECTED

*/

@import <Foundation/CPObject.j>

@global MyType

@implementation MyCall : CPObject
{
    MyType property1;
}

@end
