@import <Foundation/Foundation.j>

@implementation CPPredicateTest : OJTestCase
{
    CPDictionary dict;
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        var d,
            objects;

        dict = [[CPDictionary alloc] init];
        [dict setObject: @"A Title" forKey:@"title"];

        var keys = [CPArray arrayWithObjects:@"Name",@"Age",@"Children"];
        objects = [CPArray arrayWithObjects:@"John",[CPNumber numberWithInt:34],[CPArray arrayWithObjects:@"Kid1", @"Kid2"]];

        d = [CPDictionary dictionaryWithObjects:objects forKeys:keys];
        [dict setObject:d forKey:@"Record1"];

        objects = [CPArray arrayWithObjects:@"Mary",[CPNumber numberWithInt:30],[CPArray arrayWithObjects:@"Kid1", @"Girl1"]];

        d = [CPDictionary dictionaryWithObjects:objects forKeys:keys];
        [dict setObject:d forKey:@"Record2"];

    }
    return self;
}

- (void)testExpressionsInit
{
    var expression_keypath = [CPExpression expressionForKeyPath:@"name"];
    [self assertNotNull:expression_keypath message:"KeyPath Expression should not be nil"];

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

    var expression_self = [CPExpression expressionForEvaluatedObject];
    [self assertNotNull:expression_self message:"Function Expression should not be nil"];

    var expression_aggregate = [CPExpression expressionForAggregate:[CPArray arrayWithObjects:expression_str,expression_num,expression_function]];
    [self assertNotNull:expression_aggregate message:"Aggregate Expression should not be nil"];

    var expression_subquery = [CPExpression expressionForSubquery:expression_collection usingIteratorVariable:@"self" predicate:[CPPredicate predicateWithValue:YES]];
    // [self assertNotNull:expression_subquery message:"Subquery Expression should not be nil"];

    var set = [CPSet setWithObjects:@"a",@"b",@"d"];
    var array = [CPArray arrayWithObjects:@"a",@"b",@"d"];

    var expression_intersect = [CPExpression expressionForIntersectSet:set with:array];
    [self assertNotNull:expression_intersect message:"IntersectSet Expression should not be nil"];

    var expression_unionset = [CPExpression expressionForUnionSet:set with:array];
    [self assertNotNull:expression_unionset message:"UnionSet Expression should not be nil"];

    var expression_minusset = [CPExpression expressionForMinusSet:set with:array];
    [self assertNotNull:expression_minusset message:"MinusSet Expression should not be nil"];
}

- (void)testFunctionExpression
{
    var function_exp = [CPExpression expressionForFunction:"sum:" arguments:[CPArray arrayWithObjects:[CPExpression expressionForConstantValue:1],[CPExpression expressionForConstantValue:2],[CPExpression expressionForConstantValue:3]]];

    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:function_exp rightExpression:[CPExpression expressionForConstantValue:3] modifier:CPDirectPredicateModifier type:CPGreaterThanPredicateOperatorType options:0];

    [self assertTrue:[pred evaluateWithObject:nil] message:[pred description] + " should be true"];
}

- (void)testVariableExpression
{
    var variable_exp = [CPExpression expressionForVariable:@"variable"];
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Age"] rightExpression:variable_exp modifier:CPDirectPredicateModifier type:CPGreaterThanPredicateOperatorType options:0];

    var variables = [CPDictionary dictionaryWithObject:20 forKey:@"variable"];

    [self assertTrue:[pred evaluateWithObject:dict substitutionVariables:variables] message:"'"+ [pred description]  + "' should be true"];
}

- (void)testOptions
{
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"àa"] rightExpression:[CPExpression expressionForConstantValue:@"aà"] modifier:CPDirectPredicateModifier type:CPLikePredicateOperatorType options:3];
    [self assertTrue:[pred evaluateWithObject:nil] message:"/"+ [pred description]  + "/ should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"aB"] rightExpression:[CPExpression expressionForConstantValue:@"Ab"] modifier:CPDirectPredicateModifier type:CPLikePredicateOperatorType options:1];
    [self assertTrue:[pred evaluateWithObject:nil] message:"/"+ [pred description]  + "/ should be true"];
}

- (void)testModifier
{
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record2.Children"] rightExpression:[CPExpression expressionForConstantValue:@"Gi"] modifier:CPAnyPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];
    [self assertTrue:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be true"];

        pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Children"] rightExpression:[CPExpression expressionForConstantValue:@"Kid"] modifier:CPAllPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];
    [self assertTrue:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be true"];
}

- (void)testOperators
{
    var pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:"Farenight 451"] rightExpression:[CPExpression expressionForConstantValue:"(F|g)\\w+\\s\\d{3}"] modifier:CPDirectPredicateModifier type:CPMatchesPredicateOperatorType options:2];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'"+ [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"b"] rightExpression:[CPExpression expressionForConstantValue:@"[a-c]"] modifier:CPDirectPredicateModifier type:CPLikePredicateOperatorType options:1];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'"+ [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"Aa"] rightExpression:[CPExpression expressionForConstantValue:@"ab"] modifier:CPDirectPredicateModifier type:CPLessThanPredicateOperatorType options:0];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'"+ [pred description]  + "' should be true"];

    pred = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForConstantValue:@"Ac"] rightExpression:[CPExpression expressionForConstantValue:@"ab"] modifier:CPDirectPredicateModifier type:CPLessThanPredicateOperatorType options:2];
   [self assertTrue:[pred evaluateWithObject:nil] message:"'"+ [pred description]  + "' should be true"];

}

- (void)testCompoundPredicate
{
    var predOne = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Name"] rightExpression:[CPExpression expressionForConstantValue:@"J"] modifier:CPDirectPredicateModifier type:CPBeginsWithPredicateOperatorType options:0];

    var predTwo = [[CPComparisonPredicate alloc] initWithLeftExpression:[CPExpression expressionForKeyPath:@"Record1.Age"] rightExpression:[CPExpression expressionForConstantValue:[CPNumber numberWithInt:40]] modifier:CPDirectPredicateModifier type:CPLessThanPredicateOperatorType options:0];

    var pred = [[CPCompoundPredicate alloc] initWithType:CPAndPredicateType subpredicates:[CPArray arrayWithObjects:predOne,predTwo]];

    [self assertTrue:[pred evaluateWithObject:dict] message:"'"+ [pred description]  + "' should be true"];
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

    predicate = [CPPredicate predicateWithFormat: @"%K BETWEEN %@", @"Record1.Age", [CPArray arrayWithObjects:[CPNumber numberWithInt: 20], [CPNumber numberWithInt:40]]];
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

// TEST Aggregate
    predicate = [CPPredicate predicateWithFormat: @"%@ IN %K", @"Kid1", @"Record1.Children"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];

    predicate = [CPPredicate predicateWithFormat: @"ANY %K == %@", @"Record2.Children", @"Girl1"];
    [self assertTrue:[predicate evaluateWithObject:dict] message:[predicate description] + " should be true"];
}

@end