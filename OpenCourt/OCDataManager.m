//
//  OCDataManager.m
//  OpenCourt
//
//  Created by Tang Han on 20/3/14.
//  Copyright (c) 2014 Waterdrop. All rights reserved.
//

#import "OCDataManager.h"
#import <Parse/Parse.h>
#import "Court.h"

@implementation OCDataManager

//------ Query for courts
+ (void)nearbyCourtsWithCurrentCoordinate:(CLLocationCoordinate2D)coordinate
                           withinDistance:(double)distance
                           withCompletion:(void(^)(NSError *error, NSArray *courts))completion {
    PFGeoPoint *currentLocation = [PFGeoPoint geoPointWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    
    PFQuery *queryForCourt = [Court query];
    [queryForCourt whereKey:@"location" nearGeoPoint:currentLocation withinKilometers:distance];
    [queryForCourt findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        completion(error,objects);
    }];
    
}

+ (void)addNewCourt:(Court *)court withCompletion:(void (^)(NSError *error, BOOL success))completion {
    [court saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        completion(error,succeeded);
    }];
}
@end
