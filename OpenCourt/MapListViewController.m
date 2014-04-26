//
//  MapListViewController
//  OpenCourt
//
//  Created by TH Tom on 13/11/13.
//  Copyright (c) 2013 KOKO. All rights reserved.
//

#import "MapListViewController.h"
#import "SDUser.h"
#import "ILBarButtonItem.h"

#import "UIColor+SD3Color.h"
#import "UIFont+SD3Font.h"

#import "BarActivityIndicator.h"
#import "SDDataObject.h"
#import "SDShop.h"
#import "SDLocationManager.h"

@interface MapListViewController ()
@property (nonatomic,assign) BOOL isSearching;
@property (nonatomic,strong) NSDictionary *itemDataSource;
@property (nonatomic,strong) NSArray *itemSearchResultDataSource;
@property (nonatomic,strong) NSArray *itemKeys;
@property (nonatomic,strong) UISearchBar *searchBar;
@property (nonatomic,strong) BarActivityIndicator *activityIndicator;
@end

@implementation MapListViewController

- (id)initWithBackingDataSource:(NSArray *)dataSource {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.backingDataSource = dataSource;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"ShopsDirect3";
    self.navigationController.navigationBar.translucent = NO;
    self.tableView.backgroundColor = [UIColor sd3ColorBckgndWhite];

    ILBarButtonItem *leftButton =
    [ILBarButtonItem barItemWithImage:[UIImage imageNamed:@"btn_back.png"]
                        selectedImage:[UIImage imageNamed:@"btn_back.png"]
                               target:self
                               action:@selector(tapOnBackButton:)];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    self.navigationItem.rightBarButtonItem = [BarActivityIndicator barActivityIndicator];
    
    [self initializeUI];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.isSearching = false;
    
    [self reloadList];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tapOnBackButton:(id)sender {
    [self.delegate controllerDidFinished:self];
}

#pragma mark - UI

- (void)initializeUI {
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    _searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, screenSize.width, 40)];
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        _searchBar.tintColor = [UIColor lightGrayColor];
    }else {
        _searchBar.barTintColor = [UIColor lightGrayColor];
    }
    _searchBar.delegate = self;
    
    self.tableView.tableHeaderView = _searchBar;
    
    //Replace Search button to Done
    for (UIView *subview in _searchBar.subviews) {
        if (!SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            for (UIView *subSubview in subview.subviews)
            {
                if ([subSubview conformsToProtocol:@protocol(UITextInputTraits)])
                {
                    UITextField *textField = (UITextField *)subSubview;
                    textField.returnKeyType = UIReturnKeyDone;
                    break;
                }
            }
        }else {
            if ([subview conformsToProtocol:@protocol(UITextInputTraits)])
            {
                UITextField *textField = (UITextField *)subview;
                textField.returnKeyType = UIReturnKeyDone;
                break;
            }
        }
    }
}

#pragma mark - Data management

- (void)parsingDataWithData:(NSArray *)metaData {
    //sort mall by name
    NSArray *sortedItems = [metaData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        SDMall *mall1 = obj1; SDMall *mall2 = obj2;

        switch (self.dataSourceCategory) {
            case kSDMainCategoryMall:
            {
                return [mall1.mallName compare:mall2.mallName options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch];
            }
            case kSDMainCategoryStandaloneShop:
            case kSDMainCategoryPetrolStation:
            case kSDMainCategoryATM:
            {
                return [mall1.shopName compare:mall2.shopName options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch];
            }
            default:
                return NSOrderedSame;
        }

    }];
    
    NSMutableDictionary *itemSectionDic = [NSMutableDictionary dictionary];
    NSString *firstChar = nil;
    
    switch (self.dataSourceCategory) {
        case kSDMainCategoryMall:
        {
            for (SDMall *item in sortedItems) {
                
                if (!item.mallName) continue;
                
                NSMutableArray *items = nil;
                
                //Compare the first character using diacritic insensitive search
                if([item.mallName compare:firstChar options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, 1)] == NSOrderedSame)
                {
                    //switch associated exist store for the char
                    items = [itemSectionDic objectForKey:firstChar];
                }
                else
                {
                    //new letter found, create array to store the associated malls
                    //decomposedStringWithCanonicalMapping is where the magic happens
                    //(it removes the accent mark)
                    firstChar = [[[item.mallName decomposedStringWithCanonicalMapping] substringToIndex:1]uppercaseString];
                    items = [NSMutableArray array];
                    [itemSectionDic setObject:items forKey:firstChar];
                }
                
                [items addObject:item];
            }
            
            self.itemDataSource = itemSectionDic;
            
            //sort key by Diacritic e.g. #number,a,b,c,d....
            NSArray *keys = [self.itemDataSource allKeys];
            self.itemKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [obj1 compare:obj2 options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch];
            }];
            
            //sort all items for each key by distance
            /**
            CLLocation *currentLocation = [SDLocationManager defaultManager].location;
            [self.itemKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString *key = obj;
                
                [[self.itemDataSource objectForKey:key] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    SDMall *mall1 = obj1; SDMall *mall2 = obj2;
                    CLLocationDistance mall1Distance = [mall1 mallDistanceFromLocation:currentLocation];
                    CLLocationDistance mall2Distance = [mall2 mallDistanceFromLocation:currentLocation];
                    if (mall1Distance < mall2Distance) {
                        return NSOrderedAscending;
                    }else if (mall1Distance > mall2Distance) {
                        return NSOrderedDescending;
                    }else {
                        return NSOrderedSame;
                    }
                }];
                
            }];
             */
        }
            break;
        case kSDMainCategoryStandaloneShop:
        case kSDMainCategoryPetrolStation:
        case kSDMainCategoryATM:
        {
            //section malls by first letter of the mall name
            for (SDMall *item in sortedItems) {
                
                if (!item.shopName) continue;
                
                NSMutableArray *items = nil;
                
                //Compare the first character using diacritic insensitive search
                if([item.shopName compare:firstChar options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, 1)] == NSOrderedSame)
                {
                    //switch associated exist store for the char
                    items = [itemSectionDic objectForKey:firstChar];
                }
                else
                {
                    //new letter found, create array to store the associated malls
                    //decomposedStringWithCanonicalMapping is where the magic happens
                    //(it removes the accent mark)
                    firstChar = [[[item.shopName decomposedStringWithCanonicalMapping] substringToIndex:1]uppercaseString];
                    items = [NSMutableArray array];
                    [itemSectionDic setObject:items forKey:firstChar];
                }
                
                [items addObject:item];
            }
            
            self.itemDataSource = itemSectionDic;
            
            //sort key by Diacritic e.g. #number,a,b,c,d....
            NSArray *keys = [self.itemDataSource allKeys];
            self.itemKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [obj1 compare:obj2 options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch];
            }];
            
            
            //sort all items for each key by distance
            /**
            CLLocation *currentLocation = [SDLocationManager defaultManager].location;
            [self.itemKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString *key = obj;
                
                [[self.itemDataSource objectForKey:key] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    SDMall *mall1 = obj1; SDMall *mall2 = obj2;
                    CLLocationDistance mall1Distance = [mall1 mallDistanceFromLocation:currentLocation];
                    CLLocationDistance mall2Distance = [mall2 mallDistanceFromLocation:currentLocation];
                    if (mall1Distance < mall2Distance) {
                        return NSOrderedAscending;
                    }else if (mall1Distance > mall2Distance) {
                        return NSOrderedDescending;
                    }else {
                        return NSOrderedSame;
                    }
                }];
                
            }];
             */
        }
            break;
        default:
            break;
    }
    
}

- (void)reloadList {

    [self.activityIndicator.activityIndicator startAnimating];
    
    [self parsingDataWithData:_backingDataSource];
    [self.tableView reloadData];
    
    [self.activityIndicator.activityIndicator stopAnimating];

}

- (NSArray *)itemForKeyword:(NSString *)keyword {
    //get all malls
    NSMutableArray *items = [NSMutableArray array];
    NSPredicate *predicate = nil;

    switch (self.dataSourceCategory) {
        case kSDMainCategoryMall:
            predicate = [NSPredicate predicateWithFormat:@"SELF.mallName CONTAINS[cd] %@ OR SELF.mallAddress CONTAINS[cd] %@",keyword,keyword];
            break;
        case kSDMainCategoryPetrolStation:
        case kSDMainCategoryStandaloneShop:
        case kSDMainCategoryATM:
            predicate = [NSPredicate predicateWithFormat:@"SELF.shopName CONTAINS[cd] %@ OR SELF.mallName CONTAINS[cd] %@ OR SELF.mallAddress CONTAINS[cd] %@",keyword, keyword, keyword];
            break;
        default:
            break;
    }
    NSArray *arrayOfMallArray = [self.itemDataSource allValues];   //array of mall arraies
    for (NSArray *mallArray in arrayOfMallArray) {
        NSArray *filteredMalls = [mallArray filteredArrayUsingPredicate:predicate];
        
        if (filteredMalls && filteredMalls.count) {
            [items addObjectsFromArray:filteredMalls];
        }
    }
    
    return items;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.isSearching) {
        return 1;
    }else {
        return self.itemKeys.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isSearching) {
        return self.itemSearchResultDataSource.count;
    }else {
        NSString *keyForSection = [self.itemKeys objectAtIndex:section];
        return [(NSArray *)[self.itemDataSource objectForKey:keyForSection] count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.isSearching) {
        return nil;
    }else {
        return [self.itemKeys objectAtIndex:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MallListViewControllerCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumScaleFactor = 0.9;
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.textLabel.font = [UIFont sd3FontWithSize:17];
        
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.minimumScaleFactor = 0.9;
        cell.detailTextLabel.font = [UIFont sd3FontWithSize:13];
        cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    //get mall data
    SDMall *mall = nil;
    if (self.isSearching) {
        mall = [self.itemSearchResultDataSource objectAtIndex:indexPath.row];
    }else {
        NSString *keyForSection = [self.itemKeys objectAtIndex:indexPath.section];
        mall = [[self.itemDataSource objectForKey:keyForSection] objectAtIndex:indexPath.row];
    }

    // Configure the cell...
    switch (self.dataSourceCategory) {
        case kSDMainCategoryMall:
            cell.textLabel.text = mall.mallName;

            break;
        case kSDMainCategoryPetrolStation:
        case kSDMainCategoryStandaloneShop:
            
            cell.textLabel.text = mall.shopName;

            break;
        case kSDMainCategoryATM:
        {
            NSString *title = mall.shopName;
            if (mall.mallName && ![mall.mallName isEqualToString:@""]) {
                title = [title stringByAppendingString:[NSString stringWithFormat:@" @%@",mall.mallName]];
            }
            
            cell.textLabel.text = title;
        }
            break;
        default:
            break;
    }
    
    //CLLocationDistance distanceFromUserLocation = [mall mallDistanceFromLocation:[SDLocationManager defaultManager].location];
    //NSString *distanceString = nil;
    //if (distanceFromUserLocation >= 1000) {
    //    distanceString = [NSString stringWithFormat:@"%.1fkm",distanceFromUserLocation/1000];
    //}else {
    //    distanceString = [NSString stringWithFormat:@"%.1fm",distanceFromUserLocation];
    //}
    cell.detailTextLabel.text = mall.mallAddress;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //get mall data
    SDMall *mall = nil;
    if (self.isSearching) {
        mall = [self.itemSearchResultDataSource objectAtIndex:indexPath.row];
    }else {
        NSString *keyForSection = [self.itemKeys objectAtIndex:indexPath.section];
        mall = [[self.itemDataSource objectForKey:keyForSection] objectAtIndex:indexPath.row];
    }
    
    if (mall) {
        [self.delegate controller:self didSelectedMall:mall];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.itemSearchResultDataSource = nil;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] > 0) {
        self.isSearching = TRUE;
    }else {
        self.isSearching = FALSE;
    }
    
    if (self.isSearching) {
        self.itemSearchResultDataSource = [self itemForKeyword:searchText];
    }
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    
    self.isSearching = FALSE;
    
    [self.tableView reloadData];
}
@end




