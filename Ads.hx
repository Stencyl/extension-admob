package;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#else
import nme.Lib;
#end

import com.stencyl.Engine;
import com.stencyl.event.EventMaster;
import com.stencyl.event.StencylEvent;

import nme.utils.ByteArray;
import nme.display.BitmapData;
import nme.geom.Rectangle;

class Ads 
{	
	private static var initialized:Bool = false;
	
	private static function notifyListeners(inEvent:Dynamic)
	{
		#if cpp
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

	public static function initialize():Void 
	{
		#if cpp
		if(!initialized)
		{
			set_event_handle(notifyListeners);
			initialized = true;
		}
		#end	
	}

	public static function showAd(position:Int = 0):Void
	{
		#if cpp
		ads_showad(position);
		#end
	}	
	
	public static function hideAd():Void
	{
		#if cpp
		ads_hidead();
		#end
	}
	
	#if cpp
	private static var set_event_handle = nme.Loader.load("ads_set_event_handle", 1);
	private static var ads_showad = nme.Loader.load("ads_showad", 1);
	private static var ads_hidead = nme.Loader.load("ads_hidead", 0);
	#end
}