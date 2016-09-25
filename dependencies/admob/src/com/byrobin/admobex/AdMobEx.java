/*
 *
 * Created by Robin Schaafsma
 * www.byrobingames.com
 *
 */

package com.byrobin.admobex;

import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;

import java.util.Date;
import java.util.Queue;

import android.app.Activity;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Window;
import android.view.WindowManager;
import android.content.Context;
import android.content.Intent;
import android.media.AudioManager;
import android.media.audiofx.AudioEffect.OnControlStatusChangeListener;
import android.widget.LinearLayout;
import android.view.ViewGroup;
import android.view.Gravity;
import android.view.animation.Animation;
import android.view.animation.AlphaAnimation;
import android.view.View;
import android.view.ViewGroup.LayoutParams;
import android.util.Log;
import android.provider.Settings.Secure;

import java.security.MessageDigest;

import com.google.android.gms.ads.*;

import dalvik.system.DexClassLoader;

public class AdMobEx extends Extension {

	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////

	private static InterstitialAd interstitial;
	private static AdView banner = null;
    private static LinearLayout layout;
	private static AdRequest adReq;
    private static HaxeObject callback;

	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
    
	private static String admobId=null;
    
    private static boolean failInterstitial=false;
	private static boolean loadingInterstitial=false;
	private static String interstitialId=null;

	private static boolean failBanner=false;
	private static boolean loadingBanner=false;
	private static boolean mustBeShowingBanner=false;
	private static String bannerId=null;

	private static AdMobEx instance=null;
	private static Boolean testingAds=false;
	private static int gravity=Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;

	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////

	static public AdMobEx getInstance(){
		if(instance==null && bannerId!=null) instance = new AdMobEx();
		if(bannerId==null){
			Log.e("AdMobEx","You tried to get Instance without calling INIT first on AdMobEx class!");
		}
		return instance;
	}


	static public void init(HaxeObject cb, String admobId, String bannerId, String interstitialId, String gravityMode, boolean testingAds){
        
        callback = cb;
        AdMobEx.admobId=admobId;
		AdMobEx.bannerId=bannerId;
		AdMobEx.interstitialId=interstitialId;
		AdMobEx.testingAds=testingAds;
		setBannerPosition(gravityMode);
		
		mainActivity.runOnUiThread(new Runnable() {
            public void run() 
			{ 
			
				Log.d("AdMobEx","Init Admob");
				getInstance(); 
			
				initAdmob();
			}
		});	
	}

    static public void loadInterstitial() {
        Log.d("AdMobEx","Load Interstitial Begin");
        if(interstitialId=="") return;
        mainActivity.runOnUiThread(new Runnable() {
            public void run() { reloadInterstitial();}
        });

        Log.d("AdMobEx","Load Interstitial End");
    }

	static public void showInterstitial() {
		Log.d("AdMobEx","Show Interstitial Begin");
		if(interstitialId=="") return;
		mainActivity.runOnUiThread(new Runnable() {
			public void run() {	if(interstitial.isLoaded()) interstitial.show();	}
		});
		Log.d("AdMobEx","Show Interstitial End");
	}


	static public void showBanner() {
		if(bannerId=="") return;
		mustBeShowingBanner=true;
		if(failBanner){
			mainActivity.runOnUiThread(new Runnable() {
				public void run() {reloadBanner();}
			});
			return;
		}
		Log.d("AdMobEx","Show Banner");
		
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
		if(bannerId=="") return;
		mustBeShowingBanner=false;
		if(failBanner){
			mainActivity.runOnUiThread(new Runnable() {
				public void run() {reloadBanner();}
			});
			return;
		}
		Log.d("AdMobEx","Hide Banner");

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
		Log.d("AdMobEx","On Resize");
		mainActivity.runOnUiThread(new Runnable() {
			public void run() {
                reinitBanner();
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
                MobileAds.initialize(mainActivity.getApplicationContext(), admobId);
                Log.d("AdMobEx","Admob AppID: "+admobId);
        
                AdRequest.Builder builder = new AdRequest.Builder();
        
                if(testingAds){
                    String android_id = Secure.getString(mainActivity.getContentResolver(), Secure.ANDROID_ID);
                    String deviceId = getInstance().md5(android_id).toUpperCase();
                    Log.d("AdMobEx","DEVICE ID: "+deviceId);
                    builder.addTestDevice(deviceId);
                }
        
                builder.addTestDevice(AdRequest.DEVICE_ID_EMULATOR);
                adReq = builder.build();
        
                if(bannerId!=""){
                    reinitBanner();
                }
        
                if(interstitialId!=""){
                 interstitial = new InterstitialAd(mainActivity);
                 interstitial.setAdUnitId(interstitialId);
                 interstitial.setAdListener(new AdListener() {
                    public void onAdLoaded() {
                        loadingInterstitial=false;
                        callback.call("onAdmobInterstitialLoaded", new Object[] {});
                        Log.d("AdMobEx","Received Interstitial!");
                    }
                    public void onAdFailedToLoad(int errorcode) {
                        loadingInterstitial=false;
                        failInterstitial=true;
                        callback.call("onAdmobInterstitialFailed", new Object[] {});
						//reloadInterstitial();
                        Log.d("AdMobEx","Fail to get Interstitial: "+errorcode);
                    }
                    public void onAdClosed() {
                        //reloadInterstitial();
                        callback.call("onAdmobInterstitialClosed", new Object[] {});
                        Log.d("AdMobEx","Dismiss Interstitial");
                    }
                    public void onAdOpened(){
                        callback.call("onAdmobInterstitialOpened", new Object[] {});
                    }
                    public void onAdLeftApplication(){
                        callback.call("onAdmobInterstitialClicked", new Object[] {});
                    }
                 });
                 reloadInterstitial();
                 }
                
            }
        });
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
                callback.call("onAdmobBannerLoaded", new Object[] {});
                Log.d("AdMobEx","Received Banner OK!");
                if(mustBeShowingBanner){
                    showBanner();
                }else{
                    hideBanner();
                }
            }
            public void onAdFailedToLoad(int errorcode) {
                loadingBanner=false;
                failBanner=true;
                callback.call("onAdmobBannerFailed", new Object[] {});
                Log.d("AdMobEx","Fail to get Banner: "+errorcode);
            }
            public void onAdClosed(){
                callback.call("onAdmobBannerClosed", new Object[] {});
            }
            public void onAdOpened(){
                callback.call("onAdmobBannerOpened", new Object[] {});
            }
			public void onAdLeftApplication(){
                    callback.call("onAdmobBannerClicked", new Object[] {});
            }
        });
        
        mainActivity.addContentView(layout, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
        layout.addView(banner);
        layout.bringToFront();
        reloadBanner();
    }
    
    public static void reloadInterstitial(){
        if(interstitialId=="") return;
        //if(loadingInterstitial) return;
        Log.d("AdMobEx","Reload Interstitial");
        loadingInterstitial=true;
        interstitial.loadAd(adReq);
        failInterstitial=false;
    }
    
    static public void reloadBanner(){
        if(bannerId=="") return;
        if(loadingBanner) return;
        Log.d("AdMobEx","Reload Banner");
        loadingBanner=true;
        banner.loadAd(adReq);
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
	
}
