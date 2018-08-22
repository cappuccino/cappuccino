
var FILE = require("file"),
    compressor = require("minify/shrinksafe");

var FILENAMES = [
        "Class/root-class",
        "Class/root-class-one-ivar",
        "Class/root-class-multiple-ivars",
        "Class/accessors",

        "Messages/no-parameters",
        "Messages/one-parameter",
        "Messages/multiple-parameters",
        "Messages/ternary-operator-argument",
        "Messages/keyword-in-selector",
        "Messages/colon-selector",
        "Messages/self-as-receiver",
        "Messages/complex-receiver",
        "Messages/super-selector",

        "Misc/parenthesis-return",
        "Misc/preprocess-if-directives",
        "Misc/regex-simple-char-classes",
        "Misc/empty-loops",
        "Misc/empty-statements",
        "Misc/ref-self",
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
                var d = FILE.dirname(module.path),
                    filePath = FILE.join(d, filename + ".j"),
                    unpreprocessed = FILE.read(filePath, { charset:"UTF-8" }),
                    preprocessed,
                    preprocessedInlined,
                    correct = FILE.read(FILE.join(d, filename + ".js")),
                    p = FILE.join(d, filename + "-inlined.js"),
                    correctInlined = FILE.exists(p) ? FILE.read(p) : correct; // Get inlined version if it exists. Otherwise use the regular one.

                [self assertNoThrow:function() {
                    preprocessed = ObjectiveJ.ObjJCompiler.compileToExecutable(unpreprocessed, nil, {includeMethodFunctionNames: true, includeMethodArgumentTypeSignatures: true, includeIvarTypeSignatures: true, inlineMsgSendFunctions: false, transformNamedFunctionDeclarationToAssignment: true}).code();
                    preprocessed = compressor.compress(preprocessed, { charset : "UTF-8", useServer : true });
                    correct = compressor.compress(correct, { charset : "UTF-8", useServer : true });

                    // Get an Inlined version
                    preprocessedInlined = ObjectiveJ.ObjJCompiler.compileToExecutable(unpreprocessed, nil, {includeMethodFunctionNames: true, includeMethodArgumentTypeSignatures: true, includeIvarTypeSignatures: true, inlineMsgSendFunctions: true, transformNamedFunctionDeclarationToAssignment:true}).code();
                    preprocessedInlined = compressor.compress(preprocessedInlined, { charset : "UTF-8", useServer : true });
                    correctInlined = compressor.compress(correctInlined, { charset : "UTF-8", useServer : true });
                }];

                [self assert:correct equals:preprocessed];
                [self assert:correctInlined equals:preprocessedInlined];
            });
        })();
    }
}

@end

[OutputTest alloc];
