//
//  SSTItem.h
//  TableMadness
//
//  Created by Brennan Stehling on 11/4/13.
//  Copyright (c) 2013 SmallSharpTools LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SSTTableViewUpdater.h"

@interface SSTItem : NSObject <TableViewDataRow>

@property (strong, nonatomic) NSNumber *number;
@property (assign, nonatomic) CGFloat height;
@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) NSDate *created;
@property (strong, nonatomic) NSDate *modified;

+ (SSTItem *)itemWithNumber:(NSNumber *)number height:(CGFloat)height color:(UIColor *)color;

- (SSTItem *)copyItemWithChangedNumber:(NSNumber *)number;

- (BOOL)isEqualToItem:(SSTItem *)otherItem;

@end
