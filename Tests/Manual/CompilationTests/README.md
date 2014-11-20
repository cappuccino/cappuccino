## Run tests

./run.py


## Create a test case

create a `.j` file in `TestCases` folder:

-First line MUST be:

    // Expected output: [OBJJ_STATUS_CODE]


Then after that add a block comment that contains:

    /*
    START_EXPECTED
    [CONSOLE_OUTPUT_OF_OBJJ]
    END_EXPECTED
    */


Be sure to replace the file path by the token `[__PATH__]` After that, add the code you want to test.

If your test doesn't expect any output, don't put any `START_EXPECTED` and `END_EXPECTED`


For instance:

    /*
    START_EXPECTED
    Error on line 10771 of file [unknown]
    SyntaxError:
    @typedef MyType
             ^
    ERROR line 2 in file:[__PATH__]: Duplicate type definition MyType
    END_EXPECTED
    */
    @import <Foundation/Foundation.j>

    @implementation MyCall : CPObject
    {
        CPString property1;
    }
    @end
