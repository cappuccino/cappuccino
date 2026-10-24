@import <AppKit/CPApplication.j>
@import <AppKit/CPRulerView.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPTextView.j>

@implementation CPRulerViewTest : OJTestCase
{
    CPScrollView    scrollView;
    CPRulerView     ruler;
}

- (void)setUp
{
    [[CPApplication alloc] init];

    scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 200.0)];
    [scrollView setHasHorizontalRuler:YES];

    ruler = [scrollView horizontalRulerView];
}

- (id)roundTrip:(id)anObject
{
    return [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:anObject]];
}

- (void)testRequiredThicknessCombinesTheRulerAreas
{
    [ruler setRuleThickness:16.0];
    [ruler setReservedThicknessForMarkers:9.0];
    [ruler setReservedThicknessForAccessoryView:5.0];

    [self assert:30.0 equals:[ruler requiredThickness]];
    [self assert:14.0 equals:[ruler baselineLocation]];
}

- (void)testMeasurementUnitsAcceptOnlyRegisteredUnits
{
    [ruler setMeasurementUnits:CPRulerViewUnitPoints];
    [self assert:CPRulerViewUnitPoints equals:[ruler measurementUnits]];

    [ruler setMeasurementUnits:@"Furlongs"];
    [self assert:CPRulerViewUnitPoints equals:[ruler measurementUnits]];

    [CPRulerView registerUnitWithName:@"Furlongs" abbreviation:@"fur" unitToPointsConversionFactor:570240.0 stepUpCycle:[2.0] stepDownCycle:[0.5]];
    [ruler setMeasurementUnits:@"Furlongs"];
    [self assert:@"Furlongs" equals:[ruler measurementUnits]];
}

- (void)testRulerViewArchiving
{
    var marker = [[CPRulerMarker alloc] initWithRulerView:ruler markerLocation:42.0 image:nil imageOrigin:CGPointMake(4.0, 8.0)];

    [marker setRemovable:YES];
    [marker setRepresentedObject:@"Tab"];

    [ruler setRuleThickness:18.0];
    [ruler setReservedThicknessForMarkers:9.0];
    [ruler setOriginOffset:7.0];
    [ruler setMeasurementUnits:CPRulerViewUnitPicas];
    [ruler setMarkers:[marker]];

    var decodedScrollView = [self roundTrip:scrollView],
        decodedRuler = [decodedScrollView horizontalRulerView],
        decodedMarker = [[decodedRuler markers] firstObject];

    [self assert:decodedScrollView equals:[decodedRuler scrollView] message:@"the scroll view should reconnect its decoded ruler"];
    [self assert:CPHorizontalRuler equals:[decodedRuler orientation]];
    [self assert:18.0 equals:[decodedRuler ruleThickness]];
    [self assert:9.0 equals:[decodedRuler reservedThicknessForMarkers]];
    [self assert:7.0 equals:[decodedRuler originOffset]];
    [self assert:CPRulerViewUnitPicas equals:[decodedRuler measurementUnits]];

    [self assert:42.0 equals:[decodedMarker markerLocation]];
    [self assert:4.0 equals:[decodedMarker imageOrigin].x];
    [self assert:8.0 equals:[decodedMarker imageOrigin].y];
    [self assertTrue:[decodedMarker isMovable]];
    [self assertTrue:[decodedMarker isRemovable]];
    [self assert:@"Tab" equals:[decodedMarker representedObject]];
    [self assert:decodedRuler equals:[decodedMarker ruler]];
}

- (void)testTextViewUsesRulerArchiving
{
    var textView = [[CPTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 200.0)];

    [self assertTrue:[textView usesRuler] message:@"a text view uses a ruler by default"];

    [textView setUsesRuler:NO];
    [self assertFalse:[[self roundTrip:textView] usesRuler]];

    [textView setUsesRuler:YES];
    [self assertTrue:[[self roundTrip:textView] usesRuler]];
}

- (void)testTextViewWithoutRulerCannotShowIt
{
    var textView = [[CPTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 200.0)];

    [scrollView setDocumentView:textView];
    [textView setUsesRuler:NO];
    [textView setRulerVisible:YES];

    [self assertFalse:[textView isRulerVisible]];
}

@end
