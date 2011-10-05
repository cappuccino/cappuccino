
@interface AppController : NSObject
{
    IBOutlet NSScrollView* scrollView;
    IBOutlet NSView* contentView;
}
- (IBAction)change:(id)aSender;
- (IBAction)changeKnob:(id)aSender;
- (IBAction)changeBackground:(id)aSender;
- (IBAction)makeBigDocView:(id)aSender;
- (IBAction)makeSmallDocView:(id)aSender;
- (IBAction)flash:(id)aSender;
@end