package com.stencyl.admob;

import com.stencyl.Extension;
import com.stencyl.event.Event;
import com.stencyl.models.Scene;

class AdMob extends Extension
{
	private static var instance:AdMob;

	//stencyl events
	public var adEvent:Event<(AdEventData)->Void>;
	public var rewardEvent:Event<(rewardType:String, rewardAmount:Float)->Void>;
	
	public function new()
	{
		super();
		instance = this;
	}

	public static function get()
	{
		return instance;
	}

	//Called from Design Mode
	public static function setDebugGeography(value:String) {}
	public static function setChildDirectedTreatment(value:String) {}
	public static function setUnderAgeOfConsent(value:String) {}
	public static function setMaxAdContentRating(value:String) {}
	public static function showConsentForm(checkConsent:Bool = true) {}
	public static function initSdk(position:Int) {}
	public static function showBanner() {}
	public static function hideBanner() {}
	public static function setBannerPosition(position:Int) {}
	public static function getBannerHeight() { return 0; }
	public static function loadInterstitial() {}
	public static function showInterstitial() {}
	public static function loadRewarded() {}
	public static function showRewarded() {}
	public static function loadRewardedInterstitial() {}
	public static function showRewardedInterstitial() {}

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