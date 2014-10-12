//
//  LightBriView.m
//  QLink
//
//  Created by SANSAN on 14-9-28.
//  Copyright (c) 2014年 SANSAN. All rights reserved.
//

#import "LightBriView.h"

@implementation LightBriView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)awakeFromNib
{
    _sliderLight.frame = CGRectMake(100, 44, 206, 5);
    [_sliderLight setThumbImage:[UIImage imageNamed:@"light_roundButton.png"] forState:UIControlStateNormal];
}

- (IBAction)btnPressed:(OrderButton *)sender
{
    NSLog(@"=====%@",sender.orderObj.OrderName);
}
@end
