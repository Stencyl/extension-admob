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

-(void)moveBannerOffScreen;
-(void)moveBannerOnScreen;
-(void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation;
-(int)getBannerHeight:(UIInterfaceOrientation)orientation;

@end

@implementation AdController

@synthesize bannerView = _bannerView;
@synthesize contentView = _contentView;
@synthesize visible = _isVisible;

-(void)moveBannerOffScreen
{
    NSLog(@"Hide Ad.");
    self.visible = false;
    [self fixupAdView:self.interfaceOrientation];
}

-(void)moveBannerOnScreen
{
    NSLog(@"Show Ad.");
    self.bannerView.frame = CGRectZero;
    self.visible = true;
    [self fixupAdView:self.interfaceOrientation];
}

- (void)bannerViewDidLoadAd:(ADBannerView*)banner
{
    NSLog(@"Loaded ad.");
    [self moveBannerOnScreen];   
}

- (void)bannerView:(ADBannerView*)banner didFailToReceiveAdWithError:(NSError*)error
{
    NSLog(@"Could not load ad.");
    [self moveBannerOffScreen];
}

- (void) viewWillAppear:(BOOL)animated 
{
    [self fixupAdView:self.interfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration 
{
    [self fixupAdView:toInterfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
{
    return YES;
}

- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation 
{
    NSLog(@"Fix ad up.");
    
    if(_bannerView != nil) 
    {        
        if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) 
        {
            [_bannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
        } 
        
        else 
        {
            [_bannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        }
        
        [UIView beginAnimations:@"fixupViews" context:nil];
        
        if(_isVisible) 
        {
            CGRect adBannerViewFrame = [_bannerView frame];
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = 0;
            [_bannerView setFrame:adBannerViewFrame];
            CGRect contentViewFrame = _contentView.frame;
            contentViewFrame.origin.y = 0;
            contentViewFrame.size.height = self.view.frame.size.height - [self getBannerHeight:toInterfaceOrientation];
            _contentView.frame = contentViewFrame;
        } 
        
        else 
        {
            CGRect adBannerViewFrame = [_bannerView frame];
            adBannerViewFrame.origin.x = 0;
            adBannerViewFrame.origin.y = -[self getBannerHeight:toInterfaceOrientation];
            [_bannerView setFrame:adBannerViewFrame];
            CGRect contentViewFrame = _contentView.frame;
            contentViewFrame.origin.y = 0;
            contentViewFrame.size.height = self.view.frame.size.height;
            _contentView.frame = contentViewFrame;            
        }
        
        [UIView commitAnimations];
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
        
        if(NSClassFromString(@"ADBannerView") != nil) 
        {
            AdController* c = [[AdController alloc] init];
            adController = c;
            ADBannerView* ad = [[ADBannerView alloc] initWithFrame:CGRectZero];
            c.bannerView = ad;
            
            [ad setRequiredContentSizeIdentifiers:[NSSet setWithObjects: ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil]];
            
            ad.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
            [ad setDelegate:c];
            
            UIViewController* vc = [[UIViewController alloc] init];
            c.contentView = vc.view;
            
			[window addSubview: vc.view];
            [vc.view addSubview:ad];
            [c moveBannerOffScreen];
        }
        
		[pool drain];
    }
    
    void showAd(int position)
    {
        if(adController == NULL)
        {
            init();
        }
        
        adController.bannerView.hidden = NO;
    }

    void hideAd()
    {
        if(adController == NULL)
        {
            init();
        }
        
        adController.bannerView.hidden = YES;
    }
}