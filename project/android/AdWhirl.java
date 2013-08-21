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
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.LinearLayout;


import android.view.Gravity;
import com.google.ads.AdRequest;
import com.google.ads.AdSize;
import com.google.ads.AdView;

import dalvik.system.DexClassLoader;

public class AdWhirl extends GameActivity
{
	public static LinearLayout layout;
	public static GameActivity activity;

	static AdView adView;

	static public void initAdmob(final String code, final int position)
	{
		activity = GameActivity.getInstance();

		activity.runOnUiThread(new Runnable() 
		{
        	public void run() 
			{
				adView = new AdView(activity, AdSize.BANNER, code);

				LinearLayout layout = new LinearLayout(activity);
				layout.setGravity(Gravity.CENTER_HORIZONTAL);
				
				if(position == 0)
				{
					layout.setGravity(Gravity.CENTER_HORIZONTAL|Gravity.BOTTOM);
				}
				
				else if(position == 1)
				{
					layout.setGravity(Gravity.BOTTOM|Gravity.LEFT);
				}
				
				else if(position == 2)
				{
					layout.setGravity(Gravity.BOTTOM|Gravity.RIGHT);
				}
				
				else if(position == 3)
				{
					layout.setGravity(Gravity.CENTER_HORIZONTAL);
				}
				
				else if(position == 4)
				{
					layout.setGravity(Gravity.LEFT);
				}
				
				else
				{
					layout.setGravity(Gravity.RIGHT);
				}
				
				layout.addView(adView);
				activity.addContentView(layout, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));

    			AdRequest adRequest = new AdRequest();
				//adRequest.setTesting(true);
    			adView.loadAd(adRequest);
            }
        });
	}

	static public void showAd()
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

	static public void hideAd()
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

}