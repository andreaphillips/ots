//
//  MultipleEventsExampleControllerViewController.h
//  spotlightIos
//
//  Created by Andrea Phillips on 14/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MultipleEventsExampleControllerViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *Title;
@property (strong, nonatomic) IBOutlet UICollectionView *eventsView;
@property (strong, nonatomic) IBOutlet UICollectionViewFlowLayout *eventsViewLayout;

@property (strong, nonatomic) NSMutableDictionary *user;
@property (strong, nonatomic) NSString *instance_id;

@end
