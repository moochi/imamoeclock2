//
//  JDCountdownFlipView.m
//
//  Created by Markus Emrich on 12.03.11.
//  Copyright 2011 Markus Emrich. All rights reserved.
//

#import "JDDateCountdownFlipView.h"


@implementation JDDateCountdownFlipView

- (id)init
{
    return [self initWithTargetDate: [NSDate date]];
}


- (id)initWithTargetDate: (NSDate*) targetDate
{
    self = [super initWithFrame: CGRectZero];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizesSubviews = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		
        self.mFlipNumberViewDay    = [[JDGroupedFlipNumberView alloc] initWithFlipNumberViewCount: 3];
        self.mFlipNumberViewHour   = [[JDGroupedFlipNumberView alloc] initWithFlipNumberViewCount: 2];
        self.mFlipNumberViewMinute = [[JDGroupedFlipNumberView alloc] initWithFlipNumberViewCount: 2];
        self.mFlipNumberViewSecond = [[JDGroupedFlipNumberView alloc] initWithFlipNumberViewCount: 2];
        
        self.mFlipNumberViewDay.delegate    = self;
        self.mFlipNumberViewHour.delegate   = self;
        self.mFlipNumberViewMinute.delegate = self;
        self.mFlipNumberViewSecond.delegate = self;
        
        self.mFlipNumberViewHour.maximumValue = 23;
        self.mFlipNumberViewMinute.maximumValue = 59;
        self.mFlipNumberViewSecond.maximumValue = 59;
        
        [self setZDistance: 60];
        
        CGRect frame = self.mFlipNumberViewHour.frame;
        CGFloat spacing = floorf(frame.size.width*0.1);
        
        self.frame = CGRectMake(0, 0, frame.size.width*4+spacing*3, frame.size.height);
        
        frame.origin.x += frame.size.width + spacing;
        self.mFlipNumberViewHour.frame = frame;
        frame.origin.x += frame.size.width + spacing;
        self.mFlipNumberViewMinute.frame = frame;
        frame.origin.x += frame.size.width + spacing;
        self.mFlipNumberViewSecond.frame = frame;
        
        [self addSubview: self.mFlipNumberViewDay];
        [self addSubview: self.mFlipNumberViewHour];
        [self addSubview: self.mFlipNumberViewMinute];
        [self addSubview: self.mFlipNumberViewSecond];
        
        [self setTargetDate: targetDate];
        
        [self.mFlipNumberViewSecond animateDownWithTimeInterval: 1.0];
    }
    return self;
}

- (void)dealloc
{
    self.mFlipNumberViewDay = nil;
    self.mFlipNumberViewHour = nil;
    self.mFlipNumberViewMinute = nil;
    self.mFlipNumberViewSecond = nil;

    /*
    [mFlipNumberViewDay release];
    [mFlipNumberViewHour release];
    [mFlipNumberViewMinute release];
    [mFlipNumberViewSecond release];
    
    [super dealloc];
     */
}

#pragma mark -
#pragma mark DEBUG

- (void) setDebugValues
{
    // DEBUG
    
    self.mFlipNumberViewHour.maximumValue = 2;
    self.mFlipNumberViewMinute.maximumValue = 2;
    self.mFlipNumberViewSecond.maximumValue = 4;
    
    self.mFlipNumberViewHour.intValue = 2;
    self.mFlipNumberViewMinute.intValue = 2;
    self.mFlipNumberViewSecond.intValue = 4;
    
    [self.mFlipNumberViewSecond animateDownWithTimeInterval: 0.5];
}

#pragma mark -

- (void) setZDistance: (NSUInteger) zDistance
{
    [self.mFlipNumberViewDay setZDistance: zDistance];
    [self.mFlipNumberViewHour setZDistance: zDistance];
    [self.mFlipNumberViewMinute setZDistance: zDistance];
    [self.mFlipNumberViewSecond setZDistance: zDistance];
}

- (void) setTargetDate: (NSDate*) targetDate
{
    NSUInteger flags = NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents* dateComponents = [[NSCalendar currentCalendar] components: flags fromDate: [NSDate date] toDate: targetDate options: 0];
    
    self.mFlipNumberViewDay.intValue    = [dateComponents day];
    self.mFlipNumberViewHour.intValue   = [dateComponents hour];
    self.mFlipNumberViewMinute.intValue = [dateComponents minute];
    self.mFlipNumberViewSecond.intValue = [dateComponents second];
}

- (void) setFrame: (CGRect) rect
{
    CGFloat digitWidth = rect.size.width/10.0;
    CGFloat margin     = digitWidth/3.0;
    CGFloat currentX   = 0;
    
    self.mFlipNumberViewDay.frame = CGRectMake(currentX, 0, digitWidth*3, rect.size.height);
    currentX   += self.mFlipNumberViewDay.frame.size.width;
    
    for (JDGroupedFlipNumberView* view in [NSArray arrayWithObjects: self.mFlipNumberViewHour, self.mFlipNumberViewMinute, self.mFlipNumberViewSecond, nil])
    {
        currentX   += margin;
        view.frame = CGRectMake(currentX, 0, digitWidth*2, rect.size.height);
        currentX   += view.frame.size.width;
    }
    
    // take bottom right of last view for new size, to match size of subviews
    CGRect lastFrame = self.mFlipNumberViewSecond.frame;
    rect.size.width  = ceil(lastFrame.size.width  + lastFrame.origin.x);
    rect.size.height = ceil(lastFrame.size.height + lastFrame.origin.y);
    
    [super setFrame: rect];
}

#pragma mark -
#pragma mark GroupedFlipNumberViewDelegate


- (void) groupedFlipNumberView: (JDGroupedFlipNumberView*) groupedFlipNumberView willChangeToValue: (NSUInteger) newValue
{
//    LOG(@"ToValue: %d", newValue);
    
    JDGroupedFlipNumberView* animateView = nil;
    
    if (groupedFlipNumberView == self.mFlipNumberViewSecond) {
        animateView = self.mFlipNumberViewMinute;
    }
    else if (groupedFlipNumberView == self.mFlipNumberViewMinute) {
        animateView = self.mFlipNumberViewHour;
    }
    else if (groupedFlipNumberView == self.mFlipNumberViewHour) {
        animateView = self.mFlipNumberViewDay;
    }
    
    if (animateView != nil)
    {
        if (groupedFlipNumberView.currentDirection == eFlipDirectionDown && newValue == groupedFlipNumberView.maximumValue)
        {
            [animateView animateToPreviousNumber];
        }
        else if (groupedFlipNumberView.currentDirection == eFlipDirectionUp && newValue == 0)
        {
            [animateView animateToNextNumber];
        }
    }
}


- (void) groupedFlipNumberView: (JDGroupedFlipNumberView*) groupedFlipNumberView didChangeValue: (NSUInteger) newValue animated: (BOOL) animated
{
}

@end
