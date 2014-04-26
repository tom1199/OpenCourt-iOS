//
//  NSObject+MKMapView_ZoomLevel.h
//  SD3
//
//  Created by iamaun on 10/4/55 BE.
//
//

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)
{
    
}
- (double)getZoomLevel;
- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;
@end
