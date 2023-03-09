#ifndef ADMOBEX_H
#define ADMOBEX_H


namespace admobex {
	
	
	void init(const char *__BannerID, const char *__InterstitialID, const char *gravityMode, bool testingAds);
    void setBannerPosition(const char *gravityMode);
	void showBanner();
	void hideBanner();
	void refreshBanner();
    void loadInterstitial();
	void showInterstitial();
    void loadRewarded();
    void showRewarded();
	void showConsentForm(bool checkConsent);
    void setDebugGeography(const char *value);
    void setTagForChildDirectedTreatment(const char *value);
    void setTagForUnderAgeOfConsent(const char *value);
    void setMaxAdContentRating(const char *value);
}


#endif
