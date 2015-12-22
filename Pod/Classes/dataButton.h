//
//  dataButton.h
//  spotlightIos
//
//  Created by Andrea Phillips on 16/11/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface dataButton : UIButton

@property (nonatomic, retain) NSMutableDictionary* userData;

-(NSMutableDictionary*) getData;
@end
