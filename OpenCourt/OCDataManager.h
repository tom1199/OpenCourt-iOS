//
//  OCDataManager.h
//  OpenCourt
//
//  Created by Tang Han on 20/3/14.
//  Copyright (c) 2014 Waterdrop. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Court.h"

@interface OCDataManager : NSObject
+ (void)nearbyCourtsWithCurrentCoordinate:(CLLocationCoordinate2D)coordinate
                           withinDistance:(double)distance //in kilometers
                           withCompletion:(void(^)(NSError *error, NSArray *courts))completion;

+ (void)addNewCourt:(Court *)court withCompletion:(void(^)(NSError *error, BOOL success))completion;
@end
