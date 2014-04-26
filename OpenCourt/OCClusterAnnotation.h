


#import <MapKit/MapKit.h>

@interface OCClusterAnnotation : NSObject <MKAnnotation>

@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *subtitle;
@property (assign, nonatomic) NSInteger count;

@property (nonatomic, readwrite) BOOL isAddNewMarker;

@property (nonatomic, strong) NSArray *clusteredObjects;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate count:(NSInteger)count;

@end
