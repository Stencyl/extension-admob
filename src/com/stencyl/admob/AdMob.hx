package com.stencyl.admob;

import openfl.Lib;

#if android
import lime.system.JNI;
#end

import com.stencyl.Config;
import com.stencyl.Engine;
import com.stencyl.Extension;
import com.stencyl.event.Event;

using com.stencyl.event.EventDispatcher;

#if ios
@:buildXml('<include name="${haxelib:com.stencyl.admob}/project/Build.xml"/>')
//This is just here to prevent the otherwise indirectly referenced native code from bring stripped at link time.
@:cppFileCode('extern "C" int admobex_register_prims();void com_stencyl_admobex_link(){admobex_register_prims();}')
#end
class AdMob extends Extension
{
	public function new()
	{
		super();
		instance = this;
	}

	public static function get()
	{
		return instance;
	}

	public var adEvent:Event<(AdEventData)->Void> = new Event<(AdEventData)->Void>();
	public var nativeEventQueue:Array<AdEventData> = [];
	
	private static var initialized:Bool=false;
	private static var instance:AdMob;
	private static var testingAds:Bool=false;
	private static var gravityMode:String;

	///////////////////////////////////////////////////////////////////////////
	
	private static var __showBanner:Void->Void = function(){};
	private static var __hideBanner:Void->Void = function(){};
	private static var __loadInterstitial:Void->Void = function(){};
	private static var __showInterstitial:Void->Void = function(){};
	private static var __onResize:Void->Void = function(){};
	private static var __refresh:Void->Void = function(){};
	private static var __setBannerPosition:String->Void = function(gravityMode:String){};
	private static var __setPrivacyURL:String->Void = function(privacyURL:String){};
	private static var __showConsentForm:Bool->Void = function(checkConsent:Bool){};
	
	////////////////////////////////////////////////////////////////////////////

	private static var lastTimeInterstitial:Int = -60*1000;
	private static var displayCallsCounter:Int = 0;

	////////////////////////////////////////////////////////////////////////////
	
	#if ios
	//Ads Events only happen on iOS. AdMob provides no out-of-the-box way.
	private static function notifyListeners(inEvent:Dynamic)
	{
		var data:String = Std.string(Reflect.field(inEvent, "type"));
		
		if(data == "banneropen")
		{
			trace("USER OPENED BANNER");
			instance.nativeEventQueue.push(AdEvent(BANNER, OPENED));
		}
		
		if(data == "bannerclose")
		{
			trace("USER CLOSED BANNER");
			instance.nativeEventQueue.push(AdEvent(BANNER, CLOSED));
		}
		
		if(data == "bannerload")
		{
			trace("BANNER SHOWED UP");
			instance.nativeEventQueue.push(AdEvent(BANNER, LOADED));
		}
		
		if(data == "bannerfail")
		{
			trace("BANNER FAILED TO LOAD");
			instance.nativeEventQueue.push(AdEvent(BANNER, FAILED_TO_LOAD));
		}
		if(data == "bannerclicked")
		{
			trace("BANNER IS CLICKED");
			instance.nativeEventQueue.push(AdEvent(BANNER, CLICKED));
		}
		if(data == "interstitialopen")
		{
			trace("USER OPENED INTERSTITIAL");
			instance.nativeEventQueue.push(AdEvent(INTERSTITIAL, OPENED));
		}
		
		if(data == "interstitialclose")
		{
			trace("USER CLOSED INTERSTITIAL");
			instance.nativeEventQueue.push(AdEvent(INTERSTITIAL, CLOSED));
		}
		
		if(data == "interstitialload")
		{
			trace("INTERSTITIAL SHOWED UP");
			instance.nativeEventQueue.push(AdEvent(INTERSTITIAL, LOADED));
		}
		
		if(data == "interstitialfail")
		{
			trace("INTERSTITIAL FAILED TO LOAD");
			instance.nativeEventQueue.push(AdEvent(INTERSTITIAL, FAILED_TO_LOAD));
		}
		if(data == "interstitialclicked")
		{
			trace("INTERSTITIAL IS CLICKED");
			instance.nativeEventQueue.push(AdEvent(INTERSTITIAL, CLICKED));
		}
	}
	#end
	
	public static function loadInterstitial() {
		try{
			__loadInterstitial();
		}catch(e:Dynamic){
			trace("LoadInterstitial Exception: "+e);
		}
	}
	
	public static function showInterstitial() {
		try{
			__showInterstitial();
		}catch(e:Dynamic){
			trace("ShowInterstitial Exception: "+e);
		}
	}
	
	public static function init(position:Int){
		if(position == 1)
		{
			gravityMode = "TOP";
		}else
		{
			gravityMode = "BOTTOM";
		}
	
		if(initialized) return;
		initialized = true;
		AdmobConfig.load();

		#if ios
		try{
			// CPP METHOD LINKING
			var __init = cpp.Lib.load("adMobEx","admobex_init",5);
			var set_event_handle = cpp.Lib.load("adMobEx", "ads_set_event_handle", 1);
			__showBanner = cpp.Lib.load("adMobEx","admobex_banner_show",0);
			__hideBanner = cpp.Lib.load("adMobEx","admobex_banner_hide",0);
			__loadInterstitial = cpp.Lib.load("admobex","admobex_interstitial_load",0);
			__showInterstitial = cpp.Lib.load("admobex","admobex_interstitial_show",0);
			__refresh = cpp.Lib.load("adMobEx","admobex_banner_refresh",0);
			__setBannerPosition = cpp.Lib.load("admobex","admobex_banner_move",1);
			__setPrivacyURL = cpp.Lib.load("admobex","admobex_setPrivacyURL",1);
			__showConsentForm = cpp.Lib.load("admobex","admobex_showConsentForm",1);

			__init("",AdmobConfig.iosBannerKey,AdmobConfig.iosInterstitialKey,gravityMode,AdmobConfig.enableTestAds);
			set_event_handle(notifyListeners);
		}catch(e:Dynamic){
			trace("iOS INIT Exception: "+e);
		}
		#end
		
		#if android
		try{
			// JNI METHOD LINKING
			__showBanner = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "showBanner", "()V");
			__hideBanner = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "hideBanner", "()V");
			__loadInterstitial = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "loadInterstitial", "()V");
			__showInterstitial = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "showInterstitial", "()V");
			__onResize = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "onResize", "()V");
			__setBannerPosition = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "setBannerPosition", "(Ljava/lang/String;)V");
			__setPrivacyURL = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "setPrivacyURL", "(Ljava/lang/String;)V");
			__showConsentForm = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "showConsentForm", "(Z)V");

			var _init_func = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "init", "(Lorg/haxe/lime/HaxeObject;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V", true);
	
			var args = new Array<Dynamic>();
			args.push(instance);
			args.push("");
			args.push(AdmobConfig.androidBannerKey);
			args.push(AdmobConfig.androidInterstitialKey);
			args.push(gravityMode);
			args.push(AdmobConfig.enableTestAds);
			_init_func(args);
		}catch(e:Dynamic){
			trace("Android INIT Exception: "+e);
		}
		#end
	}
	
	public static function showBanner() {
		try {
			__showBanner();
			instance.nativeEventQueue.push(AdEvent(BANNER, OPENED));
		} catch(e:Dynamic) {
			trace("ShowAd Exception: "+e);
		}
	}
	
	public static function hideBanner() {
		try {
			__hideBanner();
			instance.nativeEventQueue.push(AdEvent(BANNER, CLOSED));
		} catch(e:Dynamic) {
			trace("HideAd Exception: "+e);
		}
	}
	
	public static function onResize() {
	
		#if ios
		try{
			__refresh();
		}catch(e:Dynamic){
			trace("onResize Exception: "+e);
		}
		#end
		#if android
		try{
			__onResize();
		}catch(e:Dynamic){
			trace("onResize Exception: "+e);
		}
		#end
	}
	
	public static function setBannerPosition(position:Int) {
	
		if(position == 1)
		{
			gravityMode = "TOP";
		}else
		{
			gravityMode = "BOTTOM";
		}
		
		try{
			__setBannerPosition(gravityMode);
		}catch(e:Dynamic){
			trace("setBannerPosition Exception: "+e);
		}
	}
	
	public static function setPrivacyURL(privacyURL:String)
	{
		try{
			__setPrivacyURL(privacyURL);
		}catch(e:Dynamic){
			trace("setPrivacyURL Exception: "+e);
		}
	}
	
	public static function showConsentForm(checkConsent:Bool = true)
	{
		try{
			__showConsentForm(checkConsent);
		}catch(e:Dynamic){
			trace("showConsentForm Exception: "+e);
		}
	}
	
	///Android Callbacks
	#if android
	public function onAdmobBannerClosed() 
	{
		trace("USER CLOSED BANNER");
		nativeEventQueue.push(AdEvent(BANNER, CLOSED));
	}
			
	public function onAdmobBannerOpened() 
	{
		trace("USER OPENED BANNER");
		nativeEventQueue.push(AdEvent(BANNER, OPENED));
	}
	
	public function onAdmobBannerLoaded() 
	{		
		trace("BANNER SHOWED UP");
		nativeEventQueue.push(AdEvent(BANNER, LOADED));
	}		
	
	public function onAdmobBannerFailed() 
	{
		trace("BANNER FAILED TO LOAD");
		nativeEventQueue.push(AdEvent(BANNER, FAILED_TO_LOAD));
	}
	
	public function onAdmobBannerClicked() 
	{
		trace("BANNER IS CLICKED");
		nativeEventQueue.push(AdEvent(BANNER, CLICKED));
	}
	
	public function onAdmobInterstitialClosed() 
	{
		trace("USER CLOSED INTERSTITIAL");
		nativeEventQueue.push(AdEvent(INTERSTITIAL, CLOSED));
	}
			
	public function onAdmobInterstitialOpened() 
	{
		trace("USER OPENED INTERSTITIAL");
		nativeEventQueue.push(AdEvent(INTERSTITIAL, OPENED));
	}
	
	public function onAdmobInterstitialLoaded() 
	{		
		trace("INTERSTITIAL SHOWED UP");
		nativeEventQueue.push(AdEvent(INTERSTITIAL, LOADED));
	}		
	
	public function onAdmobInterstitialFailed() 
	{
		trace("INTERSTITIAL FAILED TO LOAD");
		nativeEventQueue.push(AdEvent(INTERSTITIAL, FAILED_TO_LOAD));
	}
	public function onAdmobInterstitialClicked() 
	{
		trace("INTERSTITIAL IS CLICKED");
		nativeEventQueue.push(AdEvent(INTERSTITIAL, CLICKED));
	}
	#end

	public override function preSceneUpdate()
	{
		for(event in nativeEventQueue)
		{
			adEvent.dispatch(event);
		}
		nativeEventQueue.splice(0, nativeEventQueue.length);
	}
}

enum AdEventData {
	AdEvent(adType:AdType, adEventType:AdEventType);
}

enum AdType {
	BANNER;
	INTERSTITIAL;
}

enum AdEventType {
	OPENED;
	CLOSED;
	LOADED;
	FAILED_TO_LOAD;
	CLICKED;
}
