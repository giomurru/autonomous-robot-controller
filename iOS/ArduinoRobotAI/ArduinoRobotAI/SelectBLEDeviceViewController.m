//
//  SelectBLEDeviceViewController.m
//  BleDataExchangeExample
//
//  Created by Fenix Lux on 05/07/15.
//  Copyright (c) 2015 Giovanni Murru. All rights reserved.
//

#import "SelectBLEDeviceViewController.h"

@implementation SelectBLEDeviceViewController


- (void)viewDidLoad
{
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}
#pragma mark Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.deviceList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *tableIdentifier = @"Cell";
    
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableIdentifier];
    
    
    if (cell != nil)
    {
        
        cell.textLabel.text = [self.deviceList objectAtIndex:indexPath.row];
        
    }
    
    return cell;
    
    
}

#pragma mark Delegate

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Select a device";
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 100.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self.delegate didSelectBleDeviceAt:indexPath.row];    
}

@end
