//
//  MMDataController.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMDataController.h"
#import "MMNetworkController.h"
#import "MMFullModel.h"
#import "OneBusAwayKey.h"

@interface MMDataController ()

@property (strong, nonatomic) NSOperationQueue *fetchQueue;

@end


@implementation MMDataController

+ (MMDataController *) sharedController {

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

        MMTransitSystem *newSystem = [[MMTransitSystem alloc] initWithSupportedSystemDictionary:rawSystem];

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
        currentsystem.name = [networkController getStringforUniqueDataPoint:systemName ForSystem:currentsystem withDataSources:_dataSources];
        currentsystem.timeZone = [networkController getStringforUniqueDataPoint:systemTimeZone ForSystem:currentsystem withDataSources:_dataSources];
    }


}

- (void) getStopsForCLLocation: (CLLocation *) location {
    MMNetworkController *networkController = [MMNetworkController sharedController];

    MKMapPoint locationPoint = MKMapPointForCoordinate(location.coordinate);

    __block NSMutableSet *systemsToCheck = [NSMutableSet new];

    [_systems enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        MMTransitSystem *currentSystem = (MMTransitSystem *)obj;
        if(MKMapRectContainsPoint(currentSystem.coveredArea, locationPoint)) {
            [systemsToCheck addObject:currentSystem];
            NSLog(@"%@", currentSystem.name);
        }
    }];

    [networkController getRoutesForSystems:systemsToCheck atPoint:locationPoint withDataSources:_dataSources];
// Register a notification here.
    
}


@end
