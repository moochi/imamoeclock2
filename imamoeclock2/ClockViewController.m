//
//  ClockViewController.m
//  imamoeclock2
//
//  Created by mochida rei on 12/09/24.
//  Copyright (c) 2012年 mochida rei. All rights reserved.
//

#import "ClockViewController.h"

@interface ClockViewController ()
@property (strong, nonatomic) IBOutlet UIView *secondView;
@property (strong, nonatomic) JDGroupedFlipNumberView *secondFlip;
@property (strong, nonatomic) IBOutlet UIView *minuteView;
@property (strong, nonatomic) JDGroupedFlipNumberView *minuteFlip;
@property (strong, nonatomic) IBOutlet UIView *hourView;
@property (strong, nonatomic) JDGroupedFlipNumberView *hourFlip;
@property (strong, nonatomic) NSTimer *ctimer;

@end

@implementation ClockViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit |
                                   NSMonthCalendarUnit  |
                                   NSDayCalendarUnit    |
                                   NSHourCalendarUnit   |
                                   NSMinuteCalendarUnit |
                                   NSSecondCalendarUnit
                                              fromDate:date];
    
    
    self.secondFlip = [[JDGroupedFlipNumberView alloc] initWithFlipNumberViewCount: 2];
    self.secondFlip.delegate = self;
    [self.secondFlip setIntValue:dateComps.second];
    //[self.secondFlip animateUpWithTimeInterval:1.f];
    [self.secondFlip setMaximumValue:59];
    [self.secondFlip setFrame:CGRectMake(0, 0, 28, 28)];
    [self.secondView addSubview: self.secondFlip];
    
    self.minuteFlip = [[JDGroupedFlipNumberView alloc] initWithFlipNumberViewCount: 2];
    self.minuteFlip.delegate = self;
    [self.minuteFlip setIntValue:dateComps.minute];
    [self.minuteFlip setMaximumValue:59];
    [self.minuteFlip setFrame:CGRectMake(0, 0, 48, 48)];
    [self.minuteView addSubview:self.minuteFlip];
    
    self.hourFlip = [[JDGroupedFlipNumberView alloc] initWithFlipNumberViewCount: 2];
    self.hourFlip.delegate = self;
    [self.hourFlip setIntValue:dateComps.hour];
    [self.hourFlip setMaximumValue:23];
    [self.hourFlip setFrame:CGRectMake(0, 0, 48, 48)];
    [self.hourView addSubview:self.hourFlip];
    
    self.ctimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                   target:self
                                                 selector:@selector(timerDidEnd)
                                                 userInfo:nil
                                                  repeats:YES];

}

- (void)timerDidEnd
{
    //タイマー動作
    //TODO
    [self.secondFlip animateToNextNumber];
}

- (void) groupedFlipNumberView: (JDGroupedFlipNumberView*) groupedFlipNumberView willChangeToValue: (NSUInteger) newValue {
    //NSLog(@"hoge:%d",newValue);
    if (newValue == 0) {
        if ([groupedFlipNumberView isEqual:self.secondFlip]) {
            // next minute
            [self.minuteFlip animateToNextNumber];
        }
        if ([groupedFlipNumberView isEqual:self.minuteFlip]) {
            // next hour
            [self.hourFlip animateToNextNumber];
        }
    }
}

- (void)viewDidUnload
{
    [self setSecondView:nil];
    [self setMinuteView:nil];
    [self setHourView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)dealloc {
    self.secondView = nil;
    self.minuteView = nil;
    self.hourView = nil;
    
    //タイマーの停止
    if (self.ctimer) {
        if ([self.ctimer isValid]) {
            [self.ctimer invalidate];
            //停止時にはnilにすること
            [self setCtimer:nil];
        }
    }
    
    //[super dealloc];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
