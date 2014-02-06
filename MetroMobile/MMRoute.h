//
//  MMRoute.h
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/6/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMTransitSystem.h"

@interface MMRoute : NSObject


@property (nonatomic, strong) NSString *routeID;
@property (nonatomic, strong) NSString *headsign;
@property (nonatomic, strong) MMTransitSystem *system;

@end
