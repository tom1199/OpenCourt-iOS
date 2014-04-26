//
//  Court.h
//  OpenCourt
//
//  Created by Tang Han on 19/3/14.
//  Copyright (c) 2014 Waterdrop. All rights reserved.
//

#import <Parse/Parse.h>

@interface Court : PFObject
<PFSubclassing>

+ (NSString *)parseClassName;

@property (nonatomic, assign) int courtCount;
@property (nonatomic, strong) NSString *courtName;
@property (nonatomic, assign) BOOL isIndoor;
@property (nonatomic, assign) BOOL isPrivate;
@property (nonatomic, assign) BOOL isHalfCourt;
@property (nonatomic, assign) BOOL hasLight;
@property (nonatomic, assign) float rating;
@property (nonatomic, assign) PFGeoPoint *location;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) PFFile *thumbnailImage;
@property (nonatomic, strong) NSString *courtOpen;
@property (nonatomic, strong) NSString *courtSurface;
@property (nonatomic, strong) NSString *contact;

@end
