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

+ (SSTItem *)itemWithNumber:(NSNumber *)number height:(CGFloat)height color:(UIColor *)color {
    SSTItem *item = [[SSTItem alloc] init];
    item.number = number;
    item.height = height > 0 ? height : 44.0f;
    item.color = color ? color : [UIColor blackColor];
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    CFRelease(uuid);
    item.identifier = uuidString;

    item.created = [NSDate date];
    item.modified = item.created;
    
    return item;
}

#pragma mark - Public
#pragma mark -

- (SSTItem *)copyItemWithChangedNumber:(NSNumber *)number {
    SSTItem *copied = [self copy];
    copied.number = number;
    copied.modified = [NSDate date];
    
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
    copied.height = self.height;
    copied.color = self.color;
    copied.created = self.created;
    copied.modified = self.modified;
    
    return copied;
}

@end
