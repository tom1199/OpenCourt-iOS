//
//  Court.m
//  OpenCourt
//
//  Created by Tang Han on 19/3/14.
//  Copyright (c) 2014 Waterdrop. All rights reserved.
//

#import "Court.h"
#import <Parse/PFObject+Subclass.h>

@implementation Court

@dynamic courtCount, courtName, isIndoor, isPrivate, isHalfCourt, hasLight, rating, location, address, thumbnailImage, courtOpen, courtSurface, contact;

+ (NSString *)parseClassName {
    return @"Court";
}


@end
