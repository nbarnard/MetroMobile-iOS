//
//  MMNetworkController.h
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMTransitSystem.h"

@interface MMNetworkController : NSObject


+ (MMNetworkController *) sharedController;
- (MKCoordinateRegion) getBoundBoxForSystem: (MMTransitSystem *) transitSystem withDataSources: (NSSet *) dataSources;
- (NSString *) getStringKey: (NSString *) key ForSystem: (MMTransitSystem *) transitSystem withDataSources: (NSSet *) dataSources;


@end
