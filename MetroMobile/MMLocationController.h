//
//  MMLocationController.h
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/5/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MMLocationController : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocation *currentLocation;
@property (nonatomic) BOOL userWaiting;

+ (MMLocationController *) sharedController;

@end
