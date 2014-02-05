//
//  MMDataController.h
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMDataController : NSObject

@property (nonatomic, strong) NSSet *systems;
@property (nonatomic, strong) NSSet *hosts;
@property (nonatomic, strong) NSSet *dataSources;


-(void) populateTransitSystems;
+ (MMDataController *) shared;


@end
