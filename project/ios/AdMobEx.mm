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

@interface AdmBanner : NSObject <GADBannerViewDelegate>

-(instancetype)initWithBannerID:(NSString*)bannerId withVisbility:(BOOL)visible withGravity:(NSString*)gravity withCallbacks:(AutoGCRoot*)callbacks;
-(void)loadAd;
-(void)fadeIn;
-(void)fadeOut;
-(void)setPosition:(NSString *)gravity;
-(void)dispose;

@end

@interface AdmFullScreenContent : NSObject<GADFullScreenContentDelegate>

-(instancetype)initWithCallbacks:(AutoGCRoot*)callbacks;

@end

@interface AdmInterstitial : NSObject

-(instancetype)initWithAd:(GADInterstitialAd*)ad;
-(void)setFullScreenContentCallback:(AdmFullScreenContent*)contentCallback;
-(void)showAd;

@end

@interface AdmRewarded : NSObject

-(instancetype)initWithAd:(GADRewardedAd*)ad;
-(void)setFullScreenContentCallback:(AdmFullScreenContent*)contentCallback;
-(void)showAd:(AutoGCRoot*)rewardCallback;

@end

/**
 Very simple scheme to share object references with
 Haxe without worrying about ObjC ARC and HXCPP GC interactions
 */
@interface AdmForeignReferenceManager : NSObject

-(id)getReference:(int)idx;
-(int)addReference:(NSObject*)o;
-(void)clearReference:(int)idx;

@end

static bool loggingEnabled = false;
#define debugLog(...) if(loggingEnabled) NSLog(@"AdMobEx [debug] : %s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])

@implementation AdmBanner {
    NSLayoutConstraint *bannerHorizontalConstraint;
    NSLayoutConstraint *bannerVerticalConstraint;
    UIViewController *root;
    GADBannerView *bannerView;
    AutoGCRoot *callbacks;
}

- (instancetype)
    initWithBannerID:(NSString *)bannerId
       withVisbility:(BOOL)visible
         withGravity:(NSString *)gravity
       withCallbacks:(AutoGCRoot *)_callbacks
{
    self = [super init];
    NSLog(@"AdMob Init Banner");
    
    if(!self) return nil;
    
    root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    GADAdSize adSize = [self getFullWidthAdaptiveAdSize];
    bannerView = [[GADBannerView alloc] initWithAdSize:adSize];
    bannerView.adUnitID = bannerId;
    callbacks = _callbacks;
    [bannerView setDelegate:self];
    
    bannerView.rootViewController = root;
    bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [root.view addSubview:bannerView];
    [self setPosition:gravity];
    if(visible)
        [self fadeIn];
    else
        bannerView.hidden=true;
    
    static int _id_onAdHeightUpdated = val_id("onAdHeightUpdated");
    CGSize adCgSize = CGSizeFromGADAdSize(adSize);
    int adHeight = (int) roundf(adCgSize.height * [UIScreen mainScreen].nativeScale);
    val_ocall1(callbacks->get(), _id_onAdHeightUpdated, alloc_int(adHeight));
    
    return self;
}

- (GADAdSize)getFullWidthAdaptiveAdSize {
  CGRect frame = root.view.frame;
  if (@available(iOS 11.0, *)) {
    frame = UIEdgeInsetsInsetRect(root.view.frame, root.view.safeAreaInsets);
  }
  return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(frame.size.width);
}

- (void)loadAd
{
    [bannerView loadRequest:[GADRequest request]];
}

- (void)fadeIn
{
    bannerView.hidden = false;
}

- (void)fadeOut
{
    bannerView.hidden = true;
}

- (void)setPosition:(NSString*)position
{
    bool bottom = [position isEqualToString:@"BOTTOM"];
    
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

- (void)dispose
{
    [bannerView removeFromSuperview];
    bannerView.delegate = nil;
    bannerView = nil;
    root = nil;
    callbacks = nil;
}

/// Called when an banner ad request succeeded.
- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView
{
    static int _id_onAdLoaded = val_id("onAdLoaded");
    val_ocall0(callbacks->get(), _id_onAdLoaded);
}

/// Called when an banner ad request failed.
- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(nonnull NSError *)error
{
    static int _id_onAdFailedToLoad = val_id("onAdFailedToLoad");
    val_ocall1(callbacks->get(), _id_onAdFailedToLoad, alloc_string([[error localizedDescription] UTF8String]));
}

- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView
{
    static int _id_onAdOpened = val_id("onAdOpened");
    val_ocall0(callbacks->get(), _id_onAdOpened);
}

/// Called before the banner is to be animated off the screen.
- (void)bannerViewWillDismissScreen:(GADBannerView *)bannerView
{
    static int _id_onAdClosed = val_id("onAdClosed");
    val_ocall0(callbacks->get(), _id_onAdClosed);
}

- (void)bannerViewDidRecordClick:(GADBannerView *)bannerView
{
    static int _id_onAdClicked = val_id("onAdClicked");
    val_ocall0(callbacks->get(), _id_onAdClicked);
}

- (void)bannerViewDidRecordImpression:(GADBannerView *)bannerView
{
    static int _id_onAdImpression = val_id("onAdImpression");
    val_ocall0(callbacks->get(), _id_onAdImpression);
}

@end

@implementation AdmFullScreenContent {
    AutoGCRoot* callbacks;
}

- (instancetype)initWithCallbacks:(AutoGCRoot *)_callbacks
{
    self = [super init];
    if(!self) return nil;
    
    callbacks = _callbacks;
    
    return self;
}

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
    static int _id_onAdShowedFullScreenContent = val_id("onAdShowedFullScreenContent");
    val_ocall0(callbacks->get(), _id_onAdShowedFullScreenContent);
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error
{
    static int _id_onAdFailedToShowFullScreenContent = val_id("onAdFailedToShowFullScreenContent");
    val_ocall1(callbacks->get(), _id_onAdFailedToShowFullScreenContent, alloc_string([[error localizedDescription] UTF8String]));
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
    static int _id_onAdDismissedFullScreenContent = val_id("onAdDismissedFullScreenContent");
    val_ocall0(callbacks->get(), _id_onAdDismissedFullScreenContent);
}

- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad
{
    static int _id_onAdClicked = val_id("onAdClicked");
    val_ocall0(callbacks->get(), _id_onAdClicked);
}

- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad
{
    static int _id_onAdImpression = val_id("onAdImpression");
    val_ocall0(callbacks->get(), _id_onAdImpression);
}

@end

@implementation AdmInterstitial {
    GADInterstitialAd *ad;
}

- (instancetype)initWithAd:(GADInterstitialAd *)_ad
{
    self = [super init];
    if(!self) return nil;
    
    ad = _ad;
    
    return self;
}

- (void)showAd
{
    [ad presentFromRootViewController:[[[UIApplication sharedApplication] keyWindow] rootViewController]];
}

- (void)setFullScreenContentCallback:(AdmFullScreenContent *)contentCallback
{
    ad.fullScreenContentDelegate = contentCallback;
}

@end

@implementation AdmRewarded {
    GADRewardedAd *ad;
}

- (instancetype)initWithAd:(GADRewardedAd *)_ad
{
    self = [super init];
    if(!self) return nil;
    
    ad = _ad;
    
    return self;
}

- (void)showAd:(AutoGCRoot *)rewardCallback
{
    static int _id_onUserEarnedReward = val_id("onUserEarnedReward");

    [ad
     presentFromRootViewController:[[[UIApplication sharedApplication] keyWindow] rootViewController]
     userDidEarnRewardHandler:^{
        GADAdReward *reward = ad.adReward;
        val_ocall2(rewardCallback->get(), _id_onUserEarnedReward, alloc_string(reward.type.UTF8String), alloc_int(reward.amount.intValue));
    }];
}

- (void)setFullScreenContentCallback:(AdmFullScreenContent *)contentCallback
{
    ad.fullScreenContentDelegate = contentCallback;
}

@end

@implementation AdmForeignReferenceManager {
    NSMutableArray *referenceArray;
}

- (instancetype)init
{
    self = [super init];
    if(!self) return nil;
    
    referenceArray = [NSMutableArray arrayWithCapacity:5];
    
    return self;
}

- (id)getReference:(int)idx
{
    return referenceArray[idx];
}

- (int)addReference:(NSObject *)o
{
    int i = 0;
    while(i < [referenceArray count] && referenceArray[i] != [NSNull null]) { ++i; }
    if(i == [referenceArray count])
    {
        debugLog(@"Growing reference count past %lu", [referenceArray count]);
        [referenceArray addObject:o];
    }
    else
    {
        referenceArray[i] = o;
    }
    return i;
}

- (void)clearReference:(int)idx
{
    referenceArray[idx] = [NSNull null];
}

@end

namespace admobex {
    
    static NSString *admobId;
    static bool testingAds;
    static NSString *deviceId;

    static AdmForeignReferenceManager *refs;
    static UMPConsentForm *consentForm;

    //forward declarations
    NSString *admobDeviceID();
    void applyUmpDebugGeography(UMPDebugSettings* debugSettings, const char *value);
    void applyUmpTagForUnderAgeOfConsent(UMPRequestParameters* params, const char *value);
    void applyGadTagForChildDirectedTreatment(GADRequestConfiguration* requestConfig, const char *value);
    void applyGadTagForUnderAgeOfConsent(GADRequestConfiguration* requestConfig, const char *value);
    void applyGadMaxAdContentRating(GADRequestConfiguration* requestConfig, const char *value);
    
    void initConfig(bool _testingAds, bool _loggingEnabled)
    {
        refs = [[AdmForeignReferenceManager alloc] init];
        admobId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GADApplicationIdentifier"];
        loggingEnabled = _loggingEnabled;
        debugLog(@"initConfig(%d,%d)", _testingAds, _loggingEnabled);
        
        testingAds = _testingAds;
        if(_testingAds)
        {
            deviceId = admobDeviceID();
        }
    }

    // https://stackoverflow.com/a/25012633
    NSString *admobDeviceID()
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

    void resetConsent()
    {
        debugLog(@"resetConsent()");
        [UMPConsentInformation.sharedInstance reset];
    }
    
    void setupConsentForm(bool testingConsent, const char* debugGeography, const char* underAgeOfConsent, AutoGCRoot* callbacks)
    {
        static int _id_onConsentInfoUpdateSuccess = val_id("onConsentInfoUpdateSuccess");
        static int _id_onConsentInfoUpdateFailure = val_id("onConsentInfoUpdateFailure");
        
        debugLog(@"setupConsentForm(%d,%s,%s)", testingConsent, debugGeography, underAgeOfConsent);
        
        UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
        applyUmpTagForUnderAgeOfConsent(parameters, underAgeOfConsent);
        if(testingConsent)
        {
            UMPDebugSettings* debugSettings = [[UMPDebugSettings alloc] init];
            applyUmpDebugGeography(debugSettings, debugGeography);
            debugSettings.testDeviceIdentifiers = @[ [[[UIDevice currentDevice] identifierForVendor] UUIDString] ];
            parameters.debugSettings = debugSettings;
        }

        [UMPConsentInformation.sharedInstance
            requestConsentInfoUpdateWithParameters:parameters
                                 completionHandler:^(NSError *_Nullable error) {
            if (error) {
                val_ocall1(callbacks->get(), _id_onConsentInfoUpdateFailure, alloc_string([[error localizedDescription] UTF8String]));
            } else {
                UMPFormStatus formStatus = UMPConsentInformation.sharedInstance.formStatus;
                val_ocall1(callbacks->get(), _id_onConsentInfoUpdateSuccess, alloc_bool(formStatus == UMPFormStatusAvailable));
            }
        }];
    }

    void applyUmpDebugGeography(UMPDebugSettings* debugSettings, const char *value)
    {
        if     (strcmp(value, "eea")      == 0) debugSettings.geography = UMPDebugGeographyEEA;
        else if(strcmp(value, "not_eea")  == 0) debugSettings.geography = UMPDebugGeographyNotEEA;
        else if(strcmp(value, "disabled") == 0) debugSettings.geography = UMPDebugGeographyDisabled;
        //do nothing for ""
    }

    void applyUmpTagForUnderAgeOfConsent(UMPRequestParameters* params, const char *value)
    {
        if     (strcmp(value, "true")  == 0) params.tagForUnderAgeOfConsent = true;
        else if(strcmp(value, "false") == 0) params.tagForUnderAgeOfConsent = false;
        //do nothing for ""
    }

    void loadConsentForm(AutoGCRoot* callbacks)
    {
        static int _id_onConsentFormLoadSuccess = val_id("onConsentFormLoadSuccess");
        static int _id_onConsentFormLoadFailure = val_id("onConsentFormLoadFailure");
        
        debugLog(@"loadConsentForm()");
        
        consentForm = nil;
        
        [UMPConsentForm loadWithCompletionHandler:^(UMPConsentForm *form,
                                                  NSError *loadError) {
            if (loadError) {
                val_ocall1(callbacks->get(), _id_onConsentFormLoadFailure, alloc_string([[loadError localizedDescription] UTF8String]));
            } else {
                consentForm = form;
                val_ocall0(callbacks->get(), _id_onConsentFormLoadSuccess);
            }
        }];
    }

    void showConsentForm(AutoGCRoot* callbacks)
    {
        static int _id_onConsentFormDismissed = val_id("onConsentFormDismissed");
        
        debugLog(@"showConsentForm()");
        
        UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        [consentForm
            presentFromViewController:root
                    completionHandler:^(NSError *_Nullable dismissError) {
            if(dismissError)
                val_ocall1(callbacks->get(), _id_onConsentFormDismissed, alloc_string([[dismissError localizedDescription] UTF8String]));
            else
                val_ocall1(callbacks->get(), _id_onConsentFormDismissed, alloc_string(""));
        }];
    }

    void initSdk(AutoGCRoot* callbacks)
    {
        static int _id_onInitializationComplete = val_id("onInitializationComplete");
        
        debugLog(@"initSdk()");
        
        [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus * _Nonnull status) {
            val_ocall0(callbacks->get(), _id_onInitializationComplete);
        }];
    }

    void updateRequestConfig(const char* childDirected, const char* underAgeOfConsent, const char* maxAdContentRating)
    {
        debugLog(@"updateRequestConfig(%s,%s,%s)", childDirected, underAgeOfConsent, maxAdContentRating);
        GADRequestConfiguration* requestConfig = [GADMobileAds.sharedInstance requestConfiguration];
        applyGadTagForChildDirectedTreatment(requestConfig, childDirected);
        applyGadTagForUnderAgeOfConsent(requestConfig, underAgeOfConsent);
        applyGadMaxAdContentRating(requestConfig, maxAdContentRating);
    }

    void applyGadTagForChildDirectedTreatment(GADRequestConfiguration* requestConfig, const char *value)
    {
        if     (strcmp(value, "true")  == 0) [requestConfig tagForChildDirectedTreatment:true];
        else if(strcmp(value, "false") == 0) [requestConfig tagForChildDirectedTreatment:false];
        //do nothing for ""
    }

    void applyGadTagForUnderAgeOfConsent(GADRequestConfiguration* requestConfig, const char *value)
    {
        if     (strcmp(value, "true")  == 0) [requestConfig tagForUnderAgeOfConsent:true];
        else if(strcmp(value, "false") == 0) [requestConfig tagForUnderAgeOfConsent:false];
        //do nothing for ""
    }

    void applyGadMaxAdContentRating(GADRequestConfiguration* requestConfig, const char *value)
    {
        if     (strcmp(value, "G")  == 0) [requestConfig setMaxAdContentRating:GADMaxAdContentRatingGeneral];
        else if(strcmp(value, "PG") == 0) [requestConfig setMaxAdContentRating:GADMaxAdContentRatingParentalGuidance];
        else if(strcmp(value, "T")  == 0) [requestConfig setMaxAdContentRating:GADMaxAdContentRatingTeen];
        else if(strcmp(value, "MA") == 0) [requestConfig setMaxAdContentRating:GADMaxAdContentRatingMatureAudience];
        //do nothing for ""
    }

    int initBanner(const char* bannerId, bool visible, const char* position, AutoGCRoot* callbacks)
    {
        debugLog(@"initBanner(%s,%d,%s)", bannerId, visible, position);
        
        AdmBanner* banner = [[AdmBanner alloc]
                             initWithBannerID:[NSString stringWithUTF8String:bannerId]
                                withVisbility:visible
                                  withGravity:[NSString stringWithUTF8String:position]
                                withCallbacks:callbacks];
        
        return [refs addReference:banner];
    }

    void loadBanner(int bannerRef)
    {
        AdmBanner *banner = [refs getReference:bannerRef];
        [banner loadAd];
    }

    void showBanner(int bannerRef)
    {
        AdmBanner *banner = [refs getReference:bannerRef];
        [banner fadeIn];
    }

    void hideBanner(int bannerRef)
    {
        AdmBanner *banner = [refs getReference:bannerRef];
        [banner fadeOut];
    }

    void setBannerPosition(int bannerRef, const char* position)
    {
        AdmBanner *banner = [refs getReference:bannerRef];
        [banner setPosition:[NSString stringWithUTF8String:position]];
    }

    void disposeBanner(int bannerRef)
    {
        AdmBanner *banner = [refs getReference:bannerRef];
        [banner dispose];
    }

    void loadInterstitial(const char* interstitialId, AutoGCRoot* callbacks)
    {
        static int _id_onAdLoaded = val_id("onAdLoaded");
        static int _id_onAdFailedToLoad = val_id("onAdFailedToLoad");
        
        [GADInterstitialAd loadWithAdUnitID:[NSString stringWithUTF8String:interstitialId]
                                    request:[GADRequest request]
                          completionHandler:^(GADInterstitialAd *ad, NSError *error) {
            
            if (error) {
                val_ocall1(callbacks->get(), _id_onAdFailedToLoad, alloc_string([[error localizedDescription] UTF8String]));
                return;
            }
            
            AdmInterstitial *interstitial = [[AdmInterstitial alloc] initWithAd:ad];
            int interstitalRef = [refs addReference:interstitial];
            
            val_ocall1(callbacks->get(), _id_onAdLoaded, alloc_int(interstitalRef));
        }];
    }

    void showInterstitial(int interstitialRef)
    {
        AdmInterstitial *interstital = [refs getReference:interstitialRef];
        [interstital showAd];
    }

    void loadRewarded(const char* rewardedId, AutoGCRoot* callbacks)
    {
        static int _id_onAdLoaded = val_id("onAdLoaded");
        static int _id_onAdFailedToLoad = val_id("onAdFailedToLoad");
        
        [GADRewardedAd loadWithAdUnitID:[NSString stringWithUTF8String:rewardedId]
                                    request:[GADRequest request]
                          completionHandler:^(GADRewardedAd *ad, NSError *error) {
            
            if (error) {
                val_ocall1(callbacks->get(), _id_onAdFailedToLoad, alloc_string([[error localizedDescription] UTF8String]));
                return;
            }
            
            AdmRewarded *rewarded = [[AdmRewarded alloc] initWithAd:ad];
            int rewardedRef = [refs addReference:rewarded];
            
            val_ocall1(callbacks->get(), _id_onAdLoaded, alloc_int(rewardedRef));
        }];
    }

    void showRewarded(int rewardedRef, AutoGCRoot* callbacks)
    {
        AdmRewarded *rewarded = [refs getReference:rewardedRef];
        [rewarded showAd:callbacks];
    }

    void setFullScreenContentCallback(int adRef, AutoGCRoot* callbacks)
    {
        NSObject *ad = [refs getReference:adRef];
        
        if([ad isKindOfClass:[AdmInterstitial class]]) {
            AdmInterstitial *interstitial = (AdmInterstitial*) ad;
            [interstitial setFullScreenContentCallback:[[AdmFullScreenContent alloc] initWithCallbacks:callbacks]];
        }
        else if([ad isKindOfClass:[AdmRewarded class]]) {
            AdmRewarded *rewarded = (AdmRewarded*) ad;
            [rewarded setFullScreenContentCallback:[[AdmFullScreenContent alloc] initWithCallbacks:callbacks]];
        }
    }

    void clearReference(int ref)
    {
        [refs clearReference:ref];
    }
}
