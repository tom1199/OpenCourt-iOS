
#import <Foundation/Foundation.h>
#import "TBQuadTree.h"
#import <MapKit/MapKit.h>

@interface OCCoordinateQuadTree : NSObject

@property (assign, nonatomic) TBQuadTreeNode* root;
@property (strong, nonatomic) MKMapView *mapView;

- (void)buildTreeWithData:(NSArray *)data;
- (NSArray *)clusteredAnnotationsWithinMapRect:(MKMapRect)rect withZoomScale:(double)zoomScale;

@end
