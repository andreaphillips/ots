//
//  UIView+EasyAutoLayout.m
//  spotlightIos
//
//  Created by Andrea Phillips on 28/10/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import "UIView+EasyAutolayout.h"

@implementation UIView (EasyAutolayout)

-(NSLayoutConstraint *)constraintForIdentifier:(NSString *)identifier {
    
    for (NSLayoutConstraint *constraint in self.constraints) {
        NSLog(constraint.identifier);
        if ([constraint.identifier isEqualToString:identifier]) {
            return constraint;
        }
    }
    return nil;
}

@end
