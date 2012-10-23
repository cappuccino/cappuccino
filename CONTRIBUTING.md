Contributing
------------

As an open source project, your contributions are important to the future of Cappuccino. Whether you're looking to write code, add new documentation, or just report a bug, you'll be helping everyone who uses Cappuccino in the future.

## Reporting Bugs

We use [GitHub to track issues](https://github.com/cappuccino/cappuccino/issues). You might be interested in our [issue life cycle](http://www.cappuccino-project.org/community/contribute/the-issue-lifecycle/) which explains the process of how an issue is taken from new to resolved.

## Patches

To contribute a patch or a fix, fork Cappuccino and then clone your fork and make the changes to a branch of your fork:

    git clone https://github.com/<your username>/cappuccino.git
    git checkout -b descriptive-branch-name master

    # Check that the unit tests work.
    jake test

    # Make changes. Make sure you follow the coding style guidelines and write unit tests.

    # Check that everything is still working, then commit.
    jake test
    git commit

    git push origin descriptive-branch-name

Now you can go to GitHub and [make a pull request](https://help.github.com/articles/using-pull-requests).

Some things are difficult to unit test in a way that's worthwhile. For instance a change to the mouse interaction of a `CPButton`. In this case a manual test is fine instead. Find the closest related manual test in `Tests/Manual` and add whatever it takes to easily reproduce the patched behavior, ideally with some labels describing how someone running the manual test should exercise it.

## Cappuccino Coding Style Guidelines

### Trailing whitespace
Leave no trailing spaces or tabs at the end of a line (`trailing whitespace`), even if the line is empty and in an otherwise indented block.

### Indentation

Use spaces, not tabs. Tabs should only appear in files that require them for semantic meaning, like Makefiles (which there are currently none of). The indent size is 4 spaces.

##### Right:

    function main()
    {
        return 0;
    }

##### Wrong:

    function main()
    {
            return 0;
    }

---

A case label should be indented once from its switch statement. The case statement is indented out from the longest label.

##### Right:

    switch (condition)
    {
        case fooCondition:
        case barCondition:  i++;
                            break;

        default:            i--;
    }

##### Wrong:

    switch (condition) {
        case fooCondition:
        case barCondition:
            i++;
            break;
        default:
            i--;
    }

### Spacing

Do not place spaces around unary operators.

##### Right:

    i++

##### Wrong:

    i ++

---

Do place spaces around binary and ternary operators.

##### Right:

    y = m * x + b;
    f(a, b);
    c = a | b;
    return condition ? 1 : 0;

##### Wrong:

    y=m*x+b;
    f(a,b);
    c = a|b;
    return condition ? 1:0;

---

Place spaces between control statements and their parentheses.

##### Right:

    if (condition)
        doIt();

##### Wrong:

    if(condition)
        doIt();

---

Do not place spaces between a function and its parentheses, or between a parenthesis and its content.

##### Right:

    f(a, b);

##### Wrong:

    f (a, b);
    f( a, b );

---

Do not place spaces between the return type of an Objective-J method and the selector name. DO place spaces between the method type and the method return type.

##### Right:

    - (void)method;

##### Wrong:

    - (void) method;
    -(void)method;

---

Do not place spaces between Objective-J selectors and arguments.

##### Right:

    [myNumber addNumber:5]

##### Wrong:

    [myNumber addNumber: 5]

### Line breaking

Each statement should get its own line.

##### Right:

    var x,
        y;
    x++;
    y++;
    if (condition)
        doIt();

##### Wrong:

    var x, y;
    x++; y++;
    if (condition) doIt();

### Braces

Every brace gets its own line, very simple to remember:

##### Right:

    int main()
    {
        //...
    }

    if (condition)
    {
        //...
    }
    else if (condition)
    {
        //...
    }

    @implementation MyObject : CPObject
    {
    }

    @end

##### Wrong:

    int main() {
        ...
    }

    if (condition) {
        ...
    } else if (condition) {
        ...
    }

    @implementation MyObject : CPObject {}
    @end

### Null, false and 0

In JavaScript, the null object value should be written as null. In Objective-J, it should be written as `nil` when the variable refers to an object, and `Nil` when it refers to a `Class`. Objective-J `BOOL` values should be written as `YES` and `NO`.

Tests for `true/false`, `null/non-null`, and zero/non-zero should all be done without equality comparisons, except for cases when a value could be both 0 or `null` (or another "falsey" value). In this case, the comparison should be preceded by a comment explaining the distinction.

##### Right:

    if (condition)
        doIt();

    if (!ptr)
        return;

    if (!count)
        return;

    // object is an ID number, so 0 is OK, but null is not.
    if (object === null)
        return;

##### Wrong:

    if (condition == true)
        doIt();

    if (ptr == NULL)
        return;

    if (count == 0)
        return;

    if (object == null)
        return;

---

In Objective-J, instance variables are initialized to `nil` automatically. Don't add explicit initializations to `nil` or `NO` in an init method.

### Names

Use CamelCase. Capitalize the first letter of a class. Lower-case the first letter of a variable or function name. Fully capitalize acronyms.

##### Right:

    @implementation Data : //...
    @implementation HTMLDocument : //...

##### Wrong:

    @implementation data : //...
    @implementation HtmlDocument : //...

---

Multiple var declarations should be collapsed with commas.

##### Right:

    var index = 0,
        count = 5;

##### Wrong:

    var index = 0;
    var count = 5;

---

Variable declarations should be created as needed, rather than up front ("hoisted").

##### Right:

    - (BOOL)doSomething:(id)aFoo
    {
        var importantVariable = [aFoo message];
        if (!importantVariable)
            return;

        var index = [aFoo count];
        while (index--)
        {
            var innerVariable = [aFoo objectAtIndex:index];
            //do something;
        }
    }

##### Wrong:

    - (BOOL)doSomething:(id)aFoo
    {
        var importantVariable = [aFoo message],
            index = [aFoo count],
            innerVariable;

        if (!importantVariable)
            return;

        while (index--)
        {
            innerVariable = [aFoo objectAtIndex:index];
            //do something;
        }
    }

---

Use full words, except in the rare case where an abbreviation would be more canonical and easier to understand.

##### Right:

    var characterSize,
        length,
        tabIndex; // more canonical

##### Wrong:

    var charSize,
        len,
        tabulationIndex; // bizarre

---

Prefix Objective-J instance variables with `_`, but only when writing code for the Cappuccino frameworks. User level (application) code should not prefix variables with `_`. This prevents conflicts between the two scopes.

##### Right:

    @implementation CPString
    {
        unsigned _length;
    }
    @end

##### Wrong:

    @implementation CPString
    {
        unsigned length;
    }
    @end

---

Precede boolean values with words like "is" and "did".

##### Right:

    var isValid;
    var didSendData;
    - (BOOL)isEditable;
    - (BOOL)didReceiveResponse;

##### Wrong:

    var valid;
    var sentData;
    - (BOOL)editable;
    - (BOOL)receivedResponse;

---

Precede setters with the word "set". Use bare words for getters. Setter and getter names should match the names of the variables being set/gotten.

##### Right:

    - (void)setCount:(unsigned)aCount; // sets _count
    - (unsigned)count; // returns _count

##### Wrong:

    - (unsigned)getCount;

---

Use descriptive verbs in function names, and place desired types in comments.

##### Right:

    function convertToASCII(/*String*/ aString)

##### Wrong:

    function toASCII(str)

---

Use descriptive parameter names that are not abbreviated.

##### Right:

    - (void)convertString:(CPString)aString toFormat:(Format)aFormat;
    - (void)appendSubviews:(CPArray)subviews inOrder:(BOOL)shouldBeInOrder;

##### Wrong:

    - (void)convertString:(CPString)str toFormat:(Format)f;
    - (void)appendSubviews:(CPArray)s inOrder:(BOOL)flag;

---

Use descriptive parameter types, despite not being fully supported in JavaScript. At some point we will be adding optional static typing, and even until then this serves as a much better indicator of what the method expects. Of course, if the method can truly take any input or return any output, it is perfectly acceptable to use `id`, `CPObject`, or `var`.

##### Right:

    - (char)characterAtIndex:(unsigned)anIndex;
    - (void)insertObject:(id)anObject;

##### Wrong:

    - (String)characterAtIndex:(var)index;

---

Objective-J method names should follow the Cocoa naming guidelines — they should read like a phrase and each piece of the selector should start with a lowercase letter and use intercaps.

Enum members should user InterCaps with an initial capital letter.

`#defined` constants should use all uppercase names with words separated by underscores.

Macros that expand to function calls or other non-constant computation: these should be named like functions, and should have parentheses at the end, even if they take no arguments (with the exception of some special macros like ASSERT).

##### Right:

    #define StopButtonTitle() \
            CPLocalizedString(@"Stop", @"Stop button title")

##### Wrong:

    #define STOP_BUTTON_TITLE \
            CPLocalizedString(@"Stop", @"Stop button title")

    #define StopButtontitle \
            CPLocalizedString(@"Stop", @"Stop button title")

### import Statements

1. Include external frameworks first.
2. Include Foundation classes before AppKit classes.
3. Include files in alphabetical order.
4. Use local imports whenever possible.

##### Right:

    // (Within AppKit)
    import <Foundation/CPObject.j>
    import <Foundation/CPArray.j>

    import "CPTabViewItem.j"
    import "CPTabView.j"

##### Wrong:

    // (Within AppKit)
    import "CPTabView.j"
    import <AppKit/CPTabViewItem.j>

    import <Foundation/CPArray.j>
    import <Foundation/CPObject.j>
