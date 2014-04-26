//
//  ClusterMapViewController.h
//  OpenCourt
//
//  Created by TH Tom on 14/1/14.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AddCourtViewController.h"

@interface ClusterMapViewController : UIViewController
<MKMapViewDelegate,
UIAlertViewDelegate,
AddCourtViewControllerDelegate>
{
    NSString *puTableViewHighlight;
}

@property (nonatomic, strong) IBOutlet MKMapView *mapView;

- (IBAction)refreshButtonPressed:(id)sender;

- (void)reloadData;

@end
