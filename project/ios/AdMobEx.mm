/*
 *
 * Created by Robin Schaafsma
 * www.byrobingames.com
 * Modified by Stencyl
 */

#include "AdMobEx.h"
#import <UIKit/UIKit.h>
#import <AdSupport/ASIdentifierManager.h>
#import <GoogleMobileAds/GADBannerView.h>
#import <GoogleMobileAds/GADBannerViewDelegate.h>
#import <GoogleMobileAds/GADInterstitialAd.h>
#import <GoogleMobileAds/GADRewardedAd.h>
#import <GoogleMobileAds/GADMobileAds.h>
#import <GoogleMobileAds/GADExtras.h>
#include <CommonCrypto/CommonDigest.h>
#include <UserMessagingPlatform/UserMessagingPlatform.h>

using namespace admobex;

extern "C" void sendAdEvent(const char* adType, const char* adEventType);
extern "C" void sendRewardEvent(const char* rewardType, double rewardAmount);

@interface InitializeAdmobListener : NSObject
    {
        @public
    }
    
- (id)initWithAdmobID:(NSString*)ID;
    
@end

@interface InterstitialListener : NSObject<GADFullScreenContentDelegate>
{
    @public
    GADInterstitialAd *interstitial;
}

+ (InterstitialListener*)getInterstitialListener;
+ (void)setInterstitialListener:(InterstitialListener*)newListener;

- (id)initWithID:(NSString*)ID;
- (void)show;
- (bool)isReady;

@end

@interface RewardedListener : NSObject<GADFullScreenContentDelegate>
{
    @public
    GADRewardedAd *rewarded;
}

+ (RewardedListener*)getRewardedListener;
+ (void)setRewardedListener:(RewardedListener*)newListener;

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

+ (void)setDebugGeography:(UMPDebugGeography)newDebugGeography;

+ (void)showConsentForm:(BOOL)checkConsent;
+ (void)setupForm;
+ (NSString*)admobDeviceID;
+ (void)getConsentInfo;
+ (void)loadForm;
+ (void)showForm;
+ (BOOL)consentHasBeenChecked;
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
static NSString* adId;

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
    adId = ID;
    [self loadAd];
    return self;
}

- (void)loadAd
{
    if(![Consent consentHasBeenChecked])
    {
        sendAdEvent("interstitial", "fail");
        NSLog(@"interstitialDidFailToReceiveAdWithError: User consent hasn't been checked yet");
        return;
    }
    GADRequest *request = [Consent buildAdReq];
    [GADInterstitialAd loadWithAdUnitID:adId
                                request:request
                      completionHandler:^(GADInterstitialAd *ad, NSError *error) {
        if (error) {
          sendAdEvent("interstitial", "fail");
          NSLog(@"interstitialDidFailToReceiveAdWithError: %@", [error localizedDescription]);
          return;
        }
        interstitial = ad;
        sendAdEvent("interstitial", "load");
        NSLog(@"interstitialDidReceiveAd");
        interstitial.fullScreenContentDelegate = self;
    }];
}

- (bool)isReady
{
    return interstitial != nil;
}

- (void)show
{
    if (!interstitial) return;
    [interstitial presentFromRootViewController:[[[UIApplication sharedApplication] keyWindow] rootViewController]];
}

- (void)adWillPresentFullScreenContent:(id)ad
{
    sendAdEvent("interstitial", "open");
    NSLog(@"interstitialWillPresentScreen");
}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error
{
    NSLog(@"Ad failed to present full screen content with error %@.", [error localizedDescription]);
}

- (void)adDidDismissFullScreenContent:(id)ad
{
    sendAdEvent("interstitial", "close");
    NSLog(@"interstitialDidDismissScreen");
}

- (void)adDidRecordClick:(id)ad
{
    sendAdEvent("interstitial", "click");
}

@end

@implementation RewardedListener

static RewardedListener *rewardedListener;
static NSString* rewardedAdId;

+ (RewardedListener*)getRewardedListener
{
    return rewardedListener;
}
+ (void)setRewardedListener:(RewardedListener*)newListener
{
    if (rewardedListener != newListener)
    {
        rewardedListener = newListener;
    }
}

/////IRewarded
- (id)initWithID:(NSString*)ID
{
    self = [super init];
    NSLog(@"AdMob Init Rewarded");
    if(!self) return nil;
    rewardedAdId = ID;
    [self loadAd];
    return self;
}

- (void)loadAd
{
    if(![Consent consentHasBeenChecked])
    {
        sendAdEvent("rewarded", "fail");
        NSLog(@"rewardedDidFailToReceiveAdWithError: User consent hasn't been checked yet");
        return;
    }
    GADRequest *request = [Consent buildAdReq];
    [GADRewardedAd loadWithAdUnitID:rewardedAdId
                                request:request
                      completionHandler:^(GADRewardedAd *ad, NSError *error) {
        if (error) {
          sendAdEvent("rewarded", "fail");
          NSLog(@"rewardedDidFailToReceiveAdWithError: %@", [error localizedDescription]);
          return;
        }
        rewarded = ad;
        sendAdEvent("rewarded", "load");
        NSLog(@"rewardedDidReceiveAd");
        rewarded.fullScreenContentDelegate = self;
    }];
}

- (bool)isReady{
    return rewarded != nil;
}

- (void)show
{
    if (!rewarded) return;
    [rewarded
      presentFromRootViewController:[[[UIApplication sharedApplication] keyWindow] rootViewController]
           userDidEarnRewardHandler:^{
        GADAdReward *reward = rewarded.adReward;
        sendRewardEvent(reward.type.UTF8String, reward.amount.doubleValue);
    }];
}

- (void)adWillPresentFullScreenContent:(id)ad
{
    sendAdEvent("rewarded", "open");
    NSLog(@"rewardedWillPresentScreen");
}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error
{
    NSLog(@"Ad failed to present full screen content with error %@.", [error localizedDescription]);
}

- (void)adDidDismissFullScreenContent:(id)ad
{
    sendAdEvent("rewarded", "close");
    NSLog(@"rewardedDidDismissScreen");
}

- (void)adDidRecordClick:(id)ad
{
    sendAdEvent("rewarded", "click");
}

@end

@implementation BannerListener

@synthesize bottom;

static BannerListener *bannerListener;
static NSLayoutConstraint *bannerHorizontalConstraint;
static NSLayoutConstraint *bannerVerticalConstraint;
static BOOL firstBannerLoad = NO;

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
    
    GADAdSize adSize = [self getFullWidthAdaptiveAdSize];
    bannerView = [[GADBannerView alloc] initWithAdSize:adSize];
    
    bannerView.adUnitID = bannerID;
    bannerView.rootViewController = root;
    
    if([Consent consentHasBeenChecked])
    {
        firstBannerLoad = YES;
        GADRequest *request = [Consent buildAdReq];
        [bannerView loadRequest:request];
    }
    bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [root.view addSubview:bannerView];
    
    [bannerView setDelegate:self];
    
    bannerView.hidden=true;
    [self setPosition:GMODE];
    
    return self;
}

- (GADAdSize)getFullWidthAdaptiveAdSize {
  CGRect frame = root.view.frame;
  if (@available(iOS 11.0, *)) {
    frame = UIEdgeInsetsInsetRect(root.view.frame, root.view.safeAreaInsets);
  }
  return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(frame.size.width);
}

-(void)setPosition:(NSString*)position
{
    bottom=[position isEqualToString:@"BOTTOM"];
    
    if (bottom) // Reposition the adView to the bottom of the screen
    {
        if (@available(ios 11.0, *)) {
            [self positionBannerViewAtBottomOfSafeArea];
        } else {
            [self positionBannerViewAtBottomOfView];
        }
    }else // Reposition the adView to the top of the screen
    {
        if (@available(ios 11.0, *)) {
            [self positionBannerViewAtTopOfSafeArea];
        } else {
            [self positionBannerViewAtTopOfView];
        }
    }
}

-(void)positionBannerViewAtTopOfSafeArea NS_AVAILABLE_IOS(11.0)
{
    // Position the banner. Stick it to the top of the Safe Area.
    // Centered horizontally.
    UILayoutGuide *guide = root.view.safeAreaLayoutGuide;
    if(bannerHorizontalConstraint && bannerVerticalConstraint)
    {
        [NSLayoutConstraint deactivateConstraints:@[bannerHorizontalConstraint,bannerVerticalConstraint]];
    }
    bannerHorizontalConstraint=[bannerView.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor];
    bannerVerticalConstraint=[bannerView.topAnchor constraintEqualToAnchor:guide.topAnchor];
    [NSLayoutConstraint activateConstraints:@[bannerHorizontalConstraint,bannerVerticalConstraint]];
}

-(void)positionBannerViewAtBottomOfSafeArea NS_AVAILABLE_IOS(11.0)
{
    // Position the banner. Stick it to the bottom of the Safe Area.
    // Centered horizontally.
    UILayoutGuide *guide = root.view.safeAreaLayoutGuide;
    if(bannerHorizontalConstraint && bannerVerticalConstraint)
    {
        [NSLayoutConstraint deactivateConstraints:@[bannerHorizontalConstraint,bannerVerticalConstraint]];
    }
    bannerHorizontalConstraint=[bannerView.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor];
    bannerVerticalConstraint=[bannerView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor];
    [NSLayoutConstraint activateConstraints:@[bannerHorizontalConstraint,bannerVerticalConstraint]];
}

-(void)positionBannerViewAtTopOfView
{
    if(bannerHorizontalConstraint && bannerVerticalConstraint)
    {
        [root.view removeConstraints:@[bannerHorizontalConstraint,bannerVerticalConstraint]];
    }
    bannerHorizontalConstraint=[NSLayoutConstraint constraintWithItem:bannerView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:root.view
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1
                                                             constant:0];
    bannerVerticalConstraint=[NSLayoutConstraint constraintWithItem:bannerView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:root.topLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:0];
    [root.view addConstraints:@[bannerHorizontalConstraint,bannerVerticalConstraint]];
}

-(void)positionBannerViewAtBottomOfView
{
    if(bannerHorizontalConstraint && bannerVerticalConstraint)
    {
        [root.view removeConstraints:@[bannerHorizontalConstraint,bannerVerticalConstraint]];
    }
    bannerHorizontalConstraint=[NSLayoutConstraint constraintWithItem:bannerView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:root.view
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1
                                                             constant:0];
    bannerVerticalConstraint=[NSLayoutConstraint constraintWithItem:bannerView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:root.bottomLayoutGuide
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:0];
    [root.view addConstraints:@[bannerHorizontalConstraint,bannerVerticalConstraint]];
}

-(void)showBannerAd
{
    if(!firstBannerLoad)
    {
        [self reloadBanner];
    }
    bannerView.hidden=false;
}

-(void)hideBannerAd
{
    bannerView.hidden=true;
}

-(void)reloadBanner
{
	if(![Consent consentHasBeenChecked])
    {
        sendAdEvent("banner", "fail");
        NSLog(@"AdMob: banner failed to load: User consent hasn't been checked yet");
        return;
    }
    firstBannerLoad = YES;
    GADRequest *request = [Consent buildAdReq];
    [bannerView loadRequest:request];
}

/// Called when an banner ad request succeeded.
- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView
{
    sendAdEvent("banner", "load");
    NSLog(@"AdMob: banner ad successfully loaded!");
}

/// Called when an banner ad request failed.
- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(nonnull NSError *)error
{
    sendAdEvent("banner", "fail");
    NSLog(@"AdMob: banner failed to load...");
}

- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView
{
    sendAdEvent("banner", "open");
    NSLog(@"AdMob: banner was opened.");
}

/// Called before the banner is to be animated off the screen.
- (void)bannerViewWillDismissScreen:(GADBannerView *)bannerView
{
    sendAdEvent("banner", "close");
    NSLog(@"AdMob: banner was closed.");
}

- (void)bannerViewDidRecordClick:(GADBannerView *)bannerView
{
    sendAdEvent("banner", "click");
}

@end

@implementation Consent

static NSString *publisherID;
static BOOL testing = NO;
static BOOL showWhenLoaded = NO;
static BOOL consentChecked = NO;
static UMPConsentForm* consentForm;
static BOOL debugGeographySpecified = NO;
static UMPDebugGeography debugGeography;

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

+ (void)setDebugGeography:(UMPDebugGeography)newDebugGeography
{
    debugGeography = newDebugGeography;
    debugGeographySpecified = YES;
}

+ (void)showConsentForm:(BOOL)checkConsent
{
    NSLog(@"consentsdk: showConsentForm");
    
    if (checkConsent && UMPConsentInformation.sharedInstance.consentStatus == UMPConsentStatusObtained)
    {
        NSLog(@"consentsdk: Skipping form because player already answered");
        consentChecked = YES;
        return;
    }
    
    showWhenLoaded = YES;
    
    if (consentForm != nil)
    {
        [self showForm];
    }
    else
    {
        [self setupForm];
    }
}

+ (void)setupForm
{
    UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
    parameters.tagForUnderAgeOfConsent = NO;
    if(testing)
    {
        UMPDebugSettings* debugSettings = [[UMPDebugSettings alloc] init];
        if(debugGeographySpecified)
            debugSettings.geography = debugGeography;
        debugSettings.testDeviceIdentifiers = @[[self admobDeviceID]];
        parameters.debugSettings = debugSettings;
    }

    [UMPConsentInformation.sharedInstance
        requestConsentInfoUpdateWithParameters:parameters
                             completionHandler:^(NSError *_Nullable error) {
        if (error) {
            NSLog(@"consentsdk: consent update failed with error: %@", [error localizedDescription]);
        } else {
            UMPFormStatus formStatus = UMPConsentInformation.sharedInstance.formStatus;
            if (formStatus == UMPFormStatusAvailable) {
                [self loadForm];
            } else {
                consentChecked = YES;
                NSLog(@"consentsdk: no consent form available");
            }
        }
    }];
}

// https://stackoverflow.com/a/25012633
+ (NSString *)admobDeviceID
{
    NSUUID* adid = [[ASIdentifierManager sharedManager] advertisingIdentifier];
    const char *cStr = [adid.UUIDString UTF8String];
    unsigned char digest[16];
    CC_MD5(cStr, strlen(cStr), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return output;
}

+ (void)getConsentInfo
{
    NSLog(@"consentsdk: getConsentInfo");
    
    if (UMPConsentInformation.sharedInstance.consentStatus == UMPConsentStatusObtained)
    {
        NSLog(@"consentsdk: Skipping form because player already answered");
        consentChecked = YES;
        return;
    }
    
    showWhenLoaded = NO;
    [self setupForm];
}

+ (void)loadForm {
    consentForm = nil;
    
    [UMPConsentForm loadWithCompletionHandler:^(UMPConsentForm *form,
                                              NSError *loadError) {
    if (loadError) {
        NSLog(@"consentsdk: Form load failed with error: %@", [loadError localizedDescription]);
    } else {
        NSLog(@"consentsdk: Form has loaded.");
        consentForm = form;
        if(showWhenLoaded)
        {
            [self showForm];
        }
    }
  }];
}

+ (void) showForm {
    showWhenLoaded = false;
    UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [consentForm
        presentFromViewController:root
                completionHandler:^(NSError *_Nullable dismissError) {
        [self loadForm];
        NSLog(@"consentsdk: consent form closed");
        consentChecked = YES;
    }];
}

+ (BOOL)consentHasBeenChecked
{
    return consentChecked;
}

+ (GADRequest*)buildAdReq
{
	GADRequest *request = [GADRequest request];

	return request;
}
    
@end


namespace admobex {
	
    static InitializeAdmobListener *initializeAdmobListener;
    static InterstitialListener *interstitialListener;
    static RewardedListener *rewardedListener;
    static BannerListener *bannerListener;
    static NSString *interstitialID;
    static NSString *rewardedID;
    
	void init(const char *__BannerID, const char *__InterstitialID, const char *__RewardedID, const char *gravityMode, bool testingAds){
        NSString *admobID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GADApplicationIdentifier"];
        NSString *GMODE = [NSString stringWithUTF8String:gravityMode];
        NSString *bannerID = [NSString stringWithUTF8String:__BannerID];
        interstitialID = [NSString stringWithUTF8String:__InterstitialID];
        rewardedID = [NSString stringWithUTF8String:__RewardedID];

        NSString *pubID = [[admobID componentsSeparatedByString:@"~"] objectAtIndex:0];
        [Consent setPublisherID:pubID];
        [Consent setTesting:testingAds];
        [Consent getConsentInfo];

        if(testingAds){
            admobID = @"ca-app-pub-3940256099942544~1458002511"; // ADMOB GENERIC TESTING appID
            interstitialID = @"ca-app-pub-3940256099942544/4411468910"; // ADMOB GENERIC TESTING INTERSTITIAL
            rewardedID = @"ca-app-pub-3940256099942544/1712485313"; // ADMOB GENERIC TESTING REWARDED
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

        // REWARDED
        if ([rewardedID length] != 0) {
            rewardedListener = [[RewardedListener alloc] initWithID:rewardedID];
            [RewardedListener setRewardedListener:rewardedListener];
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
        interstitialListener = [[InterstitialListener alloc] initWithID:interstitialID];
    }
    
    void showInterstitial()
    {
        if(interstitialListener!=NULL) [interstitialListener show];
    }

    void loadRewarded()
    {
        rewardedListener = [[RewardedListener alloc] initWithID:rewardedID];
    }

    void showRewarded()
    {
        if(rewardedListener!=NULL) [rewardedListener show];
    }
	
    void showConsentForm(bool checkConsent)
    {
		[Consent showConsentForm:checkConsent];
    }

    void setDebugGeography(const char *value)
    {
        if     (strcmp(value, "eea")      == 0) [Consent setDebugGeography:UMPDebugGeographyEEA];
        else if(strcmp(value, "not_eea")  == 0) [Consent setDebugGeography:UMPDebugGeographyNotEEA];
        else if(strcmp(value, "disabled") == 0) [Consent setDebugGeography:UMPDebugGeographyDisabled];
        //do nothing for ""
    }

    void setTagForChildDirectedTreatment(const char *value)
    {
        GADRequestConfiguration* requestConfig = [GADMobileAds.sharedInstance requestConfiguration];
        if     (strcmp(value, "true")  == 0) [requestConfig tagForChildDirectedTreatment:true];
        else if(strcmp(value, "false") == 0) [requestConfig tagForChildDirectedTreatment:false];
        //do nothing for ""
    }

    void setTagForUnderAgeOfConsent(const char *value)
    {
        GADRequestConfiguration* requestConfig = [GADMobileAds.sharedInstance requestConfiguration];
        if     (strcmp(value, "true")  == 0) [requestConfig tagForUnderAgeOfConsent:true];
        else if(strcmp(value, "false") == 0) [requestConfig tagForUnderAgeOfConsent:false];
        //do nothing for ""
    }

    void setMaxAdContentRating(const char *value)
    {
        GADRequestConfiguration* requestConfig = [GADMobileAds.sharedInstance requestConfiguration];
        if     (strcmp(value, "G")  == 0) [requestConfig setMaxAdContentRating:GADMaxAdContentRatingGeneral];
        else if(strcmp(value, "PG") == 0) [requestConfig setMaxAdContentRating:GADMaxAdContentRatingParentalGuidance];
        else if(strcmp(value, "T")  == 0) [requestConfig setMaxAdContentRating:GADMaxAdContentRatingTeen];
        else if(strcmp(value, "MA") == 0) [requestConfig setMaxAdContentRating:GADMaxAdContentRatingMatureAudience];
        //do nothing for ""
    }
}
