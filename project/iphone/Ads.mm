#include <Ads.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <iAd/iAd.h>

extern "C" void sendEvent(char* event);


@interface iAdsController:NSObject <ADBannerViewDelegate>
{
    BOOL onBottom;
}

@property (nonatomic, assign) BOOL onBottom;

@end

@implementation iAdsController

@synthesize onBottom;

-(id) init
{
    NSLog(@"AsiAds : iAdsDelegate :: init");
    self = [super init];
    return self;
}

#pragma mark iAds delegate methods

- (BOOL)bannerViewActionShouldBegin:(ADBannerView*)banner willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"User opened ad.");
    sendEvent("open");
    
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView*)banner
{
    NSLog(@"User closed ad.");
    sendEvent("close");
    
}

- (void)bannerViewDidLoadAd:(ADBannerView*)banner
{
    NSLog(@"Loaded ad. Show it (if Developer set to visible).");
    sendEvent("load");
    
    ads::adBanner.hidden = NO;
    
    [self show];
    
}

- (void)bannerView:(ADBannerView*)banner didFailToReceiveAdWithError:(NSError*)error
{
    NSLog(@"Could not load ad. Hide it for now.");
    sendEvent("fail");
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    NSLog(@"Ad Controller saying YES to auto-rotate.");
    return YES;
}

- (void)show
{
    CGSize screenRect = [self getCorrectedSize];
    CGRect frame = ads::adBanner.frame;
    frame.origin.y = 0;
    
    [UIView beginAnimations:nil context:nil];
    
    if(onBottom)
    {
        frame.origin.y = screenRect.height - frame.size.height;
        ads::adBanner.frame=frame;
    }else
    {
        frame.origin.y = 0;
        ads::adBanner.frame=frame;
    }
    
    [UIView commitAnimations];
}

- (void)hide
{
    CGSize screenRect = [self getCorrectedSize];
    CGRect frame = ads::adBanner.frame;
    frame.origin.y = 0;
    
    [UIView beginAnimations:nil context:nil];
    
    if(onBottom)
    {
        frame.origin.y = screenRect.height + frame.size.height;
        ads::adBanner.frame=frame;
    }else
    {
        frame.origin.y = -frame.size.height;
        ads::adBanner.frame=frame;
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


namespace ads
{
    static ADBannerView *adBanner=nil;
    static iAdsController *adController=nil;

    void init()
    {
        NSLog(@"asiAds : Init()");
        
        //Create our ad view Controller object
        adController = [[iAdsController alloc]init];
        
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
        

        adBanner.delegate = adController;
        
        [[[[UIApplication sharedApplication] keyWindow] rootViewController].view addSubview: adBanner];
        
        //Initially hidden. Should wait until we receive an ad before displaying it
        adBanner.hidden = YES;
        
    }
    
    void showAd(int position)
    {
        
        NSLog(@"Showing ad...");
        if(adBanner == NULL)
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
        if(adBanner == NULL)
        {
            NSLog(@"Need to init ad controller first");
            init();
        }
        
        [adController hide];
    }
    
}
@end
