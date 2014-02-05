//
//  MMAgency.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMTransitSystem.h"

@implementation MMTransitSystem

-(MMTransitSystem *)initWithName: (NSString *) name andNameSource: (NSString *) nameSource andBoundBoxSource: (NSString *) boundBoxSource andRealTimeSource: (NSString *) realTimeSource andStopsSource: (NSString *) stopsSource andRoutePolygonSource: (NSString *) routePolygonSource andSourceIDs: (NSArray *) sourceIDs; {
    self = [super init];

    if (self != nil) {
        _name = name;
        _nameSource = nameSource;
        _boundBoxSource = boundBoxSource;
        _realTimeSource = realTimeSource;
        _stopsSource = stopsSource;
        _routePolygonSource = routePolygonSource;
        _sourceIDs = sourceIDs;
    }
    return self;
}

@end
