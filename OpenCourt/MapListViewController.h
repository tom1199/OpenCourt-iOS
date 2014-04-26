//
//  MapListViewController
//  OpenCourt
//
//  Created by TH Tom on 13/11/13.
//  Copyright (c) 2013 KOKO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDMall.h"
#import "SDDataManager.h"

@class MapListViewController;
@protocol MapListViewControllerDelegate <NSObject>

- (void)controller:(MapListViewController *)controller didSelectedMall:(SDMall *)mall;
- (void)controllerDidFinished:(MapListViewController *)controller;
@end

@interface MapListViewController : UITableViewController
<UIScrollViewDelegate,
UISearchBarDelegate>

@property (assign) id<MapListViewControllerDelegate>delegate;

@property (nonatomic, assign) SDMainCategory dataSourceCategory;
@property (nonatomic, strong) NSArray *backingDataSource;

- (id)initWithBackingDataSource:(NSArray *)dataSource;
- (void)reloadList;
@end
