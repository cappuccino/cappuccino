
var FILE = require("file"),
    compressor = require("minify/shrinksafe");

var FILENAMES = [
        "Class/root-class",
        "Class/root-class-one-ivar",
        "Class/root-class-multiple-ivars",

        "Messages/no-parameters",
        "Messages/one-parameter",
        "Messages/multiple-parameters",
        "Messages/ternary-operator-argument",

// TODO Re-enable this test when the new Objective-J parser has been enabled.
// Before that it will fail with "*** Expected "pragma" to follow # but instead saw "]".".
//        "Misc/regex-simple-char-classes"
];

@implementation OutputTest : OJTestCase
{
}

+ (void)initialize
{
    var index = 0,
        count = FILENAMES.length;

    for (; index < count; ++index)
    {
        (function ()
        {
            var filename = FILENAMES[index],
                testSelector = sel_getUid("test" + FILENAMES[index]);

            class_addMethod(self, testSelector, function(self, _cmd)
            {
                var filePath = FILE.join(FILE.dirname(module.path), filename + ".j"),
                    unpreprocessed = FILE.read(filePath, { charset:"UTF-8" }),
                    preprocessed,
                    correct = FILE.read(FILE.join(FILE.dirname(module.path), filename + ".js"));

                [self assertNoThrow:function() {
                    preprocessed = ObjectiveJ.preprocess(unpreprocessed).code(),
                    preprocessed = compressor.compress(preprocessed, { charset : "UTF-8", useServer : true });
                    correct = compressor.compress(correct, { charset : "UTF-8", useServer : true });
                }];

                [self assert:preprocessed equals:correct];
            });
        })();
    }
}

@end

[OutputTest alloc];
