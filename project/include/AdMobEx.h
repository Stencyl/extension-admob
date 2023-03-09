#ifndef ADMOBEX_H
#define ADMOBEX_H

#ifndef STATIC_LINK
#define STATIC_LINK
#endif

#include <hx/CFFI.h>

namespace admobex {

    void initConfig(bool testingAds, bool loggingEnabled);
    void resetConsent();
    void setupConsentForm(bool testingConsent, const char* debugGeography, const char* underAgeOfConsent, AutoGCRoot* callbacks);
    void loadConsentForm(AutoGCRoot* callbacks);
    void showConsentForm(AutoGCRoot* callbacks);
    void initSdk(AutoGCRoot* callbacks);
    void updateRequestConfig(const char* childDirected, const char* underAgeOfConsent, const char* maxAdContentRating);
    int initBanner(const char* bannerId, bool visible, const char* position, AutoGCRoot* callbacks);
    void loadBanner(int bannerRef);
    void showBanner(int bannerRef);
    void hideBanner(int bannerRef);
    void setBannerPosition(int bannerRef, const char* position);
    void disposeBanner(int bannerRef);
    void loadInterstitial(const char* interstitialId, AutoGCRoot* callbacks);
    void showInterstitial(int interstitialRef);
    void loadRewarded(const char* rewardedId, AutoGCRoot* callbacks);
    void showRewarded(int rewardedRef, AutoGCRoot* callbacks);
    void loadRewardedInterstitial(const char* rewardedInterstitialId, AutoGCRoot* callbacks);
    void showRewardedInterstitial(int rewardedInterstitialRef, AutoGCRoot* callbacks);
    void setFullScreenContentCallback(int adRef, AutoGCRoot* callbacks);
    void clearReference(int ref);
}


#endif
