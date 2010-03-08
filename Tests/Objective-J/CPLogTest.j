@implementation CPLogTest : OJTestCase

- (void)testCPLogAll
{
    var last = null;
    var testLogger = function(message, level, title) { last = arguments; }

    var log = CPLog.createLogger("asdf");

    log.register(testLogger);

    ["fatal", "error", "warn", "info", "debug", "trace"].forEach(function(level) {
        last = null;
        log[level](level);
        [self assert:last[0] equals:[level]];
        [self assert:last[1] equals:level];
        [self assert:last[2] equals:"asdf"];
    });
}

- (void)testCPLogSingle
{
    var last = null;
    var testLogger = function(message, level, title) { last = arguments; }

    var log = CPLog.createLogger();

    log.registerSingle(testLogger, "info");

    ["fatal", "error", "warn", "info", "debug", "trace"].forEach(function(level) {
        last = null;
        log[level](level);
        if (level === "info")
            [self assert:last[0] equals:[level]];
        else
            [self assert:last equals:null];
    });
}

- (void)testCPLogRange
{
    var last = null;
    var testLogger = function(message, level, title) { last = arguments; }

    var log = CPLog.createLogger();

    log.registerRange(testLogger, "warn", "debug");

    ["fatal", "error", "warn", "info", "debug", "trace"].forEach(function(level) {
        last = null;
        log[level](level);
        if (level === "warn" || level === "info" || level === "debug")
            [self assert:last[0] equals:[level]];
        else
            [self assert:last equals:null];
    });
}

- (void)testCPLogUnregister
{
    var last = null;
    var testLogger = function(message, level, title) { last = arguments; }

    var log = CPLog.createLogger();

    log.register(testLogger);
    log.unregister(testLogger);

    ["fatal", "error", "warn", "info", "debug", "trace"].forEach(function(level) {
        last = null;
        log[level](level);
        [self assert:last equals:null];
    });
}


- (void)testCPLogSetTitle
{
    var last = null;
    var testLogger = function(message, level, title) { last = arguments; }

    var log = CPLog.createLogger();
    log.register(testLogger);

    CPLog.setDefaultTitle("A")
    log("");
    [self assert:last[2] equals:"A"];

    CPLog.setDefaultTitle("B")
    log("");
    [self assert:last[2] equals:"B"];

}

@end
