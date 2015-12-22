//
//  ViewController.m
//  spotlightIos
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import "ViewController.h"
#import <Spotlight/MainSpotlightControllerViewController.h>

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIButton *SingleInstanceButton;
@property (strong, nonatomic) IBOutlet UIButton *SingleInstanceHost;
@property (strong, nonatomic) IBOutlet UIButton *SingleInstanceFan;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;

@property MainSpotlightControllerViewController  *spotlightController;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)openSingleInstance:(id)sender {
    self.instance_id = @"AAAA2";
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                @"type":@"celebrity",
                                @"name":@"Celebridad",
                                @"id":@1234,
                                  }];
    
    [self presentController:user];
}

- (IBAction)singleInstanceAsHost:(id)sender {
    
    self.instance_id = @"AAAA2";
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"host",
                                                           @"name":@"HOST NAME",
                                                           @"id":@1235,
                                                           }];
    
    [self presentController:user];

    
}
- (IBAction)singleInstanceAsFan:(id)sender {
    
    
    self.instance_id = @"AAAA2";
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"fan",
                                                           @"name":@"FanName",
                                                           }];
    [self presentController:user];

}



- (IBAction)openMultipleInstance:(id)sender {
    self.instance_id = @"AAAA1";
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"fan",
                                                           @"name":@"FanName",
                                                           }];
    [self presentController:user];

}
- (IBAction)multipleAsHost:(id)sender {
    self.instance_id = @"AAAA1";
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"host",
                                                           @"name":@"HostName",
                                                           }];
    [self presentController:user];
}
- (IBAction)multipleAsCeleb:(id)sender {
    self.instance_id = @"AAAA1";
    NSMutableDictionary *user =[NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"type":@"celebrity",
                                                           @"name":@"CelebName",
                                                           }];
    [self presentController:user];
}

///SELF IMPLEMENTED MULTIPLE EVENTS VIEW
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"GoToMultipleEvents"]) {
        ViewController *vc = [segue destinationViewController];
        NSString* instance_id = @"AAAA1";
        NSMutableDictionary *user =[NSMutableDictionary
                                    dictionaryWithDictionary:@{
                                                               @"type":@"fan",
                                                               @"name":@"FanName",
                                                               }];
        vc.instance_id = instance_id;
        vc.user = user;

        
    }
}




-(void) presentController:(NSMutableDictionary*)userOptions{
    if(![self.nameTextField.text isEqualToString:@"" ]){
        userOptions[@"name"] = self.nameTextField.text;
    }
//    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Bundle" ofType:@"bundle"];
//    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
//    
    self.spotlightController = [[MainSpotlightControllerViewController alloc] initWithData:self.instance_id user:userOptions];
//    self.spotlightController.instance_id = self.instance_id;
//    self.spotlightController.user = userOptions;
    
    [self presentViewController:self.spotlightController animated:NO completion:nil];
}

@end
