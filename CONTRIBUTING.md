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

## Commit Messages

The style and format of your commit messages are very important to the health of the project. A good commit message helps not only users reading the release notes, but also your fellow Cappuccino developers as they review `git log` or `git blame` to figure out what you were doing.

Commit messages should be in the following format:

    <type>: <summary>

    <body>

    <footer>

### Types

Allowed `type` values are:

* **New** — A new feature has been implemented
* **Fixed** — A bug has been fixed
* **Docs** — Documentation has been added or tweaked
* **Formatting** — Code has been reformatted to conform to style guidelines
* **Test** — Test cases have been added
* **Task** — A build task has been added or updated

### Message summary

The summary is one of the most important parts of the commit message, because that is what we see when scanning through a list of commits, and it is also what we use to generate change logs.

The summary should be a **concise** description of the commit, preferably 72 characters or less (so we can see the entire description in github), beginning with a lowercase letter and with a terminating period. It should describe only the core issue addressed by the commit. If you find that the summary needs to be very long, your commit is probably too big! Smaller commits are better.

For a `New` commit, the summary should answer the question, “What is new and where?” For a `Fixed` commit, the summary should answer the question, “What was fixed?”, for example “Window content view overlapped frame”. It should **not** answer the question, “What was done to fix it?” That belongs in the body.

Do **not** simply reference another issue or pull request by number in the summary. First of all, we want to know what was actually changed and why, which may not be fully explained in the referenced issue. Second, github will not create a link to the referenced issue in the commit summary.

### Message body

The details of the commit go in the body. Specifically, the body should include the motivation for the change for `New`, `Fixed` and `Task` types. For `Fixed` commits, you should also contrast behavior before the commit with behavior after the commit.

If the summary can completely express everything, there is no need for a message body.

### Message footer

If the commit closes an issue by fixing the bug, implementing a feature, or rendering it obsolete, or if it references an issue without closing it, that should be indicated in the message footer.

Issues closed by a commit should be listed on a separate line in the footer with an appropriate prefix:

- "Fixes" for `Fixed` commit types
- "Closes" for all other commit types

For example:

    Fixes #1234

or in the case of multiple issues, like this:

    Fixes #1234, #2345

Issues that a commit references without closing them should be listed on a separate line in the footer with the prefix "Refs", like this:

    Refs #1234

or in the case of multiple issues, like this:

    Refs #1234, #2345

If a commit changes the API or behavior in such a way that existing code may break, a description of the change, what might break, and how existing code should be modified **must** be noted in the footer like this:

    BREAKING CHANGE:
    The scroller orientation is no longer calculated from the size,
    but is read from the xib during nib2cib.

    All existing xibs should be regenerated by executing the following
    within a project directory: `find . -name *.xib -exec nib2cib {} \;`

### Examples

    New: custom rendered pattern fill/stroke.

    Canvas supports using another canvas as the source for a pattern fill
    or stroke. We needed an API for this that fit into the rest of the
    CGContext API.

    CGContextCreatePatternContext returns a context into which any arbitrary
    drawing can be done. This context can then be passed to CGContextSetFillPattern
    or CGContextSetStrokePattern to render the drawing into the current drawing context.

    Test app in Tests/Manual/PatternFillTest.

***

    Fixed: CPAlert was a CPView.

    Previously, CPAlert subclassed CPView, causing an API mismatch
    with Cocoa and exposing unexpected methods in the public API which
    made no sense for a CPAlert, such as autoresizing masks. It also led
    to CPAlert mistakingly shadowing _window from its CPView superclass.

    This commit makes CPAlert inherit from CPObject as it should. The theming,
    which needs to be applied to a view, was moved to an internal view.

    Fixes #307

***

    Fixed: CPScroller did not retrieve orientation from the xib.

    Previously, CPScrollers created from cibs calculated their orientation
    (horizontal/vertical) based on their size. Unfortunately this did not
    account for the unlikely case where a horizontal scroller's width < height,
    and vice versa.

    Now the CPScroller's orientation is read from the xib and is guaranteed
    to be correct.

    Fixes #1027

    BREAKING CHANGE:
    The scroller orientation is no longer calculated from the size,
    but is read from the xib during nib2cib.

    All existing xibs should be regenerated by executing the following
    within a project directory: `find . -name *.xib -exec nib2cib {} \;`

***

    Docs: Typo in CPWindow -minSize.

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

A case label should be indented once from its switch statement. The case statement is indented once from its label. There should be one blank line between case + code blocks.

##### Right:

    switch (condition)
    {
        case fooCondition:
        case barCondition:
            i++;
            break;

        case bazCondition:
            i += 2;
            break;

        default:
            i--;
    }

##### Wrong:

    switch (condition) {
        case fooCondition:
        case barCondition:
            i++;
            break;
        case bazCondition:  i += 2;
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

There should be blank lines around bracketed code blocks and control structures, and a blank line after multiline var blocks.

##### Right:

    var x,
        y;

    x++;
    y++;

    if (condition)
        doIt();
    else
    {
        doSomethingElse();
        doMore();
    }

    return x;

##### Wrong:

    var x,
        y;
    x++;
    y++;
    if (condition)
        doIt();
    else
    {
        doSomethingElse();
        doMore();
    }
    return x;

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

    var isValid,
        didSendData;

    - (BOOL)isEditable;
    - (BOOL)didReceiveResponse;

##### Wrong:

    var valid,
        sentData;

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
