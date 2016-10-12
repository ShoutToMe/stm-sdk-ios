//
//  GraphView.m
//  ShoutToMeDev
//
//  Created by Adam Harris on 11/13/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import "GraphView.h"

#define DEFAULT_LINE_SPACING    1.0
#define DEFAULT_LINE_COLOR      [UIColor blackColor]
#define DEFAULT_LINE_WIDTH      1.0

@interface GraphView ()
{
    BOOL _bInitialized;
}

@property (nonatomic, strong) NSMutableArray *arrayValues;

@end

@implementation GraphView

#pragma mark - UIView Methods

- (id)init
{
    self = [super init];
    if (self)
    {
        [self initInternal];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initInternal];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initInternal];
}

- (void)drawRect:(CGRect)rect
{
    //NSLog(@"draw rect");
    if (self.arrayValues)
    {
        CGContextRef context = UIGraphicsGetCurrentContext();

        CGContextSetLineWidth(context, self.lineWidth);
        CGContextSetStrokeColorWithColor(context, [self.lineColor CGColor]);

        CGFloat span = _maxValue - _minValue;

        for (int nValue = 0; nValue < [self.arrayValues count]; nValue++)
        {
            CGPoint ptStart, ptEnd;
            CGFloat val = [[self.arrayValues objectAtIndex:[self.arrayValues count] - nValue - 1] floatValue];
            val = fmax(val, _minValue);
            val = fmin(val, _maxValue);

            ptStart.x = self.bounds.size.width - (((nValue + 1) * self.lineWidth) + ((nValue + 0) * self.lineSpacing));
            ptEnd.x = ptStart.x;

            CGFloat valPerY = (val - _minValue) / span;
            CGFloat coverage = self.bounds.size.height * valPerY;
            ptStart.y = (self.bounds.size.height - coverage) / 2.0;
            ptEnd.y = ptStart.y + coverage;

            if ((ptEnd.y - ptStart.y) < 1.0)
            {
                //ptStart.y--;
                ptEnd.y++;
            }
            CGContextMoveToPoint(context, ptStart.x, ptStart.y);
            CGContextAddLineToPoint(context, ptEnd.x, ptEnd.y);

            //NSLog(@"%f - span: %f, per: %f, height: %f, coverage: %f, start: %f, end: %f", val, span, valPerY, self.bounds.size.height, coverage, ptStart.y, ptEnd.y);

#if 0 // old graph
            pt.y = self.bounds.size.height - (((val - self.minValue) / (self.maxValue - self.minValue)) * self.bounds.size.height);

            //NSLog(@"%f becomes %f", val, pt.y);

            if (nValue == 0)
            {
                CGContextMoveToPoint(context, pt.x, pt.y);
            }
            else
            {
                CGContextAddLineToPoint(context, pt.x, pt.y);
            }
#endif
        }

        CGContextStrokePath(context);
    }
}

#pragma mark - Assigment Methods

- (void)setMinValue:(CGFloat)minValue
{
    [self initInternal];
    _minValue = minValue;
    [self setNeedsDisplay];
}

- (void)setMaxValue:(CGFloat)maxValue
{
    [self initInternal];
    _maxValue = maxValue;
    [self setNeedsDisplay];
}

- (void)setLineSpacing:(CGFloat)lineSpacing
{
    [self initInternal];
    _lineSpacing = lineSpacing;
    [self.arrayValues removeAllObjects];
    [self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    [self initInternal];
    _lineWidth = lineWidth;
    [self.arrayValues removeAllObjects];
    [self setNeedsDisplay];
}


#pragma mark - Public Methods

- (void)addValue:(CGFloat)value
{
    [self addNumber:[NSNumber numberWithFloat:value]];
}

- (void)addNumber:(NSNumber *)number
{
    [self initInternal];
    if (self.arrayValues)
    {
        [self.arrayValues addObject:number];
        [self removeUneededValues];
        [self setNeedsDisplay];
    }
}

- (void)clear
{
    [self initInternal];
    self.arrayValues = [[NSMutableArray alloc] init];
    [self setNeedsDisplay];
}

#pragma mark - Misc Methods

- (void)initInternal
{
    if (!_bInitialized)
    {
        _bInitialized = YES;
        self.arrayValues = [[NSMutableArray alloc] init];
        _lineSpacing = DEFAULT_LINE_SPACING;
        _lineWidth = DEFAULT_LINE_WIDTH;
        self.lineColor = DEFAULT_LINE_COLOR;
    }
}

// maximum number of values that can be shown based upon graph size and spacing
- (NSUInteger)maxValuesShown
{
    NSUInteger max = (self.bounds.size.width / (self.lineSpacing + self.lineWidth));
    max++;
    //NSLog(@"width: %f, spacing: %f, total_width: %f, max: %d", self.lineWidth, self.lineSpacing, self.bounds.size.width, (int)max);

    return max;
}

- (void)removeUneededValues
{
    if (self.arrayValues)
    {
        NSUInteger nShown = [self maxValuesShown];
        if ([self.arrayValues count] > nShown)
        {
            NSUInteger nDelete = [self.arrayValues count] - nShown;
            [self.arrayValues removeObjectsInRange:NSMakeRange(0, nDelete)];
        }
    }
}

@end
