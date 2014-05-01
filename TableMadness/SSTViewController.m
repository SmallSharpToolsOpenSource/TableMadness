//
//  SSTViewController.m
//  TableMadness
//
//  Created by Brennan Stehling on 11/3/13.
//  Copyright (c) 2013 SmallSharpTools LLC. All rights reserved.
//

#import "SSTViewController.h"

#import "SSTItem.h"

typedef NSArray * (^FetchItemsBlock) ();

@interface SSTViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *currentItems;
@property (strong, nonatomic) NSArray *dataSets;

@end

#define kDelay 1.5

@implementation SSTViewController {
    NSUInteger index;
    BOOL isUpdatingTable;
}

#pragma mark - View Lifecycle
#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MAAssert(self.tableView.delegate, @"Delegate is required");
    MAAssert(self.tableView.dataSource, @"DataSource is required");
    
    [self populateDataSets];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    UILabel * label = (UILabel *)[self.tableView.tableHeaderView viewWithTag:1];
    label.text = nil;
    
    index = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self runNextUpdate];
    });
}

#pragma mark - Private
#pragma mark -

- (void)populateDataSets {
    UIColor *baseColor = [UIColor colorWithRed:0.27 green:0.56 blue:0.80 alpha:1.0];
    UIColor *lighterColor = [self lighterColorForColor:baseColor];
    UIColor *darkerColor = [self darkerColorForColor:baseColor];
    
    SSTItem *item1 = [SSTItem itemWithNumber:@1 height:54.0f color:baseColor];
    SSTItem *item2 = [SSTItem itemWithNumber:@2 height:34.0f color:lighterColor];
    SSTItem *item3 = [SSTItem itemWithNumber:@3 height:64.0f color:darkerColor];
    SSTItem *item4 = [SSTItem itemWithNumber:@4 height:44.0f color:lighterColor];
    
    SSTItem *item1alt = [item1 copyItemWithChangedNumber:@99];
    SSTItem *item2alt = [item2 copyItemWithChangedNumber:@99];
    SSTItem *item3alt = [item3 copyItemWithChangedNumber:@99];
    SSTItem *item4alt = [item4 copyItemWithChangedNumber:@99];
    
    self.currentItems = @[item1, item3, item4];
    
    self.dataSets = @[
                      @{@"label" : @"add 2", @"fetchItems" : ^{
                          return @[item1, item2, item3, item4];
                      }, @"height" : @44.0f},
                      @{@"label" : @"remove 3", @"fetchItems" : ^{
                          return @[item1, item2, item4];
                      }, @"height" : @44.0f},
                      @{@"label" : @"remove 1", @"fetchItems" : ^{
                          return @[item2, item4];
                      }, @"height" : @44.0f},
                      @{@"label" : @"add all 4", @"fetchItems" : ^{
                          return @[item1, item2, item3, item4];
                      }, @"height" : @44.0f},
                      @{@"label" : @"update to 99", @"fetchItems" : ^{
                          return @[item1alt, item2alt, item3alt, item4alt];
                      }, @"height" : @44.0f},
                      @{@"label" : @"return to standard", @"fetchItems" : ^{
                          return @[item1, item2, item3, item4];
                      }, @"height" : @44.0f},
                      @{@"label" : @"remove 2", @"fetchItems" : ^{
                          return @[item1, item3, item4];
                      }, @"height" : @44.0f},
                    ];
}

- (void)runNextUpdate {
    if (isUpdatingTable) {
        DebugLog(@"Update is already running, trying again later.");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self runNextUpdate];
        });
        return;
    }
    
    isUpdatingTable = TRUE;
    
    if (index >= self.dataSets.count) {
        index = 0;
    }
    
    UILabel *label = (UILabel *)[self.tableView.tableHeaderView viewWithTag:1];
    NSString *labelText = (NSString *)self.dataSets[index][@"label"];
    label.text = labelText;
    
    FetchItemsBlock fetchItemsBlock = (FetchItemsBlock)self.dataSets[index][@"fetchItems"];
    NSArray *fetchedItems = fetchItemsBlock();
    
    // determine items which need to be inserted, updated or removed
    NSMutableArray *inserts = [@[] mutableCopy];
    NSMutableArray *deletes = [@[] mutableCopy];
    NSMutableArray *reloads = [@[] mutableCopy];
    
    // look for inserts
    for (NSUInteger row=0; row<fetchedItems.count; row++) {
        SSTItem *item = fetchedItems[row];
        if (![self.currentItems containsObject:item]) {
            // inserts are items which are not already in self.items
            [inserts addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
        else {
            NSUInteger otherIndex = [self.currentItems indexOfObject:item];
            SSTItem *otherItem = [self.currentItems objectAtIndex:otherIndex];
            if (![item.modified isEqualToDate:otherItem.modified]) {
                [reloads addObject:[NSIndexPath indexPathForRow:row inSection:0]];
            }
        }
    }
    
    // look for deletes
    for (NSUInteger row=0; row<self.currentItems.count; row++) {
        SSTItem *item = self.currentItems[row];
        if (![fetchedItems containsObject:item]) {
            [deletes addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
    }
    
    static NSString *lock = @"LOCK";
    
    void (^completionBlock)(void) = ^void() {
        DebugLog(@"Completed!");
        index++;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            isUpdatingTable = FALSE;
            [self runNextUpdate];
        });
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (kDelay / 4) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // lock is required to prevent inconsistencies when changing view orientation during rotation
        @synchronized(lock) {
            self.currentItems = fetchedItems;
            
#ifndef NDEBUG
            NSUInteger numberOfRowsInSection = [self tableView:self.tableView numberOfRowsInSection:0];
            DebugLog(@"numberOfRowsInSection: %li", (unsigned long)numberOfRowsInSection);
            DebugLog(@"self.items: %li", (unsigned long)self.currentItems.count);
            MAAssert(self.currentItems.count == numberOfRowsInSection, @"Match is required");
#endif
            
            if (inserts.count || deletes.count || reloads.count) {
#ifndef NDEBUG
                for (NSIndexPath *indexPath in inserts) {
                    DebugLog(@"Inserting at %li", (long)indexPath.row);
                }
                for (NSIndexPath *indexPath in deletes) {
                    DebugLog(@"Deleting at %li", (long)indexPath.row);
                }
                for (NSIndexPath *indexPath in reloads) {
                    DebugLog(@"Reloading at %li", (long)indexPath.row);
                }
#endif
                [CATransaction begin];
                [CATransaction setCompletionBlock:completionBlock];
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:inserts withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView deleteRowsAtIndexPaths:deletes withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView reloadRowsAtIndexPaths:reloads withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                [CATransaction commit];
            }
            else {
                completionBlock();
            }
        }
        
    });
}

- (UIColor *)lighterColorForColor:(UIColor *)c {
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)darkerColorForColor:(UIColor *)c {
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.2, 0.0)
                               green:MAX(g - 0.2, 0.0)
                                blue:MAX(b - 0.2, 0.0)
                               alpha:a];
    return nil;
}

#pragma mark - UITableViewDataSource
#pragma mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DebugLog(@"self.items.count: %lu", (unsigned long)self.currentItems.count);
    return  self.currentItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TableRow";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    SSTItem *item = self.currentItems[indexPath.row];
    NSNumber *number = item.number;
    UILabel *label = (UILabel *)[cell viewWithTag:1];
//    label.textColor = item.color;
    cell.backgroundColor = item.color;
    label.text = [NSString stringWithFormat:@"Item %li", (long)[number integerValue]];
    
    return cell;
}

#pragma mark - UITableViewDelegate
#pragma mark -

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SSTItem *item = self.currentItems[indexPath.row];
    return item.height;
}

@end
