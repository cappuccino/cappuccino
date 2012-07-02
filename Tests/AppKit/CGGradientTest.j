@import <AppKit/CGGradient.j>

@implementation CGGradientTest : OJTestCase

/*
  Using default values for location and count.
*/
- (void)testCreateWithColorComponentsDefault
{
    
    // Test one color and no location
    var components = [ 0.2,0.2,0.4,0.4 ];

    var tmp = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(),
                                                  components);
    [self assert:1 equals:tmp.colors.length];
    [self assert:1 equals:tmp.locations.length];

    // TODO: This should not be supported since there is no gradient if only one color
    // TODO: NaN not really helpful...
    [self assert:NaN equals:tmp.locations[0]];

    [self assert:components.slice(0,4) equals:tmp.colors[0].components];

    // Test two colors and no location
    var components = [ 0.2,0.2,0.4,0.4, 
                       0.6,0.6,0.8,0.8 ];
    
    var tmp = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(),
                                                  components);
    [self assert:2 equals:tmp.colors.length];
    [self assert:2 equals:tmp.locations.length];

    [self assert:0 equals:tmp.locations[0]];
    [self assert:1.0 equals:tmp.locations[1]];

    [self assert:components.slice(4,8) equals:tmp.colors[1].components];
    [self assert:components.slice(0,4) equals:tmp.colors[0].components];

    // Test three colors and no location
    var components = [ 0.2,0.2,0.4,0.4, 
                        0.6,0.6,0.8,0.8,
                        0.6,0.6,0.8,0.8 ];
    
    var tmp = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(),
                                                  components);
    [self assert:3 equals:tmp.colors.length];
    [self assert:3 equals:tmp.locations.length];

    [self assert:0 equals:tmp.locations[0]];
    [self assert:0.5 equals:tmp.locations[1]];
    [self assert:1.0 equals:tmp.locations[2]];

    [self assert:components.slice(8,12) equals:tmp.colors[2].components];
    [self assert:components.slice(4,8)  equals:tmp.colors[1].components];
    [self assert:components.slice(0,4)  equals:tmp.colors[0].components];
}

/*
  Using location and components to specify two color stops that aren't
  evenly spread out.
*/
- (void)testCreateWithColorComponentsUsingTwoColorStops
{
    var components = [ 0.2,0.2,0.4,0.4, 
                       0.6,0.6,0.8,0.8 ];
    var locations = [0.3,0.6];
    
    var tmp = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(),
                                                  components,locations);
    [self assert:2 equals:tmp.colors.length];
    [self assert:2 equals:tmp.locations.length];

    [self assert:0.3 equals:tmp.locations[0]];
    [self assert:0.6 equals:tmp.locations[1]];

    [self assert:components.slice(4,8) equals:tmp.colors[1].components];
    [self assert:components.slice(0,4) equals:tmp.colors[0].components];
}

/*
  Define three color components and ensure that the Gradient defined contains 3 color stops.
*/
- (void)testCanHaveMoreThanTwoColorStops
{
    var components = [ 1,2,3,4, 5,6,7,8, 9,10,11,12 ];
    var locations = [1,2,3];
    
    var tmp = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(),
                                                  components, locations, 3);
    [self assert:3 equals:tmp.colors.length];
    [self assert:3 equals:tmp.locations.length];

    [self assert:1 equals:tmp.locations[0]];
    [self assert:2 equals:tmp.locations[1]];
    [self assert:3 equals:tmp.locations[2]];
}


@end
