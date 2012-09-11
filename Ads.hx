package com.stencyl.extensions;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#else
import nme.Lib;
#end

import nme.utils.ByteArray;
import nme.display.BitmapData;
import nme.geom.Rectangle;

class Ads 
{	
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
	private static var ads_showad = nme.Loader.load("ads_showad", 1);
	private static var ads_hidead = nme.Loader.load("ads_hidead", 0);
	#end
}