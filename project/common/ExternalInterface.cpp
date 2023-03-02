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

AutoGCRoot* adEventHandle = 0;

#ifdef IPHONE

static void ads_set_ad_event_handle(value onEvent)
{
    adEventHandle = new AutoGCRoot(onEvent);
}
DEFINE_PRIM(ads_set_ad_event_handle, 1);

static value admobex_init(value admob_id, value banner_id, value interstitial_id, value gravity_mode, value testing_ads){
	init(val_string(admob_id),val_string(banner_id),val_string(interstitial_id), val_string(gravity_mode), val_bool(testing_ads));
	return alloc_null();
}
DEFINE_PRIM(admobex_init,5);

static value admobex_banner_show(){
	showBanner();
	return alloc_null();
}
DEFINE_PRIM(admobex_banner_show,0);

static value admobex_banner_hide(){
	hideBanner();
	return alloc_null();
}
DEFINE_PRIM(admobex_banner_hide,0);

static value admobex_banner_refresh(){
	refreshBanner();
	return alloc_null();
}
DEFINE_PRIM(admobex_banner_refresh,0);

static value admobex_interstitial_load(){
    loadInterstitial();
    return alloc_null();
}
DEFINE_PRIM(admobex_interstitial_load,0);

static value admobex_interstitial_show(){
	showInterstitial();
	return alloc_null();
}
DEFINE_PRIM(admobex_interstitial_show,0);

static value admobex_banner_move(value gravity_mode){
    setBannerPosition(val_string(gravity_mode));
    return alloc_null();
}
DEFINE_PRIM(admobex_banner_move,1);

static value admobex_showConsentForm(value checkConsent){
    showConsentForm(val_bool(checkConsent));
    return alloc_null();
}
DEFINE_PRIM(admobex_showConsentForm,1);

#endif

extern "C" void admobex_main () {
    val_int(0); // Fix Neko init
    
}
DEFINE_ENTRY_POINT (admobex_main);

extern "C" int admobex_register_prims () { return 0; }

extern "C" void sendAdEvent(char* adType, char* adEventType)
{
    printf("Send Ad Event: %s %s\n",adType, adEventType);
    val_call2(adEventHandle->get(), alloc_string(adType), alloc_string(adEventType));
}
