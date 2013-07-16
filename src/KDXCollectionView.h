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

#import <Cocoa/Cocoa.h>

@class KDXCollectionView;
@class KDXCollectionViewCell;

typedef enum {
    KDXCollectionViewDropOn,
    KDXCollectionViewDropBefore
} KDXCollectionViewDropOperation;

@protocol KDXCollectionViewDataSource <NSObject>
@required
- (NSInteger)numberOfItemsInCollectionView:(KDXCollectionView *)collectionView;
- (KDXCollectionViewCell *)collectionView:(KDXCollectionView *)collectionView cellForItemAtIndex:(NSInteger)index;
@optional
- (void)collectionView:(KDXCollectionView *)collectionView removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)collectionView:(KDXCollectionView *)collectionView moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)destinationIndex;
@end

@protocol KDXCollectionViewDelegate <NSObject>
@optional
- (void)collectionView:(KDXCollectionView *)collectionView willSelectItemAtIndex:(NSInteger)index;
- (void)collectionView:(KDXCollectionView *)collectionView didSelectItemAtIndex:(NSInteger)index;
- (void)collectionView:(KDXCollectionView *)collectionView willDeselectItemAtIndex:(NSInteger)index;
- (void)collectionView:(KDXCollectionView *)collectionView didDeselectItemAtIndex:(NSInteger)index;

- (NSMenu *)collectionView:(KDXCollectionView *)collectionView menuForEvent:(NSEvent *)event forItemAtIndex:(NSInteger)index;
- (void)collectionView:(KDXCollectionView *)collectionView keyEvent:(NSEvent *)event forItemAtIndex:(NSInteger)index;

- (BOOL)collectionView:(KDXCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event;
- (NSDragOperation)collectionView:(KDXCollectionView *)collectionView validateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(KDXCollectionViewDropOperation *)proposedDropOperation;
- (BOOL)collectionView:(KDXCollectionView *)collectionView acceptDrop:(id <NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(KDXCollectionViewDropOperation)dropOperation;
- (id <NSPasteboardWriting>)collectionView:(KDXCollectionView *)collectionView pasteboardWriterForItemAtIndex:(NSInteger)index;
- (void)collectionView:(KDXCollectionView *)collectionView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItemsAtIndexes:(NSIndexSet *)indexes;
- (void)collectionView:(KDXCollectionView *)collectionView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation;
- (void)collectionView:(KDXCollectionView *)collectionView updateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo;
@end

/*
 * KDXCollectionView provides an alternative implementation for
 * NSCollectionView (which features very poor performance,
 * and, indeed, it just sucks).
 *
 * There are currently some limitations (characteristics in other
 * perspective). In particular,
 *
 * ** All cells have a fixed size.
 *    If the size is adjusted dynamically, all visible
 *    cells will be re-layouted and re-drawn accordingly
 *    and animatedly;
 *    (NOTE: Since KDXCollectionView is originally designed
 *           for KDXContactCollectionView, the suggested
 *           implementation is to figure out a suitable cell
 *           size, and then use NSScrollView inside each cell.
 *    )
 *
 * ** Only vertical scrolling is allowed.
 *    Vertical margin and intercell spacing are both fixed;
 *
 * ** Only when the first row has enough space to fit more
 *    columns, the cells would be left-aligned, and both horizontal
 *    margin and intercell spacing would be fixed and used to determine
 *    the frames for cells.
 *    Otherwise, cells will be center-aligned whilst the horizontal
 *    margin becomes the minimum horizontal margin, and the
 *    horizontal intercell spacing is still valid.
 */

@interface KDXCollectionView : NSView <NSDraggingSource, NSDraggingDestination> {
@private
    id <KDXCollectionViewDataSource> _dataSource;
    id <KDXCollectionViewDelegate> _delegate;
    
    NSTrackingArea *_trackingArea;
    NSClipView *_clipView;
    
    NSMutableIndexSet *_selectedIndexes;
    NSInteger _hoveringIndex;
    
    struct {
        NSPoint startPoint;
        NSRect rect;
    } _multipleSelection;
    
    struct {
        NSInteger mouseDownIndex;
        NSPoint mouseDownPoint;
    } _dragging;
    
    struct {
        NSInteger dropIndex;
        KDXCollectionViewDropOperation dropOperation;
    } _dropping;
    
    NSMutableArray *_visibleCells;
    NSMutableDictionary *_reusableCells;
    
    NSSize _cellSize;
    NSSize _margin;
    NSSize _intercellSpacing;
    
    NSInteger _numberOfItems;
    NSInteger _numberOfRows;
    NSInteger _numberOfColumns;
    
    NSColor *_backgroundColor;
    NSTimeInterval _animationDuration;
    
    struct {
        unsigned int dataSourceRemoveItemsAtIndexes : 1;
        unsigned int dataSourceMoveItemsAtIndexesToIndex : 1;
        
        unsigned int delegateWillSelectItemAtIndex : 1;
        unsigned int delegateDidSelectItemAtIndex : 1;
        unsigned int delegateWillDeselectItemAtIndex : 1;
        unsigned int delegateDidDeselectItemAtIndex : 1;
        unsigned int delegateMenuForEventForItemAtIndex : 1;
        unsigned int delegateKeyEventForItemAtIndex : 1;
        unsigned int delegateCanDragItemsAtIndexesWithEvent : 1;
        unsigned int delegateValidateDropProposedIndexDropOperation : 1;
        unsigned int delegateAcceptDropIndexDropOperation : 1;
        unsigned int delegatePasteboardWriterForItemAtIndex : 1;
        unsigned int delegateDraggingSessionWillBeginAtPointForItemsAtIndexes : 1;
        unsigned int delegateDraggingSessionEndedAtPointDragOperation : 1;
        unsigned int delegateUpdateDraggingItemsForDrag : 1;
        
        unsigned int selectable : 1;
        unsigned int allowsMultipleSelection : 1;
        
        unsigned int animates : 1;
        unsigned int removable : 1;
        unsigned int allowsReordering : 1;
        unsigned int allowsHovering : 1;
        
        unsigned int multipleSelectionInPhase : 1;
        unsigned int shouldAnimateCellFrameChanging : 1;
        
        // dragging distance threshold
        // 4-bit unsinged integer should be enough for now
        // allowed range [0, 15]
        unsigned int draggingDistanceThreshold : 4;
        unsigned int draggingSessionDidBegin : 1;
        
        // only valid when current dropIndex
        // is the first column in the row except
        // the first row
        unsigned int droppingAtPreviousRow : 1;
        unsigned int droppingInPhase : 1;
    } _flags;
}

@property (nonatomic, assign) id <KDXCollectionViewDataSource> dataSource;
@property (nonatomic, assign) id <KDXCollectionViewDelegate> delegate;

@property (nonatomic, assign) NSSize cellSize;
@property (nonatomic, assign) NSSize margin;
@property (nonatomic, assign) NSSize intercellSpacing;

@property (nonatomic, assign, getter = isSelectable) BOOL selectable;
@property (nonatomic, assign) BOOL allowsMultipleSelection;

@property (nonatomic, assign) BOOL animates;
@property (nonatomic, assign, getter = isRemovable) BOOL removable;
@property (nonatomic, assign) BOOL allowsReordering;
@property (nonatomic, assign) BOOL allowsHovering;

@property (nonatomic, readonly) NSIndexSet *selectedIndexes;
@property (nonatomic, readonly) NSInteger hoveringIndex;

@property (nonatomic, retain) NSColor *backgroundColor;

- (void)selectItemAtIndex:(NSInteger)index;
- (void)selectItemsAtIndexes:(NSIndexSet *)indexes;
- (void)deselectItemAtIndex:(NSInteger)index;
- (void)deselectItemsAtIndexes:(NSIndexSet *)indexes;

- (void)selectAllItems;
- (void)deselectAllItems;

- (void)reloadData;
- (void)reloadDataForIndexes:(NSIndexSet *)indexes;

- (KDXCollectionViewCell *)cellAtIndex:(NSInteger)index;
- (KDXCollectionViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

- (NSRange)visibleRange;
- (NSRect)visibleRect;

- (NSIndexSet *)indexesForVisibleCells;
- (NSIndexSet *)indexesForCellsInRect:(NSRect)rect;

- (NSRect)rectForCellAtIndex:(NSInteger)index;
- (NSInteger)indexOfCellAtPoint:(NSPoint)point;

- (void)scrollCellToVisible:(NSInteger)index;

- (void)insertItemsAtIndexes:(NSIndexSet *)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)destinationIndex;

@end
