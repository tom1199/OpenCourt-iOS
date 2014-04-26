//
//  ClusterMapViewController.m
//  OpenCourt
//
//  Created by TH Tom on 14/1/14.
//

#import "ClusterMapViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

#import "OCLocationManager.h"
#import "OCCoordinateQuadTree.h"
#import "OCClusterAnnotation.h"
#import "OCDataManager.h"
#import "OCClusterAnnotationView.h"

#import "Court.h"

#import "UIColor+OCColor.h"
#import "MKMapView+ZoomLevel.h"

typedef NS_ENUM(NSUInteger, MapViewAlertViewTag) {
    kMapViewAlertTryReload
};

typedef NS_ENUM(NSUInteger, MapViewViewTag) {
    kMapViewViewTagAnnotationLeftAccessory,
    kMapViewViewTagAnnotationRightAccessory
};

@interface ClusterMapViewController ()

@property (strong, nonatomic) OCCoordinateQuadTree *coordinateQuadTree;

@property (nonatomic, strong) NSArray *courtDataSource;              //all courts data from server
@property (nonatomic, strong) NSArray *clusteredCourtDataSource;     //malls been clustered in cluster

@property (nonatomic, strong) OCClusterAnnotation *addedNewCourtMarker;

@end


static NSString *const AddNewLocationSegue = @"AddCourtSegue";

static NSString *const FadeInAnimation  = @"fadeIn";
static NSString *const FadeOutAnimation  =  @"fadeOut";

@implementation ClusterMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //== ถ้าผู้ใช้งาน tap ค้างไว้บนแผนที่ 5 วินาที จะ Drop Pin ลงมาเพื่อให้เพิ่มข้อมูล ======
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.5;
    [self.mapView addGestureRecognizer:lpgr];
    
    [self loadNearbyCourts];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:AddNewLocationSegue]) {
        UINavigationController *nav = segue.destinationViewController;
        AddCourtViewController *addNewCourtViewController = (AddCourtViewController *)nav.topViewController;
        addNewCourtViewController.delegate = self;
        
        Court *newCourt = sender;
        addNewCourtViewController.court = newCourt;
    }
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:AddNewLocationSegue]) {
        Court *newCourt = sender;
        if (!newCourt.address || !newCourt.location) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Actions

- (IBAction)refreshButtonPressed:(id)sender {
    [self reloadData];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    //remove previous added new lcoation if there is one
    if (self.addedNewCourtMarker) {
        [self.mapView removeAnnotation:self.addedNewCourtMarker];
        self.addedNewCourtMarker = nil;
    }
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    //==============create annotation
    OCClusterAnnotation *marker = [[OCClusterAnnotation alloc]init];
    marker.title = @"Add new location";
    marker.coordinate = touchMapCoordinate;
    marker.subtitle = @"loading...";
    marker.isAddNewMarker = YES;
    
    //NOTE: don't add it to clusterer, cause we don want it to be managed by clusterer
    //instead, add it to mapview directly
    
    self.addedNewCourtMarker = marker;
    
    [self.mapView addAnnotation:marker];
    
    //-- update it location info
    CLLocation *touchlc = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:touchlc completionHandler:^(NSArray *placemarks, NSError *error)
     {
         for (CLPlacemark *placemark in placemarks) {
             [marker setSubtitle:placemark.name];
         }
     }];
}

#pragma mark - Data loader

- (void)loadNearbyCourts {
    
    double distanceThreshold = 50.0f; // in kilometers
    CLLocation *currentUserLocation = [OCLocationManager defaultManager].location;
    
    [OCDataManager nearbyCourtsWithCurrentCoordinate:currentUserLocation.coordinate
                                      withinDistance:distanceThreshold
                                      withCompletion:^(NSError *error, NSArray *courts) {
                                          if (!error) {
                                              self.courtDataSource = courts;
                                              
                                              NSMutableSet *allAnnotations = [NSMutableSet setWithArray:self.mapView.annotations];
                                              [allAnnotations removeObject:self.mapView.userLocation];
                                              [self.mapView removeAnnotations:allAnnotations.allObjects];
                                              
                                              if(self.courtDataSource.count < 1){
                                                  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Data not found", nil)
                                                                                                      message:NSLocalizedString(@"Result NOT found.", nil)
                                                                                                     delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Try Again!",nil), nil];
                                                  alertView.tag = kMapViewAlertTryReload;
                                                  [alertView show];
                                              }
                                              
                                              //setup quadtree system
                                              self.coordinateQuadTree = [[OCCoordinateQuadTree alloc] init];
                                              self.coordinateQuadTree.mapView = self.mapView;
                                              [self.coordinateQuadTree buildTreeWithData:self.courtDataSource];
                                              [self mapView:self.mapView regionDidChangeAnimated:YES];
                                              
                                              [self zoomToAnnotationsBounds:self.mapView.annotations];
                                              
                                              [self.mapView  setUserInteractionEnabled:YES];
                                              
                                          }else {
                                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Operation Fail", nil)
                                                                                                  message:NSLocalizedString(@"Unable to load data.", nil)
                                                                                                 delegate:self
                                                                                        cancelButtonTitle:nil
                                                                                        otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Try Again!",nil), nil];
                                              [alertView show];
                                          }
                                      }];
}



- (void)reloadData {
    [self loadNearbyCourts];
}

#pragma mark - Helper

- (void)setLatitude:(double)latitude longitude:(double)longitude delta:(double)delta
{
    MKCoordinateRegion newRegion;
    newRegion.center.latitude = latitude;
    newRegion.center.longitude = longitude;
    newRegion.span.latitudeDelta = delta;
    newRegion.span.longitudeDelta = delta;
    [self.mapView setRegion:newRegion animated:YES];
}

- (void)zoomToAnnotationsBounds:(NSArray *)annotations
{
    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;
    
    for (id<MKAnnotation>annotation in annotations) {
        CGFloat annotationLat = annotation.coordinate.latitude;
        CGFloat annotationLong = annotation.coordinate.longitude;
        if (annotationLat == 0 && annotationLong == 0)
            continue;
        minLatitude = fmin(annotationLat, minLatitude);
        maxLatitude = fmax(annotationLat, maxLatitude);
        minLongitude = fmin(annotationLong, minLongitude);
        maxLongitude = fmax(annotationLong, maxLongitude);
    }
    
    // See function below
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
    
    // If your markers were 40 in height and 20 in width, this would zoom the map to fit them perfectly. Note that there is a bug in mkmapview's set region which means it will snap the map to the nearest whole zoom level, so you will rarely get a perfect fit. But this will ensure a minimum padding.
    UIEdgeInsets mapPadding = UIEdgeInsetsMake(40.0, 10.0, 40.0, 10.0);
    CLLocationCoordinate2D relativeFromCoord = [self.mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:self.mapView];
    
    // Calculate the additional lat/long required at the current zoom level to add the padding
    CLLocationCoordinate2D topCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.top) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D rightCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.right) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D bottomCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.bottom) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D leftCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.left) toCoordinateFromView:self.mapView];
    
    CGFloat latitudeSpanToBeAddedToTop = relativeFromCoord.latitude - topCoord.latitude;
    CGFloat longitudeSpanToBeAddedToRight = relativeFromCoord.latitude - rightCoord.latitude;
    CGFloat latitudeSpanToBeAddedToBottom = relativeFromCoord.latitude - bottomCoord.latitude;
    CGFloat longitudeSpanToBeAddedToLeft = relativeFromCoord.latitude - leftCoord.latitude;
    
    maxLatitude = maxLatitude + latitudeSpanToBeAddedToTop;
    minLatitude = minLatitude - latitudeSpanToBeAddedToBottom;
    
    maxLongitude = maxLongitude + longitudeSpanToBeAddedToRight;
    minLongitude = minLongitude - longitudeSpanToBeAddedToLeft;
    
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
}

- (void)setMapRegionForMinLat:(CGFloat)minLatitude minLong:(CGFloat)minLongitude maxLat:(CGFloat)maxLatitude maxLong:(CGFloat)maxLongitude
{
    MKCoordinateRegion region;
    region.center.latitude = (minLatitude + maxLatitude) / 2;
    region.center.longitude = (minLongitude + maxLongitude) / 2;
    region.span.latitudeDelta = (maxLatitude - minLatitude);
    region.span.longitudeDelta = (maxLongitude - minLongitude);
    
    if (region.span.latitudeDelta < 0.059863)
        region.span.latitudeDelta = 0.059863;
    
    if (region.span.longitudeDelta < 0.059863)
        region.span.longitudeDelta = 0.059863;
    
    // MKMapView BUG: this snaps to the nearest whole zoom level, which is wrong- it doesn't respect the exact region you asked for. See http://stackoverflow.com/questions/1383296/why-mkmapview-region-is-different-than-requested
    //
    if ((region.center.latitude >= -90) && (region.center.latitude <= 90) && (region.center.longitude >= -180) && (region.center.longitude <= 180)) {
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    }
}

- (void)moveToCurrenLocation
{
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate zoomLevel:13 animated:YES];
}

- (NSString *)distanceTextRepresentationForDistance:(float)distance {
    if (distance < 1000) {
        return [NSString stringWithFormat:@"%.0fm", distance];
    }else {
        distance = distance/1000;
        if (distance > 99) {
            return [NSString stringWithFormat:@">99km"];
        }else {
            return [NSString stringWithFormat:@"%.1fkm",distance];
        }
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [[NSOperationQueue new] addOperationWithBlock:^{
        double scale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
        NSArray *annotations = [self.coordinateQuadTree clusteredAnnotationsWithinMapRect:mapView.visibleMapRect withZoomScale:scale];
        
        [self updateMapViewAnnotationsWithAnnotations:annotations];
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (annotation == mapView.userLocation) {
        return nil;
    }
    
    static NSString *const TBAnnotatioViewReuseID = @"TBAnnotatioViewReuseID";
    
    OCClusterAnnotationView *annotationView = (OCClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:TBAnnotatioViewReuseID];
    
    if (!annotationView) {
        annotationView = [[OCClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:TBAnnotatioViewReuseID];
    }
    
    NSInteger objectCount = [(OCClusterAnnotation *)annotation count];
    
    //it is clusterer
    if (objectCount > 1) {
        annotationView.filledColor = [UIColor ocClusteredAnnotationViewFilledColor];
        annotationView.innerStrokeColor = [UIColor ocClusteredAnnotationViewInnerStrikeColor];
        annotationView.count = objectCount;
        
        annotationView.canShowCallout = NO;
        
    //single object
    }else {
        Court *data = nil;
        if ([annotation isKindOfClass:[OCClusterAnnotation class]]) {
            data = [[(OCClusterAnnotation *)annotation clusteredObjects]firstObject];
        }
        
        //determine marker type
        annotationView.canShowCallout = YES;
        if ([(OCClusterAnnotation *)annotation isAddNewMarker]) {
            annotationView.filledColor = [UIColor ocNewItemAnnotationViewFilledColor];
            annotationView.innerStrokeColor = [UIColor ocNewItemAnnotationViewInnerStrikeColor];
            annotationView.titleText = @"?";
        }else {
            annotationView.filledColor = [UIColor ocClusteredAnnotationViewFilledColor];
            annotationView.innerStrokeColor = [UIColor ocClusteredAnnotationViewInnerStrikeColor];
            annotationView.titleText = @"B";
        }
        
        //callout accessary button
        UIButton *navgationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        //navgationButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        //navgationButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        
        CGFloat imageViewWidthHeight;
        CGFloat distanceLabelHeight;
        CGFloat imageViewOriginY;
        if (!SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            navgationButton.frame = CGRectMake(0, 0, 44, 45);
            navgationButton.backgroundColor = [UIColor lightGrayColor];
            
            imageViewWidthHeight = 22.0f;
            distanceLabelHeight = 15;
            imageViewOriginY = 6;
        }else {
            navgationButton.frame = CGRectMake(0, 0, 30, 30);
            navgationButton.backgroundColor = [UIColor clearColor];
            
            imageViewWidthHeight = 20.0f;
            distanceLabelHeight = 14;
            imageViewOriginY = 0;
        }
        
        CGRect imageViewRect = CGRectMake((CGRectGetWidth(navgationButton.frame) - imageViewWidthHeight)/2,
                                          imageViewOriginY,
                                          imageViewWidthHeight,
                                          imageViewWidthHeight);
        UIImageView *buttonImageView = [[UIImageView alloc]initWithFrame:imageViewRect];
        buttonImageView.contentMode = UIViewContentModeScaleAspectFill;
        buttonImageView.backgroundColor = [UIColor clearColor];
        //buttonImageView.image = [UIImage imagewith];
        
        UILabel *distanceLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,
                                                                          CGRectGetMaxY(imageViewRect),
                                                                          CGRectGetWidth(navgationButton.frame),
                                                                          distanceLabelHeight)];
        distanceLabel.textAlignment = NSTextAlignmentCenter;
        distanceLabel.minimumScaleFactor = 0.8;
        distanceLabel.textColor = [UIColor whiteColor];
        distanceLabel.backgroundColor = [UIColor clearColor];
        distanceLabel.font = [UIFont systemFontOfSize:10];
        
        CLLocation *pinLocation = [[CLLocation alloc]initWithLatitude:[(OCClusterAnnotation *)annotation coordinate].latitude longitude:[(OCClusterAnnotation *)annotation coordinate].longitude];
        CLLocationDistance distance = [self.mapView.userLocation.location distanceFromLocation:pinLocation];
        distanceLabel.text = [self distanceTextRepresentationForDistance:distance];
        
        [navgationButton addSubview:buttonImageView];
        [navgationButton addSubview:distanceLabel];
        navgationButton.tag = kMapViewViewTagAnnotationLeftAccessory;
        
        annotationView.leftCalloutAccessoryView = navgationButton;
        annotationView.leftCalloutAccessoryView.contentMode = UIViewContentModeCenter;
        
        UIButton *detailButton = [UIButton buttonWithType: UIButtonTypeDetailDisclosure];
        detailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        detailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        detailButton.tag = kMapViewViewTagAnnotationRightAccessory;
        annotationView.rightCalloutAccessoryView = detailButton;

    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    
    for (UIView *view in views) {
        if ([[(MKAnnotationView *)view annotation] isKindOfClass:[MKUserLocation class]]) {
            continue;
        }
        
        [self addFadeInAnimationToView:view];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    OCClusterAnnotation *annotation = view.annotation;
    if ([annotation isKindOfClass:[MKUserLocation class]]) return;
    if (annotation.isAddNewMarker) return;    //user added new location
    
    BOOL isCluster = annotation.count > 1;
    if (isCluster) {
        
        [mapView deselectAnnotation:annotation animated:NO];
        
        self.clusteredCourtDataSource = annotation.clusteredObjects;
        
        //show popover list veiw
        
    }

}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    OCClusterAnnotation *annotation = view.annotation;
    if ([annotation isKindOfClass:[MKUserLocation class]]) return;
    
    //user added new location, it is not managed by clusterer
    if (annotation.isAddNewMarker == YES) {
        
        Court *newCourt = [[Court alloc]init];
        newCourt.address = annotation.subtitle;
        newCourt.location  = [PFGeoPoint geoPointWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
        
        //push in add new location vc ......
        [self performSegueWithIdentifier:AddNewLocationSegue sender:newCourt];
        
    }else {
        
        BOOL isCluster = annotation.clusteredObjects.count > 1;
        
        if (!isCluster)
        {
            Court *court = annotation.clusteredObjects.lastObject;
            if (control.tag == kMapViewViewTagAnnotationLeftAccessory) {    //navigation button pressed
                
                PFGeoPoint *point = court.location;
                
                //open direction for given geo location
                
            }else { //object detail button pressed
                

                //open court detail info
                
            }
        }
        
    }
    
}

#define AnimationDurantion  0.3f

- (void)addFadeInAnimationToView:(UIView *)view {
    
    view.alpha = 0;
    CGFloat randomDelay = arc4random() % 2;
    randomDelay /= 10;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:AnimationDurantion];
    [UIView setAnimationDelay:randomDelay];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    
    view.alpha = 1;

    [UIView commitAnimations];

}

- (void)removeAnnotation:(id<MKAnnotation>)annotation {
    
    MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation];
    
    annotationView.alpha = 1;
    CGFloat randomDelay = arc4random() % 2;
    randomDelay /= 10;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:AnimationDurantion];
    [UIView setAnimationDelay:randomDelay];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    
    annotationView.alpha = 0;
    
    [UIView commitAnimations];
}

- (void)addBounceAnnimationToView:(UIView *)view
{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.values = @[@(0.05), @(1.1), @(0.9), @(1)];
    
    bounceAnimation.duration = 0.6;
    NSMutableArray *timingFunctions = [[NSMutableArray alloc] initWithCapacity:bounceAnimation.values.count];
    for (NSUInteger i = 0; i < bounceAnimation.values.count; i++) {
        [timingFunctions addObject:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    [bounceAnimation setTimingFunctions:timingFunctions.copy];
    bounceAnimation.removedOnCompletion = NO;
    
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations
{
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
    [before removeObject:[self.mapView userLocation]];
    NSSet *after = [NSSet setWithArray:annotations];
    
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.mapView addAnnotations:[toAdd allObjects]];
        
        [self.mapView removeAnnotations:[toRemove allObjects]];
//        [toRemove enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
//            [self removeAnnotation:obj];
//            //[self.mapView removeAnnotation:obj];
//        }];
    }];
}

#pragma mark - AddCourtViewControllerDelegate

- (void)addCourtViewControllerDidCancel:(AddCourtViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addCourtViewController:(AddCourtViewController *)controller didAddNewCourt:(Court *)court {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self reloadData];
}

#pragma mark - UIAleartView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kMapViewAlertTryReload:
        {
            switch (buttonIndex)
            {
                case 1:
                {
                    [self reloadData];
                    break;
                }
                default:
                    break;
            }
        }
            break;
        default:
            break;
    }
}

@end
