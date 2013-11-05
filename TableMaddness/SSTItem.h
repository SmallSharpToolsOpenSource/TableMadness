//
//  SSTItem.h
//  TableMaddness
//
//  Created by Brennan Stehling on 11/4/13.
//  Copyright (c) 2013 SmallSharpTools LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSTItem : NSObject

@property (strong, nonatomic) NSNumber *number;
@property (strong, nonatomic) NSDate *created;
@property (strong, nonatomic) NSDate *modified;

+ (SSTItem *)itemWithNumber:(NSNumber *)number;
+ (NSArray *)itemsWithNumbers:(NSArray *)numbers;

- (void)changeNumber:(NSNumber *)number;
- (SSTItem *)copyItemWithChangedNumber:(NSNumber *)number;

@end
