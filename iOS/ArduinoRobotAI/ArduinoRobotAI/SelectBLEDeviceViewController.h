//
//  SelectBLEDeviceViewController.h
//  BleDataExchangeExample
//
//  Created by Fenix Lux on 05/07/15.
//  Copyright (c) 2015 Giovanni Murru. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SelectBLEDeviceViewControllerDelegate <NSObject>
- (void)didSelectBleDeviceAt:(NSInteger)index;
@end

@interface SelectBLEDeviceViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>


@property (strong,nonatomic) NSArray *deviceList;

@property (nonatomic, weak) id <SelectBLEDeviceViewControllerDelegate> delegate;
@end
