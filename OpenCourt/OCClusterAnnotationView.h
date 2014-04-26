//
//  OCClusterAnnotationView
//  OpenCourt
//
//  Created by TH Tom on 14/1/14.
//

#import <MapKit/MapKit.h>

@interface OCClusterAnnotationView : MKAnnotationView

@property (assign, nonatomic) NSUInteger count;
@property (nonatomic, strong) NSString *titleText;

//Appearience
@property (nonatomic, strong) UIColor *innerStrokeColor;
@property (nonatomic, strong) UIColor *outerStrokeColor;
@property (nonatomic, strong) UIColor *filledColor;
@property (nonatomic, strong) UIColor *textColor;
@end
