//
//  PlacesTableViewController.h
//  Whereis
//
//  Created by Innocent Magagula on 2020/06/06.
//  Copyright © 2020 Innocent Magagula. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapSearchResult.h"

@interface PlacesTableViewController : UITableViewController <UISearchResultsUpdating>
@property (nonatomic, weak) id<MapSearchResults> delegate;
@end
