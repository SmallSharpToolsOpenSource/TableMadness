//
//  SSTItem.m
//  TableMaddness
//
//  Created by Brennan Stehling on 11/4/13.
//  Copyright (c) 2013 SmallSharpTools LLC. All rights reserved.
//

#import "SSTItem.h"

#pragma mark - Class Extension
#pragma mark -

@interface SSTItem () <NSCopying>

@property (strong, nonatomic) NSString *identifier;

@end

@implementation SSTItem

#pragma mark - Static Constructors
#pragma mark -

+ (SSTItem *)itemWithNumber:(NSNumber *)number {
    SSTItem *item = [[SSTItem alloc] init];
    item.number = number;
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    item.identifier = uuidString;

    item.created = [NSDate date];
    item.modified = item.created;
    
    return item;
}

+ (NSArray *)itemsWithNumbers:(NSArray *)numbers {
    NSMutableArray *items = [@[] mutableCopy];
    for (NSNumber *number in numbers) {
        SSTItem *item = [SSTItem itemWithNumber:number];
        [items addObject:item];
    }
    
    return items;
}

#pragma mark - Public
#pragma mark -

- (void)changeNumber:(NSNumber *)number {
    self.number = number;
    self.modified = [NSDate date];
}

- (SSTItem *)copyItemWithChangedNumber:(NSNumber *)number {
    SSTItem *copied = [self copy];
    [copied changeNumber:number];
    return copied;
}

#pragma mark - Base Overrides
#pragma mark -

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[SSTItem class]]) {
        SSTItem *other = (SSTItem *)object;
        return [self.identifier isEqualToString:other.identifier];
    }
    
    return FALSE;
}

- (NSUInteger)hash {
    return self.identifier.hash;
}

#pragma mark - NSCopying
#pragma mark -

- (id)copyWithZone:(NSZone *)zone {
    SSTItem *copied = [[SSTItem alloc] init];
    
    copied.identifier = self.identifier;
    copied.number = self.number;
    copied.created = self.created;
    copied.modified = self.modified;
    
    return copied;
}

@end
