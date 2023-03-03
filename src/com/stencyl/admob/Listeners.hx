package com.stencyl.admob;

interface OnConsentInfoUpdateListener
{
    public function onConsentInfoUpdateSuccess(formAvailable:Bool):Void;
    public function onConsentInfoUpdateFailure(formError:String):Void;
}

interface OnConsentFormLoadListener
{
    public function onConsentFormLoadSuccess():Void;
    public function onConsentFormLoadFailure(formError:String):Void;
}

interface OnConsentFormDismissedListener
{
    public function onConsentFormDismissed(formError:String):Void;
}

interface OnInitializationCompleteListener
{
    public function onInitializationComplete():Void;
}

interface AdListener
{
    public function onAdClicked():Void;
    public function onAdClosed():Void;
    public function onAdFailedToLoad(loadAdError:String):Void;
    public function onAdImpression():Void;
    public function onAdLoaded():Void;
    public function onAdOpened():Void;
    public function onAdHeightUpdated(heightInPixels:Int):Void;
}

interface AdLoadCallback
{
    public function onAdLoaded(adRef:Int):Void;
    public function onAdFailedToLoad(loadAdError:String):Void;
}

interface FullScreenContentCallback
{
    public function onAdClicked():Void;
    public function onAdDismissedFullScreenContent():Void;
    public function onAdFailedToShowFullScreenContent(adError:String):Void;
    public function onAdImpression():Void;
    public function onAdShowedFullScreenContent():Void;
}

interface OnUserEarnedRewardListener
{
    public function onUserEarnedReward(rewardType:String, rewardAmount:Int):Void;
}
