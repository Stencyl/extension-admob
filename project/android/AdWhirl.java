import org.haxe.nme.GameActivity;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.util.HashMap;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.AssetManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.net.Uri;
import android.os.Bundle;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.LinearLayout;


import android.view.Gravity;
import com.google.ads.*;

import dalvik.system.DexClassLoader;

public class AdWhirl extends GameActivity
{
	public static LinearLayout layout;
	public static GameActivity activity;

	static AdView adView;
    static InterstitialAd interstitial;
    
    static public void initAdmob(final String code, final int position)
    {
    	AdWhirl.initBanner(code, position, 0);
    }

	static public void initBanner(final String code, final int position, final int smartBanner)
	{
		activity = GameActivity.getInstance();

		activity.runOnUiThread(new Runnable() 
		{
        	public void run() 
			{
				LinearLayout layout = new LinearLayout(activity);
				layout.setGravity(Gravity.CENTER_HORIZONTAL);
                
                if (smartBanner == 0)
                {
                    adView = new AdView(activity, AdSize.BANNER, code);
                }
                else
                {
                    adView = new AdView(activity, AdSize.SMART_BANNER, code);
                }
				
				if(position == 0)
				{
					layout.setGravity(Gravity.CENTER_HORIZONTAL|Gravity.BOTTOM);
				}
                else
				{
					layout.setGravity(Gravity.CENTER_HORIZONTAL);
                }
				
				layout.addView(adView);
				activity.addContentView(layout, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));

    			AdRequest adRequest = new AdRequest();
    			adView.loadAd(adRequest);
            }
        });
	}

	static public void showBanner()
	{
		activity = GameActivity.getInstance();
		
        activity.runOnUiThread(new Runnable() 
        {
        	public void run() 
			{
				if(adView.getVisibility() == AdView.GONE)
				{
     				adView.setVisibility(AdView.VISIBLE);
				}
            }
        });
    }

	static public void hideBanner()
	{
		activity = GameActivity.getInstance();
		
        activity.runOnUiThread(new Runnable() 
        {
        	public void run() 
        	{
				if(adView.getVisibility() == AdView.VISIBLE)
				{
     				adView.setVisibility(AdView.GONE);
				}
            }
        });
	}
    
    static public void initInterstitial(final String code)
    {
        activity = GameActivity.getInstance();
		
        activity.runOnUiThread(new Runnable()
        {
        	public void run()
        	{
				interstitial = new InterstitialAd(activity, code);
            }
        });
    }
    
    static public void loadInterstitial()
    {
        activity = GameActivity.getInstance();
		
        activity.runOnUiThread(new Runnable()
                               {
        	public void run()
        	{
				AdRequest adRequest = new AdRequest();
                interstitial.loadAd(adRequest);
            }
        });
    }
    
    static public void showInterstitial()
    {
        activity = GameActivity.getInstance();
		
        activity.runOnUiThread(new Runnable()
                               {
        	public void run()
        	{
				interstitial.show();
            }
        });
    }
}