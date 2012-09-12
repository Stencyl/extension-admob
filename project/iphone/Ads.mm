#include <Ads.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <iAd/iAd.h>

//---

@interface AdController : UIViewController <ADBannerViewDelegate>
{
    ADBannerView* _bannerView;
    UIView* _contentView;
    BOOL _isVisible;
}

@property (nonatomic, retain) ADBannerView* bannerView;
@property (nonatomic, retain) UIView* contentView;
@property (nonatomic) BOOL visible;

-(void)showAd;
-(void)hideAd;
-(void)fixupAdView:(UIInterfaceOrientation)toDeviceOrientation;
-(int)getBannerHeight:(UIInterfaceOrientation)orientation;

@end

@implementation AdController

@synthesize bannerView = _bannerView;
@synthesize contentView = _contentView;
@synthesize visible = _isVisible;

-(void)showAd
{
	NSLog(@"Set Ad to Visible");
	_isVisible = true;	
   	[self fixupAdView:[UIApplication sharedApplication].statusBarOrientation];
}

-(void)hideAd
{
	NSLog(@"Set Ad to Hidden");
	_isVisible = false;
	[self fixupAdView:[UIApplication sharedApplication].statusBarOrientation];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView*)banner willLeaveApplication:(BOOL)willLeave
{
	NSLog(@"User opened ad.");
	[self hideAd];
}

- (void)bannerViewActionDidFinish:(ADBannerView*)banner
{
	NSLog(@"User closed ad.");
	[self showAd];
}

- (void)bannerViewDidLoadAd:(ADBannerView*)banner
{
    NSLog(@"Loaded ad. Show it.");
    
    if(!_isVisible)
    {
    	[self showAd];
    }
}

- (void)bannerView:(ADBannerView*)banner didFailToReceiveAdWithError:(NSError*)error
{
    NSLog(@"Could not load ad. Hide it.");
   
    if(_isVisible)
    {
   		[self hideAd];
   	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
{
    return YES;
}

- (void)orientationChanged:(NSNotification*)notification
{   
	[self fixupAdView:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [self fixupAdView:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)fixupAdView:(UIInterfaceOrientation)toDeviceOrientation 
{
    if(_bannerView != nil) 
    {
        if(UIInterfaceOrientationIsLandscape(toDeviceOrientation)) 
        {
            [_bannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
        } 
        
        else 
        {
            [_bannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        }
        
        //[UIView beginAnimations:@"fixupViews" context:nil];
        
        if(_isVisible) 
        {
        	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        	CGSize adBannerViewSize = [_bannerView frame].size;
        	
        	float bannerWidth = adBannerViewSize.width;
        	float bannerHeight = adBannerViewSize.height;

			//Early on, the banner size can be flipped. This protects against that.
			if(bannerWidth > bannerHeight && UIInterfaceOrientationIsLandscape(toDeviceOrientation))
			{
				bannerWidth = adBannerViewSize.height;
        	 	bannerHeight = adBannerViewSize.width;
			}

			[(UIView*)_bannerView setTransform:CGAffineTransformIdentity];
			[_bannerView setFrame:CGRectMake(0.f, 0.f, bannerWidth, bannerHeight)];
	
			NSLog(@"Visible");
	
			//Set the transformation for each orientation
			switch(toDeviceOrientation)
			{
				case UIInterfaceOrientationPortrait:
				{
					NSLog(@"UIInterfaceOrientationPortrait");

					[_bannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height - bannerHeight/2)];
					
					if([_bannerView isHidden])
					{
						NSLog(@"Hidden");
						[_bannerView setCenter:CGPointMake(screenSize.width/2, screenSize.height + bannerHeight/2)];
					}
				}
				
				break;
				
				case UIInterfaceOrientationPortraitUpsideDown:
				{
					NSLog(@"UIInterfaceOrientationPortraitUpsideDown");
					[(UIView*)_bannerView setTransform:CGAffineTransformMakeRotation(M_PI)];
					[_bannerView setCenter:CGPointMake(screenSize.width/2, bannerHeight/2)];
					
					if([_bannerView isHidden])
					{
						NSLog(@"Hidden");
						[_bannerView setCenter:CGPointMake(screenSize.width/2, -bannerHeight/2)];
					}
				}
				
				break;
				
				case UIInterfaceOrientationLandscapeRight:
				{
					NSLog(@"UIInterfaceOrientationLandscapeRight");
					[(UIView*)_bannerView setTransform:CGAffineTransformMakeRotation(M_PI/2)];
					[_bannerView setCenter:CGPointMake(bannerWidth/2, screenSize.height/2)];
					
					if([_bannerView isHidden])
					{
						NSLog(@"Hidden");
						[_bannerView setCenter:CGPointMake(-bannerHeight/2, screenSize.height/2)];
					}
				}
				
				break;
				
				case UIInterfaceOrientationLandscapeLeft:
				{
					NSLog(@"UIInterfaceOrientationLandscapeLeft");
					[(UIView*)_bannerView setTransform:CGAffineTransformMakeRotation(-M_PI/2)];
					[_bannerView setCenter:CGPointMake(screenSize.width - bannerWidth/2, screenSize.height/2)];
					
					if([_bannerView isHidden])
					{
						NSLog(@"Hidden");
						[_bannerView setCenter:CGPointMake(screenSize.width + bannerWidth/2, screenSize.height/2)];
					}
	
				}
				
				break;
					
				default:
					break;
			}
        } 
        
        else 
        {
        	NSLog(@"NOT Visible");
        
            CGRect adBannerViewFrame = [_bannerView frame];
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = -9999;
            [_bannerView setFrame:adBannerViewFrame];         
        }
        
        //[UIView commitAnimations];
    }   
}

-(int)getBannerHeight:(UIInterfaceOrientation)orientation 
{
    if(UIInterfaceOrientationIsLandscape(orientation)) 
    {
        return 32;
    } 
    
    else 
    {
        return 50;
    }
}

@end

//---

namespace ads
{	
    static AdController* adController;

    void init()
    {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		UIWindow* window = [UIApplication sharedApplication].keyWindow;
		
		Class classAdBannerView = NSClassFromString(@"ADBannerView");
		
		if(classAdBannerView != nil) 
		{
			AdController* c = [[AdController alloc] init];
            adController = c;
            
			ADBannerView* _adBannerView = [[[classAdBannerView alloc] initWithFrame:CGRectZero] autorelease];
			c.bannerView = _adBannerView;
			
			[_adBannerView setRequiredContentSizeIdentifiers:[NSSet setWithObjects: ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil]];
			
			int bannerHeight = 0;
			
			if(UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) 
			{
				[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
				bannerHeight = 32;
			} 
			
			else 
			{
				[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];  
				bannerHeight = 50;
			}

			[_adBannerView setFrame:CGRectOffset([_adBannerView frame], 0, -9999)];
			[_adBannerView setDelegate:c];
	
			[[NSNotificationCenter defaultCenter] addObserver:c selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
			
			UIViewController* vc = [[UIViewController alloc] init];
            c.contentView = vc.view;
            
			[window addSubview: vc.view];
            [vc.view addSubview:_adBannerView];        
		}

		[pool drain];
    }
    
    void showAd(int position)
    {
        if(adController == NULL)
        {
            init();
        }
        
        [adController showAd];
    }

    void hideAd()
    {
        if(adController == NULL)
        {
            init();
        }
        
        [adController hideAd];
    }
}