//
//  EventViewController.h
//  spotlightIos
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) IBOutlet UIView *videoHolder;


@property (strong, nonatomic) IBOutlet UIView *statusBar;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *eventName;
@property (strong, nonatomic) IBOutlet UIButton *getInLineBtn;
@property (strong, nonatomic) IBOutlet UIButton *leaveLineBtn;
@property (strong, nonatomic) IBOutlet UIButton *chatBtn;
@property (strong, nonatomic) IBOutlet UIButton *closeChat;
@property (strong, nonatomic) IBOutlet UIView *chatBar;
@property (strong, nonatomic) IBOutlet UIButton *closeEvenBtn;
@property (strong, nonatomic) IBOutlet UIButton *dismissInline;
@property (strong, nonatomic) IBOutlet UILabel *inlineNotification;

@property (strong, nonatomic) IBOutlet UIView *namePrompt;
@property (strong, nonatomic) IBOutlet UIButton *closeNamePrompt;
@property (strong, nonatomic) IBOutlet UITextField *getInLineName;
@property (strong, nonatomic) IBOutlet UIButton *submitGetInLine;

@property (strong,nonatomic) NSMutableDictionary *user;
@property (strong,nonatomic) NSMutableDictionary *eventData;
@property (strong,nonatomic) NSMutableDictionary *connectionData;

@property NSString *apikey;
@property NSString *userName;
@property Boolean isCeleb;
@property Boolean isHost;
@property NSString *connectionQuality;

@property (strong, nonatomic) IBOutlet UIView *internalHolder;
@property (strong, nonatomic) IBOutlet UIView *HostViewHolder;
@property (strong, nonatomic) IBOutlet UIView *FanViewHolder;
@property (strong, nonatomic) IBOutlet UIView *CelebrityViewHolder;
@property (strong, nonatomic) IBOutlet UIView *inLineHolder;
@property (strong, nonatomic) IBOutlet UIImageView *eventImage;

@property (strong, nonatomic) IBOutlet UIView *notificationBar;
@property (strong, nonatomic) IBOutlet UILabel *notificationLabel;

@property (strong, nonatomic) IBOutlet UIView *countdownView;
@property (strong, nonatomic) IBOutlet UILabel *countdownNumber;

- (id)initEventWithData:(NSDictionary *)aEventData user:(NSMutableDictionary *)aUser isSingle:(BOOL)aSingle NS_DESIGNATED_INITIALIZER;

@end
