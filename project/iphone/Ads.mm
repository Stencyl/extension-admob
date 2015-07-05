#include <Ads.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <iAd/iAd.h>

using namespace ads;

extern "C" void sendEvent(char* event);


@interface iAdsController: UIViewController <ADBannerViewDelegate>
{
    ADBannerView *adBanner;
    UIViewController *root;
    
    BOOL isLoaded; // set true if ad is loaded
    BOOL isVisible;// set true if ad shows
    BOOL onBottom;//set banner on bottom if true, if false sets banner at top
}

@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL onBottom;

@end

@implementation iAdsController

@synthesize isLoaded;
@synthesize isVisible;
@synthesize onBottom;

-(id) init
{
    NSLog(@"AsiAds : iAdsDelegate :: init");
    self = [super init];
    return self;
}

-(void)initWithBanner
{
    root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    //Setup iAds
    adBanner = [[ADBannerView alloc] initWithFrame:CGRectZero];
    
    //Landscape or Portrait
    if( [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft ||
       [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight )
    {
        
        adBanner.requiredContentSizeIdentifiers = [NSSet setWithObject:ADBannerContentSizeIdentifierLandscape];
        
        adBanner.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    }else{
        
        adBanner.requiredContentSizeIdentifiers = [NSSet setWithObject:ADBannerContentSizeIdentifierPortrait];
        
        adBanner.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    }
    
    [adBanner setDelegate:self];
    
    [root.view addSubview: adBanner];
    
    //Initially hidden. Should wait until we receive an ad before displaying it
    adBanner.hidden = YES;
}

- (void)show
{
    isVisible = true;
    [self setPosition];
}

- (void)hide
{
    isVisible = false;
    [self setPosition];
}

-(void)setPosition
{
    CGSize screenRect = [self getCorrectedSize];
    CGRect frame = adBanner.frame;
    frame.origin.y = 0;
    
    [UIView beginAnimations:nil context:nil];
    
    if (isVisible && ![adBanner isHidden] && isLoaded) {
        
        if(onBottom)
        {
            frame.origin.y = screenRect.height - frame.size.height;
            
        }else
        {
            frame.origin.y = 0;
        }
        
        adBanner.frame=frame;

    }else {
        
        if(onBottom)
        {
            frame.origin.y = screenRect.height + frame.size.height;
        }else
        {
            frame.origin.y = -frame.size.height;
        }
        
        adBanner.frame=frame;
    }
    
    [UIView commitAnimations];
}



//  Normal [UIScreen mainScreen] will always report portrait mode.  So check current orientation and
//  return a properly corrected Size if landscape.
- (CGSize)getCorrectedSize
{
    CGSize correctSize;
    UIInterfaceOrientation toOrientation = [UIApplication sharedApplication].statusBarOrientation;
    correctSize = [[UIScreen mainScreen] bounds].size;
    return correctSize;
}

#pragma mark iAds delegate methods

- (BOOL)bannerViewActionShouldBegin:(ADBannerView*)banner willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"User opened ad.");
    sendEvent("open");
    
    isLoaded = false;
    [self setPosition];
    
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView*)banner
{
    NSLog(@"User closed ad.");
    sendEvent("close");
    
    isLoaded = true;
    [self setPosition];
}

- (void)bannerViewDidLoadAd:(ADBannerView*)banner
{
    NSLog(@"Loaded ad. Show it (if Developer set to visible).");
    sendEvent("load");
    
    isLoaded = true;
    adBanner.hidden = NO;
    [self setPosition];
    
}

- (void)bannerView:(ADBannerView*)banner didFailToReceiveAdWithError:(NSError*)error
{
    NSLog(@"Could not load ad. Hide it for now.");
    sendEvent("fail");
    
    isLoaded = false;
    [self setPosition];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    NSLog(@"Ad Controller saying YES to auto-rotate.");
    
    if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        adBanner.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    }
    else
    {
        adBanner.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    }
    return YES;
}


namespace ads
{
    static iAdsController *adController;

    void init()
    {
        NSLog(@"asiAds : Init()");
        
        //Create our ad view Controller object
        adController = [[iAdsController alloc]init];
        
        [adController initWithBanner];
        
    }
    
    void showAd(int position)
    {
        
        NSLog(@"Showing ad...");
        if(adController == NULL)
        {
            NSLog(@"Need to init ad controller first");
            init();
        }
        
        //set ad position
        if(position == 0)
        {
            adController.onBottom = YES;
        }
        
        else
        {
            adController.onBottom = NO;
        }
        
        [adController show];
    }

    
    void hideAd()
    {
        NSLog(@"Hiding ad...");
        if(adController == NULL)
        {
            NSLog(@"Need to init ad controller first");
            init();
        }
        
        [adController hide];
    }
    
}
@end
