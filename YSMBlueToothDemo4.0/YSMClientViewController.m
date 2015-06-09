//
//  YSMClientViewController.m
//  YSMBlueToothDemo4.0
//
//  Created by ysmeng on 15/5/25.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import "YSMClientViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define kPeripheralName @"ysmeng's 5s"                              //!<中央设备名称
#define kServiceUUID @"C4FB2349-72FE-4CA2-94D6-1F3CB16331EE"        //!<服务的UUID
#define kCharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC" //!<特征的UUID

@interface YSMClientViewController ()<UITableViewDelegate,UITableViewDataSource,CBCentralManagerDelegate,CBPeripheralDelegate>

@property (strong,nonatomic) CBCentralManager *centralManager;  //!<中心设备管理器
@property (weak, nonatomic) IBOutlet UITextView *infoView;      //!<信息展示框
@property (weak, nonatomic) IBOutlet UITableView *listView;     //!<列表
@property (retain,nonatomic) NSMutableArray *dataSource;        //!<数据源

@end

@implementation YSMClientViewController

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
}

///开启连接
- (IBAction)startButtonAction:(UIButton *)sender
{
    
    ///创建中心设备管理器并设置当前控制器视图为代理
    if (nil == _centralManager) {
        
        _centralManager=[[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
    }
    
}

#pragma mark - 中心设备代理设置
///中心服务器状态更新后
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    switch (central.state)
    {
            
        case CBPeripheralManagerStatePoweredOn:
            
            [self writeToLog:@"BLE已打开."];
            //扫描外围设备
            [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            
            break;
            
        default:
            
            [self writeToLog:@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备."];
            
            break;
            
    }

}

/** 
 * 发现外围设备 
 *
 * @param central 中心设备 
 * @param peripheral 外围设备 
 * @param advertisementData 特征数据 
 * @param RSSI 信号质量（信号强度） 
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    [self writeToLog:@"发现外围设备..."];
    
    //停止扫描
    [self.centralManager stopScan];
    
    //连接外围设备
    if (peripheral) {
        
        ///添加保存外围设备，注意如果这里不保存外围设备（或者说peripheral没有一个强引用，无法到达连接成功（或失败）的代理方法，因为在此方法调用完就会被销毁
        if(![self.dataSource containsObject:peripheral]) {
            
            [self.dataSource addObject:peripheral];
            [self.listView reloadData];
        
        }
        
        [self writeToLog:@"开始连接外围设备..."];
        [self.centralManager connectPeripheral:peripheral options:nil];
    
    }

}

///连接到外围设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{

    [self writeToLog:@"连接外围设备成功!"];
    
    //设置外围设备的代理为当前视图控制器
    peripheral.delegate = self;
    
    //外围设备开始寻找服务
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];

}

///连接外围设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
    [self writeToLog:@"连接外围设备失败!"];

}

///外围设备寻找到服务后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    
    [self writeToLog:@"已发现可用服务..."];
    if(error) {
        
        [self writeToLog:[NSString stringWithFormat:@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription]];
    
    }
    
    //遍历查找到的服务
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    
    for (CBService *service in peripheral.services) {
        
        if([service.UUID isEqual:serviceUUID]){
            
            //外围设备查找指定服务中的特征
            [peripheral discoverCharacteristics:@[characteristicUUID] forService:service];
        
        }
    
    }

}

///外围设备寻找到特征后
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    [self writeToLog:@"已发现可用特征..."];
    
    if (error) {
        
        [self writeToLog:[NSString stringWithFormat:@"外围设备寻找特征过程中发生错误，错误信息：%@",error.localizedDescription]];
        
    }
    
    ///遍历服务中的特征
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    if ([service.UUID isEqual:serviceUUID]) {
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if ([characteristic.UUID isEqual:characteristicUUID]) {
                
                /** 情景一：通知
                 *  找到特征后设置外围设备为已通知状态（订阅特征）：
                 *
                 *  1.调用此方法会触发代理方法
                 *  -(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
                 *
                 *  2.调用此方法会触发外围设备的订阅代理方法
                 */
                
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
#if 0
                /** 情景二：读取
                 */
                [peripheral readValueForCharacteristic:characteristic];
                if(characteristic.value) {
                    
                    NSString *value = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
                }
#endif
                
            }
            
        }
        
    }
    
}

///特征值被更新后
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    [self writeToLog:@"收到特征更新通知..."];
    if (error) {
        
        NSLog(@"更新通知状态时发生错误，错误信息：%@",error.localizedDescription);
    
    }
    
    ///给特征值设置新的值
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    if ([characteristic.UUID isEqual:characteristicUUID]) {
        
        if (characteristic.isNotifying) {
            
            if (characteristic.properties == CBCharacteristicPropertyNotify) {
                
                [self writeToLog:@"已订阅特征通知."];
                return;
            
            } else if (characteristic.properties == CBCharacteristicPropertyRead) {
                
                /** 从外围设备读取新值,调用此方法会触发代理方法
                 *  -(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
                 */
                [peripheral readValueForCharacteristic:characteristic];
                
            }
        
        } else {
            
            [self writeToLog:@"BLE已停止."];
            
            ///取消连接
            [self.centralManager cancelPeripheralConnection:peripheral];
        
        }
    
    }

}

///更新特征值后（调用readValueForCharacteristic:方法或者外围设备在订阅后更新特征值都会调用此代理方法）
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    if (error) {
        
        [self writeToLog:[NSString stringWithFormat:@"更新特征值时发生错误，错误信息：%@",error.localizedDescription]];
        return;
        
    } if (characteristic.value) {
        
        NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        [self writeToLog:[NSString stringWithFormat:@"读取到特征值：%@",value]];
        
    } else {
        
        [self writeToLog:@"未发现特征值."];
        
    }
    
}

#pragma mark - getter
- (NSMutableArray *)dataSource
{

    if (nil == _dataSource) {
        
        _dataSource = [NSMutableArray array];
        
    }
    
    return _dataSource;

}

#pragma mark - 日志
- (void)writeToLog:(NSString *)info
{
    
    self.infoView.text = [NSString stringWithFormat:@"%@\r\n%@",self.infoView.text,info];
    
}

#pragma mark - 列表配置
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return [self.dataSource count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *normalCell = @"normalCell";
    UITableViewCell *cellNormal = [tableView dequeueReusableCellWithIdentifier:normalCell];
    if (nil == cellNormal) {
        
        cellNormal = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:normalCell];
        
    }
    
    CBPeripheral *tempCentral = self.dataSource[indexPath.row];
    cellNormal.textLabel.text = tempCentral.identifier.UUIDString;
    
    return cellNormal;

}

@end
