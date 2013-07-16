//
//  AppDelegate.m
//  CollectionView
//
//  Created by Chongyu Zhu on 17/07/2013.
//  Copyright (c) 2013 Chongyu Zhu. All rights reserved.
//

#import "AppDelegate.h"
#import "KDXCollectionViewCell.h"

@interface Cell : KDXCollectionViewCell
@property (nonatomic, strong) NSNumber *identifierNumber;
@end

@implementation Cell
- (void)drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];

  [NSGraphicsContext saveGraphicsState];
  [NSBezierPath clipRect:dirtyRect];

  NSRect rect = NSInsetRect([self bounds], 8.0, 8.0);

  if ([self isSelected]) {
    [[NSColor yellowColor] setFill];
  }
  else if ([self isHovering]) {
    [[NSColor magentaColor] setFill];
  }
  else {
    [[NSColor cyanColor] setFill];
  }
  NSRectFill(rect);

  NSShadow *textShadow = [[NSShadow alloc] init];
  [textShadow setShadowBlurRadius:4.0];
  [textShadow setShadowOffset:NSMakeSize(0.0, -2.0)];
  [textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.6]];

  NSDictionary *textAttributes = @{
                                   NSFontAttributeName: [NSFont systemFontOfSize:36.0],
                                   NSForegroundColorAttributeName: [NSColor whiteColor],
                                   NSShadowAttributeName: textShadow
                                   };

  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[_identifierNumber stringValue]
                                                                         attributes:textAttributes];
  NSSize textSize = [attributedString size];

  NSRect textRect;
  textRect.origin.x = NSMinX(rect) + round((NSWidth(rect) - textSize.width) / 2.0);
  textRect.origin.y = NSMinY(rect) + round((NSHeight(rect) - textSize.height) / 2.0);
  textRect.size = textSize;

  [attributedString drawInRect:textRect];

  [NSGraphicsContext restoreGraphicsState];
}
@end

@interface AppDelegate () {
@private
  KDXCollectionView *_collectionView;
  NSScrollView *_scrollView;

  NSMutableArray *_identifiers;
}
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  _scrollView = [[NSScrollView alloc] initWithFrame:[[_window contentView] bounds]];
  [_scrollView setBorderType:NSNoBorder];
  [_scrollView setDrawsBackground:NO];
  [_scrollView setHasVerticalScroller:YES];
  [_scrollView setHasHorizontalScroller:NO];
  [_scrollView setAutohidesScrollers:YES];
  [_scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

  _collectionView = [[KDXCollectionView alloc] initWithFrame:[[_scrollView contentView] bounds]];
  [_scrollView setDocumentView:_collectionView];

  [_collectionView setDelegate:self];
  [_collectionView setDataSource:self];
  [_collectionView setSelectable:YES];
  [_collectionView setAllowsMultipleSelection:YES];
  [_collectionView setAllowsHovering:YES];
  [_collectionView setAllowsReordering:YES];
  [_collectionView setRemovable:YES];
  [_collectionView setAnimates:YES];
  [_collectionView setCellSize:NSMakeSize(128.0, 128.0)];

  [_collectionView registerForDraggedTypes:@[(__bridge NSString *)kUTTypeText]];

  [_collectionView setBackgroundColor:[NSColor whiteColor]];
  [_window setBackgroundColor:[NSColor whiteColor]];

  [[_window contentView] addSubview:_scrollView];

  _identifiers = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0; i < 1000; ++i) {
    [_identifiers addObject:[NSNumber numberWithUnsignedInteger:i]];
  }

  [_collectionView reloadData];
}

#pragma mark - KDXCollectionViewDataSource

- (NSInteger)numberOfItemsInCollectionView:(KDXCollectionView *)collectionView
{
  return [_identifiers count];
}

- (KDXCollectionViewCell *)collectionView:(KDXCollectionView *)collectionView cellForItemAtIndex:(NSInteger)index
{
  static NSString *const kCellIdentifier = @"CellIdentifier";
  Cell *cell = (Cell *)[collectionView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell = [[Cell alloc] initWithReuseIdentifier:kCellIdentifier];
  }

  [cell setIdentifierNumber:[_identifiers objectAtIndex:index]];
  [cell setNeedsDisplay:YES];

  return cell;
}

- (void)collectionView:(KDXCollectionView *)collectionView removeItemsAtIndexes:(NSIndexSet *)indexes
{
  [_identifiers removeObjectsAtIndexes:indexes];
}

- (void)collectionView:(KDXCollectionView *)collectionView moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)destinationIndex
{
  NSMutableArray *temporaryIdentifiers = [NSMutableArray array];

  for (NSInteger index = [indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index]) {
    if (index < destinationIndex) {
      --destinationIndex;
    }

    id identifier = [_identifiers objectAtIndex:index];
    [temporaryIdentifiers addObject:identifier];
    [_identifiers removeObjectAtIndex:index];
  }

  NSEnumerator *identifiersEnumerator = [temporaryIdentifiers objectEnumerator];

  id identifier;
  while ((identifier = [identifiersEnumerator nextObject]) != nil) {
    [_identifiers insertObject:identifier atIndex:destinationIndex];
  }
}

#pragma mark - KDXCollectionViewDelegate

- (id <NSPasteboardWriting>)collectionView:(KDXCollectionView *)collectionView pasteboardWriterForItemAtIndex:(NSInteger)index;
{
  NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
  [item setPropertyList:[_identifiers objectAtIndex:index]
                forType:(__bridge NSString *)kUTTypeText];
  return item;
}

@end
