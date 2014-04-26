//
//  AddCourtViewController.h
//  OpenCourt
//
//  Created by TH Tom on 4/4/14.
//  Copyright (c) 2014 Waterdrop. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "Court.h"

@class AddCourtViewController;
@protocol AddCourtViewControllerDelegate <NSObject>
- (void)addCourtViewController:(AddCourtViewController *)controller didAddNewCourt:(Court *)court;
- (void)addCourtViewControllerDidCancel:(AddCourtViewController *)controller;
@end

@interface AddCourtViewController : UIViewController
<UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UILabel *courtLatLabel;
@property (strong, nonatomic) IBOutlet UILabel *courtLngLabel;
@property (strong, nonatomic) IBOutlet UITextField *courtNameTextField;
@property (strong, nonatomic) IBOutlet UITextField *courtAddressTextField;

@property (nonatomic, weak) IBOutlet id<AddCourtViewControllerDelegate>delegate;

@property (nonatomic, strong) Court *court;

- (IBAction)sendButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;
@end
