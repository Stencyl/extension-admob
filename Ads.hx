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

class Ads 
{	
	//Universal
	private static var initialized:Bool = false;
	
	//Android-Only
    #if android
	public static var adwhirlCode:String = "none";
	private static inline var ANDROID_CLASS:String = "com/stencyl/Ads/Admob";
	private static var _init_func:Dynamic;
	private static var _show_func:Dynamic;
	private static var _hide_func:Dynamic;
    #end
	
	//Ad Events only happen on iOS. AdMob provides no out-of-the-box way.
	private static function notifyListeners(inEvent:Dynamic)
	{
		#if(mobile && !android && !air)
		var data:String = Std.string(Reflect.field(inEvent, "type"));
		
		if(data == "open")
		{
			trace("USER OPENED IT");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_USER_OPEN));
		}
		
		if(data == "close")
		{
			trace("USER CLOSED IT");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_USER_CLOSE));
		}
		
		if(data == "load")
		{
			trace("IT SHOWED UP");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_LOADED));
		}
		
		if(data == "fail")
		{
			trace("IT FAILED TO LOAD");
			Engine.events.addAdEvent(new StencylEvent(StencylEvent.AD_FAILED));
		}
		#end
	}

	public static function initialize(apiCode:String = "none", position:Int = 0):Void 
	{
		if(initialized)
		{
			return;
		}
		
		#if(mobile && !android && !air)
		set_event_handle(notifyListeners);
		initialized = true;
		#end	
		
		#if android
		if(apiCode == "none" || apiCode == "")
		{
			return;
		}
		
		adwhirlCode = apiCode;
		
		if(_init_func == null)
		{
			_init_func = JNI.createStaticMethod("com/stencyl/Ads/AdMob", "initBanner", "(Ljava/lang/String;I)V", true);
		}
	
		var args = new Array<Dynamic>();
		args.push(adwhirlCode);
		args.push(MyAssets.adPositionBottom ? 0 : 1);
		_init_func(args);
			
		initialized = true;
		#end
	}

	public static function showAd(onBottom:Bool = true):Void
	{
		#if(mobile && !android && !air)
		ads_showad(MyAssets.adPositionBottom);
		#end
		
		#if android
		if(!initialized)
		{
			Ads.initialize(MyAssets.whirlID, MyAssets.adPositionBottom ? 0 : 1);
		}
		
		if(_show_func == null)
		{
			_show_func = JNI.createStaticMethod("com/stencyl/Ads/AdMob", "showBanner", "()V", true);
		}

		var args = new Array<Dynamic>();
		_show_func(args);
		#end
	}	
	
	public static function hideAd():Void
	{
		#if(mobile && !android && !air)
		ads_hidead();
		#end
		
		#if android
		if(!initialized)
		{
			Ads.initialize(MyAssets.whirlID, MyAssets.adPositionBottom ? 0 : 1);
		}
		
		if(_hide_func == null)
		{
			_hide_func = JNI.createStaticMethod("com/stencyl/Ads/AdMob", "hideBanner", "()V", true);
		}

		var args = new Array<Dynamic>();
		_hide_func(args);
		#end
	}
	
	#if(mobile && !android && !air)
	private static var set_event_handle = Lib.load("ads", "ads_set_event_handle", 1);
	private static var ads_showad = Lib.load("ads", "ads_showad", 1);
	private static var ads_hidead = Lib.load("ads", "ads_hidead", 0);
	#end
}