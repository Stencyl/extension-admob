#ifndef IPHONE
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif

#include <hx/CFFI.h>
#include "Ads.h"
#include <stdio.h>

using namespace ads;

#ifdef IPHONE

void ads_showad(value position)
{
	showAd(val_int(position));
}
DEFINE_PRIM(ads_showad, 1);

void ads_hidead()
{
	hideAd();
}
DEFINE_PRIM(ads_hidead, 0);

#endif

extern "C" void ads_main() 
{	
	// Here you could do some initialization, if needed	
}
DEFINE_ENTRY_POINT(ads_main);

extern "C" int ads_register_prims() 
{ 
    return 0; 
}