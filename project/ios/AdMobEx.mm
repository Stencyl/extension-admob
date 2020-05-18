/*
 *
 * Created by Robin Schaafsma
 * www.byrobingames.com
 * Modified by Stencyl
 */

#include "AdMobEx.h"
#include <PACConsentForm.h>
#include <PACError.h>
#include <PACPersonalizedAdConsent.h>
#include <PACView.h>
#import <UIKit/UIKit.h>
#import <AdSupport/ASIdentifierManager.h>
#import <GoogleMobileAds/GADBannerView.h>
#import <GoogleMobileAds/GADBannerViewDelegate.h>
#import <GoogleMobileAds/GADInterstitial.h>
#import <GoogleMobileAds/GADMobileAds.h>
#import <GoogleMobileAds/GADExtras.h>

using namespace admobex;

extern "C" void sendEvent(const char* event);

@interface InitializeAdmobListener : NSObject
    {
        @public
    }
    
- (id)initWithAdmobID:(NSString*)ID;
    
@end

@interface InterstitialListener : NSObject <GADInterstitialDelegate>
{
    @public
    GADInterstitial *interstitial;
}

+ (InterstitialListener*)getInterstitialListener;
+ (void)setInterstitialListener:(InterstitialListener*)newListener;

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

+ (BannerListener*)getBannerListener;
+ (void)setBannerListener:(BannerListener*)newListener;

-(id)initWithBannerID:(NSString*)bannerID withGravity:(NSString*)GMODE;
-(void)setPosition:(NSString*)position;
-(void)showBannerAd;
-(void)hideBannerAd;
-(void)reloadBanner;

@property (nonatomic, assign) BOOL bottom;

@end

@interface Consent : NSObject
    {
        @public
    }

+ (NSString*)getPublisherID;
+ (void)setPublisherID:(NSString*)newID;

+ (BOOL)getTesting;
+ (void)setTesting:(BOOL)newTesting;

+ (NSString*)getPrivacyURL;
+ (void)setPrivacyURL:(NSString*)newURL;

+ (void)getConsentInfo;
+ (void)showConsentForm:(BOOL)checkConsent;
+ (GADRequest*)buildAdReq;
    
@end

@implementation InitializeAdmobListener

- (id)initWithAdmobID:(NSString*)ID
{
    self = [super init];
    if(!self) return nil;

    //[GADMobileAds configureWithApplicationID:ID]; DEPRECATED
    [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
    
    return self;
}
    
@end

@implementation InterstitialListener

static InterstitialListener *interstitialListener;

+ (InterstitialListener*)getInterstitialListener
{
	return interstitialListener;
}
+ (void)setInterstitialListener:(InterstitialListener*)newListener
{
	if (interstitialListener != newListener)
	{
		interstitialListener = newListener;
	}
}

/////Interstitial
- (id)initWithID:(NSString*)ID
{
    self = [super init];
    NSLog(@"AdMob Init Interstitial");
    if(!self) return nil;
    interstitial = [[GADInterstitial alloc] initWithAdUnitID:ID];
    interstitial.delegate = self;
	GADRequest *request = [Consent buildAdReq];
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

static BannerListener *bannerListener;

+ (BannerListener*)getBannerListener
{
	return bannerListener;
}
+ (void)setBannerListener:(BannerListener*)newListener
{
	if (bannerListener != newListener)
	{
		bannerListener = newListener;
	}
}

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
    
	GADRequest *request = [Consent buildAdReq];
    [bannerView loadRequest:request];
    [root.view addSubview:bannerView];
    
    [bannerView setDelegate:self];
    
    bannerView.hidden=true;
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
	GADRequest *request = [Consent buildAdReq];
    [bannerView loadRequest:request];
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

@implementation Consent

static NSString *publisherID;
static BOOL testing = NO;
static NSString *privacyURL;

+ (NSString*)getPublisherID
{
	return publisherID;
}
+ (void)setPublisherID:(NSString*)newID
{
	if (publisherID != newID)
	{
		publisherID = [newID copy];
	}
}

+ (BOOL)getTesting
{
	return testing;
}
+ (void)setTesting:(BOOL)newTesting
{
	testing = newTesting;
}

+ (NSString*)getPrivacyURL
{
	return privacyURL;
}
+ (void)setPrivacyURL:(NSString*)newURL
{
	if (privacyURL != newURL)
	{
		privacyURL = [newURL copy];
	}
}

+ (void)getConsentInfo
{
	NSLog(@"consentsdk: getConsentInfo");
	
	if (testing)
	{
		PACConsentInformation.sharedInstance.debugIdentifiers = @[ ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString ];
		PACConsentInformation.sharedInstance.debugGeography = PACDebugGeographyEEA;
	}
	[PACConsentInformation.sharedInstance
		requestConsentInfoUpdateForPublisherIdentifiers:@[ publisherID ]
			completionHandler:^(NSError *_Nullable error)
			{
				if (error)
				{
					NSLog(@"consentsdk: Consent info update failed with error: %@", error);
				}
				else
				{
					NSLog(@"consentsdk: Consent info update succeeded.");
					
					GADRequest *request = [Consent buildAdReq];
					
					InterstitialListener *interstitialListener = [InterstitialListener getInterstitialListener];
					if(interstitialListener)
					{
						[interstitialListener->interstitial loadRequest:request];
					}
					BannerListener *bannerListener = [BannerListener getBannerListener];
					if (bannerListener)
					{
						[bannerListener->bannerView loadRequest:request];
					}
				}
			}];
}

+ (void)showConsentForm:(BOOL)checkConsent
{
	NSLog(@"consentsdk: showConsentForm");

	if (checkConsent &&
		(PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusPersonalized ||
		PACConsentInformation.sharedInstance.consentStatus == PACConsentStatusNonPersonalized))
	{
		NSLog(@"consentsdk: Skipping form because player already answered");
		return;
	}

	NSURL *pURL = [NSURL URLWithString:privacyURL];
	PACConsentForm *form = [[PACConsentForm alloc] initWithApplicationPrivacyPolicyURL:pURL];
	form.shouldOfferPersonalizedAds = YES;
	form.shouldOfferNonPersonalizedAds = YES;
	form.shouldOfferAdFree = NO;
	
	[form loadWithCompletionHandler:^(NSError *_Nullable error) {
		if (error)
		{
			NSLog(@"consentsdk: Form load failed with error: %@", error);
		}
		else
		{
			NSLog(@"consentsdk: Form has loaded.");
			UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
			
			[form presentFromViewController:root
				dismissCompletion:^(NSError *_Nullable error, BOOL userPrefersAdFree)
				{
					if (error)
					{
						NSLog(@"consentsdk: Show form failed with error: %@", error);
					}
					else if (userPrefersAdFree)
					{
						NSLog(@"consentsdk: user prefers ad free");
					}
					else
					{
						NSLog(@"consentsdk: setting consent status");
						PACConsentStatus status = PACConsentInformation.sharedInstance.consentStatus;
						
						GADRequest *request = [Consent buildAdReq];
					
						InterstitialListener *interstitialListener = [InterstitialListener getInterstitialListener];
						if(interstitialListener)
						{
							[interstitialListener->interstitial loadRequest:request];
						}
						BannerListener *bannerListener = [BannerListener getBannerListener];
						if (bannerListener)
						{
							[bannerListener->bannerView loadRequest:request];
						}
					}
				}];
		}
	}];
}

+ (GADRequest*)buildAdReq
{
	GADRequest *request = [GADRequest request];
	request.testDevices = @[ kGADSimulatorID ];

    BOOL npa = NO;
	if (PACConsentInformation.sharedInstance.requestLocationInEEAOrUnknown)
	{
		if (PACConsentInformation.sharedInstance.consentStatus != PACConsentStatusPersonalized)
		{
			npa = YES;
			GADExtras *extras = [[GADExtras alloc] init];
			extras.additionalParameters = @{@"npa": @"1"};
			[request registerAdNetworkExtras:extras];
		}
	}
	if (npa)
	{
		NSLog(@"consentsdk: building ad request with non-personlized ads");
	}
	else
	{
		NSLog(@"consentsdk: building ad request with personlized ads");
	}
	
	return request;
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
        
        NSString *pubID = [[admobID componentsSeparatedByString:@"~"] objectAtIndex:0];
        [Consent setPublisherID:pubID];

        if(testingAds){
            admobID = @"ca-app-pub-3940256099942544~1458002511"; // ADMOB GENERIC TESTING appID
            interstitialID = @"ca-app-pub-3940256099942544/4411468910"; // ADMOB GENERIC TESTING INTERSTITIAL
            bannerID = @"ca-app-pub-3940256099942544/2934735716"; // ADMOB GENERIC TESTING BANNER
        }
        
        initializeAdmobListener = [[InitializeAdmobListener alloc] initWithAdmobID:admobID];
        
        //Banner
        if ([bannerID length] != 0) {
            bannerListener = [[BannerListener alloc] initWithBannerID:bannerID withGravity:GMODE];
            [BannerListener setBannerListener:bannerListener];
        }
        
        // INTERSTITIAL
        if ([interstitialID length] != 0) {
            interstitialListener = [[InterstitialListener alloc] initWithID:interstitialID];
            [InterstitialListener setInterstitialListener:interstitialListener];
        }

		[Consent setTesting:testingAds];
		[Consent getConsentInfo];
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
        interstitialListener = [[InterstitialListener alloc] initWithID:interstitialID];
    }
    
    void showInterstitial()
    {
        if(interstitialListener!=NULL) [interstitialListener show];
    }
	
    void setPrivacyURL(const char *url)
    {
		[Consent setPrivacyURL:[NSString stringWithUTF8String:url]];
    }
	
    void showConsentForm(bool checkConsent)
    {
		[Consent showConsentForm:checkConsent];
    }
}
