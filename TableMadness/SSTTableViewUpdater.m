//
//  SSTTableViewUpdater.m
//  TableMadness
//
//  Created by Brennan Stehling on 5/4/14.
//  Copyright (c) 2014 SmallSharpTools LLC. All rights reserved.
//

#import "SSTTableViewUpdater.h"

#define kCurrentTableDataSelector   @selector(tableViewUpdaterCurrentTableData:)
#define kWillUpdateSelector         @selector(tableViewUpdater:willUpdateWithData:)
#define kDidUpdateSelector          @selector(tableViewUpdater:didUpdateWithData:)

/*
 * A table view updater allows for changes to the table which allow for animating
 * the changes while also preventing changes from happening during the animation
 * which will often cause an internal inconsistency and crash the app. This is a
 * tough problem to solve when data is coming in at any time and possibly at the
 * exact wrong time. By managing the data and the update it is possible to prevent
 * the inconsistencies and the crashes.
 */

#pragma mark - Class Extension
#pragma mark -

@interface SSTTableViewUpdater ()

@property (strong, nonatomic) NSArray *currentTableData;
@property (strong, nonatomic) NSMutableArray *updatedTableData;
@property (assign, nonatomic) BOOL isTableViewUpdating;

@end

@implementation SSTTableViewUpdater

#pragma mark - Initialization
#pragma mark -

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updatedTableData = [@[] mutableCopy];
    }
    return self;
}

#pragma mark - Public
#pragma mark -

- (void)reloadData:(NSArray *)data {
    if ([self.tableViewUpdaterDelegate respondsToSelector:kWillUpdateSelector]) {
        [self.tableViewUpdaterDelegate tableViewUpdater:self willUpdateWithData:data];
    }
    self.currentTableData = data;
    [self.tableView reloadData];
    if ([self.tableViewUpdaterDelegate respondsToSelector:kDidUpdateSelector]) {
        [self.tableViewUpdaterDelegate tableViewUpdater:self didUpdateWithData:data];
    }
}

- (void)updateData:(NSArray *)data {
    if (data) {
        [self.updatedTableData addObject:data];
        [self processUpdate];
    }
}

- (BOOL)hasPendingUpdate {
    return self.updatedTableData.count > 0;
}

#pragma mark - Private
#pragma mark -

#define kEnableProtections 1

- (void)processUpdate {
    NSCAssert(self.tableView, @"Outlet is required");
    NSCAssert(self.tableViewUpdaterDelegate, @"Outlet is required");
    
#ifdef kEnableProtections
    static NSString *lock = @"LOCK";
    
    @synchronized(lock) {
        if (self.isTableViewUpdating) {
            DebugLog(@"Deferring update while already updating");
            return;
        }
    
        if (self.updatedTableData.count) {
            [self runUpdate];
        }
    }
#else
    if (self.isTableViewUpdating) {
        DebugLog(@"Updating table without protections");
    }
    
    if (self.updatedTableData.count) {
        [self runUpdate];
    }
#endif
}

- (void)runUpdate {
    self.isTableViewUpdating = TRUE;
    NSArray *updatedTableData = self.updatedTableData[0];
    [self.updatedTableData removeObjectAtIndex:0];
    
    if ([self.tableViewUpdaterDelegate respondsToSelector:kCurrentTableDataSelector]) {
        self.currentTableData = [self.tableViewUpdaterDelegate tableViewUpdaterCurrentTableData:self];
    }
    
    if ([self.tableViewUpdaterDelegate respondsToSelector:kWillUpdateSelector]) {
        [self.tableViewUpdaterDelegate tableViewUpdater:self willUpdateWithData:updatedTableData];
    }
    
    // determine items which need to be inserted, updated or removed
    NSMutableArray *inserts = [@[] mutableCopy];
    NSMutableArray *deletes = [@[] mutableCopy];
    NSMutableArray *reloads = [@[] mutableCopy];
    
    // look for inserts and reloads
    for (NSUInteger row=0; row<updatedTableData.count; row++) {
        NSObject *item = updatedTableData[row];
        
        if (![self.currentTableData containsObject:item]) {
            // inserts are items which are not already in self.items
            [inserts addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
        else {
            NSUInteger otherIndex = [self.currentTableData indexOfObject:item];
            NSObject *otherItem = [self.currentTableData objectAtIndex:otherIndex];
            if ([item conformsToProtocol:@protocol(TableViewDataRow)] && [otherItem conformsToProtocol:@protocol(TableViewDataRow)]) {
                id<TableViewDataRow> dataRow = (id<TableViewDataRow>)item;
                id<TableViewDataRow> otherDataRow = (id<TableViewDataRow>)otherItem;
                if ([dataRow changedFromOtherItem:otherDataRow]) {
                    [reloads addObject:[NSIndexPath indexPathForRow:row inSection:0]];
                }
            }
        }
    }
    
    // look for deletes
    for (NSUInteger row=0; row<self.currentTableData.count; row++) {
        NSObject *item = self.currentTableData[row];
        if (![updatedTableData containsObject:item]) {
            [deletes addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
    }
    
    self.currentTableData = updatedTableData;
    
    // completion block when the animation is over
    __weak SSTTableViewUpdater *weakSelf = self;
    void (^completionBlock)(void) = ^void() {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.isTableViewUpdating = FALSE;
        
        if ([strongSelf.tableViewUpdaterDelegate respondsToSelector:kDidUpdateSelector]) {
            [strongSelf.tableViewUpdaterDelegate tableViewUpdater:self didUpdateWithData:updatedTableData];
        }
        
        if (self.updatedTableData.count) {
            [self processUpdate];
        }
    };
    
    if (inserts.count || deletes.count || reloads.count) {
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

@end
