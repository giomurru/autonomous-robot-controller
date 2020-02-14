//
//  ViewController.m
//  BleDataExchangeExample
//
//  Created by Fenix Lux on 05/07/15.
//  Copyright (c) 2015 Giovanni Murru. All rights reserved.
//
@import CoreLocation;

#import "ViewController.h"
#import "SelectBLEDeviceViewController.h"

@interface ViewController () <SelectBLEDeviceViewControllerDelegate, CLLocationManagerDelegate>
@property (nonatomic, strong) UILabel *linkedDeviceName;
@property (nonatomic, strong) UIButton *linkedDeviceButton;
@property (nonatomic, strong) UIButton *startSendingStreamButton;
@property (nonatomic, strong) UIImage *connectionStatus;

@property (nonatomic) int speedFR;
@property (nonatomic) int speedFL;
@property (nonatomic) int speedRR;
@property (nonatomic) int speedRL;
@property (nonatomic) BOOL speedDirectionFW;

@property (nonatomic) CLLocationDirection currentHeading;

@property (nonatomic, strong) CLLocationManager *locManager;

@property (nonatomic) float ir00_smoothvalue;
@property (nonatomic) float ir01_smoothvalue;
@property (nonatomic) float ir02_smoothvalue;
@property (nonatomic) float ir03_smoothvalue;

@property (nonatomic) BOOL firstReading;
@property (nonatomic) int firstReadingDelay;
@end



NSString * const  kLinkedDevice = @"kLinkedDevice";

@implementation ViewController

- (void)startHeadingEvents {
    if (!self.locManager) {
        CLLocationManager* theManager = [[CLLocationManager alloc] init];
        
        // Retain the object in a property.
        self.locManager = theManager;
        self.locManager.delegate = self;
    }
    
    // Start location services to get the true heading.
    self.locManager.distanceFilter = 1;
    self.locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    [self.locManager startUpdatingLocation];
    
    // Start heading updates.
    if ([CLLocationManager headingAvailable]) {
        self.locManager.headingFilter = 1;
        [self.locManager startUpdatingHeading];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;
    
    // Use the true heading if it is valid.
    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
                                       newHeading.trueHeading : newHeading.magneticHeading);
    
    self.currentHeading = theHeading;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
   
    bleShield = [[BLE alloc] init];
    [bleShield controlSetup];
    bleShield.delegate = self;
    
    self.firstReading = YES;
    self.ir00_smoothvalue = 0.0f;
    self.ir01_smoothvalue = 0.0f;
    self.ir02_smoothvalue = 0.0f;
    self.ir03_smoothvalue = 0.0f;
    self.speedFR = 0;
    self.speedFL = 0;
    self.speedRL = 0;
    self.speedRR = 0;
    self.speedDirectionFW = true;
    
    //Retrieve saved UUID from system
    self.linkedDeviceID = [[NSUserDefaults standardUserDefaults] objectForKey:kLinkedDevice];
    
    self.linkedDeviceButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 80.0f)];
    [self.linkedDeviceButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.linkedDeviceButton.center = CGPointMake(self.view.bounds.size.width/2.0f, self.view.bounds.size.height/2.0f);
    
    self.startSendingStreamButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 80.0f)];
    [self.startSendingStreamButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.startSendingStreamButton.center = CGPointMake(self.view.bounds.size.width/2.0f, self.view.bounds.size.height/4.0f);
    [self.startSendingStreamButton setTitle:@"Start" forState:UIControlStateNormal];
    self.startSendingStreamButton.enabled = NO;
    
    if (self.linkedDeviceID.length > 0)
    {
        NSLog(@"I found a linked device %@", self.linkedDeviceID);
        [self.linkedDeviceButton setTitle:@"Connect" forState:UIControlStateNormal];
    }
    else
    {
        NSLog(@"There is no linked device.");
        [self.linkedDeviceButton setTitle:@"Link New" forState:UIControlStateNormal];
    }
    
    [self.linkedDeviceButton addTarget:self action:@selector(linkedDeviceButtonHasBeenPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.startSendingStreamButton addTarget:self action:@selector(startSendingStreamButtonHasBeenPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.linkedDeviceButton];
    [self.view addSubview:self.startSendingStreamButton];
    
    self.mDevices = [[NSMutableArray alloc] init];
    
    [self startHeadingEvents];
    
}

- (IBAction)startSendingStreamButtonHasBeenPressed:(id)sender
{
    [self sendWheelSpeeds];
}

- (IBAction)linkedDeviceButtonHasBeenPressed:(id)sender
{
    NSString *title = [self.linkedDeviceButton titleForState:UIControlStateNormal];
    
    if ([title isEqualToString:@"Link New"])
    {
        self.linkedDeviceButton.enabled = NO;
        [self startScan];
        [self.linkedDeviceButton setTitle:@"Scanning" forState:UIControlStateNormal];

    }
    else if ([title isEqualToString:@"Forget"])
    {
        [self forgetDevice];
    }
    else if ([title isEqualToString:@"Connect"])
    {
        [self connectToLinkedDevice];
    }
}

- (void)forgetDevice
{
    self.linkedDeviceID = nil;
    isFindingLast = false;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLinkedDevice];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (bleShield.activePeripheral)
    {
        if(bleShield.isConnected)
        {
            [bleShield disconnectPeripheral:[bleShield activePeripheral]];
        }
    }
    
    [self.linkedDeviceButton setTitle:@"Link New" forState:UIControlStateNormal];
}
- (void)startScan
{
    NSLog(@"Scanning for BLE devices");
    if (bleShield.activePeripheral)
    {
        if(bleShield.isConnected)
        {
            [bleShield disconnectPeripheral:[bleShield activePeripheral]];
            return;
        }
    }
    
    if (bleShield.peripherals)
        bleShield.peripherals = nil;
    
    [bleShield findBLEPeripherals:3];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    
    isFindingLast = false;
    
}


- (void)connectToLinkedDevice
{
    NSLog(@"Connecting to linked device");
    [bleShield findBLEPeripherals:3];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    isFindingLast = true;
}

- (void)setConnectedInterface
{
    [self.linkedDeviceButton setTitle:@"Forget" forState:UIControlStateNormal];

}
// Called when scan period is over
-(void) connectionTimer:(NSTimer *)timer
{
    if(bleShield.peripherals.count > 0)
    {
        //to connect to the peripheral with a particular UUID
        if(isFindingLast)
        {
            int i;
            for (i = 0; i < bleShield.peripherals.count; i++)
            {
                CBPeripheral *p = [bleShield.peripherals objectAtIndex:i];
                
                if (p.identifier.UUIDString != NULL)
                {
                    //Comparing UUIDs and call connectPeripheral is matched
                    if([self.linkedDeviceID isEqualToString:p.identifier.UUIDString])
                    {
                        [bleShield connectPeripheral:p];
                        [self setConnectedInterface];
                    }
                }
            }
        }
        //Scan for all BLE in range and prepare a list
        else
        {
            [self.mDevices removeAllObjects];
            
            int i;
            for (i = 0; i < bleShield.peripherals.count; i++)
            {
                CBPeripheral *p = [bleShield.peripherals objectAtIndex:i];
                
                if (p.identifier.UUIDString != NULL)
                {
                    [self.mDevices insertObject:p.identifier.UUIDString atIndex:i];
                }
                else
                {
                    [self.mDevices insertObject:@"NULL" atIndex:i];
                }
            }
            
            //Show the list for user selection
            SelectBLEDeviceViewController *bleDeviceViewController = [[SelectBLEDeviceViewController alloc] init];
            bleDeviceViewController.deviceList = self.mDevices;
            bleDeviceViewController.delegate = self;
            [self presentViewController:bleDeviceViewController animated:YES completion:nil];
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure" message:@"No robot found. Turn on the robot." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
        
        if(isFindingLast)
        {
            [self.linkedDeviceButton setTitle:@"Connect" forState:UIControlStateNormal];
        }
        else
        {
            [self.linkedDeviceButton setTitle:@"Link New" forState:UIControlStateNormal];
        }
    }
    
    self.linkedDeviceButton.enabled = YES;
    
}

- (void)rotate
{
    float referenceHeading = self.currentHeading + 90.0f;
    if (referenceHeading > 360.0f) referenceHeading = referenceHeading - 360.0f;
    
    float gain = (referenceHeading)/360.0f;
    
    self.speedFL = 100 + 100.0f * gain * gain;
    self.speedRL = 100 + 100.0f * gain * gain;
    
    self.speedFR = 100 + 100.0f * gain * gain;
    self.speedRR = 100 + 100.0f * gain * gain;
    
    if (gain < 0.05)
    {
        self.speedRR = 0.0f;
        self.speedRL = 0.0f;
        self.speedFL = 0.0f;
        self.speedFR = 0.0f;
    }
}

- (void)changeWheelSpeed
{
    if (self.speedDirectionFW)
    {
        if (self.speedFR < 254)
        {
            self.speedFR += 2;
            self.speedFL+=2;
            self.speedRR+=2;
            self.speedRL+=2;
        }
        else
        {
            self.speedDirectionFW = false;
        }
    }
    else
    {
        if (self.speedFR > -254)
        {
            self.speedFR-=2;
            self.speedFL-=2;
            self.speedRR-=2;
            self.speedRL-=2;
        }
        else
        {
            self.speedDirectionFW = true;
        }
    }
}

- (int)encodeSpeedForTransmission:(int)realSpeed
{
    // The speed should be a number between -254 and 254
    if (realSpeed > 254 || realSpeed < -254)
    {
        return -1;
    }
    
    int encodedSpeed;
    if (realSpeed <= 0)
    {
        encodedSpeed = (int) floorf((float)-realSpeed/2.0f);
    }
    else
    {
        encodedSpeed = 128 + (int) ceilf((float)realSpeed/2.0f) - 1;
    }
    

    return encodedSpeed;
}

- (BOOL)sendWheelSpeeds
{
    int encodedSpeedFR = [self encodeSpeedForTransmission:self.speedFR];
    int encodedSpeedFL = [self encodeSpeedForTransmission:self.speedFL];
    int encodedSpeedRR = [self encodeSpeedForTransmission:self.speedRR];
    int encodedSpeedRL = [self encodeSpeedForTransmission:self.speedRL];
    
    NSLog(@"sending wheel speeds: %d %d %d %d", encodedSpeedFR, encodedSpeedFL, encodedSpeedRR, encodedSpeedRL);
    if (encodedSpeedFR < 0 || encodedSpeedFL < 0 || encodedSpeedRR < 0 || encodedSpeedRL < 0)
    {
        return false;
    }
    
    
    UInt8 wheelSpeeds[] = {0xff, (UInt8) encodedSpeedFR, (UInt8) encodedSpeedFL, (UInt8) encodedSpeedRR, (UInt8) encodedSpeedRL};
    //NSLog(@"Sending wheel speeds: %d,\t%d,\t%d,\t%d,\t", self.speedFR, self.speedFL, self.speedRR, self.speedRL);
    NSData *data = [[NSData alloc] initWithBytes:wheelSpeeds length:5];
    [bleShield write:data];
    
    return true;
}

-(void)sendByte:(UInt8)value
{
    UInt8 buf[1] = {value};
    
    NSData *data = [[NSData alloc] initWithBytes:buf length:1];
    [bleShield write:data];
}


#pragma mark BLE delegates
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    // parse data, all commands are in 4-byte

    // a command is composed of 5 bytes, ignore the bytes if different
    if (length != 5) return;
    
    // check the controlByte to see what kind of information is coming
    UInt8 controlByte = data[0];
    
    if (controlByte == 0xff)
    {
        //must be 32.3 cm usando riga fila
        float conversionFactor = 420.0f/255.0f;
        float d0_raw = 80 + data[1]*conversionFactor;
        float d0_comp = 1.45f; //cm
        float d0_cm = 4800.0f/(d0_raw - 20.0f) - d0_comp;
        
        float d1_raw = 80 + data[2]*conversionFactor;
        float d1_comp = 2.5f; //cm
        float d1_cm = 4800.0f/(d1_raw - 20.0f) - d1_comp;
        
        float d2_raw = 80 + data[3]*conversionFactor;
        float d2_comp = 2.6f; //cm
        float d2_cm = 4800.0f/(d2_raw - 20.0f) - d2_comp;
        
        float d3_raw = 80 + data[4]*conversionFactor;
        float d3_comp = 5.75f; //cm
        float d3_cm = 4800.0f/(d3_raw - 20.0f) - d3_comp;
        
        if (self.firstReading)
        {
            self.firstReadingDelay++;
            if (self.firstReadingDelay > 3)
            {
                _ir00_smoothvalue = d0_cm;
                _ir01_smoothvalue = d1_cm;
                _ir02_smoothvalue = d2_cm;
                _ir03_smoothvalue = d3_cm;
                
                self.firstReading = false;
            }
        }
        else
        {
            _ir00_smoothvalue = d0_cm;
            _ir01_smoothvalue = d1_cm;
            _ir02_smoothvalue = d2_cm;
            _ir03_smoothvalue = d3_cm;
            
        /*
            _ir00_smoothvalue = [self smoothSensorValue:d0_cm using:_ir00_smoothvalue withParameter:0.9f];
            _ir01_smoothvalue = [self smoothSensorValue:d1_cm using:_ir01_smoothvalue withParameter:0.9f];
            _ir02_smoothvalue = [self smoothSensorValue:d2_cm using:_ir02_smoothvalue withParameter:0.9f];
            _ir03_smoothvalue = [self smoothSensorValue:d3_cm using:_ir03_smoothvalue withParameter:0.9f];
            */
            NSLog(@"ir distances: %.2f,\t%.2f,\t%.2f,\t%.2f,\t", _ir00_smoothvalue, _ir01_smoothvalue, _ir02_smoothvalue, _ir03_smoothvalue);

        }


        //[self rotate];
        [self changeWheelSpeed];
        if (![self sendWheelSpeeds])
        {
            NSLog(@"Error sending wheel speeds");
        }
    }
}

- (void) bleDidDisconnect
{
    self.startSendingStreamButton.enabled = NO;
    NSLog(@"The device did disconnect");
    if(isFindingLast)
    {
        [self.linkedDeviceButton setTitle:@"Connect" forState:UIControlStateNormal];
    }
    else
    {
        [self.linkedDeviceButton setTitle:@"Link New" forState:UIControlStateNormal];
    }

}

-(void) bleDidConnect
{
    //Save UUID into system
    NSLog(@"The device did connect");
    self.linkedDeviceID = bleShield.activePeripheral.identifier.UUIDString;//[self getUUIDString:];
    [[NSUserDefaults standardUserDefaults] setObject:self.linkedDeviceID forKey:kLinkedDevice];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.startSendingStreamButton.enabled = YES;
}

-(void) bleDidUpdateRSSI:(NSNumber *)rssi
{
    NSLog(@"Signal strength: %@", [NSString stringWithFormat:@"RSSI: %@", rssi.stringValue]);
}


-(NSString*)getUUIDString:(CFUUIDRef)ref {
    NSString *str = [NSString stringWithFormat:@"%@",ref];
    return [[NSString stringWithFormat:@"%@",str] substringWithRange:NSMakeRange(str.length - 36, 36)];
}


#pragma mark SelectBLEDevice Delegate


- (void)didSelectBleDeviceAt:(NSInteger)index
{
    [self dismissViewControllerAnimated:YES completion:^{
        [bleShield connectPeripheral:[bleShield.peripherals objectAtIndex:index]];
        [self.linkedDeviceButton setTitle:@"Forget" forState:UIControlStateNormal];
    }];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Help function
-(float)smoothSensorValue:(float)actualSensorValue using:(float)smoothedSensorValue withParameter:(float)alpha
{
    
    if (alpha > 1)
    {
        alpha = .99;
    }
    else if (alpha <= 0)
    {
        alpha = 0;
    }
    
    float newSmoothedvalue = actualSensorValue*(1 - alpha) + smoothedSensorValue*alpha;
    
    return newSmoothedvalue;
}

@end
