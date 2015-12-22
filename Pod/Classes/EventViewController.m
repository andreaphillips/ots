//
//  EventViewController.m
//  spotlightIos
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import <OpenTok/OpenTok.h>
#import <SIOSocket/SIOSocket.h>
#import "OTKTextChatComponent.h"
#import "SpotlightApi.h"


#import "EventViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "DGActivityIndicatorView.h"
#import "UIColor+AppAdditions.h"
#import "UIView+EasyAutolayout.h"


@interface EventViewController ()
<OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate, OTKTextChatDelegate>
@end

@implementation EventViewController

OTSession* _session;
OTSession* _producerSession;
OTPublisher* _publisher;


NSMutableDictionary *_subscribers;
OTSubscriber* _fanSubscriber;
OTSubscriber* _hostSubscriber;
OTSubscriber* _celebritySubscriber;
OTSubscriber* _producerSubscriber;

id<OTVideoCapture> _cameraCapture;

OTStream* _celebrityStream;
OTStream* _hostStream;
OTStream* _fanStream;
OTStream* _producerStream;

OTConnection* _producerConnection;


DGActivityIndicatorView *activityIndicatorView;
OTKTextChatComponent *textChat;

SIOSocket *signalingSocket;

NSMutableDictionary* videoViews;

static bool isBackstage = NO;
static bool isOnstage = NO;
static bool inCallWithProducer = NO;
static bool isLive = NO;
static bool isSingleEvent = NO;
static bool isFan = NO;

CGRect screen;
CGFloat screen_width;
CGFloat chatYPosition;
CGFloat activeStreams;
CGFloat unreadCount = 0;
CGFloat backcount = 3;
NSTimer * countbackTimer;

static NSString* const kTextChatType = @"chatMessage";

@synthesize apikey, userName, isCeleb, isHost, eventData,connectionData,user,eventName, namePrompt,getInLineName,statusBar,chatBar;

- (id)initEventWithData:(NSMutableDictionary *)aEventData user:(NSMutableDictionary *)aUser isSingle:(BOOL)aSingle{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Bundle" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    
    if( self = [self initWithNibName:@"EventViewController" bundle:bundle])    {
        self.eventData = [aEventData mutableCopy];
        self.userName = aUser[@"name"] ? aUser[@"name"] : aUser[@"type"];
        self.user = aUser;
        self.isCeleb = [aUser[@"type"] isEqualToString:@"celebrity"];
        self.isHost = [aUser[@"type"] isEqualToString:@"host"];
        isFan = !self.isCeleb && !self.isHost;
        
        isSingleEvent = aSingle;
        
        
        //observers
        [self.eventData  addObserver:self
                          forKeyPath:@"status"
                             options:(NSKeyValueObservingOptionNew |
                                      NSKeyValueObservingOptionOld)
                             context:NULL];
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
    }
    return self;
}

-(void)viewDidLoad {
    
    [super viewDidLoad];
    isLive = NO;
    self.connectionData = [[SpotlightApi sharedInstance] creteEventToken: self.user[@"type"]  data:self.eventData];
    if(self.connectionData){
        self.eventData = [self.connectionData[@"event"] mutableCopy];
        [self statusChanged];
        [self loadUser];
    }
    [self.statusBar setBackgroundColor: [UIColor BarColor]];
    
    screen = [UIScreen mainScreen].bounds;
    screen_width = CGRectGetWidth(screen);
    
    videoViews = [[NSMutableDictionary alloc] init];
    videoViews[@"fan"] = self.FanViewHolder;
    videoViews[@"celebrity"] = self.CelebrityViewHolder;
    videoViews[@"host"] = self.HostViewHolder;
    
    _subscribers = [[NSMutableDictionary alloc]initWithCapacity:3];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    NSLog(@"VIEW DID LOAD");

}

-(void) loadUser{
    
    //Load UI
    self.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.eventData[@"event_name"],[self getEventStatus]];
    
    [self.getInLineBtn setBackgroundColor:[UIColor SLGreenColor]];
    [self.leaveLineBtn setBackgroundColor:[UIColor SLRedColor]];
    
    self.eventName.hidden = NO;
    
    self.statusLabel.layer.borderWidth = 2.0;
    [self.statusLabel.layer setBorderColor:CFBridgingRetain([UIColor SLGreenColor])];
    self.statusLabel.layer.cornerRadius = 3;
    self.getInLineBtn.layer.cornerRadius = 3;
    self.leaveLineBtn.layer.cornerRadius = 3;
    
    self.inLineHolder.layer.cornerRadius = 3;
    self.inLineHolder.layer.borderColor = [UIColor SLGrayColor].CGColor;;
    self.inLineHolder.layer.borderWidth = 3.0f;
    
    NSNumber *api = self.connectionData[@"apiKey"];
    self.apikey = [NSString stringWithFormat:@"%@", api];
    
    _session = [[OTSession alloc] initWithApiKey:self.apikey
                                       sessionId:self.connectionData[@"sessionIdHost"]
                                        delegate:self];
    
    self.getInLineBtn.hidden = YES;
    [self statusChanged];
    [self doConnect];
    
    if(isFan){
        [self connectFanSignaling];
    }
}

-(void)loadChat{
    OTSession *currentSession;
    
    if(isBackstage){
        currentSession = _producerSession;
    }else{
        currentSession = _session;
    }
    
    textChat = [[OTKTextChatComponent alloc] init];
    
    textChat.delegate = self;
    
    [textChat setMaxLength:1050];
    
    [textChat setSenderId:currentSession.connection.connectionId alias:@"You"];
    
    chatYPosition = self.statusBar.layer.frame.size.height + self.chatBar.layer.frame.size.height;
    
    CGRect r = self.view.bounds;
    r.origin.y += chatYPosition;
    r.size.height -= chatYPosition;
    (textChat.view).frame = r;
    [self.view insertSubview:textChat.view belowSubview:self.chatBar];
    
    if(!isFan){
        self.chatBtn.hidden = NO;
    }
    
    textChat.view.alpha = 0;
    chatBar.hidden = YES;
    
}

-(void)connectFanSignaling{
    
    [SIOSocket socketWithHost: @"https://chatshow-signaling.herokuapp.com:3000" response: ^(SIOSocket *socket)
     {
         signalingSocket = socket;
         signalingSocket.onConnect = ^()
         {
             [signalingSocket emit:@"joinRoom" args:@[self.connectionData[@"sessionIdProducer"]]];
         };
     }];
}

//
/////Network Test///
//-(void)testConnection{
//    _networkTest = [[OTNetworkTest alloc] init];
//    
//    //Loader
//    [self showLoader];
//    
//    [_networkTest runConnectivityTestWithApiKey:self.apikey
//                                      sessionId:self.connectionData[@"sessionIdProducer"]
//                                          token:self.connectionData[@"tokenProducer"]
//                             executeQualityTest:YES
//                            qualityTestDuration:5
//                                       delegate:self];
//    
//}
//
//-(void)networkTestDidCompleteWithResult:(enum OTNetworkTestResult)result error:(OTError*)error{
//    if(result == OTNetworkTestResultVideoAndVoice)
//    {
//        self.connectionQuality = @"Great";
//        
//    }
//    else if(result == OTNetworkTestResultVoiceOnly)
//    {
//        self.connectionQuality = @"Good";
//    }
//    else
//    {
//        self.connectionQuality = @"Poor";
//    }
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.statusLabel.text = @"Network check finished.";
//        [self stopLoader];
//        
//        _producerSession = [[OTSession alloc] initWithApiKey:self.apikey
//                                                   sessionId:self.connectionData[@"sessionIdProducer"]
//                                                    delegate:self];
//        [self inLineConnect];
//        
//    });
//}

///SESSION CONNECTIONS///

- (void)doConnect
{
    OTError *error = nil;
    
    [_session connectWithToken:self.connectionData[@"tokenHost"] error:&error];
    if (error)
    {
        NSLog(@"do connect error");
        [self showAlert:error.localizedDescription];
    }
}

- (void)inLineConnect
{
    
    OTError *error = nil;
    [self showLoader];
    
    self.getInLineBtn.hidden = YES;
    
    [_producerSession connectWithToken:self.connectionData[@"tokenProducer"] error:&error];
    
    if (error)
    {
        [self showAlert:error.localizedDescription];
    }
    
}

-(void)disconnectBackstage
{
    [self unpublishFrom:_producerSession];
    [self cleanupPublisher];
    isBackstage = NO;
    self.inLineHolder.alpha = 0;
    [_producerSession disconnect:nil];
    
}

- (void)doDisconnect{
    OTError *error = nil;
    
    self.statusLabel.text = @"Disconnecting";
    
    [_session disconnect:&error];
    if (error)
    {
        [self showAlert:error.localizedDescription];
    }
}

//Publishers

- (void)doPublish{
    
    if(self.isCeleb){
        [self publishTo:_session];
        [videoViews[@"celebrity"] addSubview:_publisher.view];
        (_publisher.view).frame = CGRectMake(0, 0, self.CelebrityViewHolder.bounds.size.width, self.CelebrityViewHolder.bounds.size.height);
        self.closeEvenBtn.hidden = NO;
    }
    if(self.isHost){
        [self publishTo:_session];
        [videoViews[@"host"] addSubview:_publisher.view];
        self.closeEvenBtn.hidden = NO;
        (_publisher.view).frame = CGRectMake(0, 0, self.HostViewHolder.bounds.size.width, self.HostViewHolder.bounds.size.height);
    }
    
    //FAN
    if(isBackstage){
        [self sendNewUserSignal];
        [self publishTo:_producerSession];
        
        _publisher.view.layer.cornerRadius = 0.5;
        [self.inLineHolder addSubview:_publisher.view];
        [self.inLineHolder sendSubviewToBack:_publisher.view];
        self.statusLabel.text = @"IN LINE";
        self.inLineHolder.alpha = 1;
        self.closeEvenBtn.hidden = YES;
        
        (_publisher.view).frame = CGRectMake(0, 0, self.inLineHolder.bounds.size.width, self.inLineHolder.bounds.size.height);
        [self stopLoader];
        [self performSelector:@selector(hideInlineHolder) withObject:nil afterDelay:10.0];

    }
    if(isOnstage){
        [self publishTo:_session];
        [self.FanViewHolder addSubview:_publisher.view];
        _publisher.view.frame = CGRectMake(0, 0, self.FanViewHolder.bounds.size.width, self.FanViewHolder.bounds.size.height);
        self.closeEvenBtn.hidden = YES;
    }
    
    
    
    
    [self adjustChildrenWidth];
}
-(void) publishTo:(OTSession *)session
{
    if(!_publisher){
        _publisher = [[OTPublisher alloc] initWithDelegate:self name:[UIDevice currentDevice].name];
    }
    
    OTError *error = nil;
    if (error)
    {
        NSLog(@"publish error");
        [self showAlert:error.localizedDescription];
    }
    [session publish:_publisher error:&error];

}

-(void)unpublishFrom:(OTSession *)session
{
    OTError *error = nil;
    if (error)
    {
        [self showAlert:error.localizedDescription];
    }
    [session unpublish:_publisher error:&error];
}

-(void)cleanupPublisher{
    if(_publisher){
        [_publisher.view removeFromSuperview];
        _publisher = nil;
    }
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher
    streamCreated:(OTStream *)stream
{
    [self doSubscribe:stream];
    
}

- (void)publisher:(OTPublisherKit*)publisher
  streamDestroyed:(OTStream *)stream
{
    
    NSString *connectingTo =[self getStreamData:stream.connection.data];
    OTSubscriber *_subscriber = _subscribers[connectingTo];
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        [self cleanupSubscriber:connectingTo];
    }
    
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher
 didFailWithError:(OTError*) error
{
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}




//Subscribers
- (void)doSubscribe:(OTStream*)stream
{
    
    NSString *connectingTo =[self getStreamData:stream.connection.data];
    if(stream.session.connection.connectionId != _producerSession.connection.connectionId && ![connectingTo isEqualToString:@"producer"]){
        OTSubscriber *subs = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        _subscribers[connectingTo] = subs;
        
        OTError *error = nil;
        [_session subscribe: _subscribers[connectingTo] error:&error];
        if (error)
        {
            NSLog(@"subscribe error");
        }
        
    }
    if(stream.session.connection.connectionId == _producerSession.connection.connectionId && [connectingTo isEqualToString:@"producer"]){
        _producerSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        
        OTError *error = nil;
        [_producerSession subscribe: _producerSubscriber error:&error];
        if (error)
        {
            NSLog(@"subscribe to producer error");
        }
        
    }
    
}


- (void)cleanupSubscriber:(NSString*)type
{
    OTSubscriber *_subscriber = _subscribers[type];
    [_subscriber.view removeFromSuperview];
    if(_subscriber){
        [_subscribers removeObjectForKey:type];
        _subscriber = nil;
    }
    
    [self adjustChildrenWidth];
}



# pragma mark - OTSubscriber delegate callbacks

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    if(subscriber.session.connection.connectionId == _session.connection.connectionId){
        
        NSLog(@"subscriberDidConnectToStream (%@)", subscriber.stream.connection.connectionId);
        
        UIView *holder;
        NSString *connectingTo =[self getStreamData:subscriber.stream.connection.data];
        OTSubscriber *_subscriber = _subscribers[connectingTo];
        assert(_subscriber == subscriber);
        
        holder = videoViews[connectingTo];
        
        
        (_subscriber.view).frame = CGRectMake(0, 0, holder.bounds.size.width,holder.bounds.size.height);
        
        [holder addSubview:_subscriber.view];
        self.eventImage.hidden = YES;
        [self adjustChildrenWidth];
    
    }

}

- (void)subscriber:(OTSubscriberKit*)subscriber
  didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@",
          subscriber.stream.streamId,
          error);
}


# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session
{
    
    if(self.isCeleb || self.isHost){
        NSLog(@"HOST OR CELEB!");
        [self doPublish];
        [self loadChat];
        isOnstage = YES;
    }else{
        NSLog(@"user is a fan, we need to show the get in line button");
        if(session.sessionId == _session.sessionId){
            NSLog(@"FAN CONNECTED TO ONSTAGE!");
            (self.statusLabel).text = @"";
            self.closeEvenBtn.hidden = NO;
        }
        if(session.sessionId == _producerSession.sessionId){
            NSLog(@"FAN CONNECTED TO BACKSTAGE!");
            isBackstage = YES;
            self.closeEvenBtn.hidden = YES;
            self.leaveLineBtn.hidden = NO;
            [self doPublish];
            [self loadChat];
        }
    }
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage =
    [NSString stringWithFormat:@"Session disconnected: (%@)", session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
    if(session == _producerSession){
        [self disconnectBackstage];
        self.leaveLineBtn.hidden = YES;
        [self hideNotification];
    }else{
        _session = nil;
    }
}


- (void)session:(OTSession*)mySession
  streamCreated:(OTStream *)stream
{
    NSLog(@"session streamCreated (%@)", stream.streamId);
    if(mySession.connection.connectionId != _producerSession.connection.connectionId){
        if([stream.connection.data isEqualToString:@"usertype=host"]){
            _hostStream = stream;
        }
        
        if([stream.connection.data isEqualToString:@"usertype=celebrity"]){
            _celebrityStream = stream;
        }
        
        if([stream.connection.data isEqualToString:@"usertype=fan"]){
            _fanStream = stream;
        }
        
        if(isLive || isCeleb || isHost){
            [self doSubscribe:stream];
        }
    }else{
        if([stream.connection.data isEqualToString:@"usertype=producer"]){
            _producerStream = stream;
        }
    }
    
    
    
}

- (void)session:(OTSession*)session
streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
    NSLog(@"disconnectin from connecting to (%@)", stream.connection.data);
    
    NSString *type = [self getStreamData:stream.connection.data];
    OTSubscriber *_subscriber = _subscribers[type];
    
    if([type isEqualToString:@"host"]){
        _hostStream = nil;
    }
    
    if([type isEqualToString:@"celebrity"]){
        _celebrityStream = nil;
    }
    
    if([type isEqualToString:@"fan"]){
        _fanStream = nil;
    }
    if([type isEqualToString:@"producer"]){
        _producerStream = nil;
    }
    
    [self cleanupSubscriber:type];
    
}


- (void)  session:(OTSession *)session
connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
}


- (void)    session:(OTSession *)session
connectionDestroyed:(OTConnection *)connection
{
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
    NSString *connectingTo =[self getStreamData:connection.data];
    OTSubscriber *_subscriber = _subscribers[connectingTo];
    
    if ([_subscriber.stream.connection.connectionId
         isEqualToString:connection.connectionId])
    {
        [self cleanupSubscriber:connectingTo];
    }
}

- (void) session:(OTSession*)session
didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
}



///Show Alert
- (void)showAlert:(NSString *)string
{
    // show alertview on main UI
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OTError"
                                                        message:string
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] ;
        [alert show];
    });
}


//Messaging

- (void)session:(OTSession*)session receivedSignalType:(NSString*)type fromConnection:(OTConnection*)connection withString:(NSString*)string {
    NSDictionary* messageData;
    
    if(string){
        messageData = [self parseJSON:string];
    }
    NSLog(type);
    if([type isEqualToString:@"startEvent"]){
        self.eventData[@"status"] = @"P";
        self.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.eventData[@"event_name"],[self getEventStatus]];
        [self statusChanged];
        
        NSLog(@"got signal to start Event");
    }
    if([type isEqualToString:@"openChat"]){
        self.chatBtn.hidden = NO;
        _producerConnection = connection;
    }
    if([type isEqualToString:@"closeChat"]){
        if(isFan){
            [self hideChatBox];
            self.chatBtn.hidden = YES;
        }
        
    }
    if([type isEqualToString:@"muteAudio"]){
        [messageData[@"mute"] isEqualToString:@"on"] ? [_publisher setPublishAudio: NO] : [_publisher setPublishAudio: YES];
        
        NSLog(@"got signal to muteAudio");
    }
    if([type isEqualToString:@"changeVolume"]){
        NSLog(@"got signal to changeVolume");
    }
    if([type isEqualToString:@"videoOnOff"]){
        [messageData[@"video"] isEqualToString:@"on"] ? [_publisher setPublishVideo: YES] : [_publisher setPublishVideo: NO];
        NSLog(@"got signal to change video status");
    }
    if([type isEqualToString:@"newBackstageFan"]){
        if(isHost || isCeleb){
            [self showNotification:@"A new FAN has been moved to backstage" useColor:[UIColor SLBlueColor]];
            [self performSelector:@selector(hideNotification) withObject:nil afterDelay:10.0];
        }
    }
    if([type isEqualToString:@"joinBackstage"]){
        [self publishTo:_producerSubscriber.session];
        self.statusLabel.text = @"BACKSTAGE";
        [self showNotification:@"Going Backstage.You are sharing video." useColor:[UIColor SLBlueColor]];
        NSLog(@"gYOU ARE BACKSTAGE,DO SOMETHING");
    }
    
    if([type isEqualToString:@"newFanAck"]){
        NSLog(@"Got new fan! send me the pic!");
        [self performSelector:@selector(captureAndSendScreenshot) withObject:nil afterDelay:2.0];
        //[self captureAndSendScreenshot];
    }
    
    if([type isEqualToString:@"resendNewFanSignal"]){
        
        NSLog(@"RESENDME YOUR STATUS");
        if(isBackstage && !_producerStream){
            [self disconnectBackstage];
            _producerSession = [[OTSession alloc] initWithApiKey:self.apikey
                                                       sessionId:self.connectionData[@"sessionIdProducer"]
                                                        delegate:self];
            [self inLineConnect];
        }
        
    }
    
    if([type isEqualToString:@"joinProducer"]){
        [self doSubscribe:_producerStream];
        inCallWithProducer = YES;
        self.statusLabel.text = @"IN CALL WITH PRODUCER";
        [self showNotification:@"YOU ARE NOW IN CALL WITH PRODUCER" useColor:[UIColor SLBlueColor]];
    }
    
    if([type isEqualToString:@"disconnectProducer"]){
        OTError *error = nil;
        [_producerSession unsubscribe: _producerSubscriber error:&error];
        _producerSubscriber = nil;
        inCallWithProducer = NO;
        self.statusLabel.text = @"IN LINE";
        [self hideNotification];
    }
    
    if([type isEqualToString:@"disconnectBackstage"]){
        self.leaveLineBtn.hidden = YES;
        self.getInLineBtn.hidden = YES;
        [self disconnectBackstage];
        self.statusLabel.text = @"";
    }
    if([type isEqualToString:@"goLive"]){
        self.eventData[@"status"] = @"L";
        self.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.eventData[@"event_name"],[self getEventStatus]];
        if(!isLive){
            [self goLive];
        }
        [self statusChanged];
        self.eventImage.hidden = YES;
        
    }
    if([type isEqualToString:@"joinHost"]){
        
        
        OTError *error = nil;
        if (error)
        {
            NSLog(@"disconnect error");
            [self showAlert:error.localizedDescription];
        }
        
        [self disconnectBackstage];
        
        isOnstage = YES;
        
        self.statusLabel.text = @"\u2022 You are live";
        self.statusLabel.hidden = NO;
        self.leaveLineBtn.hidden = YES;
        [self hideChatBox];
        [self hideNotification];
        self.chatBtn.hidden = YES;
        
        if(![self.eventData[@"status"] isEqualToString:@"L"] && !isLive){
            [self goLive];
        }
        
        [self showCountdownView];
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(doPublish)
                                       userInfo:nil
                                        repeats:NO];
    }
    
    if([type isEqualToString:@"finishEvent"]){
        self.eventData[@"status"] = @"C";
        self.eventName.text = [NSString stringWithFormat:@"%@ (%@)",  self.eventData[@"event_name"],[self getEventStatus]];
        [self statusChanged];
    }
    
    if([type isEqualToString:@"disconnect"]){
        
        self.statusLabel.hidden = YES;
        self.chatBtn.hidden = YES;
        self.closeEvenBtn.hidden = NO;
        [self hideChatBox];
        isOnstage = NO;
        OTError *error = nil;
        if (error)
        {
            NSLog(@"disconnect error");
            [self showAlert:error.localizedDescription];
        }
        if(_publisher){
            [self unpublishFrom:_session];
        }
        [self showNotification:@"Thank you for participating, you are no longer sharing video/voice. You can continue to watch the session at your leisure." useColor:[UIColor SLBlueColor]];
        [self performSelector:@selector(hideNotification) withObject:nil afterDelay:5.0];

    }
    
    if([type isEqualToString:@"chatMessage"]){
        if (![connection.connectionId isEqualToString:session.connection.connectionId]) {
            self.chatBtn.hidden = NO;
            _producerConnection = connection;
            NSDictionary *userInfo = [self parseJSON:string];
            OTKChatMessage *msg = [[OTKChatMessage alloc]init];
            msg.senderAlias = [self getStreamData:connection.data];
            msg.senderId = connection.connectionId;
            msg.text = userInfo[@"message"][@"message"];
            unreadCount ++;
            [textChat addMessage:msg];
            [self.chatBtn setTitle:[[NSNumber numberWithFloat:unreadCount] stringValue] forState:UIControlStateNormal];
            
        }
        
        
        
    }
}

- (void)sendNewUserSignal
{
    if(!self.connectionQuality){
        self.connectionQuality = @"Good";
    }
    
    NSDictionary *data = @{
                           @"type" : @"newFan",
                           @"user" :@{
                                   @"username": self.userName,
                                   @"quality":self.connectionQuality,
                                   },
                           @"chat" : @{
                                   @"chatting" : @"false",
                                   @"messages" : @"[]"
                                   }
                           };
    
    OTError* error = nil;
    
    if (error) {
        NSLog(@"signal error %@", error);
    } else {
        NSLog(@"signal sent new user");
    }
    NSString *stringified = [NSString stringWithFormat:@"%@", [self stringify:data]];
    [_producerSession signalWithType:@"newFan" string:stringified connection:_publisher.stream.connection error:&error];
}

- (void)captureAndSendScreenshot{
    NSLog(@"Starting caputre");
    
    UIView* screenCapture = [_publisher.view snapshotViewAfterScreenUpdates:YES];
    if(screenCapture){
        [self.inLineHolder addSubview:screenCapture];
        UIImage *screenshot = [self imageFromView:self.inLineHolder];
        
        NSData *imageData = UIImageJPEGRepresentation(screenshot, 0.3);
        NSString *encodedString = [imageData base64EncodedStringWithOptions:0 ];
        NSString *formated = [NSString stringWithFormat:@"data:image/png;base64,%@",encodedString];
        
        [signalingSocket emit:@"mySnapshot" args:@[@{
                                                            @"connectionId": _publisher.session.connection.connectionId,
                                                            @"sessionId" : _producerSession.sessionId,
                                                            @"snapshot": formated
                                                            }]];
        [screenCapture removeFromSuperview];
    }
    
}

- (UIImage *) imageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size,
                                           NO, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds
               afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//STATUS OBSERVER
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqual:@"status"]) {
        [self statusChanged];
    }
}

-(void) statusChanged{
    if([self.eventData[@"status"] isEqualToString:@"N"]){
        if(isCeleb || isHost){
            self.eventImage.hidden = YES;
        }else{
            self.eventImage.hidden = NO;
            [self updateEventImage: [NSString stringWithFormat:@"https://chatshow.herokuapp.com%@", self.eventData[@"event_image"]]];
            self.getInLineBtn.hidden = YES;
        }
    };
    if([self.eventData[@"status"] isEqualToString:@"P"]){
        if(isCeleb || isHost){
            self.eventImage.hidden = YES;
        }else{
            self.eventImage.hidden = NO;
            NSString *url = [NSString stringWithFormat:@"https://chatshow.herokuapp.com%@", self.eventData[@"event_image"]];
            [self updateEventImage: url];
            self.getInLineBtn.hidden = NO;
        }
        
    };
    if([self.eventData[@"status"] isEqualToString:@"L"]){
        if (_subscribers.count > 0) {
            self.eventImage.hidden = YES;
        }else{
            self.eventImage.hidden = NO;
        }
        if(!isCeleb && !isHost && !isBackstage && !isOnstage){
            self.getInLineBtn.hidden = NO;
        }
        isLive = YES;
    };
    if([self.eventData[@"status"] isEqualToString:@"C"]){
        [self updateEventImage: [NSString stringWithFormat:@"https://chatshow.herokuapp.com%@", self.eventData[@"event_image_end"]]];
        //Event Closed, disconect fan and show image
        self.eventImage.hidden = NO;
        self.getInLineBtn.hidden = YES;
        OTError *error = nil;
        if (error)
        {
            NSLog(@"closing event error");
            [self showAlert:error.localizedDescription];
        }
        [_session disconnect:&error];
        if(isBackstage){
            [_producerSession disconnect:&error];
        }
        [self cleanupPublisher];
        self.closeEvenBtn.hidden = NO;
        
    };
    
};

-(void)goLive{
    NSLog(@"Going LIVE");
    isLive = YES;
    if(_hostStream && !_subscribers[@"host"]){
        [self doSubscribe:_hostStream];
    }
    if(_celebrityStream && !_subscribers[@"celebrity"]){
        [self doSubscribe:_celebrityStream];
    }
    if(_fanStream && !_subscribers[@"fan"]){
        [self doSubscribe:_fanStream];
    }
}


//OTCHAT
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    NSDictionary* info = aNotification.userInfo;
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    double duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        if((self.namePrompt).hidden){
            CGRect r = self.view.bounds;
            r.origin.y += chatYPosition;
            r.size.height -= chatYPosition + kbSize.height;
            textChat.view.frame = r;
        }else{
            NSLayoutConstraint *bottomConstraint = [self.view constraintForIdentifier:@"topConstraint"];
            bottomConstraint.constant -=100;
        }
        
    }];
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    NSDictionary* info = aNotification.userInfo;
    double duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        
        if((self.namePrompt).hidden){
            CGRect r = self.view.bounds;
            r.origin.y += chatYPosition;
            r.size.height -= chatYPosition;
            textChat.view.frame = r;
        }else{
            NSLayoutConstraint *bottomConstraint = [self.view constraintForIdentifier:@"topConstraint"];
            bottomConstraint.constant +=100;
        }
        
    }];
}

- (BOOL)onMessageReadyToSend:(OTKChatMessage *)message {
    OTError *error = nil;
    OTSession *currentSession;
    if(isBackstage){
        currentSession = _producerSession;
    }else{
        currentSession = _session;
    }
    
    NSDictionary *user_message = @{@"message": message.text};
    NSDictionary *userInfo = @{@"message": user_message};
    
    [currentSession signalWithType:kTextChatType string:[self stringify:userInfo] connection: _producerConnection error:&error];
    if (error) {
        return NO;
    } else {
        return YES;
    }
}


//Utils

- (void) updateEventImage:(NSString*)url {
    NSLog(url);
    NSURL *finalUrl = [NSURL URLWithString:url];
    NSData *imageData = [NSData dataWithContentsOfURL:finalUrl];
    if(imageData){
        [self.eventImage setImage:[UIImage imageWithData:imageData]];
    }
    
}

- (void) adjustChildrenWidth{
    
    NSLog(@"adjusting");
    CGFloat c = 0;
    CGFloat new_width = 1;
    CGFloat new_height = self.internalHolder.bounds.size.height;
    if(_session.streams.count == 0){
        self.eventImage.hidden = NO;
    }
    else{
        self.eventImage.hidden = YES;
        new_width = screen_width/_session.streams.count;
    }
    
    NSArray *viewNames = @[@"host",@"celebrity",@"fan"];
    
    for(NSString *viewName in viewNames){
        if(_subscribers[viewName]){
            OTSubscriber *temp = _subscribers[viewName];
            
            [videoViews[viewName] setFrame:CGRectMake((c*new_width), 0, new_width, new_height)];
            temp.view.frame = CGRectMake(0, 0, new_width,new_height);
            c++;
            
            [videoViews[viewName] setHidden:NO];
        }else{
            [videoViews[viewName] setHidden:YES];
            [videoViews[viewName] setFrame:CGRectMake(0, 0, 10,new_height)];
            
        }
        
    }
}

- (NSString*)getSessionStatus{
    NSString* connectionStatus = @"";
    if (_session.sessionConnectionStatus==OTSessionConnectionStatusConnected) {
        connectionStatus = @"Connected";
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusConnecting) {
        connectionStatus = @"Connecting";
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusDisconnecting) {
        connectionStatus = @"Disconnecting";
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusNotConnected) {
        connectionStatus = @"Disconnected";
    }else{
        connectionStatus = @"Failed";
    }
    return connectionStatus;
}

- (NSString*)getEventStatus{
    NSString* status = @"";
    if([self.eventData[@"status"] isEqualToString:@"N"]){
        status = [self getFormattedDate:self.eventData[@"date_time_start"]];
    };
    if([self.eventData[@"status"] isEqualToString:@"P"]){
        status = @"Not Started";
    };
    if([self.eventData[@"status"] isEqualToString:@"L"]){
        status = @"Live";
    };
    if([self.eventData[@"status"] isEqualToString:@"C"]){
        status = @"Closed";
    };
    return status;
    
}

- (NSString*)getFormattedDate:(NSString *)dateString{
    if(dateString != (id)[NSNull null]){
        NSDateFormatter * dateFormat = [[NSDateFormatter alloc]init];
        [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormat setLocale:[NSLocale currentLocale]];
        [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss.0"];
        [dateFormat setFormatterBehavior:NSDateFormatterBehaviorDefault];
        
        NSDate *date = [dateFormat dateFromString:dateString];
        dateFormat.dateFormat = @"dd MMM YYYY HH:mm:ss";
        
        return [dateFormat stringFromDate:date];
    }else{
        return @"Not Started";
    }
    
}

- (void) changeStatusLabelColor{
    if (_session.sessionConnectionStatus==OTSessionConnectionStatusConnected) {
        self.statusLabel.textColor = [UIColor greenColor];
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusConnecting) {
        self.statusLabel.textColor = [UIColor blueColor];
    }else if (_session.sessionConnectionStatus==OTSessionConnectionStatusDisconnecting) {
        self.statusLabel.textColor = [UIColor blueColor];
    }else {
        self.statusLabel.textColor = [UIColor SLBlueColor];
    }
}

-(NSString*)getStreamData:(NSString*)data{
    return [data stringByReplacingOccurrencesOfString:@"usertype="withString:@""];
};

-(NSDictionary*)parseJSON:(NSString*)string{
    NSString *toParse = [[NSString alloc] initWithString:string];
    NSError * errorDictionary = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[toParse dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&errorDictionary];
    return dictionary;
}

-(NSString*)stringify:(NSDictionary*)data{
    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:data options:0 error:&err];
    NSString * string = [[NSString alloc] initWithData:jsonData   encoding:NSUTF8StringEncoding];
    return string;
}


//FAN ACTIONS
- (IBAction)chatNow:(id)sender {
    [UIView animateWithDuration:0.5 animations:^() {
        //_connectingLabel.alpha = 0;
        [self showChatBox];
        unreadCount = 0;
        [self.chatBtn setTitle:@"" forState:UIControlStateNormal];
    }];
}

- (IBAction)closeChat:(id)sender {
    [UIView animateWithDuration:0.5 animations:^() {
        [self hideChatBox];
        if(!isFan){
            self.chatBtn.hidden = NO;
        }
        
    }];
    [self.getInLineName resignFirstResponder];
}

- (IBAction)getInLineClick:(id)sender {
    self.userName = self.userName;
    //[self testConnection];
    _producerSession = [[OTSession alloc] initWithApiKey:self.apikey
                                               sessionId:self.connectionData[@"sessionIdProducer"]
                                                delegate:self];
    [self inLineConnect];
}

- (IBAction)closePrompt:(id)sender {
    self.namePrompt.hidden = YES;
}

- (IBAction)leaveLine:(id)sender {
    self.leaveLineBtn.hidden = YES;
    self.chatBtn.hidden = YES;
    self.closeEvenBtn.hidden = NO;
    [self disconnectBackstage];
    self.statusLabel.text = @"";
    self.getInLineBtn.hidden = NO;
    
}

//NOTIFICATIONS
- (void)showNotification:(NSString *)text useColor:(UIColor *)nColor {
    self.notificationLabel.text = text;
    self.notificationBar.backgroundColor = nColor;
    self.notificationBar.hidden = NO;
}

-(void)hideNotification{
    self.notificationBar.hidden = YES;
}

//UI

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)showChatBox{
    self.chatBtn.hidden = YES;
    textChat.view.alpha = 1;
    chatBar.hidden = NO;
}

-(void)hideChatBox{
    textChat.view.alpha = 0;
    chatBar.hidden = YES;
}

-(void)showLoader{
    activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeFiveDots
                                                                tintColor:[UIColor SLBlueColor] size:50.0f];
    activityIndicatorView.frame = CGRectMake(0.0f, 100.0f, screen_width, 100.0f);
    [self.view addSubview:activityIndicatorView];
    [self.view bringSubviewToFront:activityIndicatorView];
    [activityIndicatorView startAnimating];
}

-(void)stopLoader{
    [activityIndicatorView stopAnimating];
    [activityIndicatorView removeFromSuperview];
}

-(IBAction)dismissInlineTxt:(id)sender {
    [self hideInlineHolder];
}

-(void)hideInlineHolder{
    [UIView animateWithDuration:5 animations:^{
        self.inLineHolder.alpha = 0;
    }];
}

-(void)showCountdownView
{
    self.countdownView.hidden = NO;
    countbackTimer =  [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(changeNumberCount) userInfo:nil repeats:YES];
    
}

-(void)changeNumberCount
{
    if(backcount == -1){
        [countbackTimer invalidate];
        self.countdownView.hidden = YES;
    }else{
        self.countdownNumber.text = [[NSNumber numberWithFloat:backcount] stringValue];
        backcount--;
    }
}

//GO BACK

- (IBAction)goBack:(id)sender {
    
    OTError *error = nil;
    if (error)
    {
        [self showAlert:error.localizedDescription];
    }
    if(_producerSession){
        [_producerSession disconnect:&error];
    }
    [_session disconnect:&error];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
    
    if(isSingleEvent){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMainController"
                                                            object:nil
                                                          userInfo:nil];
    }
}


@end
