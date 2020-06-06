//
//  PlacesTableViewController.m
//  Whereis
//
//  Created by Innocent Magagula on 2020/06/06.
//  Copyright © 2020 Innocent Magagula. All rights reserved.
//

#import "PlacesTableViewController.h"
#import <os/log.h>

@interface PlacesTableViewController () 
@property (nonatomic,nonatomic)NSArray<MKMapItem *> *matchingPlaces;
@property (nonatomic,nonatomic)MKLocalSearchRequest *request;
@end

@implementation PlacesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.matchingPlaces = [[NSArray alloc] init];
    self.request = [[MKLocalSearchRequest alloc] init];
    CLLocationCoordinate2D coordinates = {.latitude = -26.270760, .longitude = 28.112268};
    MKCoordinateSpan span = {.latitudeDelta = 5.0f, .longitudeDelta = 5.0f};
    MKCoordinateRegion region = {coordinates, span};
    self.request.region = region;
}

#pragma mark - result updating delegate
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    self.request.naturalLanguageQuery = searchController.searchBar.text;
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:self.request];
    __weak __typeof__(self) weakSelf = self;
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
        __typeof__(self) strongSelf = weakSelf;
        strongSelf.matchingPlaces = response.mapItems;
        [strongSelf.tableView reloadData];
    }];
    os_log(OS_LOG_DEFAULT, "%@", searchController.searchBar.text);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.matchingPlaces.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    MKPlacemark *item = self.matchingPlaces[indexPath.row].placemark;
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = [self parseAddress:item];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MKPlacemark *item = self.matchingPlaces[indexPath.row].placemark;
    [_delegate didSelectAddress:item];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSString *)parseAddress:(MKPlacemark *)placemark {
    // put a space between "4" and "Melrose Place"
    NSString *firstSpace = (placemark.subThoroughfare && placemark.thoroughfare) ? @" " : @"";
    // put a comma between street and city/state
    NSString *comma = (placemark.subThoroughfare || placemark.thoroughfare) &&
    (placemark.subAdministrativeArea || placemark.administrativeArea ) ? @" " : @"";
    // put a space between "Washington" and "DC"
    NSString *secondSpace = (placemark.subAdministrativeArea &&
                             placemark.administrativeArea) ? @" " : @"";

    NSString *address = [[NSString alloc] initWithFormat: @"%@%@%@%@%@%@%@",
                         // street number
                         placemark.subThoroughfare,
                         firstSpace,
                         // street name
                         placemark.thoroughfare,
                         comma,
                         // city
                         placemark.locality,
                         secondSpace,
                         // state
                         placemark.administrativeArea];
    return address;
}

@end
