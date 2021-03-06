//
//  NumberView.m
//  QLink
//
//  Created by 尤日华 on 15-1-16.
//  Copyright (c) 2015年 SANSAN. All rights reserved.
//

#import "NumberView.h"
#import "DataUtil.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "NetworkUtil.h"
#import "SVProgressHUD.h"
#import "AFHTTPRequestOperation.h"

@interface NumberView()
@property (weak, nonatomic) IBOutlet UITextField *tfNumber;

@end

@implementation NumberView

- (IBAction)actionCancle:(id)sender
{
    [self removeFromSuperview];
}
- (IBAction)actionConfirm:(id)sender
{
    NSString *num = self.tfNumber.text;
    if ([DataUtil checkNullOrEmpty:num]) {
        [UIAlertView alertViewWithTitle:@"温馨提示" message:@"请输入密码"];
        return;
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    NSString *sUrl = [NetworkUtil setNumber:num];
    NSURL *url = [NSURL URLWithString:sUrl];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFPropertyListResponseSerializer serializer];
    define_weakself;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSString *sResult = [[NSString alloc] initWithData:responseObject encoding:[DataUtil getGB2312Code]];
         if ([[sResult lowercaseString] isEqualToString:@"ok"]) {
             [UIAlertView alertViewWithTitle:@"温馨提示" message:@"设置成功"];
             [weakSelf removeFromSuperview];
             if (weakSelf.comfirmBlock) {
                 weakSelf.comfirmBlock();
             }
             
             [SVProgressHUD dismiss];
         } else {
             NSRange range = [sResult rangeOfString:@"error"];
             if (range.location != NSNotFound)
             {
                 NSArray *errorArr = [sResult componentsSeparatedByString:@":"];
                 if (errorArr.count > 1) {
                     [weakSelf removeFromSuperview];
                     [SVProgressHUD showErrorWithStatus:errorArr[1]];
                 }
             } else {
                 [UIAlertView alertViewWithTitle:@"温馨提示" message:@"设置失败,请稍后再试."];
                 [SVProgressHUD dismiss];
             }
         }
     }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         [SVProgressHUD dismiss];
         [UIAlertView alertViewWithTitle:@"温馨提示" message:@"设置失败,请稍后再试."];
     }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

#pragma mark -

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self endEditing:YES];
}

@end
