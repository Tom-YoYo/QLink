//
//  SwView.h
//  QLink
//
//  Created by SANSAN on 14-9-24.
//  Copyright (c) 2014年 SANSAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderButton.h"

@interface SwView : UIView

@property(nonatomic,strong) IBOutlet OrderButton *btnOn;
@property(nonatomic,strong) IBOutlet OrderButton *btnOff;

@end
