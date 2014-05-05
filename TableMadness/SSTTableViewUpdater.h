//
//  SSTTableViewUpdater.h
//  TableMadness
//
//  Created by Brennan Stehling on 5/4/14.
//  Copyright (c) 2014 SmallSharpTools LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TableViewDataRow;

@protocol SSTTableViewUpdaterDelegate;

@interface SSTTableViewUpdater : NSObject

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet id<SSTTableViewUpdaterDelegate>tableViewUpdaterDelegate;

- (void)reloadData:(NSArray *)data;
- (void)updateData:(NSArray *)data;
- (BOOL)hasPendingUpdate;

@end

@protocol TableViewDataRow <NSObject>

// ID is the same but the object has changed
- (BOOL)changedFromOtherItem:(id<TableViewDataRow>)otherItem;

@end

@protocol SSTTableViewUpdaterDelegate <NSObject>

@required

- (NSArray *)tableViewUpdaterCurrentTableData:(SSTTableViewUpdater *)updatableTableView;
- (void)tableViewUpdater:(SSTTableViewUpdater *)updatableTableView willUpdateWithData:(NSArray *)data;
- (void)tableViewUpdater:(SSTTableViewUpdater *)updatableTableView didUpdateWithData:(NSArray *)data;

@end
