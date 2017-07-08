//
//  YHTableView.m
//  YHTableView
//
//  Created by Alan.Turing on 17/6/15.
//  Copyright © 2017年 Alan.Turing. All rights reserved.
//

#import "YHTableView.h"

#define sectionIndex 0
#define ID @"CELL"

@implementation YHTableView

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        self.backgroundColor = [UIColor redColor];
        self.secNumInTableView = 1;
        self.contentWidth = ScreenWidth;
        self.contentHeight = 0;
        self.firstCreate = true;
        self.caculateHeight = true;
        self.topCell = 0;
        self.buttomCell = 0;
        self.visibleCells = [NSMutableArray array];
        self.reusedCells = [NSMutableDictionary dictionary];
        self.firstCellInTableView = nil;
        self.lastCellInTableView = nil;
        self.foundFirstCellInTableView = false;
        self.foundLastCellInTableView = false;
    }
    
    return self;
}


- (void) dynAddRemoveCell:(CGFloat) originY
{
    NSLog(@"dynAddRemoveCell00");
    
    if (originY >= self.firstCellInTableView.cellUpEdge &&
        originY <= self.firstCellInTableView.cellDownEdge &&
        originY + ScreenHeight >= self.lastCellInTableView.cellUpEdge &&
        originY + ScreenHeight <= self.lastCellInTableView.cellDownEdge)
    {
        return;
    }

    NSLog(@"dynAddRemoveCell11");
    
    if (originY > self.firstCellInTableView.cellDownEdge) {
        
        [self.firstCellInTableView removeFromSuperview];
        self.topCell = self.firstCellInTableView.cellIndex + 1;
        
        [self enqueueReusableCellWithIdentifier:self.firstCellInTableView.cellNodePointer forKey:ID];
        
        [self.visibleCells removeObject:self.firstCellInTableView];
        
        self.firstCellInTableView = [self findCellByIndex:self.topCell];
    }
    
    else if(originY < self.firstCellInTableView.cellUpEdge && originY > 0)
    {
        //get row height for each
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.topCell - 1) inSection:sectionIndex];
        
        YHTableViewCell* cell = nil;
        if ([self.dataSource respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
            cell = [self.dataSource tableView:self cellForRowAtIndexPath:indexPath];
        }
        
        if([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)])
            cell.cellHeight = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
        
        cell.cellIndex = self.topCell - 1;
        cell.cellDownEdge = self.firstCellInTableView.cellUpEdge;
        cell.cellUpEdge = cell.cellDownEdge - cell.cellHeight;
        self.topCell = cell.cellIndex;
        self.firstCellInTableView = cell;
        
        cell.frame = CGRectMake(0, cell.cellUpEdge, ScreenWidth, cell.cellHeight);
        [self addSubview:cell];
//        [self setNeedsLayout];
        [self layoutIfNeeded];
        
        [self.visibleCells addObject:cell];
    }
    
    
    if (originY + ScreenHeight < self.lastCellInTableView.cellUpEdge) {
        
        self.buttomCell = self.lastCellInTableView.cellIndex - 1;
        [self.lastCellInTableView removeFromSuperview];
        
        [self enqueueReusableCellWithIdentifier:self.lastCellInTableView.cellNodePointer forKey:ID];
        
        [self.visibleCells removeObject:self.lastCellInTableView];
        
        self.lastCellInTableView = [self findCellByIndex:self.buttomCell];
    }
    else if(originY + ScreenHeight > self.lastCellInTableView.cellDownEdge && self.lastCellInTableView.cellDownEdge < self.contentSize.height)
    {
        //get row height for each
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.buttomCell + 1) inSection:sectionIndex];
        
        YHTableViewCell* cell = nil;
        if ([self.dataSource respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
            cell = [self.dataSource tableView:self cellForRowAtIndexPath:indexPath];
        }
        
        if([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)])
            cell.cellHeight = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
        
        cell.cellIndex = self.buttomCell + 1;
        cell.cellUpEdge = self.lastCellInTableView.cellDownEdge;
        cell.cellDownEdge = cell.cellUpEdge + cell.cellHeight;
        self.buttomCell = cell.cellIndex;
        self.lastCellInTableView = cell;
        
        cell.frame = CGRectMake(0, cell.cellUpEdge, ScreenWidth, cell.cellHeight);
        [self addSubview:cell];
//        [self setNeedsLayout];
        [self layoutIfNeeded];
        
        [self.visibleCells addObject:cell];
    }
}

- (YHTableViewCell*) findCellByIndex:(NSUInteger) index
{
    NSUInteger i = 0;
    
    for (; i < self.visibleCells.count; i++) {

        if (index == self.visibleCells[i].cellIndex) {

            return self.visibleCells[i];
        
        }
    }
    
    //should not get here!
    return nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
//    NSLog(@"xxxxx%@", NSStringFromCGRect(self.subviews.firstObject.frame));
//    NSLog(@"xxxxx%zd", (NSUInteger)self.bounds.origin.y);
    
    
    if(self.dataSource)
       [self executeDataSourceMethod];
    
    if(self.delegate)
       [self executeDelegateMethod];

    if (self.firstCreate) {
        self.firstCreate = false;
        [self createCell];
    }
    
    [self dynAddRemoveCell:self.contentOffset.y];
//    NSLog(@"layoutSubvi  ews");
}

- (void) executeDataSourceMethod
{
    self.secNumInTableView = [self.dataSource numberOfSectionsInTableView:self];  //default is 1
    self.rowNumInSection = [self.dataSource tableView:self numberOfRowsInSection:sectionIndex];
}

- (void) executeDelegateMethod
{
    if (self.caculateHeight) {
        self.caculateHeight = false;
        CGFloat contentSizeHeight = 0;
        
        if([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)])
        {
            for (NSInteger i = 0; i < self.rowNumInSection; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:sectionIndex];
                
                contentSizeHeight += [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
            }
            
            self.contentSize = CGSizeMake(ScreenWidth, contentSizeHeight);
        }
    }
    
}

- (void) createCell
{
    //NSInteger needCreateRowNum;
//    CGFloat visibleTableHeightCurrent = 0;  //it's Y value is cell bottom.
    
    NSInteger i = 0;
    YHTableViewCell* cell = nil;
        
    for (; (i < self.rowNumInSection) && (self.contentHeight < ScreenHeight); i++) { //row number in section
//    for (; i < self.rowNumInSection; i++) {
    
        //get row height for each
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:sectionIndex];
        
        if ([self.dataSource respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
            cell = [self.dataSource tableView:self cellForRowAtIndexPath:indexPath];
        }
        
        if([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)])
            cell.cellHeight = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
        
//        NSLog(@"cell.height=%zd", (NSUInteger)cell.cellHeight);
        
        cell.cellIndex = i;
        cell.cellUpEdge = self.contentHeight;
        cell.cellDownEdge = cell.cellUpEdge + cell.cellHeight;
        
        cell.frame = CGRectMake(0, cell.cellUpEdge, ScreenWidth, cell.cellHeight);
        [self addSubview:cell];
        
        [self.visibleCells addObject:cell];
    
        self.contentHeight += cell.cellHeight;
    }
    
    self.buttomCell = i - 1;
    self.firstCellInTableView = self.visibleCells.firstObject;
    self.lastCellInTableView = self.visibleCells.lastObject;
    
}

#pragma mark Maintenance queue. Enqueue and Dequeue


- (YHTableViewCell*) dequeueReusableCellWithIdentifier:(NSString*) identifier
{
    YHCellNode* node = [self.reusedCells valueForKey:identifier];
    
    
    [self.reusedCells setValue:node.pointer forKey:identifier];
    
    return node.cell;
}

- (void) enqueueReusableCellWithIdentifier:(YHCellNode*) node forKey:(NSString*) identifier
{
    node.pointer = [self.reusedCells valueForKey:identifier];
    
    [self.reusedCells setValue:node forKey:identifier];
}

@end
