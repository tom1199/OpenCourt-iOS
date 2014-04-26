//
//  OCLocationManager.h
//  OpenCourt
//
//  Created by TH Tom on 4/4/14.
//  Copyright (c) 2014 Waterdrop. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface OCLocationManager : CLLocationManager
+ (OCLocationManager *)defaultManager;
@end
