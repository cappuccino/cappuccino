
var FILE = require("file"),
    compressor = require("minify/shrinksafe");

var FILENAMES = [
        "Class/root-class",
        "Class/root-class-one-ivar",
        "Class/root-class-multiple-ivars",
        "Class/root-class-with-accessor-ivar",
        "Class/root-class-with-readonly-accessor-ivar",

        "Messages/no-parameters",
        "Messages/one-parameter",
        "Messages/multiple-parameters",
        "Messages/ternary-operator-argument"
                ];

@implementation PreprocessorTest : OJTestCase
{
}

+ (void)initialize
{
    var index = 0,
        count = FILENAMES.length;

    for (; index < count; ++index)
    {
        var filename = FILENAMES[index],
            testSelector = sel_getUid("test" + FILENAMES[index]);

        (function(){
            var aFilename = filename;
            class_addMethod(self, testSelector, function(self, _cmd)
            {
                var filePath = FILE.join(FILE.dirname(module.path), aFilename + ".j"),
                    unpreprocessed = FILE.read(filePath, { charset:"UTF-8" }),
                    preprocessed = ObjectiveJ.preprocess(unpreprocessed).code(),
                    correct = FILE.read(FILE.join(FILE.dirname(module.path), aFilename + ".js"));


                preprocessed = compressor.compress(preprocessed, { charset : "UTF-8", useServer : true });
                correct = compressor.compress(correct, { charset : "UTF-8", useServer : true });

                [self assert:preprocessed equals:correct];
            });
        })()
    }
}

@end

[PreprocessorTest alloc];