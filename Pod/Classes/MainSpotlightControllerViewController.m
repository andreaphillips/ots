//
//  MainSpotlightControllerViewController.m
//  spotlightIos
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import "MainSpotlightControllerViewController.h"
#import "EventsViewController.h"
#import "EventViewController.h"
#import "SpotlightApi.h"
#import "Reachability.h"
#import "Alert.h"

@interface MainSpotlightControllerViewController ()<AlertDelegate>
@property UIViewController  *currentDetailViewController;

@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation MainSpotlightControllerViewController

Alert *alert;
static bool hasNetworkConnectivity = YES;

@synthesize instance_id,back_url,instance_data,user;

- (id)initWithData:(NSString *)ainstance_id user:(NSMutableDictionary *)aUser
{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Bundle" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    if( self = [self initWithNibName:@"MainSpotlightControllerViewController" bundle:bundle])
    {
        self.instance_id = ainstance_id;
        
        self.user = aUser;
        
    }
    return self;
}


//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//    }
//    return self;
//}

- (id)initWithViewController:(UIViewController*)viewController{
    
    self = [super init];
    
    if(self){
        [self presentDetailController:viewController];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //UI ***************************
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeMainController:)
                                                 name:@"dismissMainController"
                                               object:nil];
    
    self.hostReachability = [Reachability reachabilityWithHostName:@"http://google.com/"];
    //[self.hostReachability startNotifier];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    [self.wifiReachability startNotifier];
    
    [self logReachability:self.hostReachability];
    [self logReachability:self.internetReachability];
    [self logReachability:self.wifiReachability];
    
    if(hasNetworkConnectivity){
        instance_data = [[SpotlightApi sharedInstance] getEvents:self.instance_id];
    }else{
        NSLog(@"CHECK YOUR INTERNET!! ");
    }
    

}
-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(instance_data)
    {
        [self loadInstanceView];
    }
}
- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reachability = [notification object];
    [self logReachability: reachability];
}

- (void)logReachability:(Reachability *)reachability {
    NSString *whichReachabilityString = nil;
    
    if (reachability == self.hostReachability) {
        whichReachabilityString = @"https://chatshow-tesla.herokuapp.com/";
    } else if (reachability == self.internetReachability) {
        whichReachabilityString = @"The Internet";
        
    }else if (reachability == self.wifiReachability) {
        whichReachabilityString = @"Local Wi-Fi";
    }
    
    NSString *howReachableString = nil;
    
    switch (reachability.currentReachabilityStatus) {
        case NotReachable: {
            howReachableString = @"not reachable";
            hasNetworkConnectivity = NO;
            break;
        }
        case ReachableViaWWAN: {
            howReachableString = @"reachable by cellular data";
            hasNetworkConnectivity = YES;
            break;
        }
        case ReachableViaWiFi:{
            howReachableString = @"reachable by WiFi";
            hasNetworkConnectivity = YES;
            break;
        }
    }
    if(!hasNetworkConnectivity && !alert){
        alert = [[Alert alloc] initWithTitle:@"Network Error! Make sure you are connected to the internet and try again." duration:0.0 completion:^{}];
        [alert setAlertType:AlertTypeError];
        [alert setDelegate:self];
        [alert showAlert];
    }
    if(alert && hasNetworkConnectivity){
        [alert dismissAlert];
        alert = nil;
    }
}

- (void) loadInstanceView {
    if(![self.instance_data[@"events"] count]){
        //Load the first detail controller
        EventsViewController *multiEvent = [[EventsViewController alloc] initEventWithData:self.instance_data user:self.user];
        [self presentDetailController:multiEvent];
    }
    else if([self.instance_data[@"events"] count] == 1){
        //Load the first detail controller
        EventViewController *detailOne = [[EventViewController alloc] initEventWithData:self.instance_data[@"events"][0] user:self.user isSingle:YES];
        [self presentDetailController:detailOne];
    }else{
        //Load the first detail controller
        EventsViewController *multiEvent = [[EventsViewController alloc] initEventWithData:self.instance_data user:self.user];
        [self presentDetailController:multiEvent];
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentDetailController:(UIViewController*)detailVC{
    
    //[self presentDetailController:detailOne];
    [self presentModalViewController:detailVC animated:NO];
    //[self presentViewController:detailVC animated:NO completion:nil];
    
}


- (void)removeCurrentDetailViewController{
    
    //1. Call the willMoveToParentViewController with nil
    //   This is the last method where your detailViewController can perform some operations before neing removed
    [self.currentDetailViewController willMoveToParentViewController:nil];
    
    //2. Remove the DetailViewController's view from the Container
    [self.currentDetailViewController.view removeFromSuperview];
    
    //3. Update the hierarchy"
    //   Automatically the method didMoveToParentViewController: will be called on the detailViewController)
    [self.currentDetailViewController removeFromParentViewController];
}

- (CGRect)frameForDetailController{
    CGRect detailFrame = self.detailView.bounds;
    
    return detailFrame;
}

- (void)closeMainController:(NSNotification *)notification {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
    [self.presentedViewController removeFromParentViewController];
}
@end
