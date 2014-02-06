//
//  MMStop.h
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/6/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MMStop : NSObject

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSArray *routes;

@end
