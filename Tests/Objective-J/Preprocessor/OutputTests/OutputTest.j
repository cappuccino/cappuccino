
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
        "Messages/keyword-in-selector",
        "Messages/colon-selector",

        "Misc/parenthesis-return",
        "Misc/preprocess-if-directives",
        "Misc/regex-simple-char-classes",
        "Misc/empty-loops",
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
                    preprocessed = ObjectiveJ.ObjJAcornCompiler.compileToExecutable(unpreprocessed).code();
                    preprocessed = compressor.compress(preprocessed, { charset : "UTF-8", useServer : true });
                    correct = compressor.compress(correct, { charset : "UTF-8", useServer : true });
                }];

                [self assert:correct equals:preprocessed];
            });
        })();
    }
}

@end

[OutputTest alloc];
