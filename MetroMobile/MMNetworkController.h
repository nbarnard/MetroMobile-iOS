//
//  MMNetworkController.h
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMTransitSystem.h"

// Unique Data Points Map to the sourcetypes in MMTransitSystem.h
typedef enum uniqueDataPoint {
    systemName = 1,
    systemStops = 4,
    systemTimeZone = 6
} uniqueDataPoint;

@interface MMNetworkController : NSObject


+ (MMNetworkController *) sharedController;
- (MKMapRect) getBoundBoxForSystem: (MMTransitSystem *) transitSystem withDataSources: (NSSet *) dataSources;
- (NSString *) getStringforUniqueDataPoint: (uniqueDataPoint) requestedDataPoint ForSystem: (MMTransitSystem *) transitSystem withDataSources: (NSSet *) dataSources;
- (void) getRoutesForSystems:(NSSet *) systems atPoint: (MKMapPoint)locationPoint withDataSources: (NSSet *) dataSources;


@end
