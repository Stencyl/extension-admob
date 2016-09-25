/*
 *
 * Created by Robin Schaafsma
 * www.byrobingames.com
 *
 */

#include <AdMobEx.h>
#import <UIKit/UIKit.h>
#import "GoogleMobileAds/GADBannerView.h"
#import "GoogleMobileAds/GADBannerViewDelegate.h"
#import "GoogleMobileAds/GADInterstitial.h"
#import "GoogleMobileAds/GADMobileAds.h"

using namespace admobex;

extern "C" void sendEvent(char* event);

@interface InitializeAdmobListener : NSObject
    {
        @public
        //GADMobileAds *initialize;
    }
    
- (id)initWithAdmobID:(NSString*)ID;
    
@end

@interface InterstitialListener : NSObject <GADInterstitialDelegate>
{
    @public
    GADInterstitial *interstitial;
}

- (id)initWithID:(NSString*)ID;
- (void)show;
- (bool)isReady;

@end

@interface BannerListener : NSObject <GADBannerViewDelegate>
{
    @public
    GADBannerView *bannerView;
    UIViewController *root;
    
    BOOL bottom;
}

-(id)initWithBannerID:(NSString*)bannerID withGravity:(NSString*)GMODE;
-(void)setPosition:(NSString*)position;
-(void)showBannerAd;
-(void)hideBannerAd;
-(void)reloadBanner;

@property (nonatomic, assign) BOOL bottom;

@end

@implementation InitializeAdmobListener
    
- (id)initWithAdmobID:(NSString*)ID
{
    self = [super init];
    if(!self) return nil;
    
    //initialize = [[GADMobileAds alloc] configureWithApplicationID:ID];
    
    [GADMobileAds configureWithApplicationID:ID];
    
    return self;
}
    
@end

@implementation InterstitialListener

/////Interstitial
- (id)initWithID:(NSString*)ID
{
    self = [super init];
    NSLog(@"AdMob Init Interstitial");
    if(!self) return nil;
    interstitial = [[GADInterstitial alloc] initWithAdUnitID:ID];
    interstitial.delegate = self;
    GADRequest *request = [GADRequest request];
    request.testDevices = @[ kGADSimulatorID ];
    //[interstitial performSelector:@selector(loadRequest:) withObject:request afterDelay:1];
    [interstitial loadRequest:request];
    
    return self;
}

- (bool)isReady{
    return (interstitial != nil && interstitial.isReady);
}

- (void)show
{
    if (![self isReady]) return;
    
    [interstitial presentFromRootViewController:[[[UIApplication sharedApplication] keyWindow] rootViewController]];
}

/// Called when an interstitial ad request succeeded.
- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
    
    sendEvent("interstitialload");
    NSLog(@"interstitialDidReceiveAd");
}

/// Called when an interstitial ad request failed.
- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error
{
    sendEvent("interstitialfail");
    NSLog(@"interstitialDidFailToReceiveAdWithError: %@", [error localizedDescription]);
}

/// Called just before presenting an interstitial.
- (void)interstitialWillPresentScreen:(GADInterstitial *)ad
{
    sendEvent("interstitialopen");
    NSLog(@"interstitialWillPresentScreen");
}

/// Called before the interstitial is to be animated off the screen.
- (void)interstitialWillDismissScreen:(GADInterstitial *)ad
{
    NSLog(@"interstitialWillDismissScreen");
}

/// Called just after dismissing an interstitial and it has animated off the screen.
- (void)interstitialDidDismissScreen:(GADInterstitial *)ad
{
    sendEvent("interstitialclose");
    NSLog(@"interstitialDidDismissScreen");
}

/// Called just before the application will background or terminate because the user clicked on an
/// ad that will launch another application (such as the App Store).
- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad
{
    sendEvent("interstitialclicked");
    NSLog(@"interstitialWillLeaveApplication is clicked");
}

@end

@implementation BannerListener

@synthesize bottom;

/////Banner
-(id)initWithBannerID:(NSString*)bannerID withGravity:(NSString*)GMODE
{
    self = [super init];
    NSLog(@"AdMob Init Banner");
    
    if(!self) return nil;
    root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    if( [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft ||
       [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight )
    {
        bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerLandscape];
    }else{
        bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
    }
    
    bannerView.adUnitID = bannerID;
    bannerView.rootViewController = root;
    
    GADRequest *request = [GADRequest request];
    request.testDevices = @[ kGADSimulatorID ];
    [bannerView loadRequest:request];
    [root.view addSubview:bannerView];
    
    [bannerView setDelegate:self];
    
    bannerView.hidden=true;
    // set bannerposition
    [self setPosition:GMODE];
    
    return self;
    
}

-(void)setPosition:(NSString*)position
{
    
    bottom=[position isEqualToString:@"BOTTOM"];
    
    if (bottom) // Reposition the adView to the bottom of the screen
    {
        CGRect frame = bannerView.frame;
        frame.origin.y = root.view.bounds.size.height - frame.size.height;
        bannerView.frame=frame;
        
    }else // Reposition the adView to the top of the screen
    {
        CGRect frame = bannerView.frame;
        frame.origin.y = 0;
        bannerView.frame=frame;
    }
}

-(void)showBannerAd
{
    bannerView.hidden=false;
}

-(void)hideBannerAd
{
    bannerView.hidden=true;
}

-(void)reloadBanner
{
    [bannerView loadRequest:[GADRequest request]];
}

/// Called when an banner ad request succeeded.
- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    sendEvent("bannerload");
    NSLog(@"AdMob: banner ad successfully loaded!");
}

/// Called when an banner ad request failed.
- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error
{
    sendEvent("bannerfail");
    NSLog(@"AdMob: banner failed to load...");
}

- (void)adViewWillPresentScreen:(GADBannerView *)bannerView
{
    sendEvent("banneropen");
    NSLog(@"AdMob: banner was opened.");
}

/// Called before the banner is to be animated off the screen.
- (void)adViewWillDismissScreen:(GADBannerView *)bannerView
{
    sendEvent("bannerclose");
    NSLog(@"AdMob: banner was closed.");
}

/// Called just before the application will background or terminate because the user clicked on an
/// ad that will launch another application (such as the App Store).
- (void)adViewWillLeaveApplication:(GADBannerView *)bannerView
{
    sendEvent("bannerclicked");
    NSLog(@"AdMob: banner made the user leave the game. is clicked");
}

@end

namespace admobex {
	
    static InitializeAdmobListener *initializeAdmobListener;
    static InterstitialListener *interstitialListener;
    static BannerListener *bannerListener;
    static NSString *interstitialID;
    
	void init(const char *__AdmobID, const char *__BannerID, const char *__InterstitialID, const char *gravityMode, bool testingAds){
        
        NSString *admobID = [NSString stringWithUTF8String:__AdmobID];
        NSString *GMODE = [NSString stringWithUTF8String:gravityMode];
        NSString *bannerID = [NSString stringWithUTF8String:__BannerID];
        interstitialID = [NSString stringWithUTF8String:__InterstitialID];

        if(testingAds){
            admobID = @"ca-app-pub-3940256099942544~1458002511"; // ADMOB GENERIC TESTING appID
            interstitialID = @"ca-app-pub-3940256099942544/4411468910"; // ADMOB GENERIC TESTING INTERSTITIAL
            bannerID = @"ca-app-pub-3940256099942544/2934735716"; // ADMOB GENERIC TESTING BANNER
        }
        
        initializeAdmobListener = [[InitializeAdmobListener alloc] initWithAdmobID:admobID];
        
        //Banner
        if ([bannerID length] != 0) {
            bannerListener = [[BannerListener alloc] initWithBannerID:bannerID withGravity:GMODE];
        }
        
        // INTERSTITIAL
        if ([interstitialID length] != 0) {
            interstitialListener = [[InterstitialListener alloc] initWithID:interstitialID];
        }
    }
    
    void setBannerPosition(const char *gravityMode)
    {
        if(bannerListener != NULL)
        {
            NSString *GMODE = [NSString stringWithUTF8String:gravityMode];
            
            [bannerListener setPosition:GMODE];
        }
    }
    
    void showBanner()
    {
        if(bannerListener != NULL)
        {
            [bannerListener showBannerAd];
        }
        
    }
    
    void hideBanner()
    {
        if(bannerListener != NULL)
        {
            [bannerListener hideBannerAd];
        }
    }
    
	void refreshBanner()
    {
        if(bannerListener != NULL)
        {
            [bannerListener reloadBanner];
        }
	}

    void loadInterstitial()
    {
        //if(interstitialListener!=NULL) [interstitialListener show];
        interstitialListener = [[InterstitialListener alloc] initWithID:interstitialID];
    }
    
    void showInterstitial()
    {
        if(interstitialListener!=NULL) [interstitialListener show];
        //interstitialListener = [[InterstitialListener alloc] initWithID:interstitialID];
    }
    
}
