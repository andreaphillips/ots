//
//  MultipleEventsExampleControllerViewController.m
//  spotlightIos
//
//  If you want to implement your own multiple events controller you will need to import
//

#import "MultipleEventsExampleControllerViewController.h"
#import "dataButton.h"
#import <QuartzCore/QuartzCore.h>
#import "SpotlightApi.h"
#import "EventViewController.h"

@interface MultipleEventsExampleControllerViewController ()
@property EventViewController  *detailEvent;
@end


@implementation MultipleEventsExampleControllerViewController{
    NSMutableDictionary *eventsData;
    NSArray *dataArray;
}


@synthesize instance_id,user;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *cellNib = [UINib nibWithNibName:@"ExampleEventCell" bundle:nil];
    [self.eventsView registerNib:cellNib forCellWithReuseIdentifier:@"eCell"];
    
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    self.eventsViewLayout.itemSize = CGSizeMake((screenWidth - 30) /3 ,200);
    
    
    NSDictionary *parameters = @{
                                 @"instance_id" : self.instance_id,
                                 };
    
    NSMutableDictionary *allEvents = [[SpotlightApi sharedInstance] getEvents:self.instance_id];
    if(allEvents)
    {
        //We filter our closed events
        dataArray = [allEvents[@"events"]  filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(status != %@)", @"C"]];
        [self.eventsView reloadData];
    }
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [dataArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableDictionary *data = dataArray[indexPath.row];
    
    static NSString *cellIdentifier = @"eCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UILabel *statusLabel = (UILabel *)[cell viewWithTag:101];
    UIImageView *eventImageHolder = (UIImageView *)[cell viewWithTag:104];
    dataButton *eventButton = (dataButton *)[cell viewWithTag:103];
    
    
    [titleLabel setText:data[@"event_name"]];
    if([data[@"status"] isEqualToString:@"N"]){
        [statusLabel setText: [self getFormattedDate:data[@"date_time_start"]]];
        
    }else{
        [statusLabel setText: [self getEventStatus:data[@"status"]]];
    }
    NSURL *finalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://chatshow.herokuapp.com%@", data[@"event_image"]]];
    NSData *imageData = [NSData dataWithContentsOfURL:finalUrl];
    if(imageData){
        eventImageHolder.image = [UIImage imageWithData:imageData];
    }
    
    
    
    [eventButton setUserData:data];
    [eventButton addTarget:self
                    action:@selector(onCellClick:)
          forControlEvents:UIControlEventTouchUpInside];
    CGFloat borderWidth = 1.0f;
    
    cell.layer.borderColor = [UIColor colorWithRed:0.808 green:0.808 blue:0.808 alpha:1].CGColor;
    cell.layer.borderWidth = borderWidth;
    cell.layer.cornerRadius = 3.0;
    
    return cell;
    
}
-(void)onCellClick:(id)sender{
    NSMutableDictionary* eventData = [sender getData];
    //we now show our event view.
    EventViewController *detailEvent = [[EventViewController alloc] initEventWithData:eventData user:user isSingle:YES];
    [detailEvent setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self presentViewController:detailEvent animated:YES completion:nil];
    
}

- (NSString*)getEventStatus:(NSString *)statusLabel
{
    NSString* status = @"";
    if([statusLabel isEqualToString:@"N"]){
        status = @"Not Started";
    };
    if([statusLabel isEqualToString:@"P"]){
        status = @"Not Started";
    };
    if([statusLabel isEqualToString:@"L"]){
        status = @"Live";
    };
    if([statusLabel isEqualToString:@"C"]){
        status = @"Closed";
    };
    return status;
    
}

- (NSString*)getFormattedDate:(NSString *)dateString
{
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

- (IBAction)closeEventsView:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMainController"
                                                        object:nil
                                                      userInfo:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
