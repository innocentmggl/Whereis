//
//  ViewController.m
//  Whereis
//
//  Created by Innocent Magagula on 2020/06/06.
//  Copyright © 2020 Innocent Magagula. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <os/log.h>
#import "PlacesTableViewController.h"
#import "MapSearchResult.h"

//TODO:- add architecture, location streaming via socket, 
@interface ViewController () <CLLocationManagerDelegate, UISearchControllerDelegate, UISearchBarDelegate, MapSearchResults, MKMapViewDelegate>
@property (nonatomic, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic,strong)CLLocationManager *locationManager;
@property (nonatomic,strong)MKPointAnnotation *annotation;
@property (nonatomic,strong)UISearchController *searchController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationBar];
    [self configureMapView];
    [self initLocation];
}

- (void)configureNavigationBar {
    [self setTitle:@"Where"];
    [self configureSearchController];
}

- (void)configureMapView {
    _mapView.delegate = self;
    _annotation = [[MKPointAnnotation alloc] init];
    [self setMapViewRegion];
    [self.mapView addAnnotation:self.annotation];
}

- (void)configureSearchController {
    PlacesTableViewController *viewController = [self createSearchResultController];
    viewController.delegate = self;
    _searchController = [[UISearchController alloc] initWithSearchResultsController:viewController];
    _searchController.delegate = self;
    _searchController.searchResultsUpdater = viewController;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = YES;
    _searchController.searchBar.placeholder = @"Search...";
    self.definesPresentationContext = YES;
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
    } else {
        self.navigationItem.titleView = self.searchController.searchBar;
    }
}

- (PlacesTableViewController *)createSearchResultController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PlacesTableViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"PlacesTableViewController"];
    return viewController;
}

-(void) initLocation {
    // Create a location manager
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    // Set a delegate to receive location callbacks
    _locationManager.delegate = self;

    if ([CLLocationManager locationServicesEnabled]) {
        os_log(OS_LOG_DEFAULT, "Location Services not enabled");
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusNotDetermined:
                [self.locationManager requestAlwaysAuthorization];
                break;
            case kCLAuthorizationStatusDenied:
                os_log_debug(OS_LOG_DEFAULT, "Location Services denied");
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                os_log_debug(OS_LOG_DEFAULT, "Location Services allowed");
                [self.locationManager startUpdatingLocation];
                break;
            case kCLAuthorizationStatusRestricted:
                os_log_error(OS_LOG_DEFAULT, "Location Services restricted");
                break;
        }
    }
    else{
        os_log_debug(OS_LOG_DEFAULT, "Location Services not enabled");
    }
}

-(void) setMapViewRegion {
    CLLocationCoordinate2D coordinates = {.latitude = -26.270760, .longitude = 28.112268};
    MKCoordinateSpan span = {.latitudeDelta = 1.0f, .longitudeDelta = 1.0f};
    MKCoordinateRegion region = {coordinates, span};
    [self.mapView setRegion:region];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    //we are only interested in the last location
    CLLocation *currentLocation = [locations lastObject];
    [self updateCurrentLocationPin:currentLocation];
    os_log_debug(OS_LOG_DEFAULT, "Location updated");
}

-(void) updateCurrentLocationPin:(CLLocation *)location {
    [UIView animateWithDuration:1.0 delay:0.0f options:(UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        [self.annotation setCoordinate:location.coordinate];
    } completion:^(BOOL finished){
        os_log_debug(OS_LOG_DEFAULT, "Finished: %d", finished);
    }];
}

//search results delegaye
- (void)didSelectAddress:(MKPlacemark *)address {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    NSMutableArray<MKPointAnnotation *> *annotations = [[NSMutableArray alloc] init];
    //destination
    MKPointAnnotation *destination = [[MKPointAnnotation alloc] init];
    [destination setCoordinate:address.coordinate];
    [annotations addObject:self.annotation];
    [annotations addObject:destination];
    [self.mapView showAnnotations:annotations animated:YES];
    [self drawRoute:self.annotation.coordinate toLocation:address.coordinate];
}

//TODO: - refactor this mess
- (void)drawRoute:(CLLocationCoordinate2D)fromLocation toLocation:(CLLocationCoordinate2D)toLocation
{
    MKPlacemark *source = [[MKPlacemark alloc]initWithCoordinate:fromLocation
                                               addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"", nil]];
    MKMapItem *srcMapItem = [[MKMapItem alloc]initWithPlacemark:source];
    [srcMapItem setName:@"Source"];

    MKPlacemark *destination = [[MKPlacemark alloc]initWithCoordinate:toLocation
                                                    addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"", nil]];
    MKMapItem *distMapItem = [[MKMapItem alloc]initWithPlacemark:destination];
    [distMapItem setName:@"Destination"];

    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    [request setSource:srcMapItem];
    [request setDestination:distMapItem];
    [request setTransportType:MKDirectionsTransportTypeAutomobile];

    MKDirections *direction = [[MKDirections alloc]initWithRequest:request];
    os_log_debug(OS_LOG_DEFAULT, "Draw route");
    __weak __typeof__(self) weakSelf = self;
    [direction calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error)
    {
        os_log_debug(OS_LOG_DEFAULT, "Response = %@", response);
        os_log_debug(OS_LOG_DEFAULT, "Error = %@", error);

        NSArray *arrRoutes = [response routes];
        if (arrRoutes.count == 0)
        {
            os_log_debug(OS_LOG_DEFAULT, "No route found for current destination");
        }
        else
        {
            [arrRoutes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
            {
                __typeof__(self) strongSelf = weakSelf;
                MKRoute *route = obj;
                MKPolyline *line = [route polyline];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.mapView addOverlay:line];
                });
                os_log_debug(OS_LOG_DEFAULT, "Route name: %@", route.name);
                os_log_debug(OS_LOG_DEFAULT, "Total Distance (in Meters) :%f", route.distance);
                NSArray *steps = [route steps];
                os_log_debug(OS_LOG_DEFAULT, "Total Steps : %lu", [steps count]);
                [steps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
                {
                    //NSLog(@"Rout Instruction : %@",[obj instructions]);
                }];
            }];
        }
    }];

}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKGeodesicPolyline *overlayRender = ((MKGeodesicPolyline *)overlay);
    if(overlayRender){
        MKPolylineRenderer *lineRender = [[MKPolylineRenderer alloc] initWithPolyline:overlayRender];
        lineRender.lineWidth = 3;
        lineRender.strokeColor = UIColor.blueColor;
        return lineRender;
    }

    MKTileOverlay *overlayTile = ((MKTileOverlay *)overlay);
    if(overlayTile){
        MKTileOverlayRenderer *lineRender = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlayTile];
        return lineRender;
    }

    MKOverlayRenderer *defaultRender = [[MKOverlayRenderer alloc] initWithOverlay:overlay];
    return defaultRender;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *annView=[[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"pin"];
    if([annotation isEqual:self.annotation]){
        annView.pinTintColor = MKPinAnnotationView.greenPinColor;
    }
    return annView;
}

@end
