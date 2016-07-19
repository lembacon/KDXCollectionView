/* vim: set ft=objc fenc=utf-8 sw=4 ts=4 et: */
/*
 * Copyright (c) 2013 Chongyu Zhu <lembacon@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "KDXCollectionView.h"
#import "KDXCollectionViewCell.h"
#include "KDXGraphicsUtility.h"
#include <Carbon/Carbon.h>

@interface KDXCollectionView (Private)
- (void)_initialize;
- (void)_finalize;

- (void)_clearTrackingArea;
- (void)_clearScrollView;
- (void)_updateScrollView;
- (void)_scrollViewDidScroll:(NSNotification *)notification;

- (void)_preReloadData;
- (void)_postReloadData;

- (NSArray *)_sortedVisibleCells;

- (void)_fixForRemovingItemsAtIndexes:(NSIndexSet *)indexes;
- (void)_fixLayoutAfterRemoving;
- (void)_preRemoveItemsAtIndexes:(NSIndexSet *)indexes;
- (void)_postRemoveItemsAtIndexes:(NSIndexSet *)indexes;

- (void)_fixLayoutAfterMoving;
- (void)_preMoveItemsAtIndexes:(NSIndexSet *)indexes;
- (void)_postMoveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)destinationIndex;

- (void)_fixLayoutAfterInsertion;
- (void)_preInsertItemsAtIndexes:(NSIndexSet *)indexes;
- (void)_postInsertItemsAtIndexes:(NSIndexSet *)indexes;

- (void)_removeCell:(KDXCollectionViewCell *)cell;
- (void)_addCellAtIndex:(NSInteger)index;
- (void)_removeInvisibleCells;
- (void)_addVisibleCells;
- (void)_updateFrame;
- (void)_updateFramesOfCells;
- (void)_layoutCells;
- (void)_layoutCellsBoundsNotChanged;
- (void)_enqueueInvisibleCell:(KDXCollectionViewCell *)cell;

- (void)_drawBackgroundInRect:(NSRect)dirtyRect;
- (void)_drawMultipleSelectionInRect:(NSRect)dirtyRect;
- (void)_drawDroppingIndicatorInRect:(NSRect)dirtyRect;
- (void)_layout;

- (BOOL)_shouldAlignLeft;
- (CGFloat)_leftPadding;
- (NSInteger)_calculateColumnFromOriginX:(CGFloat)originX;
- (NSInteger)_calculateRowFromOriginY:(CGFloat)originY;

- (NSUInteger)_multipleSelectionModifierFlags;
- (BOOL)_shouldSelectMultiple;
- (NSRect)_makeRectWithPoint1:(NSPoint)point1 point2:(NSPoint)point2;
- (void)_updateMultipleSelectionRectWithNewPoint:(NSPoint)point;
- (void)_updateMultipleSelection;
- (void)_beginDraggingSessionAtPoint:(NSPoint)point withEvent:(NSEvent *)event;
- (void)_clearHovering;
- (void)_updateHoveringWithEvent:(NSEvent *)event;

- (void)_handleArrowKeys:(unichar)character;
- (void)_handleScrollKeys:(unichar)character;
- (void)_handleDeleteKey;
- (void)_handleUnprocessedKeyEvent:(NSEvent *)event;
- (NSMenu *)_handleMenuEvent:(NSEvent *)event;

- (void)_updateDropping:(id <NSDraggingInfo>)sender;
- (void)_updateDroppingIndexAndOperationAtPoint:(NSPoint)point isLocal:(BOOL)isLocal;

- (NSInteger)_dataSourceNumberOfItems;
- (KDXCollectionViewCell *)_dataSourceCellForItemAtIndex:(NSInteger)index;
- (void)_dataSourceRemoveItemsAtIndexes:(NSIndexSet *)indexes;
- (void)_dataSourceMoveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)destinationIndex;

- (void)_delegateWillSelectItemAtIndex:(NSInteger)index;
- (void)_delegateDidSelectItemAtIndex:(NSInteger)index;
- (void)_delegateWillDeselectItemAtIndex:(NSInteger)index;
- (void)_delegateDidDeselectItemAtIndex:(NSInteger)index;
- (NSMenu *)_delegateMenuForEvent:(NSEvent *)event forItemAtIndex:(NSInteger)index;
- (void)_delegateKeyEvent:(NSEvent *)event forItemAtIndex:(NSInteger)index;
- (BOOL)_delegateCanDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event;
- (NSDragOperation)_delegateValidateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(KDXCollectionViewDropOperation *)proposedDropOperation;
- (BOOL)_delegateAcceptDrop:(id <NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(KDXCollectionViewDropOperation)dropOperation;
- (id <NSPasteboardWriting>)_delegatePasteboardWriterForItemAtIndex:(NSInteger)index;
- (void)_delegateDraggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItemsAtIndexes:(NSIndexSet *)indexes;
- (void)_delegateDraggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation;
- (void)_delegateUpdateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo;
@end

@implementation KDXCollectionView

// TSF 7/19/2016 Work-around for a nasty bug where visibleCells array is not trustable during a reloadData.
// Ugly, but trying to minimize pod code changes.
static BOOL doingPreReloadData = false;

#pragma mark - Synthesizing Properties

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize cellSize = _cellSize;
@synthesize margin = _margin;
@synthesize intercellSpacing = _intercellSpacing;
@synthesize hoveringIndex = _hoveringIndex;
@synthesize backgroundColor = _backgroundColor;

#pragma mark - Constructor/Destructor

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self _initialize];
    }
    
    return self;
}

- (void)dealloc
{
    [self _finalize];
    [super dealloc];
}

- (void)_initialize
{
    _dataSource = nil;
    _delegate = nil;
    
    _trackingArea = nil;
    _clipView = nil;
    
    _selectedIndexes = [[NSMutableIndexSet alloc] init];
    _hoveringIndex = NSNotFound;
    
    _multipleSelection.startPoint = NSZeroPoint;
    _multipleSelection.rect = NSZeroRect;
    
    _dragging.mouseDownIndex = NSNotFound;
    _dragging.mouseDownPoint = NSZeroPoint;
    
    _dropping.dropIndex = NSNotFound;
    _dropping.dropOperation = KDXCollectionViewDropBefore;
    
    _visibleCells = [[NSMutableArray alloc] init];
    _reusableCells = [[NSMutableDictionary alloc] init];
    
    _cellSize = NSMakeSize(64.0f, 64.0f);
    _margin = NSMakeSize(16.0f, 16.0f);
    _intercellSpacing = NSMakeSize(12.0f, 12.0f);
    
    _numberOfItems = 0;
    _numberOfRows = 0;
    _numberOfColumns = 0;
    
    _backgroundColor = [[NSColor controlBackgroundColor] retain];
    _animationDuration = 0.25f;
    
    _dataSource = (id <KDXCollectionViewDataSource>)[NSNull null];
    _delegate = (id <KDXCollectionViewDelegate>)[NSNull null];
    [self setDataSource:nil];
    [self setDelegate:nil];
    
    _flags.selectable = YES;
    _flags.allowsMultipleSelection = YES;
    
    _flags.animates = YES;
    _flags.removable = YES;
    _flags.allowsReordering = YES;
    _flags.allowsHovering = YES;
    
    _flags.multipleSelectionInPhase = NO;
    _flags.shouldAnimateCellFrameChanging = NO;
    
    _flags.draggingDistanceThreshold = 5;
    _flags.draggingSessionDidBegin = NO;
    
    _flags.droppingAtPreviousRow = NO;
    _flags.droppingInPhase = NO;
    
    [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
}

- (void)_finalize
{
    [self _clearTrackingArea];
    [self _clearScrollView];
    
    [_selectedIndexes release];
    
    [_visibleCells release];
    [_reusableCells release];
    
    if (_backgroundColor != nil) {
        [_backgroundColor release];
    }
}

#pragma mark - Basic Properties

- (void)setDataSource:(id <KDXCollectionViewDataSource>)dataSource
{
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        
#define TEST_SELECTOR(sel) (_dataSource != nil && [_dataSource respondsToSelector:(sel)])
        
        _flags.dataSourceRemoveItemsAtIndexes = TEST_SELECTOR(@selector(collectionView:removeItemsAtIndexes:));
        _flags.dataSourceMoveItemsAtIndexesToIndex = TEST_SELECTOR(@selector(collectionView:moveItemsAtIndexes:toIndex:));
        
#undef TEST_SELECTOR
        
        [self reloadData];
    }
}

- (void)setDelegate:(id <KDXCollectionViewDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        
#define TEST_SELECTOR(sel) (_delegate != nil && [_delegate respondsToSelector:(sel)])
        
        _flags.delegateWillSelectItemAtIndex = TEST_SELECTOR(@selector(collectionView:willSelectItemAtIndex:));
        _flags.delegateDidSelectItemAtIndex = TEST_SELECTOR(@selector(collectionView:didSelectItemAtIndex:));
        _flags.delegateWillDeselectItemAtIndex = TEST_SELECTOR(@selector(collectionView:willDeselectItemAtIndex:));
        _flags.delegateDidDeselectItemAtIndex = TEST_SELECTOR(@selector(collectionView:didDeselectItemAtIndex:));
        
        _flags.delegateMenuForEventForItemAtIndex = TEST_SELECTOR(@selector(collectionView:menuForEvent:forItemAtIndex:));
        _flags.delegateKeyEventForItemAtIndex = TEST_SELECTOR(@selector(collectionView:keyEvent:forItemAtIndex:));
        
        _flags.delegateCanDragItemsAtIndexesWithEvent = TEST_SELECTOR(@selector(collectionView:canDragItemsAtIndexes:withEvent:));
        _flags.delegateValidateDropProposedIndexDropOperation = TEST_SELECTOR(@selector(collectionView:validateDrop:proposedIndex:dropOperation:));
        _flags.delegateAcceptDropIndexDropOperation = TEST_SELECTOR(@selector(collectionView:acceptDrop:index:dropOperation:));
        _flags.delegatePasteboardWriterForItemAtIndex = TEST_SELECTOR(@selector(collectionView:pasteboardWriterForItemAtIndex:));
        _flags.delegateDraggingSessionWillBeginAtPointForItemsAtIndexes = TEST_SELECTOR(@selector(collectionView:draggingSession:willBeginAtPoint:forItemsAtIndexes:));
        _flags.delegateDraggingSessionEndedAtPointDragOperation = TEST_SELECTOR(@selector(collectionView:draggingSession:endedAtPoint:dragOperation:));
        _flags.delegateUpdateDraggingItemsForDrag = TEST_SELECTOR(@selector(collectionView:updateDraggingItemsForDrag:));
        
#undef TEST_SELECTOR
    }
}

- (void)setCellSize:(NSSize)cellSize
{
    if (!NSEqualSizes(_cellSize, cellSize)) {
        _cellSize = cellSize;
        [self _layout];
    }
}

- (void)setMargin:(NSSize)margin
{
    if (!NSEqualSizes(_margin, margin)) {
        _margin = margin;
        [self _layout];
    }
}

- (void)setIntercellSpacing:(NSSize)intercellSpacing
{
    if (!NSEqualSizes(_intercellSpacing, intercellSpacing)) {
        _intercellSpacing = intercellSpacing;
        [self _layout];
    }
}

- (BOOL)isSelectable
{
    return _flags.selectable;
}

- (void)setSelectable:(BOOL)selectable
{
    _flags.selectable = selectable;
}

- (BOOL)allowsMultipleSelection
{
    return _flags.allowsMultipleSelection;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    _flags.allowsMultipleSelection = allowsMultipleSelection;
}

- (BOOL)animates
{
    return _flags.animates;
}

- (void)setAnimates:(BOOL)animates
{
    _flags.animates = animates;
}

- (BOOL)isRemovable
{
    return _flags.removable;
}

- (void)setRemovable:(BOOL)removable
{
    _flags.removable = removable;
}

- (BOOL)allowsReordering
{
    return _flags.allowsReordering;
}

- (void)setAllowsReordering:(BOOL)allowsReordering
{
    _flags.allowsReordering = allowsReordering;
}

- (BOOL)allowsHovering
{
    return _flags.allowsHovering;
}

- (void)setAllowsHovering:(BOOL)allowsHovering
{
    if (_flags.allowsHovering != allowsHovering) {
        _flags.allowsHovering = allowsHovering;
        [self updateTrackingAreas];
    }
}

- (NSIndexSet *)selectedIndexes
{
    return [[_selectedIndexes copy] autorelease];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    if (_backgroundColor != backgroundColor) {
        if (_backgroundColor != nil) {
            [_backgroundColor release];
            _backgroundColor = nil;
        }
        
        if (backgroundColor != nil && backgroundColor != [NSColor clearColor] && ![backgroundColor isEqual:[NSColor clearColor]]) {
            _backgroundColor = [backgroundColor retain];
        }
        
        [self setNeedsDisplay:YES];
    }
}

#pragma mark - Selection/Deselection

- (void)selectItemAtIndex:(NSInteger)index
{
    assert(index >= 0 && index < _numberOfItems);
    
    if (!_flags.selectable || [_selectedIndexes containsIndex:index]) {
        return;
    }
    
    if (!_flags.allowsMultipleSelection) {
        [self deselectAllItems];
    }
    
    [self _delegateWillSelectItemAtIndex:index];
    
    KDXCollectionViewCell *cell = [self cellAtIndex:index];
    if (cell != nil) {
        [cell setSelected:YES];
    }
    
    [_selectedIndexes addIndex:index];
    
    [self _delegateDidSelectItemAtIndex:index];
}

- (void)selectItemsAtIndexes:(NSIndexSet *)indexes
{
    if (_flags.allowsMultipleSelection) {
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self selectItemAtIndex:idx];
        }];
    }
    else {
        if ([indexes count] > 0) {
            [self selectItemAtIndex:[indexes firstIndex]];
        }
    }
}

- (void)deselectItemAtIndex:(NSInteger)index
{
    if (![_selectedIndexes containsIndex:index]) {
        return;
    }
    
    [self _delegateWillDeselectItemAtIndex:index];
    
    KDXCollectionViewCell *cell = [self cellAtIndex:index];
    if (cell != nil) {
        [cell setSelected:NO];
    }
    
    [_selectedIndexes removeIndex:index];
    
    [self _delegateDidDeselectItemAtIndex:index];
}

- (void)deselectItemsAtIndexes:(NSIndexSet *)indexes
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self deselectItemAtIndex:idx];
    }];
}

- (void)selectAllItems
{
    [self selectItemsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfItems)]];
}

- (void)deselectAllItems
{
    [self deselectItemsAtIndexes:[self selectedIndexes]];
}

#pragma mark - Data Reloading

- (void)_preReloadData
{
    doingPreReloadData = true;
    [_selectedIndexes removeAllIndexes];
    _hoveringIndex = NSNotFound;
    
    _numberOfItems = [self _dataSourceNumberOfItems];
    [self _updateFrame];
    doingPreReloadData = false;
}

- (void)_postReloadData
{
    [self _addVisibleCells];
}

- (void)reloadData
{
    [self _preReloadData];
    
    for (KDXCollectionViewCell *cell in [_visibleCells reverseObjectEnumerator]) {
        [self _removeCell:cell];
    }
    
    [self _postReloadData];
}

- (void)reloadDataForIndexes:(NSIndexSet *)indexes
{
    [self _preReloadData];
    
    for (KDXCollectionViewCell *cell in [_visibleCells reverseObjectEnumerator]) {
        if ([indexes containsIndex:[cell index]]) {
            [self _removeCell:cell];
        }
    }
    
    [self _postReloadData];
}

#pragma mark - Cell Creation/Reusability

- (KDXCollectionViewCell *)cellAtIndex:(NSInteger)index
{
    for (KDXCollectionViewCell *cell in _visibleCells) {
        if ([cell index] == index) {
            return cell;
        }
    }
    
    return nil;
}

- (KDXCollectionViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    NSMutableSet *cells = [_reusableCells objectForKey:identifier];
    if (cells == nil || [cells count] == 0) {
        return nil;
    }
    
    KDXCollectionViewCell *cell = [[[cells anyObject] retain] autorelease];
    [cells removeObject:cell];
    
    [cell prepareForReuse];
    return cell;
}

#pragma mark - Item Removing/Reordering/Insertion

- (NSArray *)_sortedVisibleCells
{
    return [_visibleCells sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        KDXCollectionViewCell *cell1 = obj1;
        KDXCollectionViewCell *cell2 = obj2;
        
        NSInteger index1 = [cell1 index];
        NSInteger index2 = [cell2 index];
        
        if (index1 < index2) {
            return NSOrderedAscending;
        }
        else if (index1 > index2) {
            return NSOrderedDescending;
        }
        else {
            assert(0);
            return NSOrderedSame;
        }
    }];
}

- (void)_fixForRemovingItemsAtIndexes:(NSIndexSet *)indexes
{
    NSInteger cellIndexOffset = 0, lastCellIndex = NSNotFound;
    for (KDXCollectionViewCell *cell in [self _sortedVisibleCells]) {
        if (lastCellIndex == NSNotFound) {
            NSInteger previousIndex = [indexes indexLessThanIndex:[cell index]];
            while (previousIndex != NSNotFound) {
                previousIndex = [indexes indexLessThanIndex:previousIndex];
                cellIndexOffset--;
            }
        }
        else {
            NSInteger currentOffset = [cell index] - lastCellIndex;
            assert(currentOffset > 0);
            if (currentOffset > 1) {
                currentOffset--;
                cellIndexOffset -= currentOffset;
            }
        }
        
        lastCellIndex = [cell index];
        [cell setIndex:(lastCellIndex + cellIndexOffset)];
    }
}

- (void)_fixLayoutAfterRemoving
{
    BOOL oldShouldAnimateCellFrameChanging = _flags.shouldAnimateCellFrameChanging;
    _flags.shouldAnimateCellFrameChanging = YES;
    
    [self _updateFrame];
    [self _updateFramesOfCells];
    [self _addVisibleCells];
    
    _flags.shouldAnimateCellFrameChanging = oldShouldAnimateCellFrameChanging;
}

- (void)_preRemoveItemsAtIndexes:(NSIndexSet *)indexes
{
    [self deselectItemsAtIndexes:indexes];
    
    if (_hoveringIndex != NSNotFound && [indexes containsIndex:_hoveringIndex]) {
        [self _clearHovering];
    }
}

- (void)_postRemoveItemsAtIndexes:(NSIndexSet *)indexes
{
    _numberOfItems -= [indexes count];
    [self _dataSourceRemoveItemsAtIndexes:indexes];
    [self _fixForRemovingItemsAtIndexes:indexes];
    [self _fixLayoutAfterRemoving];
    
    if (_flags.allowsHovering) {
        for (KDXCollectionViewCell *cell in _visibleCells) {
            if ([cell index] != _hoveringIndex) {
                [cell setHovering:NO];
            }
        }
    }
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes
{
    assert(_numberOfItems > 0);
    assert([indexes count] > 0);
    
    if (!_flags.removable) {
        return;
    }
    
    NSMutableArray *cells = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        KDXCollectionViewCell *cell = [self cellAtIndex:idx];
        if (cell != nil) {
            [cells addObject:cell];
        }
    }];
    
    if (_flags.animates) {
        NSInteger startIndexToAdd = [[[self _sortedVisibleCells] lastObject] index] + 1;
        __block NSInteger numberToAdd = 0;
        [indexes enumerateRangesInRange:[self visibleRange] options:0 usingBlock:^(NSRange range, BOOL *stop) {
            numberToAdd += range.length;
        }];
        numberToAdd = MIN(numberToAdd, _numberOfItems - [indexes count]);
        for (NSInteger i = startIndexToAdd; numberToAdd > 0 && i < _numberOfItems; i++, numberToAdd--) {
            if ([indexes containsIndex:i]) {
                continue;
            }
            
            [self _addCellAtIndex:i];
        }
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:_animationDuration];
            
            for (KDXCollectionViewCell *cell in cells) {
                [[cell animator] setAlphaValue:0.0f];
            }
        } completionHandler:^{
            [self _preRemoveItemsAtIndexes:indexes];
            for (KDXCollectionViewCell *cell in cells) {
                [[cell animator] setAlphaValue:1.0f];
                [self _removeCell:cell];
            }
            [self _postRemoveItemsAtIndexes:indexes];
        }];
    }
    else {
        [self _preRemoveItemsAtIndexes:indexes];
        for (KDXCollectionViewCell *cell in cells) {
            [self _removeCell:cell];
        }
        [self _postRemoveItemsAtIndexes:indexes];
    }
}

- (void)_fixLayoutAfterMoving
{
    BOOL oldShouldAnimateCellFrameChanging = _flags.shouldAnimateCellFrameChanging;
    _flags.shouldAnimateCellFrameChanging = YES;
    
    [self _updateFramesOfCells];
    [self _addVisibleCells];
    
    _flags.shouldAnimateCellFrameChanging = oldShouldAnimateCellFrameChanging;
}

- (void)_preMoveItemsAtIndexes:(NSIndexSet *)indexes
{
    [self deselectItemsAtIndexes:indexes];
    
    if (_hoveringIndex != NSNotFound && [indexes containsIndex:_hoveringIndex]) {
        [self _clearHovering];
    }
}

- (void)_postMoveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)destinationIndex
{
    [self _dataSourceMoveItemsAtIndexes:indexes toIndex:destinationIndex];
    [self _fixLayoutAfterMoving];
    
    if (_flags.allowsHovering) {
        for (KDXCollectionViewCell *cell in _visibleCells) {
            if ([cell index] != _hoveringIndex) {
                [cell setHovering:NO];
            }
        }
    }
}

- (void)moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)destinationIndex
{
    assert(_numberOfItems > 0);
    assert([indexes count] > 0);
    assert(destinationIndex >= 0 && destinationIndex <= _numberOfItems);
    
    if (!_flags.allowsReordering) {
        return;
    }
    
    [self _preMoveItemsAtIndexes:indexes];
    
    NSInteger originalDestinationIndex = destinationIndex;
    NSRange visibleRange = [self visibleRange];
    NSMutableArray *visibleCells = [[[self _sortedVisibleCells] mutableCopy] autorelease];
    NSMutableArray *temporaryCells = [NSMutableArray array];
    
    for (NSInteger index = [indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index]) {
        if (index < destinationIndex) {
            destinationIndex--;
        }
        
        KDXCollectionViewCell *cell = [self cellAtIndex:index];
        if (cell != nil) {
            [temporaryCells addObject:cell];
            [visibleCells removeObject:cell];
        }
        else {
            [self _addCellAtIndex:index];
            
            cell = [self cellAtIndex:index];
            [cell setFrame:[self rectForCellAtIndex:index]];
            
            [temporaryCells addObject:cell];
        }
    }
    
    NSInteger currentIndex = MIN(destinationIndex, visibleRange.location);
    destinationIndex -= visibleRange.location;
    destinationIndex = MAX(destinationIndex, 0);
    assert(destinationIndex >= 0 && destinationIndex <= [visibleCells count]);
    
    for (KDXCollectionViewCell *cell in temporaryCells) {
        [visibleCells insertObject:cell atIndex:destinationIndex];
    }
    
    for (KDXCollectionViewCell *cell in visibleCells) {
        if (NSLocationInRange(currentIndex, visibleRange)) {
            [cell setIndex:currentIndex];
        }
        else {
            [self _removeCell:cell];
        }
        
        currentIndex++;
    }
    
    [self _postMoveItemsAtIndexes:indexes toIndex:originalDestinationIndex];
}

- (void)_fixLayoutAfterInsertion
{
    BOOL oldShouldAnimateCellFrameChanging = _flags.shouldAnimateCellFrameChanging;
    _flags.shouldAnimateCellFrameChanging = YES;
    
    [self _updateFrame];
    [self _updateFramesOfCells];
    [self _removeInvisibleCells];
    [self _addVisibleCells];
    
    _flags.shouldAnimateCellFrameChanging = oldShouldAnimateCellFrameChanging;
}

- (void)_preInsertItemsAtIndexes:(NSIndexSet *)indexes
{
    [self deselectItemsAtIndexes:indexes];
    
    if (_hoveringIndex != NSNotFound && [indexes containsIndex:_hoveringIndex]) {
        [self _clearHovering];
    }
}

- (void)_postInsertItemsAtIndexes:(NSIndexSet *)indexes
{
    _numberOfItems += [indexes count];
    [self _fixLayoutAfterInsertion];
    
    if (_flags.allowsHovering) {
        for (KDXCollectionViewCell *cell in _visibleCells) {
            if ([cell index] != _hoveringIndex) {
                [cell setHovering:NO];
            }
        }
    }
}

- (void)insertItemsAtIndexes:(NSIndexSet *)indexes
{
    if ([indexes count] == 0) {
        return;
    }
    
    if (_numberOfItems == 0) {
        [self reloadData];
        return;
    }
    
    [self _preInsertItemsAtIndexes:indexes];
    
    NSInteger cellIndexOffset = 0, lastValidIndex = NSNotFound;
    for (KDXCollectionViewCell *cell in [self _sortedVisibleCells]) {
        NSInteger currentIndex = [cell index];
        if ((lastValidIndex == NSNotFound || (currentIndex - lastValidIndex) == cellIndexOffset) && [indexes containsIndex:currentIndex]) {
            lastValidIndex = currentIndex;
            
            NSInteger nextIndex, tmpIndex = currentIndex;
            do {
                nextIndex = tmpIndex;
                tmpIndex = [indexes indexGreaterThanIndex:nextIndex];
                
                cellIndexOffset++;
            } while (tmpIndex != NSNotFound && (tmpIndex - nextIndex) == 1);
        }
        
        [cell setIndex:(currentIndex + cellIndexOffset)];
    }
    
    [indexes enumerateIndexesInRange:[self visibleRange] options:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
        [self _addCellAtIndex:idx];
    }];
    
    [self _postInsertItemsAtIndexes:indexes];
}

#pragma mark - Cell Layout

- (void)_removeCell:(KDXCollectionViewCell *)cell
{
    assert([_visibleCells containsObject:cell]);
    [cell removeFromSuperview];
    [cell retain];
    [_visibleCells removeObject:cell];
    [self _enqueueInvisibleCell:cell];
    [cell release];
}

- (void)_addCellAtIndex:(NSInteger)index
{
    assert(index >= 0 && index < _numberOfItems);
    assert([self cellAtIndex:index] == nil);
    
    KDXCollectionViewCell *cell = [self _dataSourceCellForItemAtIndex:index];
    assert(cell != nil);
    
    if ([_selectedIndexes containsIndex:index]) {
        [cell setSelected:YES];
    }
    
    [cell setIndex:index];
    [cell setFrame:[self rectForCellAtIndex:index]];
    [_visibleCells addObject:cell];
    [self addSubview:cell];
}

- (void)_removeInvisibleCells
{
    NSRect visibleRect = [self visibleRect];
    for (KDXCollectionViewCell *cell in [_visibleCells reverseObjectEnumerator]) {
        if (!NSIntersectsRect(visibleRect, [cell frame])) {
            [self _removeCell:cell];
        }
    }
}

- (void)_addVisibleCells
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (KDXCollectionViewCell *cell in _visibleCells) {
        [indexes addIndex:[cell index]];
    }
    
    NSIndexSet *visibleIndexes = [self indexesForVisibleCells];
    [visibleIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if ([indexes containsIndex:idx]) {
            return;
        }
        
        [self _addCellAtIndex:idx];
    }];
}

- (void)_updateFrame
{
    NSRect frame = [self frame];
    
    _numberOfColumns = floor((frame.size.width - _margin.width * 2.0f + _intercellSpacing.width) / (_cellSize.width + _intercellSpacing.width));
    _numberOfRows = ceil((double)_numberOfItems / _numberOfColumns);
    
    CGFloat proposedHeight = _margin.height * 2.0f + _cellSize.height * _numberOfRows + _intercellSpacing.height * (_numberOfRows - 1);
    frame.size.height = fmax(NSHeight([[self enclosingScrollView] bounds]), proposedHeight);
    
    [super setFrame:frame];
}

- (void)_updateFramesOfCells
{
    if (_flags.animates && _flags.shouldAnimateCellFrameChanging) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:_animationDuration];
        
        for (KDXCollectionViewCell *cell in _visibleCells) {
            NSRect rect = [self rectForCellAtIndex:[cell index]];
            [[cell animator] setFrame:rect];
        }
        
        [NSAnimationContext endGrouping];
    }
    else {
        for (KDXCollectionViewCell *cell in _visibleCells) {
            NSRect rect = [self rectForCellAtIndex:[cell index]];
            [cell setFrame:rect];
        }
    }
}

- (void)_layoutCells
{
    [self _updateFrame];
    [self _updateFramesOfCells];
    [self _layoutCellsBoundsNotChanged];
}

- (void)_layoutCellsBoundsNotChanged
{
    [self _removeInvisibleCells];
    [self _addVisibleCells];
}

- (void)_enqueueInvisibleCell:(KDXCollectionViewCell *)cell
{
    NSMutableSet *cells = [_reusableCells objectForKey:[cell cellIdentifier]];
    if (cells == nil) {
        cells = [NSMutableSet set];
        [_reusableCells setObject:cells forKey:[cell cellIdentifier]];
    }
    
    [cells addObject:cell];
}

#pragma mark - View Layout/Draw

- (void)lockFocus
{
    [super lockFocus];
}

- (void)unlockFocus
{
    if (_flags.multipleSelectionInPhase) {
        [self _drawMultipleSelectionInRect:[self visibleRect]];
    }
    
    [super unlockFocus];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (_backgroundColor != nil) {
        [self _drawBackgroundInRect:dirtyRect];
    }
    
    if (_flags.droppingInPhase) {
        [self _drawDroppingIndicatorInRect:dirtyRect];
    }
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    if (!doingPreReloadData) {
        [self _layout];
    }
    
    if ([self inLiveResize]) {
        [self setNeedsDisplay:YES];
    }
}

- (void)_drawBackgroundInRect:(NSRect)dirtyRect
{
    assert(_backgroundColor != nil);
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGRect bounds = NSRectToCGRect([self bounds]);
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, NSRectToCGRect(dirtyRect));
    KDXFlipContext(context, bounds);
    [_backgroundColor setFill];
    CGContextFillRect(context, bounds);
    CGContextRestoreGState(context);
}

- (void)_drawMultipleSelectionInRect:(NSRect)dirtyRect
{
    assert(_flags.selectable && _flags.allowsMultipleSelection);
    assert(_flags.multipleSelectionInPhase);
    
    /*
     * XXX:
     * Since multiple selection rectangle is calculated
     * under the environment with the flipped coordinate
     * orientation, we cannot flip the context back in
     * this scenario.
     */
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    //CGRect bounds = NSRectToCGRect([self bounds]);
    
    CGRect outerRect = NSRectToCGRect(_multipleSelection.rect);
    CGRect innerRect = CGRectInset(outerRect, 1.0f, 1.0f);
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, NSRectToCGRect(dirtyRect));
    //KDXFlipContext(context, bounds);
    
    static struct {
        CGFloat red, green, blue, alpha;
    } borderColor, backgroundColor;
    {
        static BOOL colorInitialized = NO;
        if (!colorInitialized) {
            colorInitialized = YES;
            
            NSColor *color = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.8f];
            color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
            [color getRed:&borderColor.red green:&borderColor.green blue:&borderColor.blue alpha:&borderColor.alpha];
            
            color = [[NSColor selectedControlColor] colorWithAlphaComponent:0.5f];
            color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
            [color getRed:&backgroundColor.red green:&backgroundColor.green blue:&backgroundColor.blue alpha:&backgroundColor.alpha];
        }
    }
    
    CGContextBeginPath(context);
    CGContextAddRect(context, outerRect);
    CGContextAddRect(context, innerRect);
    CGContextSetRGBFillColor(context, borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha);
    CGContextEOFillPath(context);
    
    CGContextSetRGBFillColor(context, backgroundColor.red, backgroundColor.green, backgroundColor.blue, backgroundColor.alpha);
    CGContextFillRect(context, innerRect);
    
    CGContextRestoreGState(context);
}

- (void)_drawDroppingIndicatorInRect:(NSRect)dirtyRect
{
    assert(_flags.droppingInPhase);
    
    static const CGFloat indicatorWidth = 12.0f;
    static struct {
        CGFloat red, green, blue, alpha;
    } indicatorColor;
    {
        static BOOL indicatorColorInitialized = NO;
        if (!indicatorColorInitialized) {
            indicatorColorInitialized = YES;
            
            NSColor *color = [NSColor alternateSelectedControlColor];
            color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
            [color getRed:&indicatorColor.red green:&indicatorColor.green blue:&indicatorColor.blue alpha:&indicatorColor.alpha];
        }
    }
    
    CGRect indicatorRect;
    if (_dropping.dropIndex == _numberOfItems) {
        if (_numberOfItems == 0) {
            indicatorRect.origin.x = _margin.width + [self _leftPadding] - indicatorWidth;
            indicatorRect.origin.y = _margin.height;
            indicatorRect.size.width = indicatorWidth;
            indicatorRect.size.height = _cellSize.height;
        }
        else {
            NSRect cellRect = [self rectForCellAtIndex:(_dropping.dropIndex - 1)];
            indicatorRect.origin.x = NSMaxX(cellRect) + _intercellSpacing.width - indicatorWidth;
            indicatorRect.origin.y = NSMinY(cellRect);
            indicatorRect.size.width = indicatorWidth;
            indicatorRect.size.height = NSHeight(cellRect);
        }
    }
    else if (_flags.droppingAtPreviousRow) {
        assert(_numberOfItems > 0);
        assert(_dropping.dropIndex % _numberOfColumns == 0);
        
        NSRect cellRect = [self rectForCellAtIndex:(_dropping.dropIndex - 1)];
        indicatorRect.origin.x = NSMaxX(cellRect) + _intercellSpacing.width - indicatorWidth;
        indicatorRect.origin.y = NSMinY(cellRect);
        indicatorRect.size.width = indicatorWidth;
        indicatorRect.size.height = NSHeight(cellRect);
    }
    else {
        NSRect cellRect = [self rectForCellAtIndex:_dropping.dropIndex];
        indicatorRect.origin.x = NSMinX(cellRect) - indicatorWidth;
        indicatorRect.origin.y = NSMinY(cellRect);
        indicatorRect.size.width = indicatorWidth;
        indicatorRect.size.height = NSHeight(cellRect);
    }
    
    /*
     * XXX:
     * Since dropping indicator rectangle is calculated
     * under the environment with the flipped coordinate
     * orientation, we cannot flip the context back in
     * this scenario.
     */
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    //CGRect bounds = NSRectToCGRect([self bounds]);
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, NSRectToCGRect(dirtyRect));
    //KDXFlipContext(context, bounds);
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(indicatorRect), CGRectGetMinY(indicatorRect));
    KDXFlipContext(context, CGRectMake(0.0f, 0.0f, CGRectGetWidth(indicatorRect), CGRectGetHeight(indicatorRect)));
    {
        CGMutablePathRef path = CGPathCreateMutable();
        
        CGRect rect = CGRectInset(CGRectMake(0.0f, 0.0f, indicatorWidth, CGRectGetHeight(indicatorRect)), 4.0f, 0.0f);
        CGFloat radius = CGRectGetWidth(rect) / 2.0f;
        
        CGPathMoveToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMinY(rect) + radius);
        CGPathAddArc(path, NULL, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect) + radius, radius, 0.0f, M_PI * 2.0f, false);
        CGPathCloseSubpath(path);
        
        CGPathMoveToPoint(path, NULL, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect) + radius * 2.0f);
        CGPathAddLineToPoint(path, NULL, CGRectGetMinX(rect) + radius, CGRectGetMaxY(rect) - radius * 2.0f);
        CGPathCloseSubpath(path);
        
        CGPathMoveToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMaxY(rect) - radius);
        CGPathAddArc(path, NULL, CGRectGetMinX(rect) + radius, CGRectGetMaxY(rect) - radius, radius, 0.0f, M_PI * 2.0f, false);
        CGPathCloseSubpath(path);
        
        CGContextAddPath(context, path);
        CGPathRelease(path);
        
        CGContextSetLineWidth(context, 2.0f);
        CGContextSetRGBStrokeColor(context, indicatorColor.red, indicatorColor.green, indicatorColor.blue, indicatorColor.alpha);
        CGContextStrokePath(context);
    }
    CGContextRestoreGState(context);
    
    CGContextRestoreGState(context);
}

- (void)_layout
{
    [self _layoutCells];
}

#pragma mark - Point/Rect/Index Calculation

- (NSRange)visibleRange
{
    if (_numberOfItems == 0) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    NSIndexSet *indexes = [self indexesForVisibleCells];
    if ([indexes count] == 0) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    NSUInteger firstIndex = [indexes firstIndex];
    NSUInteger lastIndex = [indexes lastIndex];
    assert((lastIndex - firstIndex + 1) == [indexes count]);
    
    return NSMakeRange(firstIndex, lastIndex - firstIndex + 1);
}

- (NSRect)visibleRect
{
    return [super visibleRect];
}

- (NSIndexSet *)indexesForVisibleCells
{
    return [self indexesForCellsInRect:[self visibleRect]];
}

- (NSIndexSet *)indexesForCellsInRect:(NSRect)rect
{
    if (_numberOfItems == 0) {
        return [NSIndexSet indexSet];
    }
    
    assert(_numberOfRows > 0);
    assert(_numberOfColumns > 0);
    
    CGFloat minRow, minColumn;
    {
        minColumn = fmax(floor((NSMinX(rect) - _margin.width - [self _leftPadding] + _intercellSpacing.width) / (_cellSize.width + _intercellSpacing.width)), 0.0f);
        CGFloat proposedMinX = _margin.width + [self _leftPadding] + minColumn * (_cellSize.width + _intercellSpacing.width);
        rect.size.width += (NSMinX(rect) - proposedMinX);
        rect.origin.x = proposedMinX;
        
        minRow = fmax(floor((NSMinY(rect) - _margin.height + _intercellSpacing.height) / (_cellSize.height + _intercellSpacing.height)), 0.0f);
        CGFloat proposedMinY = _margin.height + minRow * (_cellSize.height + _intercellSpacing.height);
        rect.size.height += (NSMinY(rect) - proposedMinY);
        rect.origin.y = proposedMinY;
    }
    
    if (minRow >= _numberOfRows || minColumn >= _numberOfColumns) {
        return [NSIndexSet indexSet];
    }
    
    NSInteger rowCount, columnCount;
    {
        columnCount = ceil(NSWidth(rect) / (_cellSize.width + _intercellSpacing.width));
        rowCount = ceil(NSHeight(rect) / (_cellSize.height + _intercellSpacing.height));
    }
    
    if (minRow + rowCount > _numberOfRows) {
        rowCount = _numberOfRows - minRow;
    }
    if (minColumn + columnCount > _numberOfColumns) {
        columnCount = _numberOfColumns - minColumn;
    }
    
    if (rowCount == 0 || columnCount == 0) {
        return [NSIndexSet indexSet];
    }
    
    //NSLog(@"minRow: %ld, rowCount: %ld, minColumn: %ld, columnCount: %ld", (NSInteger)minRow, rowCount, (NSInteger)minColumn, columnCount);
    
    if (minColumn == 0 && columnCount == _numberOfColumns) {
        NSRange range;
        range.location = minRow * _numberOfColumns;
        range.length = rowCount * _numberOfColumns;
        
        if (NSMaxRange(range) > _numberOfItems) {
            range.length = _numberOfItems - range.location;
        }
        
        return [NSIndexSet indexSetWithIndexesInRange:range];
    }
    
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSInteger row = minRow; row < minRow + rowCount; row++) {
        NSRange range;
        range.location = row * _numberOfColumns + minColumn;
        range.length = columnCount;
        
        if (NSMaxRange(range) > _numberOfItems) {
            range.length = _numberOfItems - range.location;
        }
        
        [indexes addIndexesInRange:range];
    }
    
    return indexes;
}

- (NSRect)rectForCellAtIndex:(NSInteger)index
{
    assert(index >= 0 && index < _numberOfItems);
    
    if ([self _shouldAlignLeft]) {
        // The first row has enough space to fit more columns,
        // so cells are left-aligned.
        
        NSRect rect;
        rect.origin.x = _margin.width + index * _cellSize.width + index * _intercellSpacing.width;
        rect.origin.y = _margin.height;
        rect.size = _cellSize;
        
        return rect;
    }
    else {
        // Otherwise, cells are center-aligned.
        
        NSInteger row = index / _numberOfColumns;
        NSInteger column = index % _numberOfColumns;
        
        NSRect rect;
        rect.origin.x = _margin.width + [self _leftPadding] + column * _cellSize.width + column * _intercellSpacing.width;
        rect.origin.y = _margin.height + row * _cellSize.height + row * _intercellSpacing.height;
        rect.size = _cellSize;
        
        return rect;
    }
}

- (NSInteger)indexOfCellAtPoint:(NSPoint)point
{
    if (_numberOfItems == 0) {
        return NSNotFound;
    }
    
    NSInteger row = [self _calculateRowFromOriginY:point.y];
    if (row == NSNotFound || row < 0 || row >= _numberOfRows) {
        return NSNotFound;
    }
    
    NSInteger column = [self _calculateColumnFromOriginX:point.x];
    if (column == NSNotFound || column < 0 || column >= _numberOfColumns) {
        return NSNotFound;
    }
    
    NSInteger index = row * _numberOfColumns + column;
    if (index >= _numberOfItems) {
        return NSNotFound;
    }
    
    return index;
}

- (BOOL)_shouldAlignLeft
{
    // The first row has enough space to fit more columns,
    // so cells are left-aligned.
    return _numberOfItems < _numberOfColumns;
}

- (CGFloat)_leftPadding
{
    if ([self _shouldAlignLeft]) {
        return 0.0f;
    }
    
    CGFloat horizontalMargin = _margin.width;
    CGFloat maxWidth = NSWidth([self bounds]) - horizontalMargin * 2.0f;
    CGFloat leftPadding = round((maxWidth - _numberOfColumns * _cellSize.width - (_numberOfColumns - 1) * _intercellSpacing.width) / 2.0f);
    
    return leftPadding;
}

- (NSInteger)_calculateColumnFromOriginX:(CGFloat)originX
{
    assert(_numberOfItems > 0);
    assert(_numberOfRows > 0);
    assert(_numberOfColumns > 0);
    
    NSInteger column = floor((originX - _margin.width - [self _leftPadding]) / (_cellSize.width + _intercellSpacing.width));
    if (column < 0 || column >= _numberOfColumns) {
        // caller must be careful with the returned value
        return column;
    }
    
    CGFloat proposedOriginX = _margin.width + [self _leftPadding] + column * _cellSize.width + column * _intercellSpacing.width;
    CGFloat proposedMaxX = proposedOriginX + _cellSize.width;
    
    assert(originX >= proposedOriginX);
    if (originX > proposedMaxX) {
        return NSNotFound;
    }
    
    return column;
}

- (NSInteger)_calculateRowFromOriginY:(CGFloat)originY
{
    assert(_numberOfItems > 0);
    assert(_numberOfRows > 0);
    assert(_numberOfColumns > 0);
    
    NSInteger row = floor((originY - _margin.height) / (_cellSize.height + _intercellSpacing.height));
    if (row < 0 || row >= _numberOfRows) {
        // caller must be careful with the returned value
        return row;
    }
    
    CGFloat proposedOriginY = _margin.height + row * _cellSize.height + row * _intercellSpacing.height;
    CGFloat proposedMaxY = proposedOriginY + _cellSize.height;
    
    assert(originY >= proposedOriginY);
    if (originY > proposedMaxY) {
        return NSNotFound;
    }
    
    return row;
}

#pragma mark - Mouse Event

- (NSUInteger)_multipleSelectionModifierFlags
{
    return NSShiftKeyMask | NSCommandKeyMask;
}

- (BOOL)_shouldSelectMultiple
{
    if (!_flags.selectable || !_flags.allowsMultipleSelection) {
        return NO;
    }
    
    NSUInteger modifierFlags = [NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    if (!!(modifierFlags & [self _multipleSelectionModifierFlags])) {
        return YES;
    }
    
    return NO;
}

- (NSRect)_makeRectWithPoint1:(NSPoint)point1 point2:(NSPoint)point2
{
    NSRect rect;
    if (point1.x <= point2.x) {
        if (point1.y <= point2.y) {
            rect.origin = point1;
            rect.size.width = point2.x - point1.x;
            rect.size.height = point2.y - point1.y;
        }
        else {
            rect.origin.x = point1.x;
            rect.origin.y = point2.y;
            rect.size.width = point2.x - point1.x;
            rect.size.height = point1.y - point2.y;
        }
    }
    else {
        if (point1.y <= point2.y) {
            rect.origin.x = point2.x;
            rect.origin.y = point1.y;
            rect.size.width = point1.x - point2.x;
            rect.size.height = point2.y - point1.y;
        }
        else {
            rect.origin = point2;
            rect.size.width = point1.x - point2.x;
            rect.size.height = point1.y - point2.y;
        }
    }
    
    return rect;
}

- (void)_updateMultipleSelectionRectWithNewPoint:(NSPoint)point
{
    NSRect rect = [self _makeRectWithPoint1:_multipleSelection.startPoint point2:point];
    rect = NSIntegralRect(rect);
    rect = NSIntersectionRect(rect, [self bounds]);
    
    _multipleSelection.rect = rect;
}

- (void)_updateMultipleSelection
{
    assert(_flags.selectable && _flags.allowsMultipleSelection);
    if (![self _shouldSelectMultiple]) {
        [self deselectAllItems];
    }
    
    NSIndexSet *indexes = [self indexesForCellsInRect:_multipleSelection.rect];
    [self selectItemsAtIndexes:indexes];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (_flags.selectable) {
        [[self window] makeFirstResponder:self];
        
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSInteger index = [self indexOfCellAtPoint:point];
        
        _dragging.mouseDownIndex = NSNotFound;
        _dragging.mouseDownPoint = point;
        _flags.draggingSessionDidBegin = NO;
        
        if (index == NSNotFound) {
            if (![self _shouldSelectMultiple]) {
                [self deselectAllItems];
            }
            
            if (_flags.allowsMultipleSelection) {
                _multipleSelection.startPoint = point;
                _multipleSelection.rect = NSZeroRect;
                _flags.multipleSelectionInPhase = YES;
                [self setNeedsDisplay:YES];
            }
        }
        else if (![_selectedIndexes containsIndex:index]) {
            if (![self _shouldSelectMultiple]) {
                [self deselectAllItems];
            }
            
            [self selectItemAtIndex:index];
        }
        else {
            _dragging.mouseDownIndex = index;
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (_flags.multipleSelectionInPhase) {
        _flags.multipleSelectionInPhase = NO;
        [self setNeedsDisplay:YES];
    }
    
    if (_dragging.mouseDownIndex != NSNotFound) {
        if (![self _shouldSelectMultiple]) {
            [self deselectAllItems];
            [self selectItemAtIndex:_dragging.mouseDownIndex];
        }
        else {
            [self deselectItemAtIndex:_dragging.mouseDownIndex];
        }
        
        _dragging.mouseDownIndex = NSNotFound;
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (_flags.multipleSelectionInPhase) {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        if (point.y < NSMinY([self visibleRect]) || point.y > NSMaxY([self visibleRect])) {
            [self autoscroll:theEvent];
        }
        
        [self _updateMultipleSelectionRectWithNewPoint:point];
        [self _updateMultipleSelection];
        [self setNeedsDisplay:YES];
    }
    else if ([_selectedIndexes count] > 0 && (_flags.allowsReordering || [self _delegateCanDragItemsAtIndexes:_selectedIndexes withEvent:theEvent])) {
        if (_flags.draggingSessionDidBegin) {
            return;
        }
        
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        CGFloat draggingDistance = sqrt(pow(fabs(point.x - _dragging.mouseDownPoint.x), 2.0f) + pow(fabs(point.y - _dragging.mouseDownPoint.y), 2.0f));
        if (round(draggingDistance) < _flags.draggingDistanceThreshold) {
            return;
        }
        
        assert(_dragging.mouseDownIndex != NSNotFound || [_selectedIndexes count] == 1);
        [self _beginDraggingSessionAtPoint:point withEvent:theEvent];
        
        _flags.draggingSessionDidBegin = YES;
    }
}

- (void)_beginDraggingSessionAtPoint:(NSPoint)point withEvent:(NSEvent *)event
{
    assert(!_flags.draggingSessionDidBegin);
    
    __block NSMutableArray *draggingItems = [NSMutableArray arrayWithCapacity:[_selectedIndexes count]];
    [_selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        id <NSPasteboardWriting> pasteboardWriter = [self _delegatePasteboardWriterForItemAtIndex:idx];
        if (pasteboardWriter == nil) {
            return;
        }
        
        NSImage *draggingImage;
        NSRect draggingFrame;
        
        KDXCollectionViewCell *cell = [self cellAtIndex:idx];
        if (cell != nil) {
            BOOL isSelected = [cell isSelected];
            BOOL isHovering = [cell isHovering];
            
            [cell setSelected:NO];
            [cell setHovering:NO];
            
            NSData *pdfData = [cell dataWithPDFInsideRect:[cell bounds]];
            draggingImage = [[[NSImage alloc] initWithData:pdfData] autorelease];
            
            [cell setSelected:isSelected];
            [cell setHovering:isHovering];
            
            draggingFrame = [cell frame];
            cell = nil;
        }
        else {
            cell = [self _dataSourceCellForItemAtIndex:idx];
            draggingFrame = [self rectForCellAtIndex:idx];
            [cell setFrame:draggingFrame];
            
            NSData *pdfData = [cell dataWithPDFInsideRect:[cell bounds]];
            draggingImage = [[[NSImage alloc] initWithData:pdfData] autorelease];
            
            [self _enqueueInvisibleCell:cell];
            cell = nil;
        }
        
        NSDraggingItem *draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pasteboardWriter];
        [draggingItem setDraggingFrame:draggingFrame contents:draggingImage];
        
        [draggingItems addObject:draggingItem];
        [draggingItem release];
    }];
    
    NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:draggingItems event:event source:self];
    [draggingSession setAnimatesToStartingPositionsOnCancelOrFail:YES];
    [draggingSession setDraggingFormation:NSDraggingFormationNone];
}

- (void)_clearHovering
{
    if (_hoveringIndex != NSNotFound) {
        KDXCollectionViewCell *cell = [self cellAtIndex:_hoveringIndex];
        if (cell != nil) {
            [cell setHovering:NO];
        }
        
        _hoveringIndex = NSNotFound;
    }
}

- (void)_updateHoveringWithEvent:(NSEvent *)event
{
    NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
    NSInteger index = [self indexOfCellAtPoint:point];
    
    if (_hoveringIndex != index) {
        if (_hoveringIndex != NSNotFound) {
            [self _clearHovering];
        }
        else {
            _hoveringIndex = index;
            
            KDXCollectionViewCell *cell = [self cellAtIndex:_hoveringIndex];
            if (cell != nil) {
                [cell setHovering:YES];
            }
        }
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self _clearHovering];
    [self _updateHoveringWithEvent:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self _clearHovering];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [self _updateHoveringWithEvent:theEvent];
}

#pragma mark - Scrolling

- (void)scrollCellToVisible:(NSInteger)index
{
    assert(index >= 0 && index < _numberOfItems);
    
    if (!NSLocationInRange(index, [self visibleRange])) {
        [self scrollRectToVisible:[self rectForCellAtIndex:index]];
    }
}

- (void)scrollToBeginningOfDocument:(id)sender
{
    if (_numberOfItems == 0) {
        return;
    }
    
    [self scrollCellToVisible:0];
}

- (void)scrollToEndOfDocument:(id)sender
{
    if (_numberOfItems == 0) {
        return;
    }
    
    [self scrollCellToVisible:(_numberOfItems - 1)];
}

- (void)scrollPageUp:(id)sender
{
    if (_numberOfItems == 0) {
        return;
    }
    
    NSArray *sortedVisibleCells = [self _sortedVisibleCells];
    assert([sortedVisibleCells count] > 0);
    
    NSInteger firstIndex = [[sortedVisibleCells objectAtIndex:0] index];
    NSInteger lastIndex = [[sortedVisibleCells lastObject] index];
    
    assert(firstIndex % _numberOfColumns == 0);
    lastIndex = ceil((double)lastIndex / _numberOfColumns) * _numberOfColumns - 1;
    
    assert(lastIndex > firstIndex);
    NSInteger maxVisibleCount = lastIndex - firstIndex + 1;
    
    NSInteger proposedIndex = firstIndex - maxVisibleCount;
    if (proposedIndex < 0) {
        proposedIndex = 0;
    }
    
    [self scrollCellToVisible:proposedIndex];
}

- (void)scrollPageDown:(id)sender
{
    if (_numberOfItems == 0) {
        return;
    }
    
    NSArray *sortedVisibleCells = [self _sortedVisibleCells];
    assert([sortedVisibleCells count] > 0);
    
    NSInteger firstIndex = [[sortedVisibleCells objectAtIndex:0] index];
    NSInteger lastIndex = [[sortedVisibleCells lastObject] index];
    
    assert(firstIndex % _numberOfColumns == 0);
    lastIndex = ceil((double)lastIndex / _numberOfColumns) * _numberOfColumns - 1;
    
    assert(lastIndex > firstIndex);
    NSInteger maxVisibleCount = lastIndex - firstIndex + 1;
    
    NSInteger proposedIndex = lastIndex + maxVisibleCount;
    if (proposedIndex >= _numberOfItems) {
        proposedIndex = _numberOfItems - 1;
    }
    
    [self scrollCellToVisible:proposedIndex];
}

#pragma mark - Keyboard Event

- (void)selectAll:(id)sender
{
    [self selectAllItems];
}

- (void)cancelOperation:(id)sender
{
    [self deselectAllItems];
}

- (void)delete:(id)sender
{
    [self _handleDeleteKey];
}

- (void)_handleArrowKeys:(unichar)character
{
    if (_numberOfItems == 0) {
        return;
    }
    
    assert(_numberOfRows > 0);
    assert(_numberOfColumns > 0);
    
    if ([_selectedIndexes count] == 0) {
        [self selectItemAtIndex:0];
        return;
    }
    
    NSInteger index = [_selectedIndexes lastIndex];
    switch (character) {
        case NSUpArrowFunctionKey:
            index -= _numberOfColumns;
            break;
            
        case NSDownArrowFunctionKey:
            index += _numberOfColumns;
            break;
            
        case NSLeftArrowFunctionKey:
            index -= 1;
            break;
            
        case NSRightArrowFunctionKey:
            index += 1;
            break;
            
        default:
            assert(0);
            break;
    }
    
    if (index >= 0 && index < _numberOfItems) {
        [self deselectAllItems];
        [self selectItemAtIndex:index];
        
        [self scrollCellToVisible:index];
    }
}

- (void)_handleScrollKeys:(unichar)character
{
    switch (character) {
        case NSHomeFunctionKey:
            [self scrollToBeginningOfDocument:self];
            break;
            
        case NSEndFunctionKey:
            [self scrollToEndOfDocument:self];
            break;
            
        case NSPageUpFunctionKey:
            [self scrollPageUp:self];
            break;
            
        case NSPageDownFunctionKey:
            [self scrollPageDown:self];
            break;
            
        default:
            assert(0);
            break;
    }
}

- (void)_handleDeleteKey
{
    if (_numberOfItems == 0 || [_selectedIndexes count] == 0) {
        return;
    }
    
    [self removeItemsAtIndexes:[self selectedIndexes]];
}

- (void)_handleUnprocessedKeyEvent:(NSEvent *)event
{
    if (_numberOfItems == 0 || [_selectedIndexes count] == 0) {
        return;
    }
    
    [self _delegateKeyEvent:event forItemAtIndex:[_selectedIndexes lastIndex]];
}

- (NSMenu *)_handleMenuEvent:(NSEvent *)event
{
    if (_numberOfItems == 0) {
        return nil;
    }
    
    NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
    NSInteger index = [self indexOfCellAtPoint:point];
    if (index == NSNotFound) {
        return nil;
    }
    
    return [self _delegateMenuForEvent:event forItemAtIndex:index];
}

- (void)keyDown:(NSEvent *)theEvent
{
    switch ([theEvent keyCode]) {
        case kVK_UpArrow:
        case kVK_DownArrow:
        case kVK_LeftArrow:
        case kVK_RightArrow:
            [self _handleArrowKeys:[[theEvent charactersIgnoringModifiers] characterAtIndex:0]];
            break;
            
        case kVK_Home:
        case kVK_End:
        case kVK_PageUp:
        case kVK_PageDown:
            [self _handleScrollKeys:[[theEvent charactersIgnoringModifiers] characterAtIndex:0]];
            break;
            
        case kVK_Escape:
            [self cancelOperation:self];
            break;
            
        case kVK_Delete:
            [self delete:self];
            break;
            
        default:
            [self _handleUnprocessedKeyEvent:theEvent];
            break;
    }
}

- (void)keyUp:(NSEvent *)theEvent
{
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    return [self _handleMenuEvent:event];
}

#pragma mark - Dragging Source

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    switch (context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
            
        case NSDraggingContextWithinApplication:
        default:
            return NSDragOperationCopy;
    }
}

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint
{
    [self _delegateDraggingSession:session willBeginAtPoint:screenPoint forItemsAtIndexes:_selectedIndexes];
}

- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint
{
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    [self _delegateDraggingSession:session endedAtPoint:screenPoint dragOperation:operation];
}

- (BOOL)ignoreModifierKeysForDraggingSession:(NSDraggingSession *)session
{
    return YES;
}

#pragma mark - Dragging Destination

- (void)_updateDropping:(id <NSDraggingInfo>)sender
{
    NSPoint point = [self convertPoint:[sender draggingLocation] fromView:nil];
    BOOL isLocal = ([sender draggingSource] == self);
    [self _updateDroppingIndexAndOperationAtPoint:point isLocal:isLocal];
}

- (void)_updateDroppingIndexAndOperationAtPoint:(NSPoint)point isLocal:(BOOL)isLocal
{
    assert(!isLocal || _flags.allowsReordering);
    
    NSInteger column;
    if (point.x <= _margin.width + [self _leftPadding]) {
        column = 0;
        _dropping.dropOperation = KDXCollectionViewDropBefore;
    }
    else {
        CGFloat x = point.x - _margin.width - [self _leftPadding];
        column = floor(x / (_cellSize.width + _intercellSpacing.width));
        
        CGFloat proposedX = _margin.width + [self _leftPadding] + column * (_cellSize.width + _intercellSpacing.width);
        CGFloat offsetX = point.x - proposedX;
        assert(offsetX >= 0.0f);
        
        if (offsetX > _cellSize.width / 2.0f) {
            column++;
        }
        
        if (isLocal) {
            _dropping.dropOperation = KDXCollectionViewDropBefore;
        }
        else {
            CGFloat cellMinX = _margin.width + [self _leftPadding] + column * (_cellSize.width + _intercellSpacing.width);
            CGFloat cellMaxX = cellMinX + _cellSize.width;
            CGFloat cellMidX = cellMinX + _cellSize.width / 2.0f;
            
            CGFloat distanceToEdge = fmin(fabs(point.x - cellMinX), fabs(point.x - cellMaxX));
            CGFloat distanceToMiddle = fabs(point.x - cellMidX);
            
            if (distanceToEdge < distanceToMiddle) {
                _dropping.dropOperation = KDXCollectionViewDropBefore;
            }
            else {
                _dropping.dropOperation = KDXCollectionViewDropOn;
            }
        }
    }
    
    NSInteger row;
    if (point.y <= _margin.height) {
        row = 0;
    }
    else {
        CGFloat y = point.y - _margin.height;
        row = floor(y / (_cellSize.height + _intercellSpacing.height));
        
        CGFloat proposedY = _margin.height + row * (_cellSize.height + _intercellSpacing.height);
        CGFloat offsetY = point.y - proposedY;
        assert(offsetY >= 0.0f);
        
        if (offsetY > _cellSize.height + _intercellSpacing.height / 2.0f) {
            row++;
        }
    }
    
    //NSLog(@"row: %ld, column: %ld (%@)", row, column, _dropping.dropOperation == KDXCollectionViewDropBefore ? @"before" : @"on");
    
    BOOL rowDidAdvance = NO;
    if (column >= _numberOfColumns) {
        row++;
        column = 0;
        
        rowDidAdvance = YES;
    }
    
    NSInteger proposedDropIndex = row * _numberOfColumns + column;
    if (proposedDropIndex >= _numberOfItems) {
        proposedDropIndex = _numberOfItems;
    }
    
    BOOL droppingAtPreviousRow = NO;
    if (rowDidAdvance && proposedDropIndex / _numberOfColumns > 0 && proposedDropIndex % _numberOfColumns == 0) {
        droppingAtPreviousRow = YES;
    }
    
    if (_flags.droppingAtPreviousRow != droppingAtPreviousRow || _dropping.dropIndex != proposedDropIndex) {
        _flags.droppingAtPreviousRow = droppingAtPreviousRow;
        _dropping.dropIndex = proposedDropIndex;
        
        [self setNeedsDisplay:YES];
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ([sender draggingSource] == self && !_flags.allowsReordering) {
        return NSDragOperationNone;
    }
    
    NSDragOperation draggingOperation = [self draggingUpdated:sender];
    if (draggingOperation != NSDragOperationNone) {
        _flags.droppingInPhase = YES;
        [self setNeedsDisplay:YES];
    }
    
    return draggingOperation;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    [self _updateDropping:sender];
    
    if ([sender draggingSource] == self) {
        assert(_flags.allowsReordering);
        return NSDragOperationCopy;
    }
    
    return [self _delegateValidateDrop:sender proposedIndex:&_dropping.dropIndex dropOperation:&_dropping.dropOperation];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    _flags.droppingInPhase = NO;
    [self setNeedsDisplay:YES];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    [self draggingExited:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    if ([sender draggingSource] == self) {
        assert(_flags.allowsReordering);
        
        assert([_selectedIndexes count] > 0);
        assert(_dropping.dropIndex >= 0 && _dropping.dropIndex <= _numberOfItems);
        [self moveItemsAtIndexes:[self selectedIndexes] toIndex:_dropping.dropIndex];
        
        return YES;
    }
    
    return [self _delegateAcceptDrop:sender index:_dropping.dropIndex dropOperation:_dropping.dropOperation];
}

- (void)updateDraggingItemsForDrag:(id <NSDraggingInfo>)sender
{
    [self _delegateUpdateDraggingItemsForDrag:sender];
}

#pragma mark - Miscellaneous

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    NSView *hitView = [super hitTest:aPoint];
    
    if (!hitView && NSMouseInRect(aPoint, [self visibleRect], [self isFlipped])) {
        return self;
    }
    
    return hitView;
}

- (void)_clearTrackingArea
{
    if (_trackingArea != nil) {
        [self removeTrackingArea:_trackingArea];
        [_trackingArea release];
        _trackingArea = nil;
    }
}

- (void)updateTrackingAreas
{
    [self _clearTrackingArea];
    
    if (!_flags.allowsHovering) {
        return;
    }
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    [self _clearScrollView];
    [super viewWillMoveToSuperview:newSuperview];
}

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];
    [self _updateScrollView];
}

- (void)_clearScrollView
{
    if (_clipView != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:_clipView];
        [_clipView setPostsBoundsChangedNotifications:NO];
        _clipView = nil;
    }
}

- (void)_updateScrollView
{
    assert(_clipView == nil);
    if ([self superview] == nil) {
        return;
    }
    
    NSScrollView *scrollView = [self enclosingScrollView];
    assert(scrollView != nil);
    _clipView = [scrollView contentView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:_clipView];
    [_clipView setPostsBoundsChangedNotifications:YES];
}

- (void)_scrollViewDidScroll:(NSNotification *)notification
{
    [self _layoutCellsBoundsNotChanged];
    [self setNeedsDisplay:YES];
}

#pragma mark - Data Source Helpers

- (NSInteger)_dataSourceNumberOfItems
{
    if (_dataSource == nil) {
        return 0;
    }
    
    assert([_dataSource respondsToSelector:@selector(numberOfItemsInCollectionView:)]);
    return [_dataSource numberOfItemsInCollectionView:self];
}

- (KDXCollectionViewCell *)_dataSourceCellForItemAtIndex:(NSInteger)index
{
    assert(_dataSource != nil && [_dataSource respondsToSelector:@selector(collectionView:cellForItemAtIndex:)]);
    return [_dataSource collectionView:self cellForItemAtIndex:index];
}

- (void)_dataSourceRemoveItemsAtIndexes:(NSIndexSet *)indexes
{
    if (!_flags.dataSourceRemoveItemsAtIndexes) {
        return;
    }
    
    [_dataSource collectionView:self removeItemsAtIndexes:indexes];
}

- (void)_dataSourceMoveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)destinationIndex
{
    if (!_flags.dataSourceMoveItemsAtIndexesToIndex) {
        return;
    }
    
    [_dataSource collectionView:self moveItemsAtIndexes:indexes toIndex:destinationIndex];
}

#pragma mark - Delegate Helpers

- (void)_delegateWillSelectItemAtIndex:(NSInteger)index
{
    if (!_flags.delegateWillSelectItemAtIndex) {
        return;
    }
    
    [_delegate collectionView:self willSelectItemAtIndex:index];
}

- (void)_delegateDidSelectItemAtIndex:(NSInteger)index
{
    if (!_flags.delegateDidSelectItemAtIndex) {
        return;
    }
    
    [_delegate collectionView:self didSelectItemAtIndex:index];
}

- (void)_delegateWillDeselectItemAtIndex:(NSInteger)index
{
    if (!_flags.delegateWillDeselectItemAtIndex) {
        return;
    }
    
    [_delegate collectionView:self willDeselectItemAtIndex:index];
}

- (void)_delegateDidDeselectItemAtIndex:(NSInteger)index
{
    if (!_flags.delegateDidDeselectItemAtIndex) {
        return;
    }
    
    [_delegate collectionView:self didDeselectItemAtIndex:index];
}

- (NSMenu *)_delegateMenuForEvent:(NSEvent *)event forItemAtIndex:(NSInteger)index
{
    if (!_flags.delegateMenuForEventForItemAtIndex) {
        return nil;
    }
    
    return [_delegate collectionView:self menuForEvent:event forItemAtIndex:index];
}

- (void)_delegateKeyEvent:(NSEvent *)event forItemAtIndex:(NSInteger)index
{
    if (!_flags.delegateKeyEventForItemAtIndex) {
        return;
    }
    
    [_delegate collectionView:self keyEvent:event forItemAtIndex:index];
}

- (BOOL)_delegateCanDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
{
    if (!_flags.delegateCanDragItemsAtIndexesWithEvent) {
        return NO;
    }
    
    return [_delegate collectionView:self canDragItemsAtIndexes:indexes withEvent:event];
}

- (NSDragOperation)_delegateValidateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(KDXCollectionViewDropOperation *)proposedDropOperation
{
    if (!_flags.delegateValidateDropProposedIndexDropOperation) {
        return NSDragOperationNone;
    }
    
    return [_delegate collectionView:self validateDrop:draggingInfo proposedIndex:proposedDropIndex dropOperation:proposedDropOperation];
}

- (BOOL)_delegateAcceptDrop:(id <NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(KDXCollectionViewDropOperation)dropOperation
{
    if (!_flags.delegateAcceptDropIndexDropOperation) {
        return NO;
    }
    
    return [_delegate collectionView:self acceptDrop:draggingInfo index:index dropOperation:dropOperation];
}

- (id <NSPasteboardWriting>)_delegatePasteboardWriterForItemAtIndex:(NSInteger)index
{
    if (!_flags.delegatePasteboardWriterForItemAtIndex) {
        return nil;
    }
    
    return [_delegate collectionView:self pasteboardWriterForItemAtIndex:index];
}

- (void)_delegateDraggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItemsAtIndexes:(NSIndexSet *)indexes
{
    if (!_flags.delegateDraggingSessionWillBeginAtPointForItemsAtIndexes) {
        return;
    }
    
    [_delegate collectionView:self draggingSession:session willBeginAtPoint:screenPoint forItemsAtIndexes:indexes];
}

- (void)_delegateDraggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation
{
    if (!_flags.delegateDraggingSessionEndedAtPointDragOperation) {
        return;
    }
    
    [_delegate collectionView:self draggingSession:session endedAtPoint:screenPoint dragOperation:operation];
}

- (void)_delegateUpdateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo
{
    if (!_flags.delegateUpdateDraggingItemsForDrag) {
        return;
    }
    
    [_delegate collectionView:self updateDraggingItemsForDrag:draggingInfo];
}

@end
