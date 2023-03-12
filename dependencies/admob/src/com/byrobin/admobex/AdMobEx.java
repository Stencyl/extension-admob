/*
 *
 * Created by Robin Schaafsma
 * www.byrobingames.com
 *
 */

package com.byrobin.admobex;

import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;

import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import android.annotation.SuppressLint;
import android.provider.Settings.Secure;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Display;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;
import androidx.annotation.UiThread;

import com.google.android.gms.ads.*;
import com.google.android.gms.ads.interstitial.*;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.gms.ads.rewardedinterstitial.RewardedInterstitialAd;
import com.google.android.gms.ads.rewardedinterstitial.RewardedInterstitialAdLoadCallback;
import com.google.android.ump.*;

public class AdMobEx extends Extension
{
	private static final String TAG = "AdMobEx";

	@SuppressLint("StaticFieldLeak")
	private static AdMobEx instance;
	private final String admobId;

	private final ForeignReferenceManager refs;

	//consent form
	private ConsentForm consentForm;

	//testing
	private boolean testingAds = false;
	private boolean loggingEnabled = false;
	private String deviceId;

	// Logging

	private void debugLog(String msg)
	{
		if(loggingEnabled)
		{
			Log.d(TAG, msg);
		}
	}

	// Initialization

	public AdMobEx() // as an Extension, this is automatically instantiated once by GameActivity.
	{
		Log.d(TAG,"new AdMobEx()");
		if(instance != null) throw new RuntimeException();
		instance = this;
		refs = new ForeignReferenceManager();
		admobId = mainActivity.getResources().getString(R.string.admob_app_id);
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void initConfig(boolean testingAds, boolean loggingEnabled)
	{
		instance.loggingEnabled = loggingEnabled;
		debugLog(String.format("initConfig(%b, %b)", testingAds, loggingEnabled));

		this.testingAds = testingAds;
		if(testingAds)
		{
			@SuppressLint("HardwareIds") /* this is only for testing so don't worry about the warning */
			String android_id = Secure.getString(mainActivity.getContentResolver(), Secure.ANDROID_ID);

			deviceId = AdMobEx.md5(android_id).toUpperCase();
		}
	}

	private static String md5(String s)
	{
		MessageDigest digest;
		try
		{
			digest = MessageDigest.getInstance("MD5");
			digest.update(s.getBytes(),0,s.length());
			return new java.math.BigInteger(1, digest.digest()).toString(16);
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		return "";
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void resetConsent()
	{
		debugLog("resetConsent()");
		UserMessagingPlatform.getConsentInformation(mainContext).reset();
	}

	// Consent and Sdk Initialization

	@SuppressWarnings("unused") /* Called from Haxe */
	public void setupConsentForm(boolean testingConsent, String _debugGeography, String _underAgeOfConsent, HaxeObject callbacks)
	{
		debugLog("setupConsentForm()");

		int debugGeography = getDebugGeography(_debugGeography);
		int underAgeOfConsent = getTagForUnderAgeOfConsent(_underAgeOfConsent);

		mainActivity.runOnUiThread(() -> {
			debugLog("setupConsentForm.UI()");

			ConsentRequestParameters.Builder paramsBuilder = new ConsentRequestParameters.Builder();
			if (testingConsent)
			{
				ConsentDebugSettings debugSettings = new ConsentDebugSettings.Builder(mainContext)
					.setDebugGeography(debugGeography)
					.addTestDeviceHashedId(deviceId)
					.build();
				paramsBuilder.setConsentDebugSettings(debugSettings);
			}
			if (underAgeOfConsent != RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_UNSPECIFIED)
			{
				boolean value = (underAgeOfConsent == RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE);
				paramsBuilder.setTagForUnderAgeOfConsent(value);
			}
			ConsentRequestParameters params = paramsBuilder
				.setAdMobAppId(admobId)
				.build();

			UserMessagingPlatform.getConsentInformation(mainContext).requestConsentInfoUpdate(
				mainActivity,
				params,
				() -> {
					boolean formAvailable = UserMessagingPlatform.getConsentInformation(mainContext).isConsentFormAvailable();
					callbacks.call("onConsentInfoUpdateSuccess", new Object[] {formAvailable});
				},
				formError ->
					callbacks.call("onConsentInfoUpdateFailure", new Object[] {printFormError(formError)})
				);
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void loadConsentForm(HaxeObject callbacks)
	{
		debugLog("loadConsentForm()");
		mainActivity.runOnUiThread(() -> {
			debugLog("loadConsentForm.UI()");

			consentForm = null;
			UserMessagingPlatform.loadConsentForm(
				mainContext, consentForm -> {
					AdMobEx.this.consentForm = consentForm;
					callbacks.call("onConsentFormLoadSuccess", new Object[] {});
				},
				formError ->
					callbacks.call("onConsentFormLoadFailure", new Object[] {printFormError(formError)})
				);
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void showConsentForm(HaxeObject callbacks)
	{
		debugLog("showConsentForm()");
		mainActivity.runOnUiThread(() -> {
			debugLog("showConsentForm.UI()");
			consentForm.show(
				mainActivity,
				formError ->
					callbacks.call("onConsentFormDismissed", new Object[] {formError == null ? "" : printFormError(formError)})
				);
		});
	}

	private static String printFormError(FormError formError)
	{
		return "Form Error ("+formError.getErrorCode() + "): " + formError.getMessage();
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void initSdk(HaxeObject callbacks)
	{
		debugLog("initSdk()");
		mainActivity.runOnUiThread(() -> {
			debugLog("initSdk.UI()");

			MobileAds.initialize(mainActivity.getApplicationContext(), initializationStatus ->
				callbacks.call("onInitializationComplete", new Object[] {})
			);
		});
	}

	// Ads

	@SuppressWarnings("unused") /* Called from Haxe */
	public void updateRequestConfig(String _childDirected, String _underAgeOfConsent, String _maxAdContentRating)
	{
		debugLog("updateRequestConfig()");
		List<String> testDeviceIds = new ArrayList<>();

		testDeviceIds.add(AdRequest.DEVICE_ID_EMULATOR);
		if (testingAds)
		{
			testDeviceIds.add(deviceId);
		}

		RequestConfiguration requestConfiguration = MobileAds.getRequestConfiguration()
			.toBuilder()
			.setTestDeviceIds(testDeviceIds)
			.setTagForChildDirectedTreatment(getTagForChildDirectedTreatment(_childDirected))
			.setTagForUnderAgeOfConsent(getTagForUnderAgeOfConsent(_underAgeOfConsent))
			.setMaxAdContentRating(getMaxAdContentRating(_maxAdContentRating))
			.build();
		MobileAds.setRequestConfiguration(requestConfiguration);
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public int initBanner(String bannerId, boolean visible, String gravity, HaxeObject callbacks)
	{
		debugLog(String.format("initBanner(%s)", bannerId));
		final AdView banner = new AdView(mainActivity);
		mainActivity.runOnUiThread(() -> {
			debugLog(String.format("initBanner.UI(%s)", bannerId));

			banner.setAdUnitId(bannerId);
			AdSize bannerAdSize = getFullWidthAdaptiveSize();
			banner.setAdSize(bannerAdSize);
			banner.setAdListener(new AdListener()
			{
				@Override
				public void onAdImpression()
				{
					callbacks.call("onAdImpression", new Object[] {});
				}

				@Override
				public void onAdClicked()
				{
					callbacks.call("onAdClicked", new Object[] {});
				}

				@Override
				public void onAdClosed()
				{
					callbacks.call("onAdClosed", new Object[] {});
				}

				@Override
				public void onAdFailedToLoad(@NonNull LoadAdError loadAdError)
				{
					callbacks.call("onAdFailedToLoad", new Object[] {loadAdError.toString()});
				}

				@Override
				public void onAdLoaded()
				{
					callbacks.call("onAdLoaded", new Object[] {});
				}

				@Override
				public void onAdOpened()
				{
					callbacks.call("onAdOpened", new Object[] {});
				}
			});

			LinearLayout layout = new LinearLayout(mainActivity);
			layout.setGravity(getGravity(gravity));
			mainActivity.addContentView(layout, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
			layout.addView(banner);
			layout.bringToFront();
			
			layout.setAlpha(0.0f);
			if(visible)
			{
				fadeInBanner(banner);
			}
			else
			{
				layout.setVisibility(View.GONE);
			}

			callbacks.call("onAdHeightUpdated", new Object[] {bannerAdSize.getHeightInPixels(mainContext)});
		});
		return refs.addReference(banner);
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void loadBanner(int bannerRef)
	{
		debugLog("loadBanner()");
		AdView banner = refs.getReference(bannerRef);
		mainActivity.runOnUiThread(() -> {
			debugLog("loadBanner.UI()");
			banner.loadAd(buildAdReq());
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void showBanner(int bannerRef)
	{
		debugLog("showBanner()");
		AdView banner = refs.getReference(bannerRef);
		mainActivity.runOnUiThread(() -> {
			debugLog("showBanner.UI()");
			fadeInBanner(banner);
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void hideBanner(int bannerRef)
	{
		debugLog("hideBanner()");
		AdView banner = refs.getReference(bannerRef);
		mainActivity.runOnUiThread(() -> {
			debugLog("hideBanner.UI()");
			fadeOutBanner(banner);
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void setBannerPosition(int bannerRef, final String gravityMode)
	{
		debugLog(String.format("setBannerPosition(%s)", gravityMode));

		AdView banner = refs.getReference(bannerRef);
		mainActivity.runOnUiThread(() -> {
			debugLog("setBannerPosition.UI()");
			((LinearLayout) banner.getParent()).setGravity(getGravity(gravityMode));
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void disposeBanner(int bannerRef)
	{
		debugLog("disposeBanner()");
		AdView banner = refs.getReference(bannerRef);

		mainActivity.runOnUiThread(() -> {
			debugLog("disposeBanner.UI()");
			ViewGroup grandparent = (ViewGroup) banner.getParent().getParent();
			ViewGroup parent = (ViewGroup) banner.getParent();
			grandparent.removeView(parent);
			parent.removeView(banner);
			banner.destroy();
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void loadInterstitial(String interstitialId, HaxeObject callbacks)
	{
		debugLog(String.format("loadInterstitial(%s)", interstitialId));
		mainActivity.runOnUiThread(() -> {
			debugLog("loadInterstitial.UI()");

			InterstitialAd.load(mainContext, interstitialId, buildAdReq(), new InterstitialAdLoadCallback()
			{
				@Override
				public void onAdLoaded(@NonNull InterstitialAd interstitialAd)
				{
					callbacks.call("onAdLoaded", new Object[]{refs.addReference(interstitialAd)});
				}

				@Override
				public void onAdFailedToLoad(@NonNull LoadAdError loadAdError)
				{
					callbacks.call("onAdFailedToLoad", new Object[]{loadAdError.toString()});
				}
			});
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void showInterstitial(int interstitialRef)
	{
		debugLog("showInterstitial()");
		InterstitialAd interstitial = refs.getReference(interstitialRef);
		mainActivity.runOnUiThread(() -> {
			debugLog("showInterstitial.UI()");
			interstitial.show(mainActivity);
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void loadRewarded(String rewardedId, HaxeObject callbacks)
	{
		debugLog(String.format("loadRewarded(%s)", rewardedId));
		mainActivity.runOnUiThread(() -> {
			debugLog("loadRewarded.UI()");
			RewardedAd.load(mainContext, rewardedId, buildAdReq(), new RewardedAdLoadCallback()
			{
				@Override
				public void onAdLoaded(@NonNull RewardedAd rewardedAd)
				{
					callbacks.call("onAdLoaded", new Object[] {refs.addReference(rewardedAd)});
				}

				@Override
				public void onAdFailedToLoad(@NonNull LoadAdError loadAdError)
				{
					callbacks.call("onAdFailedToLoad", new Object[] {loadAdError.toString()});
				}
			});
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void showRewarded(int rewardedRef, HaxeObject callbacks)
	{
		debugLog("showRewarded()");
		RewardedAd rewarded = refs.getReference(rewardedRef);
		mainActivity.runOnUiThread(() -> {
			debugLog("showRewarded.UI()");
			rewarded.show(mainActivity, rewardItem -> {
				debugLog(String.format(Locale.ENGLISH, "rewardReceived(%s, %d)", rewardItem.getType(), rewardItem.getAmount()));
				callbacks.call("onUserEarnedReward", new Object[]{rewardItem.getType(), rewardItem.getAmount()});
			});
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void loadRewardedInterstitial(String rewardedInterstitialId, HaxeObject callbacks)
	{
		debugLog(String.format("loadRewardedInterstitial(%s)", rewardedInterstitialId));
		mainActivity.runOnUiThread(() -> {
			debugLog("loadRewardedInterstitial.UI()");
			RewardedInterstitialAd.load(mainContext, rewardedInterstitialId, buildAdReq(), new RewardedInterstitialAdLoadCallback()
			{
				@Override
				public void onAdLoaded(@NonNull RewardedInterstitialAd rewardedInterstitialAd)
				{
					callbacks.call("onAdLoaded", new Object[] {refs.addReference(rewardedInterstitialAd)});
				}

				@Override
				public void onAdFailedToLoad(@NonNull LoadAdError loadAdError)
				{
					callbacks.call("onAdFailedToLoad", new Object[] {loadAdError.toString()});
				}
			});
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void showRewardedInterstitial(int rewardedInterstitialRef, HaxeObject callbacks)
	{
		debugLog("showRewardedInterstitial()");
		RewardedInterstitialAd rewardedInterstitial = refs.getReference(rewardedInterstitialRef);
		mainActivity.runOnUiThread(() -> {
			debugLog("showRewardedInterstitial.UI()");
			rewardedInterstitial.show(mainActivity, rewardItem -> {
				debugLog(String.format(Locale.ENGLISH, "rewardReceived(%s, %d)", rewardItem.getType(), rewardItem.getAmount()));
				callbacks.call("onUserEarnedReward", new Object[]{rewardItem.getType(), rewardItem.getAmount()});
			});
		});
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void setFullScreenContentCallback(int adRef, HaxeObject callbacks)
	{
		debugLog("setFullScreenContentCallback()");
		Object ad = refs.getReference(adRef);

		FullScreenContentCallback wrapper = new FullScreenContentCallback()
		{
			@Override
			public void onAdClicked()
			{
				callbacks.call("onAdClicked", new Object[] {});
			}

			@Override
			public void onAdDismissedFullScreenContent()
			{
				callbacks.call("onAdDismissedFullScreenContent", new Object[] {});
			}

			@Override
			public void onAdFailedToShowFullScreenContent(@NonNull AdError adError)
			{
				callbacks.call("onAdFailedToShowFullScreenContent", new Object[] {adError.toString()});
			}

			@Override
			public void onAdImpression()
			{
				callbacks.call("onAdImpression", new Object[] {});
			}

			@Override
			public void onAdShowedFullScreenContent()
			{
				callbacks.call("onAdShowedFullScreenContent", new Object[] {});
			}
		};

		if(ad instanceof InterstitialAd)
		{
			((InterstitialAd) ad).setFullScreenContentCallback(wrapper);
		}
		else if(ad instanceof RewardedAd)
		{
			((RewardedAd) ad).setFullScreenContentCallback(wrapper);
		}
	}

	@SuppressWarnings("unused") /* Called from Haxe */
	public void clearReference(int refId)
	{
		refs.clearReference(refId);
	}

	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////

	private static int getDebugGeography(String id)
	{
		switch(id)
		{
			case "eea": return ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_EEA;
			case "not_eea": return ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_NOT_EEA;
			case "disabled": return ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_DISABLED;
			default: return -1;
		}
	}

	private static int getTagForChildDirectedTreatment(String id)
	{
		switch(id)
		{
			case "true": return RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE;
			case "false": return RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_FALSE;
			default: return RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_UNSPECIFIED;
		}
	}

	private static int getTagForUnderAgeOfConsent(String id)
	{
		switch(id)
		{
			case "true": return RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE;
			case "false": return RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_FALSE;
			default: return RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_UNSPECIFIED;
		}
	}

	private static String getMaxAdContentRating(String maxAdContentRating)
	{
		switch(maxAdContentRating)
		{
			case RequestConfiguration.MAX_AD_CONTENT_RATING_G:
			case RequestConfiguration.MAX_AD_CONTENT_RATING_PG:
			case RequestConfiguration.MAX_AD_CONTENT_RATING_T:
			case RequestConfiguration.MAX_AD_CONTENT_RATING_MA:
				return maxAdContentRating;
			default:
				return RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED;
		}
	}

	private static int getGravity(String gravity)
	{
		return gravity.equals("TOP") ?
			Gravity.TOP | Gravity.CENTER_HORIZONTAL :
			Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
	}

	private AdRequest buildAdReq()
	{
		debugLog("buildAdReq()");
		AdRequest.Builder builder = new AdRequest.Builder();
		return builder.build();
	}

	private static AdSize getFullWidthAdaptiveSize()
	{
		Display display = mainActivity.getWindowManager().getDefaultDisplay();
		DisplayMetrics outMetrics = new DisplayMetrics();
		display.getMetrics(outMetrics);

		float widthPixels = outMetrics.widthPixels;
		float density = outMetrics.density;

		int adWidth = (int) (widthPixels / density);
		return AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(mainContext, adWidth);
	}

	@UiThread
	private void fadeInBanner(AdView banner)
	{
		debugLog("fadeInBanner()");
		LinearLayout layout = (LinearLayout) banner.getParent();

		if(layout.getAnimation() != null && !layout.getAnimation().hasEnded())
		{
			layout.getAnimation().cancel();
			layout.clearAnimation();
		}

		layout.setVisibility(View.VISIBLE);
		int duration = (int) ((1.0f - layout.getAlpha()) * 1000);
		layout.animate()
			.alpha(1.0f)
			.setDuration(duration)
			.start();
	}

	@UiThread
	private void fadeOutBanner(AdView banner)
	{
		debugLog("fadeOutBanner()");
		LinearLayout layout = (LinearLayout) banner.getParent();

		if(layout.getAnimation() != null && !layout.getAnimation().hasEnded())
		{
			layout.getAnimation().cancel();
			layout.clearAnimation();
		}

		int duration = (int) (layout.getAlpha() * 1000);
		layout.animate()
			.alpha(0.0f)
			.setDuration(duration)
			.withEndAction(() -> layout.setVisibility(View.GONE))
			.start();
	}

	/**
	 * Very simple scheme to share object references with
	 * Haxe without worrying about JVM and HXCPP GC interactions
	 */
	class ForeignReferenceManager
	{
		private Object[] referenceArray = new Object[5];

		@SuppressWarnings("unchecked")
		private <T> T getReference(int id)
		{
			return (T) referenceArray[id];
		}

		private int addReference(Object o)
		{
			int i = 0;
			while(i < referenceArray.length && referenceArray[i] != null) { ++i; }
			if(i == referenceArray.length)
			{
				debugLog("Growing reference count: " + referenceArray.length + 5);
				Object[] newReferences = new Object[referenceArray.length + 5];
				System.arraycopy(referenceArray, 0, newReferences, 0, referenceArray.length);
				referenceArray = newReferences;
			}
			referenceArray[i] = o;
			return i;
		}

		private void clearReference(int id)
		{
			referenceArray[id] = null;
		}
	}
}
