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
import java.util.Map;

import android.os.Bundle;
import android.os.Handler;
import android.provider.Settings.Secure;
import android.util.Log;
import android.view.Gravity;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.animation.Animation;
import android.view.animation.AlphaAnimation;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;

import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.*;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;
import com.google.android.gms.ads.interstitial.*;
import com.google.android.ump.*;

public class AdMobEx extends Extension {

	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////

	private static InterstitialAd interstitial;
	private static AdView banner = null;
    private static LinearLayout layout;
	private static HaxeObject callback;

	private static final String TAG = "AdMobEx";

	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
    
	private static String admobId=null;
    
	private static String interstitialId=null;

	private static boolean failBanner=false;
	private static boolean loadingBanner=false;
	private static boolean mustBeShowingBanner=false;
	private static String bannerId=null;

	private static AdMobEx instance=null;
	private static Boolean testingAds=false;
	private static int gravity=Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
	
	private static String deviceId;
	private static boolean consentChecked = false;
	private static ConsentForm consentForm;
	private static boolean showWhenLoaded = false;

	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////

	private static int debugGeography = -1;
	private static int childDirected = RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_UNSPECIFIED;
	private static int underAgeOfConsent = RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_UNSPECIFIED;
	private static String maxAdContentRating = RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED;

	public static void setDebugGeography(String id)
	{
		switch(id)
		{
			case "eea": debugGeography = ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_EEA; break;
			case "not_eea": debugGeography = ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_NOT_EEA; break;
			case "disabled": debugGeography = ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_DISABLED; break;
			default: debugGeography = -1;
		}
	}

	public static void setTagForChildDirectedTreatment(String id)
	{
		switch(id)
		{
			case "true": childDirected = RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE; break;
			case "false": childDirected = RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_FALSE; break;
			default: childDirected = RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_UNSPECIFIED;
		}
	}

	public static void setTagForUnderAgeOfConsent(String id)
	{
		switch(id)
		{
			case "true": underAgeOfConsent = RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE; break;
			case "false": underAgeOfConsent = RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_FALSE; break;
			default: underAgeOfConsent = RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_UNSPECIFIED;
		}
	}

	public static void setMaxAdContentRating(String maxAdContentRating)
	{
		switch(maxAdContentRating)
		{
			case RequestConfiguration.MAX_AD_CONTENT_RATING_G:
			case RequestConfiguration.MAX_AD_CONTENT_RATING_PG:
			case RequestConfiguration.MAX_AD_CONTENT_RATING_T:
			case RequestConfiguration.MAX_AD_CONTENT_RATING_MA:
				AdMobEx.maxAdContentRating = maxAdContentRating;
				break;
			default:
				AdMobEx.maxAdContentRating = RequestConfiguration.MAX_AD_CONTENT_RATING_UNSPECIFIED;
		}
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////

	static public AdMobEx getInstance(){
		if(instance==null && bannerId!=null) instance = new AdMobEx();
		if(bannerId==null){
			Log.e(TAG,"You tried to get Instance without calling INIT first on AdMobEx class!");
		}
		return instance;
	}

	static public void init(HaxeObject cb, String admobId, String bannerId, String interstitialId, String gravityMode, boolean testingAds){
        
        callback = cb;
        AdMobEx.admobId=mainActivity.getResources().getString(R.string.admob_app_id);
		AdMobEx.bannerId=bannerId;
		AdMobEx.interstitialId=interstitialId;
		AdMobEx.testingAds=testingAds;
		setBannerPosition(gravityMode);
		
		mainActivity.runOnUiThread(new Runnable() {
            public void run() 
			{ 
				Log.d(TAG,"Init Admob");
				getInstance(); 
			
				initAdmob();
			}
		});	
	}

    static public void loadInterstitial() {
        Log.d(TAG,"Load Interstitial Begin");
        if(interstitialId.isEmpty()) return;
        mainActivity.runOnUiThread(new Runnable() {
            public void run() { reloadInterstitial();}
        });

        Log.d(TAG,"Load Interstitial End");
    }

	static public void showInterstitial() {
		Log.d(TAG,"Show Interstitial Begin");
		if(interstitialId.isEmpty()) return;
		mainActivity.runOnUiThread(new Runnable() {
			public void run() {	if(interstitial != null) interstitial.show(mainActivity);	}
		});
		Log.d(TAG,"Show Interstitial End");
	}

	static public void showBanner() {
		if(bannerId.isEmpty()) return;
		mustBeShowingBanner=true;
		if(failBanner){
			mainActivity.runOnUiThread(new Runnable() {
				public void run() {reloadBanner();}
			});
			return;
		}
		Log.d(TAG,"Show Banner");
		
		mainActivity.runOnUiThread(new Runnable() {
			public void run() {

				banner.setVisibility(AdView.VISIBLE);
                
                Animation animation1 = new AlphaAnimation(0.0f, 1.0f);
                animation1.setDuration(1000);
                layout.startAnimation(animation1);
			}
		});
	}

	static public void hideBanner() {
		if(bannerId.isEmpty()) return;
		mustBeShowingBanner=false;
		if(failBanner){
			mainActivity.runOnUiThread(new Runnable() {
				public void run() {reloadBanner();}
			});
			return;
		}
		Log.d(TAG,"Hide Banner");

		mainActivity.runOnUiThread(new Runnable() {
			public void run() {
                
                Animation animation1 = new AlphaAnimation(1.0f, 0.0f);
                animation1.setDuration(1000);
                layout.startAnimation(animation1);
                
                final Handler handler = new Handler();
                handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        banner.setVisibility(AdView.GONE);
                    }
                }, 1000);
            
            }
		});
	}

	static public void onResize(){
		Log.d(TAG,"On Resize");
		mainActivity.runOnUiThread(new Runnable() {
			public void run() {
                if(!bannerId.isEmpty()){
                    reinitBanner();
                }
            }
		});
	}
	
	static public void setBannerPosition(final String gravityMode)
    {
        mainActivity.runOnUiThread(new Runnable()
                                   {
        	public void run()
			{
			
				if(gravityMode.equals("TOP"))
				{
					if(banner==null)
					{
						AdMobEx.gravity=Gravity.TOP | Gravity.CENTER_HORIZONTAL;
					}else
					{
						AdMobEx.gravity=Gravity.TOP | Gravity.CENTER_HORIZONTAL;
						layout.setGravity(gravity);
					}
				}else
				{
					if(banner==null)
					{
						AdMobEx.gravity=Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
					}else
					{
						AdMobEx.gravity=Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
						layout.setGravity(gravity);
					}
				}
            }
        });
    }

	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
	
	
    static public void initAdmob(){
        mainActivity.runOnUiThread(new Runnable()
        {
            public void run()
            {
                MobileAds.initialize(mainActivity.getApplicationContext(), new OnInitializationCompleteListener()
				{
					@Override
					public void onInitializationComplete(@NonNull InitializationStatus initializationStatus)
					{
						Log.d(TAG,"Admob AppID: "+admobId);

						if(testingAds){
							String android_id = Secure.getString(mainActivity.getContentResolver(), Secure.ANDROID_ID);
							deviceId = getInstance().md5(android_id).toUpperCase();
							Log.d(TAG,"DEVICE ID: "+deviceId);
						}
						updateRequestConfig();
						getConsentInfo();
						
						if(!bannerId.isEmpty()){
							reinitBanner();
						}

						if(!interstitialId.isEmpty()){
							reloadInterstitial();
						}
					}
				});
            }
        });
    }

	private static InterstitialAdLoadCallback interstitialAdLoadCallback = new InterstitialAdLoadCallback()
	{
		@Override
		public void onAdLoaded(@NonNull InterstitialAd interstitialAd)
		{
			super.onAdLoaded(interstitialAd);
			interstitial = interstitialAd;
			interstitial.setFullScreenContentCallback(interstitialContentCallback);
			callback.call("onAdmobAdEvent", new Object[] {"interstitial", "load"});
			Log.d(TAG,"Received Interstitial!");
		}

		@Override
		public void onAdFailedToLoad(@NonNull LoadAdError loadAdError)
		{
			super.onAdFailedToLoad(loadAdError);
			interstitial = null;
			callback.call("onAdmobAdEvent", new Object[] {"interstitial", "fail"});
			//reloadInterstitial();
			Log.e(TAG,"Fail to get Interstitial: "+loadAdError);
		}
	};

	private static FullScreenContentCallback interstitialContentCallback = new FullScreenContentCallback()
	{
		@Override
		public void onAdShowedFullScreenContent()
		{
			super.onAdShowedFullScreenContent();
			callback.call("onAdmobAdEvent", new Object[] {"interstitial", "open"});
		}

		@Override
		public void onAdDismissedFullScreenContent()
		{
			super.onAdDismissedFullScreenContent();
			//reloadInterstitial();
			callback.call("onAdmobAdEvent", new Object[] {"interstitial", "close"});
			Log.d(TAG,"Dismiss Interstitial");
		}

		@Override
		public void onAdClicked()
		{
			super.onAdClicked();
			callback.call("onAdmobAdEvent", new Object[] {"interstitial", "click"});
		}

		@Override
		public void onAdFailedToShowFullScreenContent(@NonNull AdError adError)
		{
			super.onAdFailedToShowFullScreenContent(adError);
		}

		@Override
		public void onAdImpression()
		{
			super.onAdImpression();
		}
	};

	private static void updateRequestConfig()
	{
		List<String> testDeviceIds = new ArrayList<>();

		testDeviceIds.add(AdRequest.DEVICE_ID_EMULATOR);
		if (testingAds)
		{
			testDeviceIds.add(deviceId);
		}

		RequestConfiguration requestConfiguration = MobileAds.getRequestConfiguration()
			.toBuilder()
			.setTestDeviceIds(testDeviceIds)
			.setTagForChildDirectedTreatment(childDirected)
			.setTagForUnderAgeOfConsent(underAgeOfConsent)
			.setMaxAdContentRating(maxAdContentRating)
			.build();
		MobileAds.setRequestConfiguration(requestConfiguration);
	}
    
	public static AdRequest buildAdReq()
	{
		AdRequest.Builder builder = new AdRequest.Builder();
		return builder.build();
	}
	
    static public void reinitBanner(){
        if(loadingBanner) return;
        if(banner==null){ // if this is the first time we call this function
            layout = new LinearLayout(mainActivity);
            layout.setGravity(gravity);
        } else {
            ViewGroup parent = (ViewGroup) layout.getParent();
            parent.removeView(layout);
            layout.removeView(banner);
            banner.destroy();
        }
        
        banner = new AdView(mainActivity);
        banner.setAdUnitId(bannerId);
        banner.setAdSize(AdSize.SMART_BANNER);
        banner.setAdListener(new AdListener() {
            public void onAdLoaded() {
                loadingBanner=false;
                callback.call("onAdmobAdEvent", new Object[] {"banner", "load"});
                Log.d(TAG,"Received Banner OK!");
                if(mustBeShowingBanner){
                    showBanner();
                }else{
                    hideBanner();
                }
            }
            public void onAdFailedToLoad(int errorcode) {
                loadingBanner=false;
                failBanner=true;
                callback.call("onAdmobAdEvent", new Object[] {"banner", "fail"});
                Log.e(TAG,"Fail to get Banner: "+errorcode);
            }
            public void onAdClosed(){
                callback.call("onAdmobAdEvent", new Object[] {"banner", "close"});
            }
            public void onAdOpened(){
                callback.call("onAdmobAdEvent", new Object[] {"banner", "open"});
            }
			public void onAdLeftApplication(){
                    callback.call("onAdmobAdEvent", new Object[] {"banner", "click"});
            }
        });
        
        mainActivity.addContentView(layout, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
        layout.addView(banner);
        layout.bringToFront();
        if(consentChecked)
        {
        	reloadBanner();
        }
        else
        {
        	failBanner = true;
        }
    }
    
    public static void reloadInterstitial(){
        if(interstitialId.isEmpty()) return;
        //if(loadingInterstitial) return;
        Log.d(TAG,"Reload Interstitial");
        if(!consentChecked)
        {
        	callback.call("onAdmobAdEvent", new Object[] {"interstitial", "fail"});
			Log.e(TAG,"Fail to get Interstitial: User consent hasn't been checked yet");
			return;
        }
		InterstitialAd.load(mainContext, interstitialId, buildAdReq(), interstitialAdLoadCallback);
    }
    
    static public void reloadBanner(){
        if(bannerId.isEmpty()) return;
        if(loadingBanner) return;
        Log.d(TAG,"Reload Banner");
        if(!consentChecked)
        {
        	callback.call("onAdmobAdEvent", new Object[] {"banner", "fail"});
            Log.e(TAG,"Fail to get Banner: User consent hasn't been checked yet");
            failBanner = true;
			return;
        }
        loadingBanner=true;
        banner.loadAd(buildAdReq());
        failBanner=false;
    }
    
    private static String md5(String s)  {
        MessageDigest digest;
        try  {
            digest = MessageDigest.getInstance("MD5");
            digest.update(s.getBytes(),0,s.length());
            return new java.math.BigInteger(1, digest.digest()).toString(16);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return "";
    }

	public static void showConsentForm(final boolean checkConsent)
	{
		int consentStatus = UserMessagingPlatform.getConsentInformation(mainContext).getConsentStatus();
		if (checkConsent && consentStatus == ConsentInformation.ConsentStatus.OBTAINED)
		{
			Log.d(TAG, "Skipping form because player already answered");
			consentChecked = true;
			return;
		}

		mainActivity.runOnUiThread(new Runnable()
		{
			public void run()
			{
				showWhenLoaded = true;

				if (consentForm != null)
				{
					showForm();
				}
				else
				{
					setupForm();
				}
			}
		});
	}

	static public void getConsentInfo()
	{
		int consentStatus = UserMessagingPlatform.getConsentInformation(mainContext).getConsentStatus();
		if (consentStatus == ConsentInformation.ConsentStatus.OBTAINED)
		{
			Log.d(TAG, "Skipping form because player already answered");
			consentChecked = true;
			return;
		}

		mainActivity.runOnUiThread(new Runnable()
		{
			public void run()
			{
				showWhenLoaded = false;
				setupForm();
			}
		});
	}

	static public void setupForm()
	{
		ConsentRequestParameters.Builder paramsBuilder = new ConsentRequestParameters.Builder();
		if (testingAds)
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

		ConsentInformation consentInformation = UserMessagingPlatform.getConsentInformation(mainContext);
		consentInformation.requestConsentInfoUpdate(
			mainActivity,
			params,
			new ConsentInformation.OnConsentInfoUpdateSuccessListener() {
				@Override
				public void onConsentInfoUpdateSuccess() {
					if (consentInformation.isConsentFormAvailable())
					{
						loadForm();
					}
					else
					{
						consentChecked = true;
						Log.d(TAG, "No consent form available");
					}
				}
			},
			new ConsentInformation.OnConsentInfoUpdateFailureListener() {
				@Override
				public void onConsentInfoUpdateFailure(FormError formError) {
					Log.e(TAG, "Consent update failed with error: " + formError.getMessage());
				}
			});
	}

	public static void loadForm() {
		AdMobEx.consentForm = null;
		UserMessagingPlatform.loadConsentForm(
			mainContext, new UserMessagingPlatform.OnConsentFormLoadSuccessListener() {
				@Override
				public void onConsentFormLoadSuccess(ConsentForm consentForm) {
					Log.d(TAG, "Consent form loaded.");
					AdMobEx.consentForm = consentForm;


					if (showWhenLoaded)
					{
						showForm();
					}
				}
			},
			new UserMessagingPlatform.OnConsentFormLoadFailureListener() {
				@Override
				public void onConsentFormLoadFailure(FormError formError) {
					Log.e(TAG, "Consent form load failed with error: " + formError.getMessage());
				}
			});
	}

	private static void showForm()
	{
		showWhenLoaded = false;
		consentForm.show(
			mainActivity,
			new ConsentForm.OnConsentFormDismissedListener() {
				@Override
				public void onConsentFormDismissed(FormError formError) {
					loadForm();
					Log.d(TAG, "Consent form closed.");
					consentChecked = true;
				}
			});
	}
}
