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

typedef enum sourceTypes {
    defaultSource = 0,
    nameSource = 1,
    boundBoxSource = 2,
    realTimeSource = 3,
    stopsSource = 4,
    routePolygonSource = 5,
    timeZoneSource = 6,
    scheduleSource = 7
} sourceType;


// Information that in specific to the transit agency
@property (nonatomic, strong) NSString *name;
@property (nonatomic) MKCoordinateRegion coveredArea;
@property (nonatomic, strong) NSString *timeZone;

// Sources of data on the internet for this agency
@property (nonatomic, strong) NSArray *sourceIDs;

-(MMTransitSystem *)initWithSupportedSystemDictionary: (NSDictionary *) supportedSystem;

-(NSArray *)getSourceForType: (sourceType) sourceType;



@end
