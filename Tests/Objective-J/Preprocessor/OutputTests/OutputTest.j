
var fs = require("fs");
var path = require("path");
var terser = require("terser");

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

async function compressor(srcCode) {
    var m = await terser.minify(srcCode, { keep_fnames: false, mangle: { properties: true }, toplevel: true });
    return m.code;
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

            class_addMethod(self, testSelector, async function(self, _cmd)
            {
                var d = path.dirname(__filename),
                    filePath = path.join(d, filename + ".j"),
                    unpreprocessed = fs.readFileSync(filePath, {encoding: "utf8"}),
                    preprocessed,
                    preprocessedInlined,
                    correct = fs.readFileSync(path.join(d, filename + ".js"), {encoding: "utf8"}),
                    p = path.join(d, filename + "-inlined.js"),
                    correctInlined = fs.existsSync(p) ? fs.readFileSync(p, {encoding: "utf8"}) : correct; // Get inlined version if it exists. Otherwise use the regular one.

                await [self assertNoThrow: async function() {
                    preprocessed = ObjectiveJ.ObjJCompiler.compile(unpreprocessed, nil, {includeMethodFunctionNames: true, includeMethodArgumentTypeSignatures: true, includeIvarTypeSignatures: true, inlineMsgSendFunctions: false, transformNamedFunctionDeclarationToAssignment: true}).jsBuffer.toString();
                    preprocessed = await compressor(preprocessed);
                    correct = await compressor(correct);

                    // Get an Inlined version
                    preprocessedInlined = ObjectiveJ.ObjJCompiler.compile(unpreprocessed, nil, {includeMethodFunctionNames: true, includeMethodArgumentTypeSignatures: true, includeIvarTypeSignatures: true, inlineMsgSendFunctions: true, transformNamedFunctionDeclarationToAssignment: true}).jsBuffer.toString();
                    preprocessedInlined = await compressor(preprocessedInlined);
                    correctInlined = await compressor(correctInlined);
                }];

                [self assert:correct equals:preprocessed];
                [self assert:correctInlined equals:preprocessedInlined];
            });
        })();
    }
}

@end

[OutputTest alloc];
