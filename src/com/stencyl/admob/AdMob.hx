package com.stencyl.admob;

import openfl.Lib;

#if android
import lime.system.JNI;
#end

import com.stencyl.admob.Listeners;
import com.stencyl.Config;
import com.stencyl.Engine;
import com.stencyl.Extension;
import com.stencyl.event.Event;
import com.stencyl.models.Scene;
import com.stencyl.utils.Utils;

using com.stencyl.event.EventDispatcher;

#if ios
@:buildXml('<include name="${haxelib:com.stencyl.admob}/project/Build.xml"/>')
//This is just here to prevent the otherwise indirectly referenced native code from being stripped at link time.
@:cppFileCode('extern "C" int admobex_register_prims();void com_stencyl_admobex_link(){admobex_register_prims();}')
#end
class AdMob extends Extension
	implements OnConsentInfoUpdateListener
	implements OnConsentFormLoadListener
	implements OnConsentFormDismissedListener
	implements OnInitializationCompleteListener
	implements OnUserEarnedRewardListener
{
	private static var instance:AdMob;
	private static var sdkInitializing:Bool = false;
	private static var sdkInitialized:Bool = false;
	private static var debugLogs:Bool = false;
	private static inline final NULL_FOREIGN_REF = -1;
	
	//banner
	private static var bannerRef:Int = NULL_FOREIGN_REF;
	private static var bannerPosition:String;
	private static var loadingBanner:Bool = false;
	private static var bannerFailed:Bool = false;
	private static var bannerShouldBeVisible:Bool = false;
	private static var bannerHeight:Int = 0;

	//interstitial
	private static var interstitialRef:Int = NULL_FOREIGN_REF;

	//rewarded
	private static var rewardedRef:Int = NULL_FOREIGN_REF;

	//rewarded interstitial
	private static var rewardedInterstitialRef:Int = NULL_FOREIGN_REF;
	
	//consent form and ad requests
	private static var debugGeography:String = "";
	private static var childDirected = "";
	private static var underAgeOfConsent = "";
	private static var maxAdContentRating = "";

	//state management -- enforce the collection of user consent before initializing the sdk
	private static var processingForm = false;
	private static var consentChecked = false;
	private static var alwaysShowConsentForm = false;
	private static var wantToInitSdk = false;

	//constants
	#if (android && testing)
	private static final testBannerKey       = "ca-app-pub-3940256099942544/6300978111";
	private static final testInterstitialKey = "ca-app-pub-3940256099942544/1033173712";
	private static final testRewardedKey     = "ca-app-pub-3940256099942544/5224354917";
	private static final testRewardedInterstitialKey
											 = "ca-app-pub-3940256099942544/5354046379";
	#elseif (ios && testing)
	private static final testBannerKey       = "ca-app-pub-3940256099942544/2934735716";
	private static final testInterstitialKey = "ca-app-pub-3940256099942544/5135589807";
	private static final testRewardedKey     = "ca-app-pub-3940256099942544/1712485313";
	private static final testRewardedInterstitialKey
											 = "ca-app-pub-3940256099942544/6978759866";
	#end

	//stencyl events
	public var adEvent:Event<(AdEventData)->Void>;
	public var rewardEvent:Event<(rewardType:String, rewardAmount:Float)->Void>;
	public var nativeEventQueue:Array<AdEventData> = [];
	
	///////////////////////////////////////////////////////////////////////////
	
	private static var __setupConsentForm:(testingConsent:Bool, debugGeography:String, underAgeOfConsent:String, callbacks:OnConsentInfoUpdateListener)->Void;
	private static var __loadConsentForm:(callbacks:OnConsentFormLoadListener)->Void;
	private static var __showConsentForm:(callbacks:OnConsentFormDismissedListener)->Void;
	private static var __initSdk:(callbacks:OnInitializationCompleteListener)->Void;
	private static var __updateRequestConfig:(childDirected:String, underAgeOfConsent:String, maxAdContentRating:String)->Void;
	private static var __initBanner:(bannerId:String, visible:Bool, position:String, callbacks:AdListener)->Int;
	private static var __loadBanner:(bannerRef:Int)->Void;
	private static var __showBanner:(bannerRef:Int)->Void;
	private static var __hideBanner:(bannerRef:Int)->Void;
	private static var __setBannerPosition:(bannerRef:Int, position:String)->Void;
	private static var __disposeBanner:(bannerRef:Int)->Void;
	private static var __loadInterstitial:(interstitialId:String, callbacks:AdLoadCallback)->Void;
	private static var __showInterstitial:(interstitialRef:Int)->Void;
	private static var __loadRewarded:(rewardedId:String, callbacks:AdLoadCallback)->Void;
	private static var __showRewarded:(rewardedRef:Int, callbacks:OnUserEarnedRewardListener)->Void;
	private static var __loadRewardedInterstitial:(rewardedInterstitialId:String, callbacks:AdLoadCallback)->Void;
	private static var __showRewardedInterstitial:(rewardedInterstitialRef:Int, callbacks:OnUserEarnedRewardListener)->Void;
	private static var __setContentCallback:(adRef:Int, callbacks:FullScreenContentCallback)->Void;
	private static var __clearReference:(ref:Int)->Void;
	
	///////////////////////////////////////////////////////////////////////////
	
	public function new()
	{
		super();
		instance = this;
		AdmobConfig.load();

		#if android
		javaInstance = JNI.createStaticField("com/byrobin/admobex/AdMobEx", "instance", "Lcom/byrobin/admobex/AdMobEx;").get();
		var s = "Ljava/lang/String;";
		var o = "Lorg/haxe/lime/HaxeObject;";
		#end
		
		var __initConfig            = loadFunction2("initConfig"                      #if android , '(ZZ)V'        #end);
		var __resetConsent          = loadFunction0("resetConsent"                    #if android , '()V'          #end);
		__setupConsentForm          = loadFunction4("setupConsentForm"                #if android , '(Z$s$s$o)V'   #end);
		__loadConsentForm           = loadFunction1("loadConsentForm"                 #if android , '($o)V'        #end);
		__showConsentForm           = loadFunction1("showConsentForm"                 #if android , '($o)V'        #end);
		__initSdk                   = loadFunction1("initSdk"                         #if android , '($o)V'        #end);
		__updateRequestConfig       = loadFunction3("updateRequestConfig"             #if android , '($s$s$s)V'    #end);
		__initBanner                = loadFunction4("initBanner"                      #if android , '(${s}Z$s$o)I' #end);
		__loadBanner                = loadFunction1("loadBanner"                      #if android , '(I)V'         #end);
		__showBanner                = loadFunction1("showBanner"                      #if android , '(I)V'         #end);
		__hideBanner                = loadFunction1("hideBanner"                      #if android , '(I)V'         #end);
		__setBannerPosition         = loadFunction2("setBannerPosition"               #if android , '(I$s)V'       #end);
		__disposeBanner             = loadFunction1("disposeBanner"                   #if android , '(I)V'         #end);
		__loadInterstitial          = loadFunction2("loadInterstitial"                #if android , '($s$o)V'      #end);
		__showInterstitial          = loadFunction1("showInterstitial"                #if android , '(I)V'         #end);
		__loadRewarded              = loadFunction2("loadRewarded"                    #if android , '($s$o)V'      #end);
		__showRewarded              = loadFunction2("showRewarded"                    #if android , '(I$o)V'       #end);
		__loadRewardedInterstitial  = loadFunction2("loadRewardedInterstitial"        #if android , '($s$o)V'      #end);
		__showRewardedInterstitial  = loadFunction2("showRewardedInterstitial"        #if android , '(I$o)V'       #end);
		__setContentCallback        = loadFunction2("setFullScreenContentCallback"    #if android , '(I$o)V'       #end);
		__clearReference            = loadFunction1("clearReference"                  #if android , '(I)V'         #end);
		
		debugLogs = #if testing true #else false #end;
		tryRun(() -> __initConfig(AdmobConfig.enableTestAds, debugLogs));

		if(AdmobConfig.enableTestConsent)
		{
			tryRun(() -> __resetConsent());
		}
	}

	public static function get()
	{
		return instance;
	}

	private static inline function debugLog(msg:String, ?pos:haxe.PosInfos)
	{
		if(debugLogs) trace(msg, pos);
	}
	
	////////////////////////////////////////////////////////////////////////////

	//Called from Design Mode
	public static function setDebugGeography(value:String)
	{
		debugLog('setDebugGeography($value)');
		debugGeography = value;
	}

	//Called from Design Mode
	public static function setChildDirectedTreatment(value:String)
	{
		debugLog('setChildDirectedTreatment($value)');
		childDirected = value;

		if(sdkInitialized)
			tryRun(() -> __updateRequestConfig(childDirected, underAgeOfConsent, maxAdContentRating));
	}

	//Called from Design Mode
	public static function setUnderAgeOfConsent(value:String)
	{
		debugLog('setUnderAgeOfConsent($value)');
		underAgeOfConsent = value;

		if(sdkInitialized)
			tryRun(() -> __updateRequestConfig(childDirected, underAgeOfConsent, maxAdContentRating));
	}

	//Called from Design Mode
	public static function setMaxAdContentRating(value:String)
	{
		debugLog('setMaxAdContentRating($value)');
		maxAdContentRating = value;

		if(sdkInitialized)
			tryRun(() -> __updateRequestConfig(childDirected, underAgeOfConsent, maxAdContentRating));
	}

	//Called from Design Mode
	public static function showConsentForm(checkConsent:Bool = true)
	{
		debugLog('showConsentForm($checkConsent)');
		alwaysShowConsentForm = !checkConsent;
		if(processingForm) return;

		processingForm = true;
		tryRun(() -> __setupConsentForm(AdmobConfig.enableTestConsent, debugGeography, underAgeOfConsent, instance));
	}

	//OnConsentInfoUpdateListener
	public function onConsentInfoUpdateSuccess(formAvailable:Bool):Void
	{
		debugLog('onConsentInfoUpdateSuccess($formAvailable)');
		if(formAvailable)
		{
			tryRun(() -> __loadConsentForm(instance));
		}
		else
		{
			consentChecked = true;
			processingForm = false;
			if(wantToInitSdk) finishInitSdk();
		}
	}

	//OnConsentInfoUpdateListener
	public function onConsentInfoUpdateFailure(formError:String):Void
	{
		debugLog('onConsentInfoUpdateFailure($formError)');
		processingForm = false;
	}

	//OnConsentFormLoadListener
	public function onConsentFormLoadSuccess():Void
	{
		debugLog('onConsentFormLoadSuccess()');
		tryRun(() -> __showConsentForm(instance));
	}

	//OnConsentFormLoadListener
    public function onConsentFormLoadFailure(formError:String):Void
	{
		debugLog('onConsentFormLoadFailure($formError)');
		processingForm = false;
	}

	//OnConsentFormDismissedListener
	public function onConsentFormDismissed(formError:String):Void
	{
		debugLog('onConsentFormDismissed($formError)');
		processingForm = false;
		if(formError != "")
		{
			return;
		}

		consentChecked = true;
		if(wantToInitSdk) finishInitSdk();
	}
	
	//Called from Design Mode
	public static function initSdk(position:Int)
	{
		debugLog('initSdk($position)');
		if(sdkInitializing || sdkInitialized) return;
		bannerPosition = if(position == 1) "TOP" else "BOTTOM";

		if(!consentChecked)
		{
			wantToInitSdk = true;
			showConsentForm(!alwaysShowConsentForm);
			return;
		}

		tryRun(() -> __initSdk(instance));
	}

	//Called after consent has been determined if wantToInitSdk has been set
	private static function finishInitSdk()
	{
		debugLog('finishInitSdk()');
		
		wantToInitSdk = false;
		tryRun(() -> __initSdk(instance));
	}

	//OnInitializationCompleteListener
	public function onInitializationComplete():Void
	{
		debugLog('onInitializationComplete()');
		
		sdkInitializing = false;
		sdkInitialized = true;

		tryRun(() -> __updateRequestConfig(childDirected, underAgeOfConsent, maxAdContentRating));

		var bannerId = 
			#if testing if(AdmobConfig.enableTestAds) testBannerKey else #end
			#if android AdmobConfig.androidBannerKey
			#elseif ios AdmobConfig.iosBannerKey
			#end;
		if(bannerId != "")
		{
			tryRun(() -> bannerRef = __initBanner(bannerId, bannerShouldBeVisible, bannerPosition, new BannerListener()));
			reloadBanner();
		}
	}
	
	private static function reloadBanner()
	{
		debugLog('reloadBanner()');
		if(loadingBanner || bannerRef == NULL_FOREIGN_REF) return;

		loadingBanner = true;
		bannerFailed = false;
		tryRun(() -> __loadBanner(bannerRef));
	}
	
	//Called from Design Mode
	public static function showBanner()
	{
		debugLog('showBanner()');
		bannerShouldBeVisible = true;
		if(bannerRef == NULL_FOREIGN_REF) return;

		if(bannerFailed)
		{
			reloadBanner();
		}
		tryRun(() -> {
			__showBanner(bannerRef);
			instance.nativeEventQueue.push(AdEvent(BANNER, OPENED));
		});
	}
	
	//Called from Design Mode
	public static function hideBanner()
	{
		debugLog('hideBanner()');
		bannerShouldBeVisible = false;
		if(bannerRef == NULL_FOREIGN_REF) return;

		tryRun(() -> {
			__hideBanner(bannerRef);
			instance.nativeEventQueue.push(AdEvent(BANNER, CLOSED));
		});
	}
	
	//Called from Design Mode
	public static function setBannerPosition(position:Int)
	{
		debugLog('setBannerPosition($position)');
		bannerPosition = if(position == 1) "TOP" else "BOTTOM";
		
		if(bannerRef == NULL_FOREIGN_REF) return;
		tryRun(() -> __setBannerPosition(bannerRef, bannerPosition));
	}

	//Called from Design Mode
	public static function getBannerHeight()
	{
		return bannerHeight;
	}

	//Called from Design Mode
	public static function loadInterstitial()
	{
		debugLog('loadInterstitial()');
		var interstitialId = 
			#if testing if(AdmobConfig.enableTestAds) testInterstitialKey else #end
			#if android AdmobConfig.androidInterstitialKey
			#elseif ios AdmobConfig.iosInterstitialKey
			#end;

		tryRun(() -> __loadInterstitial(interstitialId, new FullScreenCallbacks(INTERSTITIAL)));
	}
	
	private static function updateInterstitialRef(ref:Int)
	{
		if(interstitialRef != NULL_FOREIGN_REF)
			tryRun(() -> __clearReference(interstitialRef));
		interstitialRef = ref;
	}
	
	//Called from Design Mode
	public static function showInterstitial()
	{
		debugLog('showInterstitial()');
		if(interstitialRef == NULL_FOREIGN_REF) return;

		tryRun(() -> __showInterstitial(interstitialRef));
	}

	//Called from Design Mode
	public static function loadRewarded()
	{
		debugLog('loadRewarded()');
		var rewardedId = 
			#if testing if(AdmobConfig.enableTestAds) testRewardedKey else #end
			#if android AdmobConfig.androidRewardedKey
			#elseif ios AdmobConfig.iosRewardedKey
			#end;

		tryRun(() -> __loadRewarded(rewardedId, new FullScreenCallbacks(REWARDED)));
	}
	
	private static function updateRewardedRef(ref:Int)
	{
		if(rewardedRef != NULL_FOREIGN_REF)
			tryRun(() -> __clearReference(rewardedRef));
		rewardedRef = ref;
	}
	
	//Called from Design Mode
	public static function showRewarded()
	{
		debugLog('showRewarded()');
		if(rewardedRef == NULL_FOREIGN_REF) return;
		
		tryRun(() -> __showRewarded(rewardedRef, instance));
	}

	//Called from Design Mode
	public static function loadRewardedInterstitial()
	{
		debugLog('loadRewardedInterstitial()');
		var rewardedInterstitialId = 
			#if testing if(AdmobConfig.enableTestAds) testRewardedInterstitialKey else #end
			#if android AdmobConfig.androidRewardedInterstitialKey
			#elseif ios AdmobConfig.iosRewardedInterstitialKey
			#end;

		tryRun(() -> __loadRewardedInterstitial(rewardedInterstitialId, new FullScreenCallbacks(REWARDED_INTERSTITIAL)));
	}
	
	private static function updateRewardedInterstitialRef(ref:Int)
	{
		if(rewardedInterstitialRef != NULL_FOREIGN_REF)
			tryRun(() -> __clearReference(rewardedInterstitialRef));
		rewardedInterstitialRef = ref;
	}
	
	//Called from Design Mode
	public static function showRewardedInterstitial()
	{
		debugLog('showRewardedInterstitial()');
		if(rewardedInterstitialRef == NULL_FOREIGN_REF) return;
		
		tryRun(() -> __showRewardedInterstitial(rewardedInterstitialRef, instance));
	}

	//OnUserEarnedRewardListener
	public function onUserEarnedReward(rewardType:String, rewardAmount:Int):Void
	{
		debugLog('onUserEarnedReward($rewardType, $rewardAmount)');
		instance.nativeEventQueue.push(RewardEvent(rewardType, rewardAmount));
	}

	//Extension
	public override function loadScene(scene:Scene)
	{
		adEvent = new Event<(AdEventData)->Void>();
		rewardEvent = new Event<(String,Float)->Void>();
	}
	
	public override function cleanupScene()
	{
		adEvent = null;
		rewardEvent = null;
	}

	public override function preSceneUpdate()
	{
		for(event in nativeEventQueue)
		{
			switch(event)
			{
				case AdEvent(_, _):
					adEvent.dispatch(event);
				case RewardEvent(rewardType, rewardAmount):
					rewardEvent.dispatch(rewardType, rewardAmount);
			}
		}
		nativeEventQueue.splice(0, nativeEventQueue.length);
	}

	//native helpers

	private static inline function tryRun(functionToRun:()->Void, ?pos:haxe.PosInfos):Void
	{
		try
		{
			functionToRun();
		}
		catch(e:Dynamic)
		{
			trace("Exception: " + e + Utils.printExceptionstackIfAvailable(), pos);
		}
	}

	#if android
	private var javaInstance:Dynamic;

	private function loadFunction0(name:String, signature:String):Dynamic
	{
		var memberMethod:(Dynamic)->Void = JNI.createMemberMethod("com/byrobin/admobex/AdMobEx", name, signature);
		return memberMethod.bind(javaInstance);
	}
	private function loadFunction1(name:String, signature:String):Dynamic
	{
		var memberMethod:(Dynamic,Dynamic)->Void = JNI.createMemberMethod("com/byrobin/admobex/AdMobEx", name, signature);
		return memberMethod.bind(javaInstance);
	}
	private function loadFunction2(name:String, signature:String):Dynamic
	{
		var memberMethod:(Dynamic,Dynamic,Dynamic)->Void = JNI.createMemberMethod("com/byrobin/admobex/AdMobEx", name, signature);
		return memberMethod.bind(javaInstance);
	}
	private function loadFunction3(name:String, signature:String):Dynamic
	{
		var memberMethod:(Dynamic,Dynamic,Dynamic,Dynamic)->Void = JNI.createMemberMethod("com/byrobin/admobex/AdMobEx", name, signature);
		return memberMethod.bind(javaInstance);
	}
	private function loadFunction4(name:String, signature:String):Dynamic
	{
		var memberMethod:(Dynamic,Dynamic,Dynamic,Dynamic,Dynamic)->Void = JNI.createMemberMethod("com/byrobin/admobex/AdMobEx", name, signature);
		return memberMethod.bind(javaInstance);
	}
	#elseif ios
	private function loadFunction0(name:String):Dynamic
	{
		return cpp.Lib.load("adMobEx", "admobex_" + name, 0);
	}
	private function loadFunction1(name:String):Dynamic
	{
		return cpp.Lib.load("adMobEx", "admobex_" + name, 1);
	}
	private function loadFunction2(name:String):Dynamic
	{
		return cpp.Lib.load("adMobEx", "admobex_" + name, 2);
	}
	private function loadFunction3(name:String):Dynamic
	{
		return cpp.Lib.load("adMobEx", "admobex_" + name, 3);
	}
	private function loadFunction4(name:String):Dynamic
	{
		return cpp.Lib.load("adMobEx", "admobex_" + name, 4);
	}
	#end
}

enum AdEventData {
	AdEvent(adType:AdType, adEventType:AdEventType);
	RewardEvent(rewardType:String, rewardAmount:Float);
}

enum AdType {
	BANNER;
	INTERSTITIAL;
	REWARDED;
	REWARDED_INTERSTITIAL;
}

enum AdEventType {
	OPENED;
	CLOSED;
	LOADED;
	FAILED_TO_LOAD;
	CLICKED;
}

@:access(com.stencyl.admob.AdMob)
class BannerListener implements AdListener
{
	public function new()
	{
		
	}

    public function onAdClicked():Void
	{
		AdMob.debugLog('onAdClicked()');
		AdMob.instance.nativeEventQueue.push(AdEvent(BANNER, CLICKED));
	}

    public function onAdClosed():Void
	{
		AdMob.debugLog('onAdClosed()');
		AdMob.instance.nativeEventQueue.push(AdEvent(BANNER, CLOSED));
	}

    public function onAdFailedToLoad(loadAdError:String):Void
	{
		AdMob.debugLog('onAdFailedToLoad($loadAdError)');
		AdMob.loadingBanner = false;
		AdMob.bannerFailed = true;
		AdMob.instance.nativeEventQueue.push(AdEvent(BANNER, FAILED_TO_LOAD));
	}

    public function onAdImpression():Void
	{
		AdMob.debugLog('onAdImpression()');
	}

    public function onAdLoaded():Void
	{
		AdMob.debugLog('onAdLoaded()');
		AdMob.loadingBanner = false;
		AdMob.instance.nativeEventQueue.push(AdEvent(BANNER, LOADED));
	}
	
    public function onAdOpened():Void
	{
		AdMob.debugLog('onAdOpened()');
		AdMob.instance.nativeEventQueue.push(AdEvent(BANNER, OPENED));
	}

	public function onAdHeightUpdated(heightInPixels:Int):Void
	{
		AdMob.debugLog('onAdHeightUpdated($heightInPixels)');
		AdMob.bannerHeight = Math.ceil(heightInPixels / (Engine.SCALE * Engine.screenScaleY));
	}
}

@:access(com.stencyl.admob.AdMob)
class FullScreenCallbacks implements AdLoadCallback implements FullScreenContentCallback
{
	private var adType:AdType;

	public function new(adType:AdType)
	{
		this.adType = adType;
	}

	public function onAdLoaded(adRef:Int):Void
	{
		AdMob.debugLog('onAdLoaded($adRef)');
		switch(adType)
		{
			case INTERSTITIAL: AdMob.updateInterstitialRef(adRef);
			case REWARDED: AdMob.updateRewardedRef(adRef);
			case REWARDED_INTERSTITIAL: AdMob.updateRewardedInterstitialRef(adRef);
			case _:
		}
		
		AdMob.tryRun(() -> AdMob.__setContentCallback(adRef, this));

		AdMob.instance.nativeEventQueue.push(AdEvent(adType, LOADED));
	}

    public function onAdFailedToLoad(loadAdError:String):Void
	{
		AdMob.debugLog('onAdFailedToLoad($loadAdError)');
		AdMob.instance.nativeEventQueue.push(AdEvent(adType, FAILED_TO_LOAD));
	}

	public function onAdClicked():Void
	{
		AdMob.debugLog('onAdClicked()');
		AdMob.instance.nativeEventQueue.push(AdEvent(adType, CLICKED));
	}

    public function onAdDismissedFullScreenContent():Void
	{
		AdMob.debugLog('onAdDismissedFullScreenContent()');
		AdMob.instance.nativeEventQueue.push(AdEvent(adType, CLOSED));
	}

    public function onAdFailedToShowFullScreenContent(adError:String):Void
	{
		AdMob.debugLog('onAdFailedToShowFullScreenContent($adError)');
	}

    public function onAdImpression():Void
	{
		AdMob.debugLog('onAdImpression()');
	}

    public function onAdShowedFullScreenContent():Void
	{
		AdMob.debugLog('onAdShowedFullScreenContent()');
		AdMob.instance.nativeEventQueue.push(AdEvent(adType, OPENED));
	}
}