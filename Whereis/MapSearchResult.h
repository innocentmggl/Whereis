//
//  MapSearchResult.h
//  Whereis
//
//  Created by Innocent Magagula on 2020/06/06.
//  Copyright © 2020 Innocent Magagula. All rights reserved.
//

#ifndef MapSearchResult_h
#define MapSearchResult_h
#import <MapKit/MapKit.h>

@protocol MapSearchResults <NSObject>
@required
- (void)didSelectAddress:(MKPlacemark *)address;
@end

#endif /* MapSearchResult_h */
