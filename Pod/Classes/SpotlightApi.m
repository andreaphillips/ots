//
//  SpotlightApi.m
//  spotlightIos
//
//  Created by Andrea Phillips on 15/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import "SpotlightApi.h"

@implementation SpotlightApi

+ (SpotlightApi*)sharedInstance
{
    static SpotlightApi *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[SpotlightApi alloc] init];
    });
    return _sharedInstance;
}


- (NSMutableDictionary*)getEvents:(NSString*)instance_id{
    NSMutableDictionary *instance_data ;
    NSString *url = @"https://chatshow-tesla.herokuapp.com/get-instance-by-id";
    NSDictionary *parameters = @{
                                 @"instance_id" : instance_id,
                                 };
    //Create the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    //parse parameters to json format
    NSError * error = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    __block NSDictionary *json;
    
    NSURLResponse * response = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    
    if (error == nil)
    {
        json = [NSJSONSerialization JSONObjectWithData:data
                                               options:0
                                                 error:nil];
        
        NSError * errorDictionary = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorDictionary];
        instance_data = [dictionary mutableCopy];
        return instance_data;
    }else{
        return instance_data;
    }
    
};

- (NSMutableDictionary*) creteEventToken:(NSString*)user_type data:(NSMutableDictionary *)event_data{
    
    NSMutableDictionary *connectionData;
    NSString *_url = [NSString stringWithFormat:@"%@_url", user_type];
    
    NSString *event_url = event_data[_url];
    
    //user_type should be @"fan", @'celebrity' or @"host"
    NSString *url = [NSString stringWithFormat:@"https://chatshow-tesla.herokuapp.com/create-token-%@/%@", user_type, event_url];
    
    //Create the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSError * error = nil;

    
    __block NSDictionary *json;
    
    NSURLResponse * response = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    
    if (error == nil)
    {
        json = [NSJSONSerialization JSONObjectWithData:data
                                               options:0
                                                 error:nil];
        
        NSError * errorDictionary = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorDictionary];
        return connectionData = [dictionary mutableCopy];
    }else{
        return connectionData;
    }
}

@end
