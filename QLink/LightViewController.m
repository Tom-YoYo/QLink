//
//  LightViewController.m
//  QLink
//
//  Created by SANSAN on 14-9-28.
//  Copyright (c) 2014年 SANSAN. All rights reserved.
//

#import "LightViewController.h"
#import "SenceConfigViewController.h"
#import "ILBarButtonItem.h"
#import "NetworkUtil.h"
#import "UIView+xib.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "SetIpView.h"
#import "SetDeviceOrderView.h"
#import "KxMenu.h"
#import "DeviceInfoViewController.h"
#import "NSString+NSStringHexToBytes.h"
#import "SVProgressHUD.h"

@interface LightViewController ()
{
    UIScrollView *svBg_;
    NSString *strCurModel_;//记录当前的发送socket模式
}

@property(nonatomic,retain) RenameView *renameView;
@property(nonatomic,retain) SetIpView *setIpView;
@property(nonatomic,retain) SetDeviceOrderView *setOrderView;

@end

@implementation LightViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [DataUtil setGlobalModel:strCurModel_];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initNavigation];
    
    [self initControl];
    
    [self initData];
}

//设置导航
-(void)initNavigation
{
    ILBarButtonItem *back =
    [ILBarButtonItem barItemWithImage:[UIImage imageNamed:@"首页_返回.png"]
                        selectedImage:[UIImage imageNamed:@"首页_返回.png"]
                               target:self
                               action:@selector(btnBackPressed)];
    
    self.navigationItem.leftBarButtonItem = back;
    
    ILBarButtonItem *rightBtn =
    [ILBarButtonItem barItemWithImage:[UIImage imageNamed:@"首页_三横.png"]
                        selectedImage:[UIImage imageNamed:@"首页_三横.png"]
                               target:self
                               action:@selector(showRightMenu)];
    self.navigationItem.rightBarButtonItem = rightBtn;
    
    UIButton *btnTitle = [UIButton buttonWithType:UIButtonTypeCustom];
    btnTitle.frame = CGRectMake(0, 0, 100, 20);
    [btnTitle setTitle:@"照明" forState:UIControlStateNormal];
    btnTitle.titleEdgeInsets = UIEdgeInsetsMake(-5, 0, 0, 0);
    btnTitle.backgroundColor = [UIColor clearColor];
    
    [btnTitle setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    self.navigationItem.titleView = btnTitle;
}

-(void)initControl
{
    //设置背景图
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"首页_bg.png"]];
    
    //UIScrollView
    int svHeight = [UIScreen mainScreen ].applicationFrame.size.height - 44;
    svBg_ = [[UIScrollView alloc] init];
    svBg_.frame = CGRectMake(0, 0, self.view.frame.size.width, svHeight);
    svBg_.backgroundColor = [UIColor clearColor];
    [self.view addSubview:svBg_];
}

-(void)initData
{
    strCurModel_ = [DataUtil getGlobalModel];
    
    for (UIView *view in svBg_.subviews) {
        [view removeFromSuperview];
    }
    
    int height = 0;
    
    //取type='light','light_1','light_check'的控件
    GlobalAttr *obj = [DataUtil shareInstanceToRoom];
    NSArray *deviceArr = [SQLiteUtil getLightDevice:obj.HouseId andLayerId:obj.LayerId andRoomId:obj.RoomId];
    
    NSInteger iCount = [deviceArr count];
    NSInteger iRowCount = iCount%3 == 0 ? iCount/3 : (iCount/3 + 1);
    
    for (int row = 0; row < iRowCount; row++)
    {
        height += 10;
        
        for (int cell = 0; cell < 3; cell ++) {
            int index = 3 * row + cell;
            if (index >= iCount) {
                break;
            }
            
            Device *obj = [deviceArr objectAtIndex:index];
            NSArray *controlArr = [[NSBundle mainBundle] loadNibNamed:@"SwView1" owner:self options:nil];
            SwView1 *swView = nil;
            if ([obj.Type isEqualToString:@"light"]) {
                swView = [controlArr objectAtIndex:0];
                swView.lTitle1.text = obj.DeviceName;
                swView.plTitle = swView.lTitle1;
            } else if ([obj.Type isEqualToString:@"light_1"]) {//翻转
                swView = [controlArr objectAtIndex:1];
                swView.lTitle2.text = obj.DeviceName;
                swView.plTitle = swView.lTitle2;
            } else if ([obj.Type isEqualToString:@"light_check"]) {//点动
                swView = [controlArr objectAtIndex:2];
                swView.lTitle3.text = obj.DeviceName;
                swView.plTitle = swView.lTitle3;
            }
            swView.frame = CGRectMake(cell * 106, height, 106, 113);
            swView.pDeviceId = obj.DeviceId;
            swView.pDeviceName = obj.DeviceName;
            swView.delegate = self;
            [swView setLongPressEvent];
            [svBg_ addSubview:swView];
            
            NSArray *orderArr = [SQLiteUtil getOrderListByDeviceId:obj.DeviceId];
            
            if ([obj.Type isEqualToString:@"light"]) {
                for (Order *orderObj in orderArr) {
                    if ([orderObj.SubType isEqualToString:@"on"]) {
                        swView.btnOn1.orderObj = orderObj;
                    }else if ([orderObj.SubType isEqualToString:@"off"]){
                        swView.btnOff1.orderObj = orderObj;
                    }
                }
            } else if ([obj.Type isEqualToString:@"light_1"]) {//翻转
                for (Order *orderObj in orderArr) {
                    swView.btnOn2.orderObj = orderObj;
                    swView.btnOff2.orderObj = orderObj;
                }
            } else if ([obj.Type isEqualToString:@"light_check"]) {
                for (Order *orderObj in orderArr) {
                    swView.btnOn3.orderObj = orderObj;
                    swView.btnOff3.orderObj = orderObj;
                }
            }
        }
        
        height += 113;
    }
    
    //绘制type为其他照明类的控件
    NSArray *deviceOtherArr = [SQLiteUtil getLightComplexDevice:obj.HouseId andLayerId:obj.LayerId andRoomId:obj.RoomId];
    for (Device *deviceObj in deviceOtherArr) {
        
        height += 10;
        
        NSArray *orderArr = [SQLiteUtil getOrderListByDeviceId:deviceObj.DeviceId];
        
        if ([deviceObj.Type isEqualToString:@"light_bc"]) {//彩色可调照明
            NSArray *controlArr = [[NSBundle mainBundle] loadNibNamed:@"LightBcView" owner:self options:nil];
            LightBcView *bcView = [controlArr objectAtIndex:0];
            bcView.frame = CGRectMake(0, height, 320, 113);
            bcView.pDeviceId = deviceObj.DeviceId;
            bcView.pDeviceName = deviceObj.DeviceName;
            bcView.delegate = self;
            bcView.plTitle = bcView.lTitle;
            [bcView setLongPressEvent];
            bcView.lTitle.text = deviceObj.DeviceName;
            [svBg_ addSubview:bcView];
            
            NSMutableArray *brOrderArr = [NSMutableArray array];
            NSMutableArray *coOrderArr = [NSMutableArray array];
            
            for (Order *obj in orderArr) {
                if ([obj.SubType isEqualToString:@"on"]) {
                    bcView.btnOn.orderObj = obj;
                } else if ([obj.SubType isEqualToString:@"off"]) {
                    bcView.btnOFF.orderObj = obj;
                } else if ([obj.Type isEqualToString:@"br"]) {
                    [brOrderArr addObject:obj];
                } else if ([obj.Type isEqualToString:@"co"]) {
                    [coOrderArr addObject:obj];
                }
            }
            
            bcView.brOrderArr = brOrderArr;
            bcView.coOrderArr = coOrderArr;
            
            height += 113;
            
        } else if ([deviceObj.Type isEqualToString:@"light_bb"]) {//灯光控制器
            NSArray *controlArr = [[NSBundle mainBundle] loadNibNamed:@"LightBbView" owner:self options:nil];
            LightBbView *bbView = [controlArr objectAtIndex:0];
            bbView.frame = CGRectMake(0, height, 320, 113);
            bbView.pDeviceId = deviceObj.DeviceId;
            bbView.pDeviceName = deviceObj.DeviceName;
            bbView.delegate = self;
            bbView.plTitle = bbView.lTitle;
            [bbView setLongPressEvent];
            bbView.lTitle.text = deviceObj.DeviceName;
            [svBg_ addSubview:bbView];
            
            for (Order *obj in orderArr) {
                if ([obj.SubType isEqualToString:@"on"]) {
                    bbView.btnOn.orderObj = obj;
                } else if ([obj.SubType isEqualToString:@"off"]) {
                    bbView.btnOff.orderObj = obj;
                } else if ([obj.SubType isEqualToString:@"ad"]) {
                    bbView.btnUp.orderObj = obj;
                } else if ([obj.SubType isEqualToString:@"rd"]) {
                    bbView.btnDown.orderObj = obj;
                } else if ([obj.SubType isEqualToString:@"red"]) {
                    bbView.btnFK1.orderObj = obj;
                    [bbView.btnFK1 setTitle:obj.OrderName forState:UIControlStateNormal];
                } else if ([obj.SubType isEqualToString:@"green"]) {
                    bbView.btnFK2.orderObj = obj;
                    [bbView.btnFK2 setTitle:obj.OrderName forState:UIControlStateNormal];
                } else if ([obj.SubType isEqualToString:@"blue"]) {
                    bbView.btnFK3.orderObj = obj;
                    [bbView.btnFK3 setTitle:obj.OrderName forState:UIControlStateNormal];
                } else if ([obj.SubType isEqualToString:@"gb"]) {
                    bbView.btnFK4.orderObj = obj;
                    [bbView.btnFK4 setTitle:obj.OrderName forState:UIControlStateNormal];
                } else if ([obj.SubType isEqualToString:@"rb"]) {
                    bbView.btnFK5.orderObj = obj;
                    [bbView.btnFK5 setTitle:obj.OrderName forState:UIControlStateNormal];
                } else if ([obj.SubType isEqualToString:@"rg"]) {
                    bbView.btnFK6.orderObj = obj;
                    [bbView.btnFK6 setTitle:obj.OrderName forState:UIControlStateNormal];
                } 
            }
            
            height += 113;
            
        } else if ([deviceObj.Type isEqualToString:@"light_bri"]) {//亮度可调照明
            NSArray *controlArr = [[NSBundle mainBundle] loadNibNamed:@"LightBriView" owner:self options:nil];
            LightBriView *briView = [controlArr objectAtIndex:0];
            briView.frame = CGRectMake(0, height, 320, 113);
            briView.pDeviceId = deviceObj.DeviceId;
            briView.pDeviceName = deviceObj.DeviceName;
            briView.delegate = self;
            [briView setLongPressEvent];
            briView.lTitle.text = deviceObj.DeviceName;
            briView.plTitle = briView.lTitle;
            [svBg_ addSubview:briView];
            
            NSMutableArray *brOrderArr = [NSMutableArray array];
            
            for (Order *obj in orderArr) {
                if ([obj.SubType isEqualToString:@"on"]) {
                    briView.btnOn.orderObj = obj;
                } else if ([obj.SubType isEqualToString:@"off"]) {
                    briView.btnOff.orderObj = obj;
                } else if ([obj.Type isEqualToString:@"br"]) {
                    [brOrderArr addObject:obj];
                }
            }
            
            briView.brOrderArr = brOrderArr;
            
            height += 113;
        }
    }
    
    [svBg_ setContentSize:CGSizeMake(320, height +10)];
    
}

#pragma mark -
#pragma mark Sw1Delegate,LightBcViewDelegate,LightBriViewDelegate,LightBbViewDelegate

-(void)handleLongPressed:(NSString *)deviceId andDeviceName:(NSString *)deviceName andLabel:(UILabel *)lTitle
{
    define_weakself;
    [UIAlertView alertViewWithTitle:@"温馨提示"
                            message:nil
                  cancelButtonTitle:@"取消"
                  otherButtonTitles:@[@"重命名",@"删除",@"设置IP",@"设备信息",@"存储协议"]
                          onDismiss:^(int buttonIndex){
                              switch (buttonIndex) {
                                  case 0://重命名
                                  {
                                      self.renameView = [RenameView viewFromDefaultXib];
                                      self.renameView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                                      self.renameView.backgroundColor = [UIColor clearColor];
                                      self.renameView.tfContent.text = deviceName;
                                      self.renameView.lTitle = lTitle;
                                      [self.renameView setCanclePressed:^{
                                          [weakSelf.renameView removeFromSuperview];
                                      }];
                                      [self.renameView setConfirmPressed:^(UILabel *lTitle,NSString *newName){
                                          NSString *sUrl = [NetworkUtil getChangeDeviceName:newName andDeviceId:deviceId];
                                          NSURL *url = [NSURL URLWithString:sUrl];
                                          NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                                          NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                                          NSString *sResult = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
                                          if ([[sResult lowercaseString] isEqualToString:@"ok"]) {
                                              
                                              [weakSelf.renameView removeFromSuperview];
                                              
                                              [SQLiteUtil renameDeviceName:deviceId andNewName:newName];
                                              lTitle.text = newName;
                                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示"
                                                                                              message:@"修改成功"
                                                                                             delegate:nil
                                                                                    cancelButtonTitle:@"确定"
                                                                                    otherButtonTitles:nil, nil];
                                              [alert show];
                                              
                                          } else
                                          {
                                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示"
                                                                                              message:@"更新失败,请稍后再试."
                                                                                             delegate:nil
                                                                                    cancelButtonTitle:@"关闭"
                                                                                    otherButtonTitles:nil, nil];
                                              [alert show];
                                          }
                                      }];
                                      [[UIApplication sharedApplication].keyWindow addSubview:weakSelf.renameView];
                                      
                                      break;
                                  }
                                  case 1://删除
                                  {
                                      [UIAlertView alertViewWithTitle:@"温馨提示"
                                                              message:@"确定要删除吗?" cancelButtonTitle:@"取消" otherButtonTitles:@[@"确定"]
                                                            onDismiss:^(int buttonIndex){
                                                                NSString *sUrl = [NetworkUtil getDelDevice:deviceId];
                                                                
                                                                NSURL *url = [NSURL URLWithString:sUrl];
                                                                NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                                                                NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                                                                NSString *sResult = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
                                                                if ([[sResult lowercaseString] isEqualToString:@"ok"]) {
                                                                    
                                                                    [SQLiteUtil removeDevice:deviceId];
                                                                    
                                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示"
                                                                                                                    message:@"删除成功."
                                                                                                                   delegate:nil
                                                                                                          cancelButtonTitle:@"确定"
                                                                                                          otherButtonTitles:nil, nil];
                                                                    [alert show];
                                                                    
                                                                    [self initData];//刷新页面
                                                                    
                                                                }else{
                                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示"
                                                                                                                    message:@"删除失败.请稍后再试."
                                                                                                                   delegate:nil
                                                                                                          cancelButtonTitle:@"关闭"
                                                                                                          otherButtonTitles:nil, nil];
                                                                    [alert show];
                                                                }
                                      }onCancel:nil];
                                      
                                      break;
                                  }
                                  case 2:
                                  {
                                      define_weakself;
                                      self.setIpView = [SetIpView viewFromDefaultXib];
                                      self.setIpView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                                      self.setIpView.backgroundColor = [UIColor clearColor];
                                      self.setIpView.deviceId = deviceId;
                                      [self.setIpView fillContent:deviceId];
                                      [self.setIpView setCancleBlock:^{
                                          [weakSelf.setIpView removeFromSuperview];
                                      }];
                                      [self.setIpView setComfirmBlock:^(NSString *ip) {
                                      }];
                                      
                                      [[UIApplication sharedApplication].keyWindow addSubview:weakSelf.setIpView];
                                      break;
                                  }
                                  case 3:
                                  {
                                      NSArray *array = [SQLiteUtil getOrderListByDeviceId:deviceId];
                                      if (array.count <= 0) {
                                          return;
                                      }
                                      
                                      BOOL isFindIp = NO;
                                      for (Order *order in array) {
                                          if (![DataUtil checkNullOrEmpty:order.Address]) {
                                              isFindIp = YES;
                                              break;
                                          }
                                      }
                                      
                                      if (!isFindIp) {
                                          [UIAlertView alertViewWithTitle:@"温馨提示"
                                                                  message:@"您还没有设置IP,现在设置?"
                                                        cancelButtonTitle:@"取消"
                                                        otherButtonTitles:@[@"确定"]
                                                                onDismiss:^(int buttonIndex) {
                                                                    define_weakself;
                                                                    self.setIpView = [SetIpView viewFromDefaultXib];
                                                                    self.setIpView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                                                                    self.setIpView.backgroundColor = [UIColor clearColor];
                                                                    self.setIpView.deviceId = deviceId;
                                                                    [self.setIpView fillContent:deviceId];
                                                                    [self.setIpView setCancleBlock:^{
                                                                        [weakSelf.setIpView removeFromSuperview];
                                                                    }];
                                                                    [self.setIpView setComfirmBlock:^(NSString *ip) {
                                                                    }];
                                                                    
                                                                    [[UIApplication sharedApplication].keyWindow addSubview:weakSelf.setIpView];
                                                                }onCancel:^{
                                                                    DeviceInfoViewController *vc = [[DeviceInfoViewController alloc] init];
                                                                    vc.deviceName = deviceName;
                                                                    vc.deviceId = deviceId;
                                                                    [self.navigationController pushViewController:vc animated:YES];
                                                                }];
                                      } else {
                                          DeviceInfoViewController *vc = [[DeviceInfoViewController alloc] init];
                                          vc.deviceName = deviceName;
                                          vc.deviceId = deviceId;
                                          [self.navigationController pushViewController:vc animated:YES];
                                      }
                                      break;
                                  }
                                  case 4: {
                                      self.renameView = [RenameView viewFromDefaultXib];
                                      self.renameView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                                      self.renameView.backgroundColor = [UIColor clearColor];
                                      self.renameView.lblTabName.text = @"请输入协议名称";
                                      [self.renameView setCanclePressed:^{
                                          [weakSelf.renameView removeFromSuperview];
                                      }];
                                      [self.renameView setConfirmPressed:^(UILabel *lTitle,NSString *newName){
                                          NSString *sUrl = [NetworkUtil getChangeDeviceProtocol:newName andDeviceId:deviceId];
                                          
                                          NSURL *url = [NSURL URLWithString:sUrl];
                                          NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                                          NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                                          NSString *sResult = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
                                          NSRange range = [sResult rangeOfString:@"error"];
                                          if (range.location != NSNotFound)
                                          {
                                              NSArray *errorArr = [sResult componentsSeparatedByString:@":"];
                                              if (errorArr.count > 1) {
                                                  [SVProgressHUD showErrorWithStatus:errorArr[1]];
                                                  return;
                                              }
                                          }
                                          if ([[sResult lowercaseString] isEqualToString:@"ok"]) {
                                              
                                              [UIAlertView alertViewWithTitle:@"温馨提示"
                                                                      message:@"设置成功"
                                                            cancelButtonTitle:@"确定"];
                                              
                                              [weakSelf.renameView removeFromSuperview];
                                              
                                          }else{
                                              [UIAlertView alertViewWithTitle:@"温馨提示"
                                                                      message:@"设置失败,请稍后再试."
                                                            cancelButtonTitle:@"关闭"];
                                          }
                                      }];
                                      [[UIApplication sharedApplication].keyWindow addSubview:weakSelf.renameView];
                                      break;
                                  }
                                  default:
                                      break;
                              }
    }onCancel:nil];
}

-(void)orderDelegatePressed:(OrderButton *)sender
{
    if (!sender.orderObj) {
        return;
    }
    
    if ([DataUtil checkNullOrEmpty:sender.orderObj.OrderCmd]) {
        
        [UIAlertView alertViewWithTitle:@"温馨提示" message:@"按钮没有配置，请先配置" cancelButtonTitle:@"确定" otherButtonTitles:nil onDismiss:nil onCancel:^{
            [self setOrderViewOpen:sender.orderObj];
        }];
        return;
    }
    
    if ([DataUtil getGlobalIsAddSence]) {//添加场景模式
        if ([SQLiteUtil getShoppingCarCount] >= 40) {
            [UIAlertView alertViewWithTitle:@"温馨提示"
                                    message:@"最多添加40个命令,请删除后再添加."
                          cancelButtonTitle:@"确定"
                          otherButtonTitles:nil
                                  onDismiss:nil
                                   onCancel:^{
                                       SenceConfigViewController *senceConfigVC = [[SenceConfigViewController alloc] init];
                                       [self.navigationController pushViewController:senceConfigVC animated:YES];
            }];
            return;
        }
        BOOL bResult = [SQLiteUtil addOrderToShoppingCar:sender.orderObj.OrderId andDeviceId:sender.orderObj.DeviceId];
        if (bResult) {
            [UIAlertView alertViewWithTitle:@"温馨提示"
                                    message:@"已成功添加命令,是否继续?"
                          cancelButtonTitle:@"继续"
                          otherButtonTitles:@[@"完成"]
                                  onDismiss:^(int buttonIndex) {
                                      SenceConfigViewController *senceConfigVC = [[SenceConfigViewController alloc] init];
                                      [self.navigationController pushViewController:senceConfigVC animated:YES];
            }onCancel:nil];
        }
    } else {
        if ([[DataUtil getGlobalModel] isEqualToString:Model_SetOrder]) {//设置命令模式
            
            [self setOrderViewOpen:sender.orderObj];
            
            return;
        }
        [self load_typeSocket:999 andOrderObj:sender.orderObj];
    }
}

#pragma mark -
#pragma mark Custom Methods

-(void)setOrderViewOpen:(Order *)orderObj
{
    define_weakself;
    self.setOrderView = [SetDeviceOrderView viewFromDefaultXib];
    self.setOrderView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.setOrderView.backgroundColor = [UIColor clearColor];
    self.setOrderView.orderId = orderObj.OrderId;
    NSString *orderCmd = orderObj.OrderCmd;
    if (![DataUtil checkNullOrEmpty:orderCmd])
    {
        NSString *handleOrderCmd = [orderCmd substringFromIndex:4];
        if ([strCurModel_ isEqualToString:Model_ZKDOMAIN] || [strCurModel_ isEqualToString:Model_ZKIp]) {//中控模式 不变
            self.setOrderView.tfOrder.text = handleOrderCmd;
            self.setOrderView.btnAsc.selected = NO;
        } else { //紧急模式(修改Order取值显示出来的时候省略4个字节；之后如果返回命令冒号后为“1”表示为ASCII码，将省略4字节后的报文，转化为ASCII码，2个为一组；“0”表示原声为16进制，无需更改)
            
            if ([orderObj.Hora isEqualToString:@"1"]) { //转ASCII
                NSData *data = [handleOrderCmd hexToBytes];
                NSString *result = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
                self.setOrderView.tfOrder.text = result;
                self.setOrderView.btnAsc.selected = YES;
            } else {
                self.setOrderView.tfOrder.text = handleOrderCmd;
                self.setOrderView.btnAsc.selected = NO;
            }
        }
    } else {
        self.setOrderView.tfOrder.text = @"";
        self.setOrderView.btnAsc.selected = NO;
    }
    
    [self.setOrderView setConfirmBlock:^(NSString *orderCmd,NSString *address,NSString *hoar){
        orderObj.OrderCmd = orderCmd;
        orderObj.Address = address;
        orderObj.Hora = hoar;
    }];
    [self.setOrderView setErrorBlock:^{
        weakSelf.setIpView = [SetIpView viewFromDefaultXib];
        weakSelf.setIpView.frame = CGRectMake(0, 0, weakSelf.view.frame.size.width, weakSelf.view.frame.size.height);
        weakSelf.setIpView.backgroundColor = [UIColor clearColor];
        weakSelf.setIpView.deviceId = orderObj.DeviceId;
        [weakSelf.setIpView fillContent:orderObj.DeviceId];
        [weakSelf.setIpView setCancleBlock:^{
            [weakSelf.setIpView removeFromSuperview];
        }];
        [weakSelf.setIpView setComfirmBlock:^(NSString *ip) {
        }];
        
        [[UIApplication sharedApplication].keyWindow addSubview:weakSelf.setIpView];
    }];
    [[UIApplication sharedApplication].keyWindow addSubview:weakSelf.setOrderView];
}

//配置菜单
-(void)showRightMenu
{
    [_menu close];
    
    if ([KxMenu isOpen]) {
        return [KxMenu dismissMenu];
    }
    
    NSArray *menuItems =
    @[
      [KxMenuItem menuItem:@"正常模式"
                     image:nil
                    target:self
                    action:@selector(pushMenuItem:)],
      
      [KxMenuItem menuItem:@"  配置模式"
                     image:nil
                    target:self
                    action:@selector(pushMenuItem:)]
      ];
    
    KxMenuItem *first = menuItems[0];
    first.foreColor = [UIColor colorWithRed:47/255.0f green:112/255.0f blue:225/255.0f alpha:1.0];
    first.alignment = NSTextAlignmentCenter;
    
    CGRect rect = CGRectMake(215, -50, 100, 50);
    
    [KxMenu showMenuInView:self.view
                  fromRect:rect
                 menuItems:menuItems];
}

//点击下拉事件
- (void)pushMenuItem:(KxMenuItem *)sender
{
    //order
    if ([sender.title isEqualToString:@"正常模式"])
    {
        [DataUtil setGlobalModel:strCurModel_];
    } else if ([sender.title isEqualToString:@"  配置模式"]) {
        [UIAlertView alertViewWithTitle:@"温馨提示"
                                message:@"您已处于设置目标模式\n点击操作即可设置."
                      cancelButtonTitle:@"确定"
                      otherButtonTitles:nil
                              onDismiss:nil
                               onCancel:nil];
        
        [DataUtil setGlobalModel:Model_SetOrder];
    }
}

-(void)btnBackPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
