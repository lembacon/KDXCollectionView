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

#import "KDXCollectionViewCell.h"
#include "KDXGraphicsUtility.h"

@implementation KDXCollectionViewCell

@synthesize cellIdentifier = _cellIdentifier;
@synthesize index = _index;

- (id)initWithReuseIdentifier:(NSString *)identifier
{
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        _cellIdentifier = [identifier copy];
        _index = NSNotFound;
        
        _flags.selected = NO;
        _flags.hovering = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [_cellIdentifier release];
    [super dealloc];
}

- (BOOL)isSelected
{
    return _flags.selected;
}

- (void)setSelected:(BOOL)selected
{
    if (_flags.selected != selected) {
        _flags.selected = selected;
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)isHovering
{
    return _flags.hovering;
}

- (void)setHovering:(BOOL)hovering
{
    if (_flags.hovering != hovering) {
        _flags.hovering = hovering;
        [self setNeedsDisplay:YES];
    }
}

- (void)prepareForReuse
{
    _flags.selected = NO;
    _flags.hovering = NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (_flags.selected) {
        [self drawSelectionInRect:dirtyRect];
    }
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGRect bounds = NSRectToCGRect([self bounds]);
    
    static CGFloat red, green, blue, alpha;
    {
        static BOOL colorInitialized = NO;
        if (!colorInitialized) {
            colorInitialized = YES;
            
            NSColor *color = [[NSColor secondarySelectedControlColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
        }
    }
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, NSRectToCGRect(dirtyRect));
    KDXFlipContext(context, bounds);
    CGContextSetRGBFillColor(context, red, green, blue, alpha);
    KDXFillRoundedRect(context, bounds, 4.0f);
    CGContextRestoreGState(context);
}

- (BOOL)isFlipped
{
    return YES;
}

@end
