//
//  AddCourtViewController.m
//  OpenCourt
//
//  Created by TH Tom on 4/4/14.
//  Copyright (c) 2014 Waterdrop. All rights reserved.
//

#import "AddCourtViewController.h"
#import "Court.h"
#import "OCDataManager.h"

@interface AddCourtViewController ()
@property (nonatomic, strong)UIToolbar *accessoryToolBar;
@property (nonatomic, strong)UIResponder *activeField;
@end

@implementation AddCourtViewController

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

    [self reloadUI];
}

- (UIToolbar *)accessoryToolBar {
    if (!_accessoryToolBar) {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGFloat toolbarHeight = 44.0f;
        CGRect toolbarRect = CGRectMake(0, 0, screenSize.width, toolbarHeight);
        _accessoryToolBar = [[UIToolbar alloc]initWithFrame:toolbarRect];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(hideKeyboard:)];
        UIBarButtonItem *divider = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        [_accessoryToolBar setItems:@[divider, doneButton]];
    }
    return _accessoryToolBar;
}

- (void)reloadUI {
    self.courtLatLabel.text = [NSString stringWithFormat:@"%f",self.court.location.latitude];
    self.courtLngLabel.text = [NSString stringWithFormat:@"%f",self.court.location.longitude];
    self.courtNameTextField.text = self.court.courtName ? self.court.courtName : @"";
    self.courtAddressTextField.text = self.court.address ? self.court.address : @"";
}

- (IBAction)sendButtonPressed:(id)sender {
    
    if (self.activeField.isFirstResponder) {
        [self.activeField resignFirstResponder];
    }
    
    BOOL canSave = YES;
    NSString *errorMsg = nil;
    
    if (!self.court.location) {
        canSave = NO;
        errorMsg = NSLocalizedString(@"Please input the Geo location of the new court", nil);
    }else if (!self.court.courtName) {
        canSave = NO;
        errorMsg = NSLocalizedString(@"Please input name of the new court", nil);
    }else if (!self.court.address) {
        canSave = NO;
        errorMsg = NSLocalizedString(@"Please input address of the new court", nil);
    }
    
    if (canSave) {
        [OCDataManager addNewCourt:self.court withCompletion:^(NSError *error, BOOL success) {
            if (success) {
                [[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Add New Location", nil)
                                           message:NSLocalizedString(@"Add location success", nil)
                                          delegate:nil
                                 cancelButtonTitle:nil
                                 otherButtonTitles:NSLocalizedString(@"OK", nil), nil]show];
                
                if ([self.delegate respondsToSelector:@selector(addCourtViewController:didAddNewCourt:)]) {
                    [self.delegate addCourtViewController:self didAddNewCourt:self.court];
                }
            }
        }];
    }else {
        [[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Add New Location", nil)
                                  message:NSLocalizedString(@"Fail to add location", nil)
                                 delegate:nil
                        cancelButtonTitle:nil
                        otherButtonTitles:NSLocalizedString(@"OK", nil), nil]show];
    }

}

- (IBAction)cancelButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(addCourtViewControllerDidCancel:)]) {
        [self.delegate addCourtViewControllerDidCancel:self];
    }
}

- (void)hideKeyboard:(id)sender {
    [self.activeField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.inputAccessoryView = self.accessoryToolBar;
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.activeField == self.courtNameTextField) {
        self.court.courtName = textField.text;
    }else if (self.activeField == self.courtAddressTextField) {
        self.court.address = textField.text;
    }
}

@end
