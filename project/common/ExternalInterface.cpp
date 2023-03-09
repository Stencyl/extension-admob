#ifndef IPHONE
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFI.h>
#include "AdMobEx.h"
#include <stdio.h>

using namespace admobex;

#ifdef IPHONE

static value admobex_initConfig(value testingAds, value loggingEnabled)
{
    initConfig(val_bool(testingAds), val_bool(loggingEnabled));
    return alloc_null();
}
DEFINE_PRIM(admobex_initConfig,2);

static value admobex_resetConsent()
{
    resetConsent();
    return alloc_null();
}
DEFINE_PRIM(admobex_resetConsent,0);

static value admobex_setupConsentForm(value testingConsent, value debugGeography, value underAgeOfConsent, value callbacks)
{
    setupConsentForm(val_bool(testingConsent), val_string(debugGeography), val_string(underAgeOfConsent), new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_setupConsentForm,4);

static value admobex_loadConsentForm(value callbacks)
{
    loadConsentForm(new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_loadConsentForm,1);

static value admobex_showConsentForm(value callbacks)
{
    showConsentForm(new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_showConsentForm,1);

static value admobex_initSdk(value callbacks)
{
    initSdk(new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_initSdk,1);

static value admobex_updateRequestConfig(value childDirected, value underAgeOfConsent, value maxAdContentRating)
{
    updateRequestConfig(val_string(childDirected), val_string(underAgeOfConsent), val_string(maxAdContentRating));
    return alloc_null();
}
DEFINE_PRIM(admobex_updateRequestConfig,3);

static value admobex_initBanner(value bannerId, value visible, value position, value callbacks)
{
    int result = initBanner(val_string(bannerId), val_bool(visible), val_string(position), new AutoGCRoot(callbacks));
    return alloc_int(result);
}
DEFINE_PRIM(admobex_initBanner,4);

static value admobex_loadBanner(value bannerRef)
{
    loadBanner(val_int(bannerRef));
    return alloc_null();
}
DEFINE_PRIM(admobex_loadBanner,1);

static value admobex_showBanner(value bannerRef)
{
    showBanner(val_int(bannerRef));
    return alloc_null();
}
DEFINE_PRIM(admobex_showBanner,1);

static value admobex_hideBanner(value bannerRef)
{
    hideBanner(val_int(bannerRef));
    return alloc_null();
}
DEFINE_PRIM(admobex_hideBanner,1);

static value admobex_setBannerPosition(value bannerRef, value position)
{
    setBannerPosition(val_int(bannerRef), val_string(position));
    return alloc_null();
}
DEFINE_PRIM(admobex_setBannerPosition,2);

static value admobex_disposeBanner(value bannerRef)
{
    disposeBanner(val_int(bannerRef));
    return alloc_null();
}
DEFINE_PRIM(admobex_disposeBanner,1);

static value admobex_loadInterstitial(value interstitialId, value callbacks)
{
    loadInterstitial(val_string(interstitialId), new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_loadInterstitial,2);

static value admobex_showInterstitial(value interstitialRef)
{
    showInterstitial(val_int(interstitialRef));
    return alloc_null();
}
DEFINE_PRIM(admobex_showInterstitial,1);

static value admobex_loadRewarded(value rewardedId, value callbacks)
{
    loadRewarded(val_string(rewardedId), new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_loadRewarded,2);

static value admobex_showRewarded(value rewardedRef, value callbacks)
{
    showRewarded(val_int(rewardedRef), new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_showRewarded,2);

static value admobex_loadRewardedInterstitial(value rewardedInterstitialId, value callbacks)
{
    loadRewardedInterstitial(val_string(rewardedInterstitialId), new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_loadRewardedInterstitial,2);

static value admobex_showRewardedInterstitial(value rewardedInterstitialRef, value callbacks)
{
    showRewardedInterstitial(val_int(rewardedInterstitialRef), new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_showRewardedInterstitial,2);

static value admobex_setFullScreenContentCallback(value adRef, value callbacks)
{
    setFullScreenContentCallback(val_int(adRef), new AutoGCRoot(callbacks));
    return alloc_null();
}
DEFINE_PRIM(admobex_setFullScreenContentCallback,2);

static value admobex_clearReference(value ref)
{
    clearReference(val_int(ref));
    return alloc_null();
}
DEFINE_PRIM(admobex_clearReference,1);


#endif

extern "C" void admobex_main () {
    val_int(0); // Fix Neko init
    
}
DEFINE_ENTRY_POINT (admobex_main);

extern "C" int admobex_register_prims () { return 0; }
