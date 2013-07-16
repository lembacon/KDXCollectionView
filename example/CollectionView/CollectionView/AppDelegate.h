//
//  AppDelegate.h
//  CollectionView
//
//  Created by Chongyu Zhu on 17/07/2013.
//  Copyright (c) 2013 Chongyu Zhu. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KDXCollectionView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, KDXCollectionViewDelegate, KDXCollectionViewDataSource>

@property (assign) IBOutlet NSWindow *window;

@end
