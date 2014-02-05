//
//  MMAgency.h
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MMTransitSystem : NSObject

// Information that in specific to the transit agency
@property (nonatomic, strong) NSString *name;
@property (nonatomic) MKCoordinateRegion coveredArea;
@property (nonatomic, strong) NSString *timeZone;

// Sources of data on the internet for this agency
@property (nonatomic, strong) NSArray *sourceIDs;

// Defines from which sources we're loading specific data
@property (nonatomic, strong) NSString *nameSource;
@property (nonatomic, strong) NSString *timeZoneSource;
@property (nonatomic, strong) NSString *boundBoxSource;
@property (nonatomic, strong) NSString *realTimeSource;
@property (nonatomic, strong) NSString *stopsSource;
@property (nonatomic, strong) NSString *routePolygonSource;

-(MMTransitSystem *)initWithName: (NSString *) name andNameSource: (NSString *) nameSource andTZSource: (NSString *) timeZoneSource andBoundBoxSource: (NSString *) boundBoxSource andRealTimeSource: (NSString *) realTimeSource andStopsSource: (NSString *) stopsSource andRoutePolygonSource: (NSString *) routePolygonSource andSourceIDs: (NSArray *) sourceIDs;

@end
