//
//  TLIndexPathDataModel.m
//
//  Copyright (c) 2013 Tim Moose (http://tractablelabs.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "TLIndexPathDataModel.h"
#import <CoreData/CoreData.h>
#import "TLIndexPathItem.h"
#import "TLIndexPathSectionInfo.h"

const NSString *TLIndexPathDataModelNilSectionName = @"__TLIndexPathDataModelNilSectionName__";

@interface TLIndexPathDataModel ()
@property (strong, nonatomic) NSMutableDictionary *itemsByIdentifier;
@property (strong, nonatomic) NSMutableDictionary *sectionInfosBySectionName;
@property (strong, nonatomic) NSMutableDictionary *identifiersByIndexPath;
@property (strong, nonatomic) NSMutableDictionary *indexPathsByIdentifier;
@end

@implementation TLIndexPathDataModel

@synthesize identifierKeyPath = _identifierKeyPath;
@synthesize sectionNameKeyPath = _sectionNameKeyPath;
@synthesize numberOfSections = _sectionCount;
@synthesize itemsByIdentifier = _itemsByIdentifier;
@synthesize identifiersByIndexPath = _identifiersByIndexPath;
@synthesize indexPathsByIdentifier = _indexPathsByIdentifier;
@synthesize items = _items;
@synthesize sectionNames = _sectionNames;
@synthesize sections = _sections;

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo>sectionInfo = [self sectionInfoForSection:section];
    return sectionInfo ? [sectionInfo objects].count : NSNotFound;
}

- (NSString *)sectionNameForSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo>sectionInfo = [self sectionInfoForSection:section];
    return [sectionInfo name];
}

- (NSInteger)sectionForSectionName:(NSString *)sectionName
{
    id<NSFetchedResultsSectionInfo>sectionInfo = [self.sectionInfosBySectionName objectForKey:sectionName];
    return sectionInfo ? [self.sections indexOfObject:sectionInfo] : NSNotFound;
}

- (NSString *)sectionTitleForSection:(NSInteger)section
{
    NSString *sectionName = [self sectionNameForSection:section];
    if ([TLIndexPathDataModelNilSectionName isEqualToString:sectionName]) {
        return nil;
    }
    return sectionName;
}

- (TLIndexPathSectionInfo *)sectionInfoForSection:(NSInteger)section
{
    if (self.sections.count <= section) {
        return nil;
    }
    return self.sections[section];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    id identifier = [self identifierAtIndexPath:indexPath];
    id item = [self.itemsByIdentifier objectForKey:identifier];
    return item;
}

- (id)identifierAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.identifiersByIndexPath objectForKey:indexPath];
}

- (BOOL)containsItem:(id)item
{
    return [self indexPathForItem:item] != nil;
}

- (NSIndexPath *)indexPathForItem:(id)item
{
    id identifier = [self identifierForItem:item];
    NSIndexPath *indexPath = [self.indexPathsByIdentifier objectForKey:identifier];
    return indexPath;
}

- (NSIndexPath *)indexPathForIdentifier:(id)identifier
{
    id item = [self itemForIdentifier:identifier];
    return [self indexPathForItem:item];
}

- (NSString *)cellIdentifierAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.cellIdentifierKeyPath) {
        id item = [self itemAtIndexPath:indexPath];
        return [item valueForKeyPath:self.cellIdentifierKeyPath];
    }
    return nil;
}

- (id)initWithIndexPathItems:(NSArray *)items
{
    return [self initWithItems:items andSectionNameKeyPath:TLIndexPathItemSectionName andIdentifierKeyPath:TLIndexPathItemIdentifier andCellIdentifierKeyPath:TLIndexPathItemCellIdentifier];
}

- (id)initWithItems:(NSArray *)items andSectionNameKeyPath:(NSString *)sectionNameKeyPath andIdentifierKeyPath:(NSString *)identifierKeyPath
{
    return [self initWithItems:items andSectionNameKeyPath:sectionNameKeyPath andIdentifierKeyPath:identifierKeyPath andCellIdentifierKeyPath:nil];
}

- (id)initWithItems:(NSArray *)items andSectionNameKeyPath:(NSString *)sectionNameKeyPath andIdentifierKeyPath:(NSString *)identifierKeyPath andCellIdentifierKeyPath:(NSString *)cellIdentifierKeyPath
{
    NSMutableDictionary *itemsByIdentifier = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *itemsBySectionName = [[NSMutableDictionary alloc] init];
    NSMutableArray *sectionNames = [NSMutableArray array];
    
    //group items by section name and remove any duplicate identifiers
    for (id item in items) {
        id identifier = [TLIndexPathDataModel identifierForItem:item andIdentifierKeyPath:identifierKeyPath];
        if (!identifier || [itemsByIdentifier objectForKey:identifier]) continue;
        NSString *sectionName = [TLIndexPathDataModel sectionNameForItem:item andSectionNameKeyPath:sectionNameKeyPath];
        NSMutableArray *items = [itemsBySectionName objectForKey:sectionName];
        if (!items) {
            items = [NSMutableArray array];
            [itemsBySectionName setObject:items forKey:sectionName];
            [sectionNames addObject:sectionName];
        }
        [items addObject:item];
        [itemsByIdentifier setObject:item forKey:identifier];
    }
    
    //create section infos
    NSMutableArray *sectionInfos = [NSMutableArray arrayWithCapacity:sectionNames.count];
    for (NSString *sectionName in sectionNames) {
        NSArray *items = [itemsBySectionName objectForKey:sectionName];
        TLIndexPathSectionInfo *sectionInfo = [[TLIndexPathSectionInfo alloc] initWithItems:items andName:sectionName andIndexTitle:sectionName];
        [sectionInfos addObject:sectionInfo];
    }
    
    if (self = [self initWithSectionInfos:sectionInfos andIdentifierKeyPath:identifierKeyPath andCellIdentifierKeyPath:cellIdentifierKeyPath]) {
        _sectionNameKeyPath = sectionNameKeyPath;
    }
    return self;
    
    return [self initWithSectionInfos:sectionInfos andIdentifierKeyPath:identifierKeyPath andCellIdentifierKeyPath:cellIdentifierKeyPath];
}

- (id)initWithSectionInfos:(NSArray *)sectionInfos andIdentifierKeyPath:(NSString *)identifierKeyPath andCellIdentifierKeyPath:(NSString *)cellIdentifierKeyPath
{    
    if (self = [super init]) {
        
        NSMutableArray *identifiedItems = [[NSMutableArray alloc] init];
        NSMutableArray *sectionNames = [[NSMutableArray alloc] init];
        
        _identifierKeyPath = identifierKeyPath;
        _cellIdentifierKeyPath = cellIdentifierKeyPath;
        _itemsByIdentifier = [[NSMutableDictionary alloc] init];
        _identifiersByIndexPath = [[NSMutableDictionary alloc] init];
        _indexPathsByIdentifier = [[NSMutableDictionary alloc] init];
        _sectionInfosBySectionName = [[NSMutableDictionary alloc] init];
        _sectionNames = sectionNames;
        _sections = sectionInfos;
        _items = identifiedItems;

        NSInteger section = 0;
        for (id<NSFetchedResultsSectionInfo>sectionInfo in sectionInfos) {

            NSInteger row = 0;
            
            for (id item in sectionInfo.objects) {

                id identifier = [self identifierForItem:item];
                //we can't remove duplicate items because section infos are
                //immutable. So the strategy will be to make duplicate items behave
                //just like any other item with the exception that they cannot be
                //looked up by identifier. TODO this needs to be tested.
                if (identifier && ![_itemsByIdentifier objectForKey:identifier]) {
                    [identifiedItems addObject:item];
                    [_itemsByIdentifier setObject:item forKey:identifier];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                    [_identifiersByIndexPath setObject:identifier forKey:indexPath];
                    [_indexPathsByIdentifier setObject:indexPath forKey:identifier];
                };

                row++;                
            }
                        
            [_sectionInfosBySectionName setObject:sectionInfo forKey:sectionInfo.name];
            [sectionNames addObject:sectionInfo.name];
            
            section++;
        }
        
        _sectionCount = sectionInfos.count;
    }
    
    return self;
}

- (id)initWithIndexPathItemSectionInfos:(NSArray *)sectionInfos
{
    return [self initWithSectionInfos:sectionInfos andIdentifierKeyPath:TLIndexPathItemIdentifier andCellIdentifierKeyPath:TLIndexPathItemCellIdentifier];
}

- (id)identifierForItem:(id)item
{
    return [[self class] identifierForItem:item andIdentifierKeyPath:self.identifierKeyPath];
}

+ (id)identifierForItem:(id)item andIdentifierKeyPath:(NSString *)identifierKeyPath
{
    id identifier;
    if (identifierKeyPath) {
        identifier = [item valueForKeyPath:identifierKeyPath];
    } else {
        identifier = item;
    }
    return identifier;
}

- (id)itemForIdentifier:(id)identifier
{
    return [self.itemsByIdentifier objectForKey:identifier];
}

- (id)currentVersionOfItem:(id)anotherVersionOfItem
{
    id identifier = [self identifierForItem:anotherVersionOfItem];
    id item = [self itemForIdentifier:identifier];
    return item;
}

- (NSString *)sectionNameForItem:(id)item
{
    return [[self class] sectionNameForItem:item andSectionNameKeyPath:self.sectionNameKeyPath];
}

+ (NSString *)sectionNameForItem:(id)item andSectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    NSString *sectionName;
    if (sectionNameKeyPath) {
        sectionName = [item valueForKeyPath:sectionNameKeyPath];
    } else {
        sectionName = [TLIndexPathDataModelNilSectionName copy];
    }
    return sectionName;
}

@end