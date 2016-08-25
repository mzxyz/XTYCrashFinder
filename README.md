# XTYCrashFinder
It is a finder class used to collect the crash information of iOS app. The crash information contains the address array of error method, the detail information can  get from PSYM file.


#Main features
* Catching crash information all the time. Not only for debug status, but also for released apps.
* The crash information combines with the current page information is stored as a file and also can upload to server for further processing.
* Tester will be more effective to catch bugs with XTYCrashFinder.

#Requirements
* iOS 6.0+ 
* Xcode 6.1.1+

#Installation
  * Move the `XTYCrashFinder and XTYCrashFinderItem ` into you project
  * Import `XTYCrashFinder.h` in AppDelegate.h 

#API
##Properties
Properties like stack_info, dsym_uuid are used to tell you what the crash is. Properties like title, crash_id, crash_name are used to identify this crash. All these information will be stored as a file in local folder called `CrashLog` 

```
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *app_ver;
@property (nonatomic, strong) NSString *crash_id;
@property (nonatomic, strong) NSString *crash_time;
@property (nonatomic, strong) NSString *crash_name;
@property (nonatomic, strong) NSString *page_name;
@property (nonatomic, strong) NSString *stack_info;
@property (nonatomic, strong) NSString *dsym_uuid;
@property (nonatomic, strong) NSString *base_address;
@property (nonatomic, strong) NSString *top_controller;
@property (nonatomic, strong) NSString *executable_name;
@property (nonatomic, strong) NSString *page_views_stack_info;
```



##Method
 *  Install the XTYCrashFinder, you should use this method  at the end of the `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions` method. This is because some other third party library may also collect crash information after you install, so that they may hijack your crash information.

```
+ (BOOL)installNSExceptionHandler;
+ (void)unInstallNSExceptionHandler;

```

#Usage
it is very easy to use in your program, just install the XTYCrashFinder in the follow method :

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    /** registed crashFinder, yeah! It's so easy to use*/
    [XTYCrashFinder installNSExceptionHandler];
    
    return YES;
}
```

After install XTYCrashFinder, let's begin a Demo:

```
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self crashCaseOne];
}

- (void)crashCaseOne
{
    NSArray *testArray = @[@"a",@"b",@"c"];
    
    /** beyond array bounds */
    [testArray objectAtIndex:4];
}
```

This is the stack_info which crashFinder catch, we can find that the key crash reason  is`[__NSArrayI objectAtIndex:]: index 4 beyond bounds [0 .. 2]`

```
0	CoreFoundation	0x0000000105261e65	__exceptionPreprocess	+	165 
1	libobjc.A.dylib	0x0000000104cdadeb	objc_exception_throw	+	48
2	CoreFoundation	0x0000000105150534	-[__NSArrayI objectAtIndex:]	+	164
3	XTYCrashFinderDemo	0x00000001047d34df	-[ViewController crashCaseOne]	+	143
4	XTYCrashFinderDemo	0x00000001047d3449	-[ViewController viewDidLoad]	+	73
5	UIKit	0x00000001057a4f98	-[UIViewController loadViewIfRequired]	+	1198
6	UIKit	0x00000001057a52e7	-[UIViewController view]	+	27
7	UIKit	0x000000010567bab0	-[UIWindow addRootViewControllerViewIfPossible]	+	61
8	UIKit	0x000000010567c199	-[UIWindow _setHidden:forced:]	+	282
9	UIKit	0x000000010568dc2e	-[UIWindow makeKeyAndVisible]	+	42
10	UIKit	0x0000000105606663	-[UIApplication _callInitializationDelegatesForMainScene:transitionContext:]	+	4131
11	UIKit	0x000000010560ccc6	-[UIApplication _runWithMainScene:transitionContext:completion:]	+	1760
12	UIKit	0x0000000105609e7b	-[UIApplication workspaceDidEndTransaction:]	+	188
13	FrontBoardServices	0x0000000107fda754	-[FBSSerialQueue _performNext]	+	192
14	FrontBoardServices	0x0000000107fdaac2	-[FBSSerialQueue _performNextFromRunLoopSource]	+	45
15	CoreFoundation	0x000000010518da31	__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__	+	17
16	CoreFoundation	0x000000010518395c	__CFRunLoopDoSources0	+	556
17	CoreFoundation	0x0000000105182e13	__CFRunLoopRun	+	867
18	CoreFoundation	0x0000000105182828	CFRunLoopRunSpecific	+	488
19	UIKit	0x00000001056097cd	-[UIApplication _run]	+	402
20	UIKit	0x000000010560e610	UIApplicationMain	+	171
21	XTYCrashFinderDemo	0x00000001047d67ff	main	+	111
22	libdyld.dylib	0x000000010799d92d	start	+	1
```

#License
XTYCrashFinder is released under the MIT license. See LICENSE for details.
