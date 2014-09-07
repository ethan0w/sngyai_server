//
//  RootViewController.m
//  MiidiSdkSample_Wall
//
//  Created by adpooh miidi on 12-5-20.
//  Copyright 2012 miidi. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController () <PBOfferWallDelegate>

@end


@implementation RootViewController


#pragma mark -
#pragma mark Initialization


#pragma mark -
#pragma mark View lifecycle


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]; if (self) {
        // 创建积分墙管理器,这⾥里使⽤用的是测试 ID,请按照 User Guide ⽂文档中获取新的 PublisherID。
        _offerWallManager = [[DMOfferWallManager alloc] initWithPublisherID:@"96ZJ1IZAzeB0nwTBAd"];
    }
    return self; }

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
        //
	_guomobwall_vc=[[GuoMobWallViewController alloc] initWithId:@"1igkea2wocd3978"];
    //设置代理
    _guomobwall_vc.delegate=self;
    _offerWallManager.delegate = self;
    
    //设置果盟定时查询是否获得积分
    _guomobwall_vc.updatetime=30;
    
    //初始化积分
    
    _score = [[[NSNumber alloc] initWithInt:0] autorelease];
    
    [PBOfferWall sharedOfferWall].delegate = self;
    
    [NSThread detachNewThreadSelector:@selector(threadMethod) toTarget:self withObject:nil];

    //设置有米获取积分监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pointsGotted:) name:kYouMiPointsManagerRecivedPointsNotification object:nil];
}

#pragma mark -
#pragma mark Table view data source


- (void)pbOfferWall:(PBOfferWall *)pbOfferWall queryResult:(NSArray *)taskCoins
          withError:(NSError *)error
{
    NSLog(@"----------%s", __PRETTY_FUNCTION__);
    NSLog(@"用户已经完成的任务：%@", taskCoins);
    
    NSMutableString *mstr = [NSMutableString string];
    if (taskCoins) {
        if (taskCoins.count > 0) {
            for (NSDictionary *dic in taskCoins) {
                [mstr appendFormat:@"%@:%@;", [dic objectForKey:@"taskContent"], [dic objectForKey:@"coins"]];
            }
        }
        else {
            [mstr appendString:@"无积分"];
        }
    }
    else {
        [mstr appendString:error.localizedDescription];
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"返回的金币数"
                                                        message:mstr
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"确定", nil];
    [alertView show];
    [alertView release];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    //多盟
	_offerWallManager.delegate = nil;
    [_offerWallManager release];
    _offerWallManager = nil;
    
    [super dealloc];
}

- (void)didReceiveAwardPoints:(NSInteger)totalPoints{
	NSLog(@"didReceiveAwardPoints success! totalPoints=%d",totalPoints);
	
	[self alertMessage:[NSString stringWithFormat:@"卧槽得分啦,用户总积分 %d !",totalPoints]];
	
}

- (void)didFailReceiveAwardPoints:(NSError *)error{
	NSLog(@"didFailReceiveAwardPoints failed!");
	
	[self alertMessage:@"卧槽得分失败啦~~~~~~~~~~~~~~~~~~~~~"];
	
}

//miidi
- (void)didReceiveGetPoints:(NSInteger)totalPoints forPointName:(NSString*)pointName{
	NSLog(@"didReceiveGetPoints success! totalPoints:%d",totalPoints);
	if (totalPoints > 0) {
        NSNumber* newScore = [[[NSNumber alloc] initWithInt:[self.score intValue]+totalPoints] autorelease];
        self.score = newScore;
        [MiidiAdWall requestSpendPoints:totalPoints withDelegate:self];
        
        UILocalNotification *localnotification=[[[UILocalNotification alloc] init]autorelease];
        if (localnotification!=nil) {
        
            NSDate *now=[NSDate new];
            localnotification.fireDate=now;
            localnotification.repeatInterval=0; //循环次数，kCFCalendarUnitWeekday一周一次
        
            localnotification.timeZone=[NSTimeZone defaultTimeZone];
            localnotification.soundName = UILocalNotificationDefaultSoundName;
            localnotification.alertBody=[NSString stringWithFormat:@"米迪的%@积分，总积分%d", pointName, totalPoints];
        
            localnotification.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
        
            //下面设置本地通知发送的消息，这个消息可以接受
            NSDictionary* infoDic = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
            localnotification.userInfo = infoDic;
            //发送通知
            [[UIApplication sharedApplication] scheduleLocalNotification:localnotification];
        }
    }
}

- (void)didFailReceiveGetPoints:(NSError *)error{
	NSLog(@"didFailReceiveGetPoints failed!");
	
	[self alertMessage:@"卧槽没获取到总分（米迪）~~~~~~~~~~~~~~~~~~~~~~~~~~~"];
}

// 有米
- (void)pointsGotted:(NSNotification *)notification {
    NSDictionary *dict = [notification userInfo];
    NSArray *pointInfos = dict[kYouMiPointsManagerPointInfosKey];
    for (NSDictionary *aPointInfo in pointInfos) {
        // aPointInfo 是每份积分的信息，包括积分数，userID，下载的APP的名字
        
        NSLog(@"积分数：%@", aPointInfo[kYouMiPointsManagerPointAmountKey]);
        NSLog(@"userID：%@", aPointInfo[kYouMiPointsManagerPointUserIDKey]);
        NSLog(@"产品名字：%@", aPointInfo[kYouMiPointsManagerPointProductNameKey]);
        
        if([aPointInfo[kYouMiPointsManagerPointAmountKey] intValue] > 0){
            NSLog(@"积分信息：%@", dict);
            
            //更新总积分
            NSNumber* newScore = [[[NSNumber alloc] initWithInt:[self.score intValue] +
                                   [aPointInfo[kYouMiPointsManagerPointAmountKey] intValue]] autorelease];
            self.score = newScore;
            
            UILocalNotification *localnotification=[[[UILocalNotification alloc] init]autorelease];
            if (localnotification!=nil) {
                
                NSDate *now=[NSDate new];
                localnotification.fireDate=now;
                localnotification.repeatInterval=0; //循环次数，kCFCalendarUnitWeekday一周一次
                
                localnotification.timeZone=[NSTimeZone defaultTimeZone];
                localnotification.soundName = UILocalNotificationDefaultSoundName;
                localnotification.alertBody=[NSString stringWithFormat:@"用户%@通过有米在应用%@获得%@积分",
                                             aPointInfo[kYouMiPointsManagerPointUserIDKey],
                                             aPointInfo[kYouMiPointsManagerPointProductNameKey],
                                             aPointInfo[kYouMiPointsManagerPointAmountKey] ];
                localnotification.soundName = UILocalNotificationDefaultSoundName;
                localnotification.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
                
                //下面设置本地通知发送的消息，这个消息可以接受
                NSDictionary* infoDic = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
                localnotification.userInfo = infoDic;
                //发送通知
                [[UIApplication sharedApplication] scheduleLocalNotification:localnotification];
            }
        }
    }
}

//果盟
- (void)checkPoint:(NSString *)appname point:(int)point
{
    if (point > 0) {
        
        NSNumber* newScore = [[[NSNumber alloc] initWithInt:[self.score intValue]+point] autorelease];
        
        self.score = newScore;
        NSLog(@"hello, world ****************** add_score%d, total_score:%@", point, self.score);
        UILocalNotification *localnotification=[[[UILocalNotification alloc] init] autorelease];

        if (localnotification!=nil) {
            NSDate *now=[NSDate new];
            localnotification.fireDate=now;
            localnotification.soundName = UILocalNotificationDefaultSoundName;
            localnotification.timeZone=[NSTimeZone defaultTimeZone];
            localnotification.soundName = UILocalNotificationDefaultSoundName;
            localnotification.alertBody= [NSString stringWithFormat:@"果盟通过%@获得%d积分",appname,point];
            
            localnotification.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
            
            //下面设置本地通知发送的消息，这个消息可以接受
            NSDictionary* infoDic = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
            localnotification.userInfo = infoDic;
            //发送通知
            [[UIApplication sharedApplication] scheduleLocalNotification:localnotification];
        }
    }
}

-(void)threadMethod

{
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(timerDone) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    [[NSRunLoop currentRunLoop] run];
}

-(void)timerDone
{
    [[PBOfferWall sharedOfferWall] queryRewardCoin:^(NSArray *taskCoins, PBRequestError *error) {
        [MiidiAdWall requestGetPoints:self];
        if (taskCoins.count > 0) {
            
            NSNumber* newScore = [[[NSNumber alloc] initWithInt:[self.score intValue]+taskCoins.count] autorelease];
            
            self.score = newScore;
            NSLog(@"hello, world ****************** add_score%d, total_score:%@ taskCoins:%@", taskCoins.count, self.score, taskCoins);
            UILocalNotification *localnotification=[[[UILocalNotification alloc] init]autorelease];
            
            if (localnotification!=nil) {
                NSDate *now=[NSDate new];
                localnotification.fireDate=now;
                localnotification.soundName = UILocalNotificationDefaultSoundName;
                localnotification.timeZone=[NSTimeZone defaultTimeZone];
                localnotification.soundName = UILocalNotificationDefaultSoundName;
                NSMutableString *alertStr = [NSMutableString string];
                for (NSDictionary *dic in taskCoins) {
                    [alertStr appendFormat:@"%@:%@;", [dic objectForKey:@"taskContent"], [dic objectForKey:@"coins"]];
                }
                localnotification.alertBody = alertStr;
                
                localnotification.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
                
                //下面设置本地通知发送的消息，这个消息可以接受
                NSDictionary* infoDic = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
                localnotification.userInfo = infoDic;
                //发送通知
                [[UIApplication sharedApplication] scheduleLocalNotification:localnotification];
            }
        }
    }];
}

-(void) alertMessage:(NSString*)msg{
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"warning"
														message:msg
													   delegate:nil
											  cancelButtonTitle:@"确定" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


@end


