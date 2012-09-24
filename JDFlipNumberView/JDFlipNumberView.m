//
//  FlipNumberView.m
//
//  Created by Markus Emrich on 26.02.11.
//  Copyright 2011 Markus Emrich. All rights reserved.
//
//
//  based on
//  www.voyce.com/index.php/2010/04/10/creating-an-ipad-flip-clock-with-core-animation/
//

#import "JDFlipNumberView.h"

static NSString* kFlipAnimationKey = @"kFlipAnimationKey";


@interface JDFlipNumberView (private)
- (void) initImages;
- (CGFloat) defaultAnimationDuration;
- (void) animateIntoCurrentDirectionWithDuration: (CGFloat) duration;
- (void) nextValueWithoutAnimation: (NSTimer*) timer;
- (void) updateFlipViewFrame;
- (NSUInteger) validValueFromInt: (NSInteger) index;
@end


@implementation JDFlipNumberView

//@synthesize delegate;
@synthesize currentDirection = mCurrentDirection;
@synthesize currentAnimationDuration = mCurrentAnimationDuration;
@synthesize intValue = mCurrentValue;
@synthesize maxValue = mMaxValue;

- (id) init
{
	return [self initWithIntValue: 0];
}

- (id) initWithIntValue: (NSUInteger) startNumber
{
	//NSLog(@"initWithIntValue %d", startNumber);
	
    self = [super initWithFrame: CGRectZero];
    if (self)
	{
		self.backgroundColor = [UIColor clearColor];
        self.autoresizesSubviews = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		
        mMaxValue = 9;
		mCurrentValue = [self validValueFromInt: startNumber];
		mCurrentState = eFlipStateFirstHalf;
        mCurrentDirection = eFlipDirectionDown;
		mCurrentAnimationDuration = 0.25;
		
		[self initImages];
		
		if (!self.mTopImages) {
			NSLog(@"ERROR CREATING IMAGES!");
			return nil;
		}
		
		// setup frame
		UIImage* image = [self.mTopImages objectAtIndex: mCurrentValue];
		super.frame = CGRectMake(0, 0, image.size.width, image.size.height*2);
    }
    return self;
}

// needed to release view properly
- (void) removeFromSuperview
{
	[self stopAnimation];
	[super removeFromSuperview];
}

- (void)dealloc
{
	// NSLog(@"dealloc (value: %d)", mCurrentValue);
	
	self.mTopImages = nil;
	self.mBottomImages = nil;
	
	self.mImageViewTop = nil;
	self.mImageViewBottom = nil;
	self.mImageViewFlip = nil;
    /*
	[mTopImages release];
	[mBottomImages release];
	
	[mImageViewTop release];
	[mImageViewBottom release];
	[mImageViewFlip release];
	
    [super dealloc];
     */
}

- (void) initImages
{
	NSMutableArray* filenames = [NSMutableArray arrayWithCapacity: 10];
	for (int i = 0; i < 10; i++) {
		[filenames addObject: [NSString stringWithFormat: @"JDFlipNumberView.bundle/%d.png", i]];
	}
	
	NSMutableArray* images = [NSMutableArray arrayWithCapacity: [filenames count]*2];
	
	// create bottom and top images
	for (int i = 0; i < 2; i++)
	{
		for (NSString* filename in filenames)
		{
			UIImage* image	= [UIImage imageNamed: [NSString stringWithFormat: @"%@", filename]];
			CGSize size		= CGSizeMake(image.size.width, image.size.height/2);
			CGFloat yPoint	= (i==0) ? 0.0 : -size.height;

			if (!image) {
				NSLog(@"DIDNT FIND IMAGE: %@", filename);
				return;
			}
			
			UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
			[image drawAtPoint:CGPointMake(0.0,yPoint)];
			UIImage *top = UIGraphicsGetImageFromCurrentImageContext();
			[images addObject: top];
			UIGraphicsEndImageContext();
		}
	}
	
	self.mTopImages	  = [images subarrayWithRange: NSMakeRange(0, [filenames count])];
	self.mBottomImages = [images subarrayWithRange: NSMakeRange([filenames count], [filenames count])];
	
	// setup image views
	self.mImageViewTop	 = [[UIImageView alloc] initWithImage: [self.mTopImages    objectAtIndex: mCurrentValue]];
	self.mImageViewBottom = [[UIImageView alloc] initWithImage: [self.mBottomImages objectAtIndex: mCurrentValue]];
	self.mImageViewFlip	 = [[UIImageView alloc] initWithImage: [self.mTopImages    objectAtIndex: mCurrentValue]];
    self.mImageViewFlip.hidden = YES;
	
	self.mImageViewBottom.frame = CGRectMake(0, self.mImageViewTop.image.size.height, self.mImageViewTop.image.size.width, self.mImageViewTop.image.size.height);
	
	// add image views
	[self addSubview: self.mImageViewTop];
	[self addSubview: self.mImageViewBottom];
	[self addSubview: self.mImageViewFlip];
	
	// setup default 3d transform
	[self setZDistance: (self.mImageViewTop.image.size.height*2)*3];
}

- (CGSize) sizeThatFits: (CGSize) aSize
{
    if (!self.mTopImages || [self.mTopImages count] <= 0) {
        return [super sizeThatFits: aSize];
    }
    
    UIImage* image = (UIImage*)[self.mTopImages objectAtIndex: 0];
    CGFloat ratioW     = aSize.width/aSize.height;
    CGFloat origRatioW = image.size.width/(image.size.height*2);
    CGFloat origRatioH = (image.size.height*2)/image.size.width;
    
    if (ratioW>origRatioW)
    {
        aSize.width = aSize.height*origRatioW;
    }
    else
    {
        aSize.height = aSize.width*origRatioH;
    }
    
    return aSize;
}


#pragma mark -
#pragma mark external access

- (void) setFrame: (CGRect)rect
{
    [self setFrame:rect allowUpscaling:NO];
}

- (void) setFrame: (CGRect)rect allowUpscaling:(BOOL)upscalingAllowed
{
    if (!upscalingAllowed) {
        rect.size.width  = MIN(rect.size.width, self.mImageViewTop.image.size.width);
        rect.size.height = MIN(rect.size.height, self.mImageViewTop.image.size.height*2);
    }
    
    rect.size = [self sizeThatFits: rect.size];
	[super setFrame: rect];
    
    rect.origin = CGPointMake(0, 0);
    rect.size.height /= 2.0;
    self.mImageViewTop.frame = rect;
    rect.origin.y += rect.size.height;
    self.mImageViewBottom.frame = rect;
    
	if (mCurrentState == eFlipStateFirstHalf) {
        self.mImageViewFlip.frame = self.mImageViewTop.frame;
    } else {
        self.mImageViewFlip.frame = self.mImageViewBottom.frame;
    }
	
	[self setZDistance: self.frame.size.height*3];
}

- (void) setZDistance: (NSUInteger) zDistance
{
	// setup 3d transform
	CATransform3D aTransform = CATransform3DIdentity;
	aTransform.m34 = -1.0 / zDistance;	
	self.layer.sublayerTransform = aTransform;
}

- (void) setIntValue: (NSUInteger) newValue
{
	// save new value
	mCurrentValue = [self validValueFromInt: newValue];
	
	// display new value
	self.mImageViewTop.image		= [self.mTopImages    objectAtIndex: mCurrentValue];
	self.mImageViewBottom.image  = [self.mBottomImages objectAtIndex: mCurrentValue];
    self.mImageViewFlip.image    = [self.mTopImages    objectAtIndex: mCurrentValue];
	
	// if animation is running in step2, top&bottom already show the next value
	if (mCurrentState == eFlipStateSecondHalf) {
        self.mImageViewTop.image	 = [self.mTopImages objectAtIndex: [self nextValue]];
		self.mImageViewFlip.image = [self.mBottomImages objectAtIndex: [self nextValue]];
	}
	// if animation is running in step1, top already shows next value
	else if ([self.mImageViewFlip.layer.animationKeys count] > 0) {
		self.mImageViewTop.image = [self.mTopImages objectAtIndex: [self nextValue]];
	}
	
	// inform delegate
	if ([delegate respondsToSelector: @selector(flipNumberView:didChangeValue:animated:)]) {
		[delegate flipNumberView: self didChangeValue: mCurrentValue animated: NO];
	}
}

#pragma mark -
#pragma mark animation

- (CGFloat) defaultAnimationDuration
{
	if (self.mTimer != nil) {
		return [self.mTimer timeInterval]/3.0;
	}
	
	return 0.15;
}

- (void) animateToNextNumber
{
	[self animateToNextNumberWithDuration: [self defaultAnimationDuration]];
}

- (void) animateToNextNumberWithDuration: (CGFloat) duration
{	
    mCurrentDirection = eFlipDirectionUp;
    [self animateIntoCurrentDirectionWithDuration: duration];
}

- (void) animateToPreviousNumber
{
	[self animateToPreviousNumberWithDuration: [self defaultAnimationDuration]];
}

- (void) animateToPreviousNumberWithDuration: (CGFloat) duration
{	
    mCurrentDirection = eFlipDirectionDown;
    [self animateIntoCurrentDirectionWithDuration: duration];
}

- (void) animateIntoCurrentDirectionWithDuration: (CGFloat) duration
{
	mCurrentAnimationDuration = duration;
	
	// get next value
    NSUInteger nextIndex = [self nextValue];
    if (mCurrentDirection == eFlipDirectionDown) {
        nextIndex = [self previousValue];
    }
	
	// if duration is less than 0.05, don't animate
	if (duration < 0.05) {
		// inform delegate
		if ([delegate respondsToSelector: @selector(flipNumberView:willChangeToValue:)]) {
			[delegate flipNumberView: self willChangeToValue: nextIndex];
		}
		[NSTimer scheduledTimerWithTimeInterval: duration
										 target: self
									   selector: @selector(nextValueWithoutAnimation:)
									   userInfo: nil
										repeats: NO];
		return;
	}
	
	[self updateFlipViewFrame];
	
	// setup animation
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
	animation.duration	= MIN(0.35,mCurrentAnimationDuration);
	animation.delegate	= self;
	animation.removedOnCompletion = NO;
	animation.fillMode = kCAFillModeForwards;
    
	// exchange images & setup animation
	if (mCurrentState == eFlipStateFirstHalf)
	{
		// setup first animation half
		self.mImageViewFlip.frame   = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height/2.0);
		self.mImageViewFlip.image   = [self.mTopImages	objectAtIndex: mCurrentValue];
		self.mImageViewBottom.image = [self.mBottomImages objectAtIndex: mCurrentValue];
		self.mImageViewTop.image	   = [self.mTopImages    objectAtIndex: nextIndex];
        
		// inform delegate
		if ([delegate respondsToSelector: @selector(flipNumberView:willChangeToValue:)]) {
			[delegate flipNumberView: self willChangeToValue: nextIndex];
		}
		
		animation.fromValue	= [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 1, 0, 0)];
		animation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-M_PI_2, 1, 0, 0)];
		animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn];
	}
	else
	{
		// setup second animation half
		self.mImageViewFlip.image = [self.mBottomImages objectAtIndex: nextIndex];
        
		animation.fromValue	= [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI_2, 1, 0, 0)];
		animation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 1, 0, 0)];
		animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
	}
	
	// add/start animation
	[self.mImageViewFlip.layer addAnimation: animation forKey: kFlipAnimationKey];
	 
	// show animated view
	self.mImageViewFlip.hidden = NO;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	if (!flag) {
		return;
	}
	
	if (mCurrentState == eFlipStateFirstHalf)
	{		
		// do second animation step
		mCurrentState = eFlipStateSecondHalf;
		[self animateIntoCurrentDirectionWithDuration: mCurrentAnimationDuration];
	}
	else
	{
		// reset state
		mCurrentState = eFlipStateFirstHalf;
		
		// set new value
		NSUInteger nextIndex = [self nextValue];
		if (mCurrentDirection == eFlipDirectionDown) {
			nextIndex = [self previousValue];
		}
		mCurrentValue = nextIndex;
		
		// update images
		self.mImageViewBottom.image = [self.mBottomImages objectAtIndex: mCurrentValue];
        self.mImageViewFlip.hidden  = YES;
		
		// remove old animation
		[self.mImageViewFlip.layer removeAnimationForKey: kFlipAnimationKey];
		
		// inform delegate
		if ([delegate respondsToSelector: @selector(flipNumberView:didChangeValue:animated:)]) {
			[delegate flipNumberView: self didChangeValue: mCurrentValue animated: YES];
		}
	}
}

- (void) nextValueWithoutAnimation: (NSTimer*) timer
{
	// get next value
    NSUInteger nextIndex = [self nextValue];
    if (mCurrentDirection == eFlipDirectionDown) {
        nextIndex = [self previousValue];
    }
	
	// set next value
	[self setIntValue: nextIndex];
	
	// inform delegate
	if ([delegate respondsToSelector: @selector(flipNumberView:didChangeValue:animated:)]) {
		[delegate flipNumberView: self didChangeValue: mCurrentValue animated: NO];
	}
}


#pragma mark -
#pragma mark timed animation


- (void) animateUpWithTimeInterval: (NSTimeInterval) timeInterval
{	
	timeInterval = MAX(timeInterval, 0.001);
	
	[self stopAnimation];
	self.mTimer = [NSTimer scheduledTimerWithTimeInterval: timeInterval target: self selector: @selector(animateToNextNumber) userInfo: nil repeats: YES];
}

- (void) animateDownWithTimeInterval: (NSTimeInterval) timeInterval
{	
	timeInterval = MAX(timeInterval, 0.001);
	
	[self stopAnimation];
	self.mTimer = [NSTimer scheduledTimerWithTimeInterval: timeInterval target: self selector: @selector(animateToPreviousNumber) userInfo: nil repeats: YES];
}


#pragma mark -
#pragma mark cancel animation


- (void) stopAnimation
{
	[self.mImageViewFlip.layer removeAllAnimations];
	self.mImageViewFlip.hidden = YES;
	
	if (self.mTimer)
	{
		[self.mTimer invalidate];
		//[mTimer release];
		self.mTimer = nil;
	}
}


#pragma mark -
#pragma mark helper


- (NSUInteger) nextValue
{
	return [self validValueFromInt: mCurrentValue+1];
}

- (NSUInteger) previousValue
{
	return [self validValueFromInt: mCurrentValue-1];
}

- (NSUInteger) validValueFromInt: (NSInteger) index
{
    if (index<0) {
        index += (mMaxValue+1);
    }
    NSUInteger newIndex = index % (mMaxValue+1);
    
    return newIndex;
}

- (void) updateFlipViewFrame
{	
	if (mCurrentState == eFlipStateFirstHalf)
	{
		self.mImageViewFlip.layer.anchorPoint = CGPointMake(0.5, 1.0);
		self.mImageViewFlip.frame = self.mImageViewTop.frame;
	}
	else
	{
		self.mImageViewFlip.layer.anchorPoint = CGPointMake(0.5, 0.0);
		self.mImageViewFlip.frame = self.mImageViewBottom.frame;
	}
}

@end
