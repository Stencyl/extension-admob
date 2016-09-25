#ifndef ADMOBEX_H
#define ADMOBEX_H


namespace admobex {
	
	
	void init(const char *__AdmobID,const char *__BannerID, const char *__InterstitialID, const char *gravityMode, bool testingAds);
    void setBannerPosition(const char *gravityMode);
	void showBanner();
	void hideBanner();
	void refreshBanner();
    void loadInterstitial();
	void showInterstitial();
}


#endif
