/* vim: set ft=c fenc=utf-8 sw=4 ts=4 et: */
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

#import "KDXGraphicsUtility.h"

CF_RETURNS_RETAINED CGPathRef KDXCreatePathForRoundedRect(CGRect bounds, CGFloat radius)
{
  CGMutablePathRef path = CGPathCreateMutable();

  CGPathMoveToPoint(path, NULL, CGRectGetMinX(bounds), CGRectGetMinY(bounds) + radius);
  CGPathAddLineToPoint(path, NULL, CGRectGetMinX(bounds), CGRectGetMaxY(bounds) - radius);
  CGPathAddArc(path, NULL, CGRectGetMinX(bounds) + radius, CGRectGetMaxY(bounds) - radius, radius, M_PI, M_PI / 2.0f, true);
  CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(bounds) - radius, CGRectGetMaxY(bounds));
  CGPathAddArc(path, NULL, CGRectGetMaxX(bounds) - radius, CGRectGetMaxY(bounds) - radius, radius, M_PI / 2.0f, 0.0f, true);
  CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(bounds), CGRectGetMinY(bounds) + radius);
  CGPathAddArc(path, NULL, CGRectGetMaxX(bounds) - radius, CGRectGetMinY(bounds) + radius, radius, 0.0f, -M_PI / 2.0f, true);
  CGPathAddLineToPoint(path, NULL, CGRectGetMinX(bounds) + radius, CGRectGetMinY(bounds));
  CGPathAddArc(path, NULL, CGRectGetMinX(bounds) + radius, CGRectGetMinY(bounds) + radius, radius, -M_PI / 2.0f, M_PI, true);
  CGPathCloseSubpath(path);

  return path;
}

void KDXAddRoundedRect(CGContextRef context, CGRect bounds, CGFloat radius)
{
  CGPathRef path = KDXCreatePathForRoundedRect(bounds, radius);
  CGContextAddPath(context, path);
  CGPathRelease(path);
}

void KDXClipToRoundedRect(CGContextRef context, CGRect bounds, CGFloat radius)
{
  KDXAddRoundedRect(context, bounds, radius);
  CGContextClip(context);
}

void KDXFillRoundedRect(CGContextRef context, CGRect bounds, CGFloat radius)
{
  KDXAddRoundedRect(context, bounds, radius);
  CGContextFillPath(context);
}

void KDXStrokeRoundedRect(CGContextRef context, CGRect bounds, CGFloat radius)
{
  KDXAddRoundedRect(context, bounds, radius);
  CGContextStrokePath(context);
}

void KDXFlipContext(CGContextRef context, CGRect bounds)
{
  CGContextTranslateCTM(context, 0.0f, bounds.size.height);
  CGContextScaleCTM(context, 1.0f, -1.0f);
}
