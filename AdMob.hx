package;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#else
import openfl.Lib;
#end

#if android
import openfl.utils.JNI;
#end

import scripts.MyAssets;
import com.stencyl.Engine;
import com.stencyl.event.EventMaster;
import com.stencyl.event.StencylEvent;

import openfl.utils.ByteArray;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class AdMob {
	
	#if android
	private function new() {}
	#end

	private static var initialized:Bool=false;
	private static var testingAds:Bool=false;
	private static var gravityMode:String;

	///////////////////////////////////////////////////////////////////////////
	#if ios
	private static var __init:String->String->String->Bool->Void = function(bannerId:String, interstitialId:String, gravityMode:String, testingAds:Bool){};
	private static var set_event_handle = Lib.load("adMobEx", "ads_set_event_handle", 1);
	#end
	#if android
	private static var _init_func:Dynamic;
	#end
	private static var __showBanner:Void->Void = function(){};
	private static var __hideBanner:Void->Void = function(){};
	private static var __showInterstitial:Void->Void = function(){};
	private static var __onResize:Void->Void = function(){};
	private static var __refresh:Void->Void = function(){};
	private static var __setBannerPosition:String->Void = function(gravityMode:String){};

	////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	
	#if ios
	//Ads Events only happen on iOS. AdMob provides no out-of-the-box way.
	private static function notifyListeners(inEvent:Dynamic)
	{
		var data:String = Std.string(Reflect.field(inEvent, "type"));
		
		if(data == "banneropen")
		{
			trace("USER OPENED BANNER");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_USER_OPEN));
		}
		
		if(data == "bannerclose")
		{
			trace("USER CLOSED BANNER");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_USER_CLOSE));
		}
		
		if(data == "bannerload")
		{
			trace("BANNER SHOWED UP");
			
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_LOADED));
		}
		
		if(data == "bannerfail")
		{
			trace("BANNER FAILED TO LOAD");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_FAILED));
		}
		if(data == "interstitialopen")
		{
			trace("USER OPENED INTERSTITIAL");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.FULL_AD_USER_OPEN));
		}
		
		if(data == "interstitialclose")
		{
			trace("USER CLOSED INTERSTITIAL");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.FULL_AD_USER_CLOSE));
		}
		
		if(data == "interstitialload")
		{
			trace("INTERSTITIAL SHOWED UP");
			
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.FULL_AD_LOADED));
		}
		
		if(data == "interstitialfail")
		{
			trace("INTERSTITIAL FAILED TO LOAD");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.FULL_AD_FAILED));
		}
	}
	#end
	
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
	
		#if ios
		if(initialized) return;
		initialized = true;
		try{
			// CPP METHOD LINKING
			__init = cpp.Lib.load("adMobEx","admobex_init",4);
			__showBanner = cpp.Lib.load("adMobEx","admobex_banner_show",0);
			__hideBanner = cpp.Lib.load("adMobEx","admobex_banner_hide",0);
			__showInterstitial = cpp.Lib.load("admobex","admobex_interstitial_show",0);
			__refresh = cpp.Lib.load("adMobEx","admobex_banner_refresh",0);
			__setBannerPosition = cpp.Lib.load("admobex","admobex_banner_move",1);

			__init(MyAssets.ioswhirlID,MyAssets.ioswhirlID1,gravityMode,MyAssets.testAds);
			set_event_handle(notifyListeners);
		}catch(e:Dynamic){
			trace("iOS INIT Exception: "+e);
		}
		#end
		
		#if android
		if(initialized) return;
		initialized = true;
		try{
			// JNI METHOD LINKING
			__showBanner = openfl.utils.JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "showBanner", "()V");
			__hideBanner = openfl.utils.JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "hideBanner", "()V");
			__showInterstitial = openfl.utils.JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "showInterstitial", "()V");
			__onResize = openfl.utils.JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "onResize", "()V");
			__setBannerPosition = openfl.utils.JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "setBannerPosition", "(Ljava/lang/String;)V");

			if(_init_func == null)
			{
				_init_func = JNI.createStaticMethod("com/byrobin/admobex/AdMobEx", "init", "(Lorg/haxe/lime/HaxeObject;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V", true);
			}
	
			var args = new Array<Dynamic>();
			args.push(new AdMob());
			args.push(MyAssets.whirlID);
			args.push(MyAssets.whirlID1);
			args.push(gravityMode);
			args.push(MyAssets.testAds);
			_init_func(args);
		}catch(e:Dynamic){
			trace("Android INIT Exception: "+e);
		}
		#end
	}
	
	public static function showBanner() {
		try {
			__showBanner();
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_USER_OPEN));
		} catch(e:Dynamic) {
			trace("ShowAd Exception: "+e);
		}
	}
	
	public static function hideBanner() {
		try {
			__hideBanner();
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_USER_CLOSE));
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
	
	///Android Callbacks
	#if android
	public function onAdmobBannerClosed() 
	{
		trace("USER CLOSED BANNER");
		Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_USER_CLOSE));
	}
			
	public function onAdmobBannerOpened() 
	{
		trace("USER OPENED BANNER");
		Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_USER_OPEN));
	}
	
	public function onAdmobBannerLoaded() 
	{		
		trace("BANNER SHOWED UP");
		Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_LOADED));
	}		
	
	public function onAdmobBannerBannerFailed() 
	{
		trace("BANNER FAILED TO LOAD");
		Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_FAILED));
	}
	
	public function onAdmobInterstitialClosed() 
	{
		trace("USER CLOSED INTERSTITIAL");
		Engine.events.addAdEvent(new StencylEvent(StencylEvent.FULL_AD_USER_CLOSE));
	}
			
	public function onAdmobInterstitialOpened() 
	{
		trace("USER OPENED INTERSTITIAL");
		Engine.events.addAdEvent(new StencylEvent(StencylEvent.FULL_AD_USER_OPEN));
	}
	
	public function onAdmobInterstitialLoaded() 
	{		
		trace("INTERSTITIAL SHOWED UP");
		Engine.events.addAdEvent(new StencylEvent(StencylEvent.FULL_AD_LOADED));
	}		
	
	public function onAdmobInterstitialFailed() 
	{
		trace("INTERSTITIAL FAILED TO LOAD");
		Engine.events.addAdEvent(new StencylEvent(StencylEvent.FULL_AD_FAILED));
	}
	#end
}
