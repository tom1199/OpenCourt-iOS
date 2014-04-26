//
//  OCLocationManager.m
//  OpenCourt
//
//  Created by TH Tom on 4/4/14.
//  Copyright (c) 2014 Waterdrop. All rights reserved.
//

#import "OCLocationManager.h"

@implementation OCLocationManager

+ (OCLocationManager *)defaultManager {
    static OCLocationManager *_sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[OCLocationManager alloc]init];
        _sharedManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    });
    
    return _sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

@end
