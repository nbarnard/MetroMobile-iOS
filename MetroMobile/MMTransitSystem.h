//
//  MMAgency.h
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMTransitSystem : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *nameSource;
@property (nonatomic, strong) NSString *boundBoxSource;
@property (nonatomic, strong) NSString *realTimeSource;
@property (nonatomic, strong) NSString *stopsSource;
@property (nonatomic, strong) NSString *routePolygonSource;
@property (nonatomic, strong) NSArray *sourceIDs;

-(MMTransitSystem *)initWithName: (NSString *) name andNameSource: (NSString *) nameSource andBoundBoxSource: (NSString *) boundBoxSource andRealTimeSource: (NSString *) realTimeSource andStopsSource: (NSString *) stopsSource andRoutePolygonSource: (NSString *) routePolygonSource andSourceIDs: (NSArray *) sourceIDs;


@end
