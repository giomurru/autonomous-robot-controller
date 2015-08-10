//
//  ViewController.h
//  BleDataExchangeExample
//
//  Created by Fenix Lux on 05/07/15.
//  Copyright (c) 2015 Giovanni Murru. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController <BLEDelegate>
{
    BLE *bleShield;
    bool isFindingLast;
}

@property (strong,nonatomic) NSMutableArray *mDevices;
@property (strong,nonatomic) NSString *linkedDeviceID;

@end

