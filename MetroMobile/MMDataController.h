//
//  MMDataController.h
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MMFullModel.h"

@interface MMDataController : NSObject

@property (nonatomic, strong) NSSet *systems;
@property (nonatomic, strong) NSSet *hosts;
@property (nonatomic, strong) NSSet *dataSources;
@property (nonatomic, strong) MMLocation *currentLocation;

+ (MMDataController *) sharedController;

- (void) getStopsForCLLocation: (CLLocation *) location;

@end
