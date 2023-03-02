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
	private static var __showConsentForm:Bool->Void = function(checkConsent:Bool){};
	private static var __setDebugGeography:String->Void = function(value:String){};
	private static var __setChildDirectedTreatment:String->Void = function(value:String){};
	private static var __setUnderAgeOfConsent:String->Void = function(value:String){};
	private static var __setMaxAdContentRating:String->Void = function(value:String){};
	
	////////////////////////////////////////////////////////////////////////////

	private static var lastTimeInterstitial:Int = -60*1000;
	private static var displayCallsCounter:Int = 0;

	////////////////////////////////////////////////////////////////////////////
	
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
			var set_ad_event_handle = cpp.Lib.load("adMobEx", "ads_set_ad_event_handle", 1);
			__showBanner = cpp.Lib.load("adMobEx","admobex_banner_show",0);
			__hideBanner = cpp.Lib.load("adMobEx","admobex_banner_hide",0);
			__loadInterstitial = cpp.Lib.load("admobex","admobex_interstitial_load",0);
			__showInterstitial = cpp.Lib.load("admobex","admobex_interstitial_show",0);
			__refresh = cpp.Lib.load("adMobEx","admobex_banner_refresh",0);
			__setBannerPosition = cpp.Lib.load("admobex","admobex_banner_move",1);
			__showConsentForm = cpp.Lib.load("admobex","admobex_showConsentForm",1);
			__setDebugGeography = cpp.Lib.load("admobex","admobex_setDebugGeography",1);
			__setChildDirectedTreatment = cpp.Lib.load("admobex","admobex_setTagForChildDirectedTreatment",1);
			__setUnderAgeOfConsent = cpp.Lib.load("admobex","admobex_setTagForUnderAgeOfConsent",1);
			__setMaxAdContentRating = cpp.Lib.load("admobex","admobex_setMaxAdContentRating",1);

			__init("",AdmobConfig.iosBannerKey,AdmobConfig.iosInterstitialKey,gravityMode,AdmobConfig.enableTestAds);
			set_ad_event_handle(onAdmobAdEvent);
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
			__showConsentForm = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "showConsentForm", "(Z)V");
			__setDebugGeography = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "setDebugGeography", "(Ljava/lang/String;)V");
			__setChildDirectedTreatment = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "setTagForChildDirectedTreatment", "(Ljava/lang/String;)V");
			__setUnderAgeOfConsent = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "setTagForUnderAgeOfConsent", "(Ljava/lang/String;)V");
			__setMaxAdContentRating = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "setMaxAdContentRating", "(Ljava/lang/String;)V");

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

	public static function setDebugGeography(value:String) {
		try{
			__setDebugGeography(value);
		}catch(e:Dynamic){
			trace("setDebugGeography Exception: "+e);
		}
	}

	public static function setChildDirectedTreatment(value:String) {
		try{
			__setChildDirectedTreatment(value);
		}catch(e:Dynamic){
			trace("setChildDirectedTreatment Exception: "+e);
		}
	}

	public static function setUnderAgeOfConsent(value:String) {
		try{
			__setUnderAgeOfConsent(value);
		}catch(e:Dynamic){
			trace("setUnderAgeOfConsent Exception: "+e);
		}
	}

	public static function setMaxAdContentRating(value:String) {
		try{
			__setMaxAdContentRating(value);
		}catch(e:Dynamic){
			trace("setMaxAdContentRating Exception: "+e);
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
	
	//Callbacks
	public function onAdmobAdEvent(adTypeString:String, adEventTypeString:String)
	{
		trace(adTypeString + " " + adEventTypeString);
		
		var adType:AdType = switch(adTypeString)
		{
			case "banner": BANNER;
			case "interstitial": INTERSTITIAL;
			default: null;
		}
		
		var adEventType:AdEventType = switch(adEventTypeString)
		{
			case "open": OPENED;
			case "close": CLOSED;
			case "load": LOADED;
			case "fail": FAILED_TO_LOAD;
			case "click": CLICKED;
			default: null;
		}
		
		if(adType != null && adEventType != null)
		{
			nativeEventQueue.push(AdEvent(adType, adEventType));
		}
	}

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
