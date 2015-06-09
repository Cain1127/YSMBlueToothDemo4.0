//
//  ViewController.m
//  YSMBlueToothDemo4.0
//
//  Created by ysmeng on 15/5/25.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define kPeripheralName @"ysmeng's touch"                           //!<外围设备名称
#define kServiceUUID @"C4FB2349-72FE-4CA2-94D6-1F3CB16331EE"        //!<服务的UUID
#define kCharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC" //!<特征的UUID

@interface ViewController () <CBPeripheralManagerDelegate,UITableViewDataSource,UITableViewDelegate>

@property (strong,nonatomic) CBPeripheralManager *peripheralManager;    //!<外围设备管理器
@property (strong,nonatomic) NSMutableArray *dataSource;                //!<订阅此外围设备特征的中心设备
@property (strong,nonatomic) CBMutableCharacteristic *characteristicM;  //!<特征
@property (weak, nonatomic) IBOutlet UITableView *listView;             //!<列表
@property (weak, nonatomic) IBOutlet UITextView *infoVIew;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *updateButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    ///1、添加CoreBluetooth.framework
    
    ///2、导入头文件<CoreBluetooth/CoreBluetooth.h>
    
    ///3、定义外围设置常用标识：名称，服务UUID，特征UUID
    
    ///4、持有代理:CBPeripheralManagerDelegate
    
    ///5、starButton事件
    
    ///6、updateButton事件
        
}

///开始创建周边设备
- (IBAction)startButtonAction:(UIButton *)sender
{
    
    if (nil == _peripheralManager) {
        
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
    }
    
}

///更新设置信息
- (IBAction)updateButtonAction:(UIButton *)sender
{
    
    [self updateCharacteristicValue];
    
}

///外围设备状态发生变化后调用
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    
    switch (peripheral.state) {
            
        case CBPeripheralManagerStatePoweredOn:
            
            [self writeToLog:@"BLE已打开."];//!<服务已开启
            [self setupService];
            
            break;
            
        default:
            
            [self writeToLog:@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备."];
            
            break;
            
    }
    
}

///外围设备添加服务后回调
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    
    if (error) {
        
        [self writeToLog:[NSString stringWithFormat:@"向外围设备添加服务失败，错误详情：%@",error.localizedDescription]];
        return;
    
    }
    
    ///添加服务后开始广播
    NSDictionary *dic = @{CBAdvertisementDataLocalNameKey:kPeripheralName};
    
    ///开始广播
    [self.peripheralManager startAdvertising:dic];
    
    [self writeToLog:@"向外围设备添加了服务并开始广播..."];

}

///广播发出时回调
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    
    if (error) {
        
        [self writeToLog:[NSString stringWithFormat:@"启动广播过程中发生错误，错误信息：%@",error.localizedDescription]];
        return;
    
    }
    
    [self writeToLog:@"启动广播..."];

}

///发现中心设备时回调
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    
    [self writeToLog:[NSString stringWithFormat:@"中心设备：%@ 已订阅特征：%@.",central.identifier.UUIDString,characteristic.UUID]];
    
    ///发现中心设备并存储
    if (![self.dataSource containsObject:central]) {
        
        [self.dataSource addObject:central];
        [self.listView reloadData];
        
    }
    
    /**
     *  brief : 中心设备订阅成功后外围设备可以更新特征值发送到中心设备,一旦更新特征值将会触发中心设备的代理方法
     *  - (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
     *
     */
    
    [self updateCharacteristicValue];
    
}

///取消订阅特征
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    
    NSLog(@"didUnsubscribeFromCharacteristic");
    
}

///接收到请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(CBATTRequest *)request
{
    
    NSLog(@"didReceiveWriteRequests");
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict
{
    
    NSLog(@"willRestoreState");
    
}

#pragma mark - 属性
- (NSMutableArray *)dataSource
{
    
    if (!_dataSource) {
        
        _dataSource = [NSMutableArray array];
    
    }
    
    return _dataSource;

}

#pragma mark - 私有方法
///创建特征、服务并添加服务到外围设备
- (void)setupService
{
    
    ///创建特征的UUID对象
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    
    ///创建特征
    
    /** 参数
     *
     * uuid         :   特征标识
     * properties   :   特征的属性，例如：可通知、可写、可读等
     * value        :   特征值
     * permissions  :   特征的权限
     *
     */
    CBMutableCharacteristic *characteristicM = [[CBMutableCharacteristic alloc]
                                                initWithType:characteristicUUID
                                                properties:CBCharacteristicPropertyNotify
                                                value:nil
                                                permissions:CBAttributePermissionsReadable];
    self.characteristicM = characteristicM;
    
    ///创建服务UUID对象
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    
    ///创建服务
    CBMutableService *serviceM = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    
    ///设置服务的特征
    [serviceM setCharacteristics:@[characteristicM]];
    
    ///将服务添加到外围设备
    [self.peripheralManager addService:serviceM];

}

///更新特征值
- (void)updateCharacteristicValue
{
    
    ///特征值
    NSString *valueStr = [NSString stringWithFormat:@"%@ --%@",kPeripheralName,[NSDate date]]; NSData *value = [valueStr dataUsingEncoding:NSUTF8StringEncoding];
    
    ///更新特征值
    [self.peripheralManager updateValue:value forCharacteristic:self.characteristicM onSubscribedCentrals:nil];
    [self writeToLog:[NSString stringWithFormat:@"更新特征值：%@",valueStr]];

}

///显示日志
- (void)writeToLog:(NSString *)info
{
    
    self.infoVIew.text = [NSString stringWithFormat:@"%@\n%@",self.infoVIew.text,info];

}

#pragma mark - 中心设备列表
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
    
    CBCentral *tempCentral = self.dataSource[indexPath.row];
    cellNormal.textLabel.text = tempCentral.identifier.UUIDString;
    
    return cellNormal;

}

@end
