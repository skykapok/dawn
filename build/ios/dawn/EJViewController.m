#import "EJViewController.h"
#import "winfw.h"

static EJViewController* _controller = nil;

@interface EJViewController () {
}

@property (strong, nonatomic) EAGLContext *context;

@end

@implementation EJViewController

-(id)init {
	_controller = [super init];
	return _controller;
}

+(EJViewController*)getLastInstance {
	return _controller;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientatio {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientatio];

    float s = [[UIScreen mainScreen] scale];
    float w = self.view.bounds.size.width;
    float h = self.view.bounds.size.height;

    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            ejoy2d_win_rotate(w, h, s, ORIENT_UP);
            break;

        case UIInterfaceOrientationPortraitUpsideDown:
            ejoy2d_win_rotate(w, h, s, ORIENT_DOWN);
            break;

        case UIInterfaceOrientationLandscapeLeft:
            ejoy2d_win_rotate(w, h, s, ORIENT_LEFT);
            break;

        case UIInterfaceOrientationLandscapeRight:
            ejoy2d_win_rotate(w, h, s, ORIENT_RIGHT);
            break;

        default:
            break;
    }
}

-(void)dealloc {
	_controller = nil;
	if ([EAGLContext currentContext] == self.context) {
		[EAGLContext setCurrentContext:nil];
	}
}

-(void)viewDidLoad {
	[super viewDidLoad];

	NSLog(@"viewDidLoad");

	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

	if (!self.context) {
		NSLog(@"Failed to create ES context");
	}

	GLKView *view = (GLKView *)self.view;
	view.context = self.context;

	[EAGLContext setCurrentContext:self.context];
    self.preferredFramesPerSecond = 30;

	CGFloat screenScale = [[UIScreen mainScreen] scale];
	CGRect bounds = [[UIScreen mainScreen] bounds];

	printf("screenScale: %f\n", screenScale);
	printf("bounds: x:%f y:%f w:%f h:%f\n",
		 bounds.origin.x, bounds.origin.y,
		 bounds.size.width, bounds.size.height);

	NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
	const char* folder = [appFolderPath UTF8String];

	ejoy2d_win_init(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height, screenScale, folder);
}

-(BOOL)prefersStatusBarHidden {
	return YES;
}

-(void)viewDidUnload {
	[super viewDidUnload];

	NSLog(@"viewDidUnload");

	if ([self isViewLoaded] && ([[self view] window] == nil)) {
		self.view = nil;

		if ([EAGLContext currentContext] == self.context) {
			[EAGLContext setCurrentContext:nil];
		}
		self.context = nil;
	}
}

-(void)update {
	ejoy2d_win_update(self.timeSinceLastUpdate);
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
	ejoy2d_win_frame();
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		CGPoint p = [touch locationInView:touch.view];
		ejoy2d_win_touch(p.x, p.y, TOUCH_BEGIN);
	}
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		CGPoint p = [touch locationInView:touch.view];
		ejoy2d_win_touch(p.x, p.y, TOUCH_MOVE);
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		CGPoint p = [touch locationInView:touch.view];
		ejoy2d_win_touch(p.x, p.y, TOUCH_END);
	}
}

@end
