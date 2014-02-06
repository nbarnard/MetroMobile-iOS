//
//  MMAgency.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMTransitSystem.h"

@interface MMTransitSystem ()

@property (nonatomic, strong) NSDictionary *supportedSystem;

@end

@implementation MMTransitSystem


- (MMTransitSystem *) initWithSupportedSystemDictionary:(NSDictionary *)supportedSystem {
    self = [super init];

    if (self != nil) {
        _supportedSystem = supportedSystem;
    }

    return self;
}

-(NSArray *)getSourceForType: (sourceType) sourceType {
// If the supported system has no more than three entries, there are no optional source overrides, so return the default.
    if ([_supportedSystem count] <= 3) {
        return [_supportedSystem objectForKey:@"defaultSource"];
    }

    NSString *sourceKey;

    switch (sourceType) {
        case defaultSource:
            sourceKey = @"defaultSource";
            break;
        case nameSource:
            sourceKey = @"nameSource";
            break;
        case boundBoxSource:
            sourceKey = @"boundBoxSource";
            break;
        case realTimeSource:
            sourceKey = @"realTimeSource";
            break;
        case stopsSource:
            sourceKey = @"stopsSource";
            break;
        case routePolygonSource: 
            sourceKey = @"routePolygonSource";
            break;
        case timeZoneSource: 
            sourceKey = @"timeZoneSource";
            break;
        case scheduleSource: 
            sourceKey = @"scheduleSource";
            break;
        default:
            sourceKey = @"defaultSource";
            break;
    }

    NSArray *requestedResult = [_supportedSystem objectForKey:sourceKey];

    if (requestedResult == nil) {
        requestedResult = [_supportedSystem objectForKey:@"defaultSource"];
    }


    return requestedResult;

}

@end
