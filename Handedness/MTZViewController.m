/*
 Copyright (c) 2013, Matt Zanchelli
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the <organization> nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//
//  MTZViewController.m
//  Handedness
//
//  Created by Matt on 5/16/13.
//  Copyright (c) 2013 Matt Zanchelli. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "MTZViewController.h"
#import "MTZHandyPinchGestureRecognizer.h"
#import "MTZZoomLevelPopover.h"

@interface MTZViewController ()

@property (strong, nonatomic) UIView *viewToScale;
@property CGSize fullSize;
@property CGSize gestureStartSize;

@property (strong, nonatomic) MTZZoomLevelPopover *zoomPercentage;
@property CGFloat labelOffset;

@end

@implementation MTZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	[self.view setBackgroundColor:[UIColor underPageBackgroundColor]];
	
	CGRect rect = self.view.bounds;
	rect.origin.y += 20;
	rect.origin.x += 20;
	rect.size.width -= 40;
	rect.size.height -= 40;
	_viewToScale = [[UIView alloc] initWithFrame:rect];
	[_viewToScale setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin  |
	                                  UIViewAutoresizingFlexibleRightMargin |
	                                  UIViewAutoresizingFlexibleTopMargin   |
	                                  UIViewAutoresizingFlexibleBottomMargin];
	[_viewToScale setBackgroundColor:[UIColor whiteColor]];
	[_viewToScale.layer setShadowColor:[UIColor blackColor].CGColor];
	[_viewToScale.layer setShadowOpacity:0.75f];
	[_viewToScale.layer setShadowOffset:(CGSize){0,1}];
	[_viewToScale.layer setShadowRadius:2];
	_fullSize = _viewToScale.bounds.size;
	[self.view addSubview:_viewToScale];
	
	MTZHandyPinchGestureRecognizer *pinch = [[MTZHandyPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinch:)];
	[self.view addGestureRecognizer:pinch];
	
	_zoomPercentage = [[MTZZoomLevelPopover alloc] initWithFrame:CGRectMake(0, 0, 128, 50)];
	[self.view addSubview:_zoomPercentage];
	
	_labelOffset = 64;
}

- (void)didPinch:(id)sender
{
	if ( [sender isKindOfClass:[MTZHandyPinchGestureRecognizer class]] ) {
		MTZHandyPinchGestureRecognizer *sendr = (MTZHandyPinchGestureRecognizer *) sender;
		switch ( sendr.state ) {
			case UIGestureRecognizerStateBegan:
				_gestureStartSize = _viewToScale.bounds.size;
			case UIGestureRecognizerStateChanged:
				[self scaleThatView:sendr.scale];
				[self showScaleForPinch:sendr];
				break;
			case UIGestureRecognizerStateCancelled:
			case UIGestureRecognizerStateEnded:
			case UIGestureRecognizerStateFailed:
				[self showScaleForPinch:sendr];
				break;
			default:
				break;
		}
	}
}

- (void)scaleThatView:(CGFloat)scale
{	
	CGFloat w = _gestureStartSize.width * scale;
	CGFloat h = _gestureStartSize.height * scale;
	CGFloat x = _viewToScale.center.x - (w/2);
	CGFloat y = _viewToScale.center.y - (h/2);
	
	[_viewToScale setFrame:(CGRect){x, y, w, h}];
}

- (CGRect)getRectWithinScreen:(CGRect)rect
{	
	CGFloat padding = 10;
	
	if ( rect.origin.x < padding ) {
		rect.origin.x = padding;
	} else if ( [UIScreen mainScreen].bounds.size.width - (rect.origin.x + rect.size.width) < padding ) {
		rect.origin.x = [UIScreen mainScreen].bounds.size.width - rect.size.width - padding;
	}
	
	if ( rect.origin.y < padding ) {
		rect.origin.y = padding;
	} else if ( [UIScreen mainScreen].bounds.size.height - (rect.origin.y + rect.size.height) < padding ) {
		rect.origin.y = [UIScreen mainScreen].bounds.size.height - rect.size.height - padding;
	}
	
	return rect;
}

- (void)showScaleForPinch:(MTZHandyPinchGestureRecognizer *)sender
{
	switch ( sender.state ) {
		case UIGestureRecognizerStateBegan:
			// Show popover
			[_zoomPercentage show];
			
			// Find center
			CGPoint center = [sender locationInView:self.view];
			
			// Check handedness and adjust center accordingly
			if ( sender.hand == MTZHandednessLeft ) {
				center.x += _labelOffset;
				center.y -= _labelOffset;
				NSLog(@"left");
			} else if ( sender.hand == MTZHandednessRight ) {
				center.x -= _labelOffset;
				center.y -= _labelOffset;
				NSLog(@"right");
			} else {
				NSLog(@"undecided");
			}
			
			
			// Show it at the appropriate place
			[_zoomPercentage setCenter:center];
			
			// Make sure it's an appropriate distance away from edges
			_zoomPercentage.frame = [self getRectWithinScreen:_zoomPercentage.frame];
			
		case UIGestureRecognizerStateChanged:
			// Set zoom level
			[_zoomPercentage setZoomLevel:(_viewToScale.bounds.size.width / _fullSize.width)];
			break;
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled:
			// Hide the popover
			[_zoomPercentage hide];
		default:
			break;
	}
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
