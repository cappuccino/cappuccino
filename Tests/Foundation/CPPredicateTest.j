@import <Foundation/Foundation.j>

@implementation CPPredicateTest : OJTestCase
{
    CPDictionary dict;
    CPArray simpleArray;
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        var d,
            objects;

        dict = [[CPDictionary alloc] init];
        [dict setObject: @"Title" forKey:@"title"];

        var keys = [CPArray arrayWithObjects:@"Name",@"Age",@"Children"];
        objects = [CPArray arrayWithObjects:@"John",[CPNumber numberWithInt:34],[CPArray arrayWithObjects:@"Kid1", @"Kid2"]];

        d = [CPDictionary dictionaryWithObjects:objects forKeys:keys];
        [dict setObject:d forKey:@"Record1"];

        objects = [CPArray arrayWithObjects:@"Mary",[CPNumber numberWithInt:30],[CPArray arrayWithObjects:@"Kid1", @"Girl1"]];

        d = [CPDictionary dictionaryWithObjects:objects forKeys:keys];
        [dict setObject:d forKey:@"Record2"];

        simpleArray = [CPArray arrayWithObjects:@"a", @"b", @"ac", @"bc"];

    }
    return self;
}

- (void)testExpressionsInit
{
    var expression_keypath = [CPExpression expressionForKeyPath:@"name"];
    [self assertNotNull:expression_keypath message:"KeyPath Expression should not be nil"];
    [self assertTrue:[expression_keypath keyPath] == @"name" message:"-keyPath should not be \"name\""];

    var expression_str = [CPExpression expressionForConstantValue:@"j[a-z]an"];
    [self assertNotNull:expression_str message:"ConstantValue Expression should not be nil"];

    var expression_num = [CPExpression expressionForConstantValue:[CPNumber numberWithInt:1]];
    [self assertNotNull:expression_num message:"ConstantValue Expression should not be nil"];

    var expression_collection = [CPExpression expressionForConstantValue:[CPArray arrayWithObjects:@"a",@"b",@"d"]];
    [self assertNotNull:expression_collection message:"ConstantValue Expression should not be nil"];

    var expression_var = [CPExpression expressionForVariable:@"variable"];
    [self assertNotNull:expression_var message:"Variable Expression should not be nil"];

    var expression_function = [CPExpression expressionForFunction:@"sum:" arguments:[CPArray arrayWithObjects:expression_num,expression_num]];
    [self assertNotNull:expression_function message:"Function Expression should not be nil"];

    expression_function = [CPExpression expressionForFunction:expression_num selectorName:@"isEqual:" arguments:[CPArray arrayWithObjects:expression_num]];
    [self assertNotNull:expression_function message:"Function Expression with target and selector  should not be nil"];

    var expression_self = [CPExpression expressionForEvaluatedObject];
    [self assertNotNull:expression_self message:"Self Expression should not be nil"];

    var expression_aggregate = [CPExpression expressionForAggregate:[CPArray arrayWithObjects:expression_str,expression_num]];
    [self assertNotNull:expression_aggregate message:"Aggregate Expression should not be nil"];

    var expression_subquery = [CPExpression expressionForSubquery:expression_collection usingIteratorVariable:@"self" predicate:[CPPredicate predicateWithValue:YES]];
    [self assertNotNull:expression_subquery message:"Subquery Expression should not be nil"];

    var set = [CPExpression expressionForConstantValue:[CPSet setWithObjects:@"a",@"b",@"c"]],
        array = [CPExpression expressionForConstantValue:[CPArray arrayWithObjects:@"a",@"b",@"d"]],
        expression_intersect = [CPExpression expressionForIntersectSet:set with:array];

    [self assertNotNull:expression_intersect message:"IntersectSet Expression should not be nil"];

    var expression_unionset = [CPExpression expressionForUnionSet:set with:array];
    [self assertNotNull:expression_unionset message:"UnionSet Expression should not be nil"];

    var expression_minusset = [CPExpression expressionForMinusSet:set with:array];
    [self assertNotNull:expression_minusset message:"MinusSet Expression should not be nil"];
}

- (void)testSetExpressionEvaluation
{
    var left = [CPExpression expressionForConstantValue:[CPSet setWithObjects:@"a", @"b", @"c"]],
        right = [CPExpression expressionForConstantValue:[CPArray arrayWithObjects:@"a", @"b", @"d"]];

    var expression = [CPExpression expressionForIntersectSet:left with:right],
        eval = [expression expressionValueWithObject:nil context:nil];
    [self assertTrue:[eval isEqualToSet:[CPSet setWithObjects:@"a", @"b"]] message:"Result should be {(a, b)}, is " + eval];

    expression = [CPExpression expressionForUnionSet:left with:right];
    eval = [expression expressionValueWithObject:nil context:nil];
    [self assertTrue:[eval isEqualToSet:[CPSet setWithObjects:@"a", @"b", @"c", @"d"]] message:"Result should be {(a, b, c, d)}, is " + eval];

    expression = [CPExpression expressionForMinusSet:left with:right];
    eval = [expression expressionValueWithObject:nil context:nil];
    [self assertTrue:[eval isEqualToSet:[CPSet setWithObjects:@"c"]] message:"Result should be {(c)}, is " + eval];
}

- (void)testFunctionExpressionEvaluation
{
    // Built-in function
    var args = [[CPExpression expressionForConstantValue:1], [CPExpression expressionForConstantValue:2], [CPExpression expressionForConstantValue:3]],
        function_exp = [CPExpression expressionForFunction:"sum:" arguments:args],
        pred = [[CPComparisonPredicate alloc] initWithLeftExpression:function_exp rightExpression:[CPExpression expressionForConstantValue:6] modifier:CPDirectPredicateModifier type:CPEqualToPredicateOperatorType options:0];

    [self assertTrue:[pred evaluateWithObject:nil] message:[pred description] + " should be true"];

    // Custom function
    var operand = [CPExpression expressionForConstantValue:@"text"],
        arg = [CPExpression expressionForConstantValue:2];
    function_exp = [CPExpression expressionForFunction:operand selectorName:@"substringFromIndex:" arguments:[arg]];
    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:function_exp rightExpression:[CPExpression expressionForConstantValue:@"xt"] modifier:CPDirectPredicateModifier type:CPEqualToPredicateOperatorType options:0];
    [self assertTrue:[pred evaluateWithObject:nil] message:[pred description] + " should be true"];
}

- (void)testVariableExpressionEvaluation
{
// Replace with constant
    var expression = [CPExpression expressionForVariable:@"variable"],
        bindings = [CPDictionary dictionaryWithObject:20 forKey:@"variable"],
        eval = [expression expressionValueWithObject:@"variable" context:bindings];
    [self assertTrue:(eval == 20) message:"'" + eval  + "' should be 20"];

// Replace with constant expression
    bindings = [CPDictionary dictionaryWithObject:[CPExpression expressionForConstantValue:10] forKey:@"variable"];
    eval = [expression expressionValueWithObject:nil context:bindings];
    [self assertTrue:(eval == 10) message:"'" + eval  + "' should be 10"];

// Replace with keypath expression
    bindings = [CPDictionary dictionaryWithObject:[CPExpression expressionForKeyPath:@"Record1.Age"] forKey:@"variable"];
    eval = [expression expressionValueWithObject:dict context:bindings];
    [self assertTrue:(eval == 34) message:"'" + eval  + "' should be 34"];
}

- (void)testSubqueryExpressionEvaluation
{
    var collection = [CPExpression expressionForKeyPath:@"Record1.Children"],
        iteratorVariable = @"x",
        predicate = [CPPredicate predicateWithFormat:@"$x BEGINSWITH 'Kid'"];

    var expression = [CPExpression expressionForSubquery:collection usingIteratorVariable:iteratorVariable predicate:predicate],
        eval = [expression expressionValueWithObject:dict context:nil],
        expected = [CPArray arrayWithObjects:"Kid1", "Kid2"];
    [self assertTrue:([eval isEqual:expected]) message:"'" + [expression predicateFormat]  + "' result is "+ eval + "but should be " + expected];
}

- (void)testOptions
{
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"àa"] rightExpression:[CPExpression expressionForConstantValue:@"aà"] modifier:CPDirectPredicateModifier type:CPLikePredicateOperatorType options:3];
    [self assertTrue:[pred evaluateWithObject:nil] message:"/" + [pred description]  + "/ should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"aB"] rightExpression:[CPExpression expressionForConstantValue:@"Ab"] modifier:CPDirectPredicateModifier type:CPLikePredicateOperatorType options:1];
    [self assertTrue:[pred evaluateWithObject:nil] message:"/" + [pred description]  + "/ should be true"];
}

- (void)testModifier
{
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record2.Children"] rightExpression:[CPExpression expressionForConstantValue:@"Gi"] modifier:CPAnyPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];
    [self assertTrue:[pred evaluateWithObject:dict] message:"'" + [pred description]  + "' should be true"];

        pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Children"] rightExpression:[CPExpression expressionForConstantValue:@"Kid"] modifier:CPAllPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];
    [self assertTrue:[pred evaluateWithObject:dict] message:"'" + [pred description]  + "' should be true"];
}

- (void)testOperators
{
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:"Farenight 451"] rightExpression:[CPExpression expressionForConstantValue:"(F|g)\\w+\\s\\d{3}"] modifier:CPDirectPredicateModifier type:CPMatchesPredicateOperatorType options:2];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'" + [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"b"] rightExpression:[CPExpression expressionForConstantValue:@"[a-c]"] modifier:CPDirectPredicateModifier type:CPLikePredicateOperatorType options:1];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'" + [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"Aa"] rightExpression:[CPExpression expressionForConstantValue:@"ab"] modifier:CPDirectPredicateModifier type:CPLessThanPredicateOperatorType options:0];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'" + [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"Ac"] rightExpression:[CPExpression expressionForConstantValue:@"ab"] modifier:CPDirectPredicateModifier type:CPLessThanPredicateOperatorType options:2];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'" + [pred description]  + "' should be true"];

}

- (void)testCompoundPredicate
{
    var predOne = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Name"] rightExpression:[CPExpression expressionForConstantValue:@"J"] modifier:CPDirectPredicateModifier type:CPBeginsWithPredicateOperatorType options:0],
        predTwo = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Age"] rightExpression:[CPExpression expressionForConstantValue:[CPNumber numberWithInt:40]] modifier:CPDirectPredicateModifier type:CPLessThanPredicateOperatorType options:0],
        pred = [[CPCompoundPredicate alloc] initWithType:CPAndPredicateType subpredicates:[CPArray arrayWithObjects:predOne,predTwo]];

    [self assertTrue:[pred evaluateWithObject:dict] message:"'" + [pred description]  + "' should be true"];
}

- (void)testBeginsWithEndsWithPredicate
{
    // This always worked
    var data = ["To", "Tom", "Tomb", "Tomboy"],
        pred = [CPPredicate predicateWithFormat:@"SELF beginsWith 'To'"],
        result = [data filteredArrayUsingPredicate:pred];

    [self assertTrue:result.length === 4 message:"'" + [pred description] + "' should return [\"To\", \"Tom\", \"Tomb\", \"Tomboy\"]"];

    // Make sure beginsWith comparison string longer than source strings works
    pred = [CPPredicate predicateWithFormat:@"SELF beginsWith 'Tomb'"];
    result = [data filteredArrayUsingPredicate:pred];

    [self assertTrue:[result isEqual:["Tomb", "Tomboy"]] message:"'" + [pred description] + "' should return [\"Tomb\", \"Tomboy\"]"];

    // Make sure endsWith comparison string longer than source strings works
    pred = [CPPredicate predicateWithFormat:@"SELF endsWith 'boy'"];
    result = [data filteredArrayUsingPredicate:pred];

    [self assertTrue:[result isEqual:["Tomboy"]] message:"'" + [pred description] + "' should return [\"Tomboy\"]"];
}

- (void)testNilComparisons
{
// Custom Selector Predicate
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Name"] rightExpression:[CPExpression expressionForConstantValue:nil] customSelector:@selector(yes:)];

    [self assertTrue:[pred evaluateWithObject:dict] message:"'" + [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:nil] rightExpression:[CPExpression expressionForConstantValue:nil] customSelector:@selector(yes:)];

    [self assertFalse:[pred evaluateWithObject:dict] message:"'" + [pred description]  + "' should be false"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Name"] rightExpression:[CPExpression expressionForConstantValue:nil] modifier:CPDirectPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];

    [self assertFalse:[pred evaluateWithObject:dict] message:"'" + [pred description]  + "' should be false"];

// Predicates with operators
    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Age"] rightExpression:[CPExpression expressionForConstantValue:nil] modifier:CPDirectPredicateModifier type:CPGreaterThanPredicateOperatorType options:0];

    [self assertFalse:[pred evaluateWithObject:dict] message:"'" + [pred description]  + "' should be false"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:nil] rightExpression:[CPExpression expressionForConstantValue:nil] modifier:CPDirectPredicateModifier type:CPGreaterThanOrEqualToPredicateOperatorType options:0];

    [self assertTrue:[pred evaluateWithObject:dict] message:"'" + [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:nil] rightExpression:[CPExpression expressionForConstantValue:nil] modifier:CPDirectPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];

    [self assertFalse:[pred evaluateWithObject:dict] message:"'" + [pred description]  + "' should be false"];
}

- (void)testPredicateParsing
{
    var predicate;
// TEST String
    predicate = [CPPredicate predicateWithFormat: @"%K == %@", @"Record1.Name", @"John"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K MATCHES[c] %@", @"Record1.Name", @"john"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K BEGINSWITH %@", @"Record1.Name", @"Jo"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"(%K == %@) AND (%K == %@)", @"Record1.Name", @"John", @"Record2.Name", @"Mary"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// TEST integer
    predicate = [CPPredicate predicateWithFormat: @"%K == %d", @"Record1.Age", 34];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K < %d", @"Record1.Age", 40];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K BETWEEN %@", @"Record1.Age", [CPArray arrayWithObjects:[CPNumber numberWithInt:20], [CPNumber numberWithInt:40]]];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"Record1.Age BETWEEN {%f,%f}", 20, 40];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"(%K == %d) OR (%K == %d)", @"Record1.Age", 34, @"Record2.Age", 34];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// TEST float
    predicate = [CPPredicate predicateWithFormat: @"%K < %f", @"Record1.Age", 40.5];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%f > %K", 40.5, @"Record1.Age"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// TEST KeyPath
    predicate = [CPPredicate predicateWithFormat: @"%@ IN %K", @"Kid1", @"Record1.Children"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"%K CONTAINS %@", @"Record1.Children", @"Kid1"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"ANY %K == %@", @"Record2.Children", @"Girl1"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// Test Aggregate
    predicate = [CPPredicate predicateWithFormat:@"{Record1.Name, Record1.Age} = {'John',34}"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// Test Symbolic token
    predicate = [CPPredicate predicateWithFormat:@"Record1.Children[  FIRST ] = 'Kid1'"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"Record1.Children[1] = 'Kid2'"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"Record1.Children[count:(Record1.Children) - 1] = 'Kid2'"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

// Test arithm
    var n = 2;
    predicate = [CPPredicate predicateWithFormat:@"SELF +1 = 3"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF- 1 = 1"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF / 2 = 1"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF / 2 = 1"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF* 2 = 4"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat:@"SELF** 3 = 8"];
    [self assertTrue:[predicate evaluateWithObject:n] message:[predicate description] + " should be true"];

// TEST Operator type
    predicate = [CPPredicate predicateWithFormat: @"a CONTAINS[c] \"b\""];
    [self assertTrue:([predicate predicateOperatorType] == CPContainsPredicateOperatorType) message:[predicate description] + " operator should be a CPContainsPredicateOperatorType"];

    predicate = [CPPredicate predicateWithFormat: @"a BETWEEN {%f,%f}", 20, 40];
    [self assertTrue:([predicate predicateOperatorType] == CPBetweenPredicateOperatorType) message:[predicate description] + " operator should be a CPBetweenPredicateOperatorType"];

// TEST Empty string
    predicate = [CPPredicate predicateWithFormat: @"a CONTAINS \"\""];
    [self assertNotNull:predicate message:[predicate description] + " should not be nil"];

// TEST variable
    predicate = [CPPredicate predicateWithFormat: @"$x CONTAINS \"\""];
    [self assertTrue:[[predicate leftExpression] expressionType] == CPVariableExpressionType message:"Left Expression should be a CPVariableExpressionType"];

// TEST variable inside keypath
    predicate = [CPPredicate predicateWithFormat: @"Record1.$age = 34"];
    var bindings = [CPDictionary dictionaryWithObject:@"Age" forKey:@"age"];
    [self assertTrue:[predicate evaluateWithObject:dict substitutionVariables:bindings] message:"Predicate " + predicate + " should evaluate to TRUE"];

    predicate = [CPPredicate predicateWithFormat: @"$record.Age = 34"];
    [bindings setObject:[CPExpression expressionForKeyPath:@"Record1"] forKey:@"record"];
    [self assertTrue:[predicate evaluateWithObject:dict substitutionVariables:bindings] message:"Predicate " + predicate + " should evaluate to TRUE"];

    predicate = [CPPredicate predicateWithFormat: @"$record.$age = 34"];
    [self assertTrue:[predicate evaluateWithObject:dict substitutionVariables:bindings] message:"Predicate " + predicate + " should evaluate to TRUE"];

// TEST built-in functions
    predicate = [CPPredicate predicateWithFormat: @"sum:(1,1) = 2"];
    [self assertTrue:[predicate evaluateWithObject:nil] message:"Predicate " + predicate + " should evaluate to TRUE"];

    predicate = [CPPredicate predicateWithFormat: @"multiply:by:(5,3) = 15"];
    [self assertTrue:[predicate evaluateWithObject:nil] message:"Predicate " + predicate + " should evaluate to TRUE"];

// TEST custom functions
    predicate = [CPPredicate predicateWithFormat:@"FUNCTION('a/path', 'lastPathComponent') = 'path'"];
    [self assertTrue:[predicate evaluateWithObject:nil] message:"Predicate " + predicate + " should evaluate to TRUE"];

    predicate = [CPPredicate predicateWithFormat:@"FUNCTION('a/path', 'substringFromIndex:', 2) = 'path'"];
    [self assertTrue:[predicate evaluateWithObject:nil] message:"Predicate " + predicate + " should evaluate to TRUE"];

    predicate = [CPPredicate predicateWithFormat:@"FUNCTION('toto', 'stringByReplacingOccurrencesOfString:withString:', 'o', 'a') == 'tata'"];
    [self assertTrue:[predicate evaluateWithObject:nil] message:"Predicate " + predicate + " should be TRUE"];

// TEST Subquery -- This means: search people who have 2 boys.
    predicate = [CPPredicate predicateWithFormat: @"SUBQUERY(Record1.Children, $x, $x BEGINSWITH 'Kid')[SIZE] = 2"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:"Predicate " + predicate + " should evaluate to TRUE"];

// Test Set expressions
// Parsing is ok but the evaluation of this predicate will return NO because:
// - lhs will evaluate to a CPSet and rhs to a CPArray (aggregate exp). Comparing sets against arrays will always fail in CPComparisonPredicate. This is also cocoa behavior but i guess it's for historical reasons (set expressions are 10.5+) and should be changed in capp in my opinion.
    var object = [CPDictionary dictionaryWithObject:[CPSet setWithObjects:@"a"] forKey:"a"],
        result = [CPSet setWithObjects:@"a",@"b"];

    predicate = [CPPredicate predicateWithFormat:@"a UNION {'b'} = {'a','b'}"];
    var left = [[predicate leftExpression] expressionValueWithObject:object context:nil];
    [self assertTrue:[left isEqualToSet:result] message:"Expression eval " + left + " should be " + result];
}

- (void)testExpressionAndPredicateIsEqual
{
    var cexp1 = [CPExpression expressionForConstantValue:2],
        cexp2 = [CPExpression expressionForConstantValue:2];
    [self assert:cexp1 equals:cexp2];

    var exp1 = [CPExpression expressionForKeyPath:"path"],
        exp2 = [CPExpression expressionForKeyPath:"path"];
    [self assert:exp1 equals:exp2];

    exp1 = [CPExpression expressionForEvaluatedObject];
    exp2 = [CPExpression expressionForEvaluatedObject];
    [self assert:exp1 equals:exp2];

    exp1 = [CPExpression expressionForVariable:"toto"];
    exp2 = [CPExpression expressionForVariable:"toto"];
    [self assert:exp1 equals:exp2];

    var left = [CPExpression expressionForConstantValue:[CPSet setWithObjects:@"a",@"b",@"c"]],
        right = [CPExpression expressionForConstantValue:[CPArray arrayWithObjects:@"a",@"b",@"d"]];

    exp1 = [CPExpression expressionForIntersectSet:left with:right];
    exp2 = [CPExpression expressionForIntersectSet:[left copy] with:[right copy]];
    [self assert:exp1 equals:exp2];

    exp1 = [CPExpression expressionForFunction:cexp1 selectorName:@"isEqual:" arguments:[CPArray arrayWithObjects:cexp2]];
    exp2 = [CPExpression expressionForFunction:cexp1 selectorName:@"isEqual:" arguments:[CPArray arrayWithObjects:cexp2]];
    [self assert:exp1 equals:exp2];

    var aexp1 = [CPExpression expressionForAggregate:[CPArray arrayWithObjects:cexp1,cexp2]],
        aexp2 = [CPExpression expressionForAggregate:[CPArray arrayWithObjects:cexp1,cexp2]];
    [self assert:aexp1 equals:aexp2];

    exp1 = [CPExpression expressionForSubquery:right usingIteratorVariable:@"self" predicate:[CPPredicate predicateWithValue:YES]];
    exp2 = [CPExpression expressionForSubquery:right usingIteratorVariable:@"self" predicate:[CPPredicate predicateWithValue:YES]];
    [self assert:exp1 equals:exp2];

    var pred1 = [CPPredicate predicateWithFormat:@"FUNCTION('toto', 'stringByReplacingOccurrencesOfString:withString:', 'o', 'a') == 'tata'"],
        pred2 = [CPPredicate predicateWithFormat:@"FUNCTION('toto', 'stringByReplacingOccurrencesOfString:withString:', 'o', 'a') == 'tata'"];
    [self assert:pred1 equals:pred2];

    pred1 = [CPPredicate predicateWithFormat:@"$record.$age = 34"];
    pred2 = [CPPredicate predicateWithFormat:@"$record.$age = 34"];
    [self assert:pred1 equals:pred2];

    pred1 = [CPPredicate predicateWithFormat:@"SUBQUERY(Record1.Children, $x, $x BEGINSWITH 'Kid')[SIZE] = 2"];
    pred2 = [CPPredicate predicateWithFormat:@"SUBQUERY(Record1.Children, $x, $x BEGINSWITH 'Kid')[SIZE] = 2"];
    [self assert:pred1 equals:pred2];

    pred1 = [CPPredicate predicateWithFormat:@"$x CONTAINS 'a'"];
    pred2 = [CPPredicate predicateWithFormat:@"$x CONTAINS 'a'"];
    [self assert:pred1 equals:pred2];

    pred1 = [CPPredicate predicateWithFormat:@"a = 'a' AND b = 'b'"];
    pred2 = [CPPredicate predicateWithFormat:@"a = 'a' AND b = 'b'"];
    [self assert:pred1 equals:pred2];
}

- (void)testProxyArrayFiltering
{
    var proxyArray = [self mutableArrayValueForKey:@"simpleArray"],
        predicate = [CPPredicate predicateWithFormat:@"SELF CONTAINS 'a'"];

    var filtered = [proxyArray filteredArrayUsingPredicate:predicate];

    [self assertTrue:([filtered count] == 2) message:@"Count should be 2 and is " + [filtered count]];
}

- (void)testTruepredicate
{
    var data = [1, 2, 3],
        result;

    var tpred = [CPPredicate predicateWithFormat:@"TRUEPREDICATE"];
    var ctpred = [CPCompoundPredicate andPredicateWithSubpredicates:[tpred]];

    // fails if evaluateWithObject: isn't implemented in CPPredicate_BOOL
    result = [tpred evaluateWithObject:"gazonk"];
    [self assertTrue:result message:"'" + [tpred description] + "' should evaluate to true"];

    // fails if evaluateWithObject:substitutionVariables: isn't implemented in CPPredicate_BOOL
    result = [data filteredArrayUsingPredicate:ctpred];
    [self assertTrue:[result isEqual:data] message:"[1, 2, 3] filtered with '" + [ctpred description] + "' should return [1, 2, 3]"];
}

@end

@implementation CPObject (PredicateTesting)

- (BOOL)yes:(id)object
{
    return YES;
}

@end
