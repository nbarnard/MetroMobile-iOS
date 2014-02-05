//
//  MMDataController.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMDataController.h"
#import "MMTransitSystem.h"
#import "MMNetworkController.h"
#import "OneBusAwayKey.h"

@interface MMDataController ()

@property (strong, nonatomic) NSOperationQueue *fetchQueue;

@end


@implementation MMDataController

+ (MMDataController *) shared {

    static dispatch_once_t pred;
    static MMDataController *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[MMDataController alloc] init];
        shared.fetchQueue = [NSOperationQueue new];
        [shared.fetchQueue addOperationWithBlock:^{
            [shared populateTransitSystems];
            [shared populateNameAndCoveredAreaAndTZ];
        }];
    });

    return shared;
}

-(void) populateTransitSystems {
    NSString *transitSystemsPlist = [[NSBundle mainBundle] pathForResource:@"SupportedTransitSystems" ofType:@"plist"];
    NSArray *rawSystems = [[NSArray alloc] initWithContentsOfFile:transitSystemsPlist];

    NSMutableSet *systems = [NSMutableSet new];
    NSMutableSet *hosts = [NSMutableSet new];
    NSMutableSet *dataSources = [NSMutableSet new];

    for (NSDictionary *rawSystem in rawSystems) {
        NSArray *rawSources = [rawSystem objectForKey:@"sources"];
        NSMutableArray *sourceIDs = [NSMutableArray new];

        for (NSDictionary *rawSource in rawSources) {
            NSString *rawHost = [rawSource objectForKey:@"host"];
            [hosts addObject:rawHost];

            NSString *rawSourceID = [rawSource objectForKey:@"id"];
            [sourceIDs addObject:rawSourceID];

            [dataSources addObject:rawSource];
        }

        MMTransitSystem *newSystem = [[MMTransitSystem alloc] initWithName: [rawSystem objectForKey:@"readableName"]
                                                             andNameSource: [rawSystem objectForKey:@"name"]
                                                               andTZSource: [rawSystem objectForKey:@"tz"]
                                                         andBoundBoxSource: [rawSystem objectForKey:@"boundbox"]
                                                         andRealTimeSource: [rawSystem objectForKey:@"realtime"]
                                                            andStopsSource: [rawSystem objectForKey:@"stops"]
                                                     andRoutePolygonSource: [rawSystem objectForKey:@"routepolygon"]
                                                              andSourceIDs: [[NSArray alloc] initWithArray:sourceIDs]];
        [systems addObject:newSystem];
    }
    
    _systems = [[NSSet alloc] initWithSet:systems];
    _hosts = [[NSSet alloc] initWithSet:hosts];
    _dataSources = [[NSSet alloc] initWithSet:dataSources];

}

-(void) populateNameAndCoveredAreaAndTZ {

    MMNetworkController *networkController = [MMNetworkController sharedController];

    for (MMTransitSystem *currentsystem in _systems) {
        currentsystem.coveredArea = [networkController getBoundBoxForSystem:currentsystem withDataSources:_dataSources];
        currentsystem.name = [networkController getStringKey: @"name" ForSystem:currentsystem withDataSources:_dataSources];
        NSLog(@"%@",currentsystem.name);
        currentsystem.timeZone = [networkController getStringKey:@"timezone" ForSystem:currentsystem withDataSources:_dataSources];
        NSLog(@"%@",currentsystem.timeZone);
    }

}


@end
