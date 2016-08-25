//
//  XTYCrashFinder.m
//  XTYCrashFinder
//
//  Created by Mr.Sunday on 16/8/3.
//  Copyright © 2016年 Sunday. All rights reserved.
//

#import "XTYCrashFinder.h"
#import <UIKit/UIKit.h>
#include <mach/exception_types.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#include <execinfo.h>
#import "XTYCrashFinderItem.h"


/** Signal Key*/
static NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
static NSString * const UncaughtExceptionHandlerSignalExceptionStackInfo = @"UncaughtExceptionHandlerSignalExceptionStackInfo";

/** Flag for judging whether we've installed our custom handlers or not. */
static volatile sig_atomic_t XTYInstalled = 0;

/** The exception handler that was in place before we installed ours. */
static NSUncaughtExceptionHandler* XTYPreviousUncaughtExceptionHandler;

/** Signal handlers that were installed before we installed ours. */
static struct sigaction* XTYPreviousSignalHandlers = NULL;

/** DSYM UUID*/
static NSString *dsym_uuid;


#define CrachLogDir [NSString stringWithFormat:@"%@/CrashLog",NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]]

@implementation XTYCrashFinder

+ (void)uploadCrashLogFileToServerWithCrashInfo:(NSString *)crashInfo crashLogFilePath:(NSString *)crashLogFilePath
{
    if ([crashLogFilePath length] && [crashInfo length] > 0)
    {
        [XTYCrashFinder uploadCrashLogFileToServerWithCrashInfo:@[crashInfo] crashLogFilePathList:@[crashLogFilePath]];
    }
}

+ (void)uploadCrashLogFileToServerWithCrashInfo:(NSArray<NSString *> *)crashInfo crashLogFilePathList:(NSArray<NSString *> *)crashLogFilePathList
{
    /**
     *  you should upload the crashInfo to the server in this class method and 
     *  delete the crashInfoFile after returning sucess through method [XTYCrashFinder deleteCrashLogFileList:crashLogFilePathList];
     */
}

+ (void)uploadAllCrashLogFilesToServer
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *crashDirectoryEnumerator = [fileManager enumeratorAtPath:CrachLogDir];
    NSArray *crashFilesList = [crashDirectoryEnumerator allObjects];
    NSString *crashLogsDir = CrachLogDir;
    
    __weak NSArray *wcrashFilesList = crashFilesList;
    if ([crashFilesList count])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSMutableArray *crashLogList = [NSMutableArray array];
            NSMutableArray *crashLogFilePathList = [NSMutableArray array];
            for (NSString *crashLogFileName in wcrashFilesList)
            {
                NSString *crashLogFilePath = [NSString stringWithFormat:@"%@/%@", crashLogsDir, crashLogFileName];
                NSString *crashInfo = [NSString stringWithContentsOfURL:[NSURL URLWithString:crashLogFilePath] encoding:NSUTF8StringEncoding error:nil];
                
                if ([crashInfo length])
                {
                    /**it is better to convert crashInfo to json*/
                    [crashLogList addObject:crashInfo];
                    [crashLogFilePathList addObject:crashLogFilePath];
                }
            }
            
            [XTYCrashFinder uploadCrashLogFileToServerWithCrashInfo:crashLogList crashLogFilePathList:crashLogFilePathList];
        });
    }
}

static BOOL s_hasCrashed = NO;
+ (void)handleException:(NSException *)exception
{
    if (XTYInstalled)
    {
        UIDevice *device = [UIDevice currentDevice];
        NSString *UUIDStr = [device identifierForVendor].UUIDString;
        NSString *crashDate = [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]];
        NSString *crashId = [NSString stringWithFormat:@"%@_%@", UUIDStr, crashDate];
        if (![dsym_uuid length]) {dsym_uuid = [XTYCrashFinder getDSYMUUID];}
        
        NSString *executableName = [[NSBundle mainBundle] infoDictionary][(__bridge_transfer NSString *)kCFBundleExecutableKey];
        
        XTYCrashFinderItem *crashInfoItem = [[XTYCrashFinderItem alloc] init];
        crashInfoItem.executable_name = executableName;
        crashInfoItem.title = [exception reason];
        crashInfoItem.app_ver = [XTYCrashFinder appVersion];
        crashInfoItem.crash_id = crashId;
        crashInfoItem.crash_name = [exception name];
        crashInfoItem.crash_time = crashDate;
        crashInfoItem.dsym_uuid = dsym_uuid;
        crashInfoItem.base_address = [XTYCrashFinder getBaseAddress];
        
        /**add by yourself*/
        crashInfoItem.page_name = nil;
        crashInfoItem.top_controller = nil;
        crashInfoItem.page_views_stack_info = nil;
        
        NSString *signalReason = [[exception userInfo] valueForKey:UncaughtExceptionHandlerSignalExceptionStackInfo];
        if ([signalReason length])
        {
            crashInfoItem.stack_info = signalReason;
        }
        else
        {
            NSArray *stacksymbol = [self handleStackSymbols:[exception callStackSymbols]];
            crashInfoItem.stack_info = [stacksymbol componentsJoinedByString:@"\n"];
        }
        
#ifdef DEBUG
        UIAlertController *alController = [UIAlertController alertControllerWithTitle:crashInfoItem.title
                                                                              message:crashInfoItem.stack_info
                                                                       preferredStyle:UIAlertControllerStyleAlert];
        [alController performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        
        [UIView animateWithDuration:0.5 animations:^{
            exit(0);
        }];
#endif
        
        /**each crash info save to file only once*/
        @synchronized([XTYCrashFinder class]) {
            if (s_hasCrashed == NO)
            {
                s_hasCrashed = YES;
            }
            else return;
        }
        
        [XTYCrashFinder saveCrashInfo:[XTYCrashFinder crashItemChangeToString:crashInfoItem] crashId:crashId];
    }
}

+ (NSString *)crashItemChangeToString:(XTYCrashFinderItem *)crashItem
{
    /**you should translate crashItem to json string*/
    return nil;
}

+ (BOOL)isSupport64bit
{
    int int_size = sizeof(NSInteger);
    
    if (int_size != 8)
    {
        return NO;
    }
    
    return YES;
}

+ (NSArray *)handleStackSymbols:(NSArray *)originalCallStackSymbols
{
    if (![self isSupport64bit]) {
        return originalCallStackSymbols;
    }
    
    NSMutableArray *stacks = [[NSMutableArray alloc] init];
    
    NSString *executableName = [[NSBundle mainBundle] infoDictionary][(__bridge_transfer NSString *)kCFBundleExecutableKey];
    
    @autoreleasepool
    {
        for (NSString *s in originalCallStackSymbols)
        {
            NSString *replaced = [s stringByReplacingOccurrencesOfString:@"([0-9]+?)(\\s*)([\\w\\.]+?)(\\s*?)(0x([0-9a-f])+)(\\s*)(.*?)(\\s*?)\\+(\\s*?)([0-9]+)(,)?" withString:@"$1$3$5$8$11" options:NSRegularExpressionSearch range:NSMakeRange(0, s.length)];
            
            NSArray *split = [replaced componentsSeparatedByString:@""];
            NSMutableString *convert_s = [[NSMutableString alloc] init];
            [split enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL conv = NO;
                if (split.count == 5 && idx == 2 && [split[3] isEqualToString:executableName])
                {
                    obj = [NSString stringWithFormat:@"0x%llx", [split[4] longLongValue]+0x100000000ll];
                    conv = YES;
                }
                else if (split.count == 5 && idx == 4)
                {
                    obj = [NSString stringWithFormat:@"+\t%@", obj];
                }
                
                [convert_s appendFormat:@"%@%@%@", idx==0?@"":@"\t", obj, conv?@"\t(conv)":@""];
            }];
            
            [stacks addObject:convert_s];
        }
    }
    
    return stacks;
}

+ (NSString*)appVersion;
{
    NSString * version = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    if (version == nil || [version length] == 0)
    {
        version = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleVersion"];
    }
    
    return version;
}

+ (NSString *)getBaseAddress
{
    NSString *executableName = [[NSBundle mainBundle] infoDictionary][(__bridge_transfer NSString *)kCFBundleExecutableKey];
    const char *exec_utf8 = [executableName UTF8String];
    
    uint32_t numImages = _dyld_image_count();
    for (uint32_t i = 0; i < numImages; i++)
    {
        const struct mach_header *header = _dyld_get_image_header(i);
        const char *name = _dyld_get_image_name(i);
        const char *p = strrchr(name, '/');
        
        if (p && (strcmp(p + 1, exec_utf8) == 0))
        {
            return [NSString stringWithFormat:@"%@ %p", executableName, header];
        }
    }
    return @"";
}

+ (NSString *)getDSYMUUID
{
    const struct mach_header *executableHeader = NULL;
    for (uint32_t i = 0; i < _dyld_image_count(); i++)
    {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE)
        {
            executableHeader = header;
            break;
        }
    }
    
    if (!executableHeader) {return nil;}
    
    BOOL is64bit = executableHeader->magic == MH_MAGIC_64 || executableHeader->magic == MH_CIGAM_64;
    uintptr_t cursor = (uintptr_t)executableHeader + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    const struct segment_command *segmentCommand = NULL;
    for (uint32_t i = 0; i < executableHeader->ncmds; i++, cursor += segmentCommand->cmdsize)
    {
        segmentCommand = (struct segment_command *)cursor;
        if (segmentCommand->cmd == LC_UUID)
        {
            const struct uuid_command *uuidCommand = (const struct uuid_command *)segmentCommand;
            return [[[NSUUID alloc] initWithUUIDBytes:uuidCommand->uuid] UUIDString];
        }
    }
    
    return nil;
}

+ (void)saveCrashInfo:(NSString *)crashInfo crashId:(NSString *)crashId
{
    /** save crash info*/
    BOOL isDir = NO;
    NSString *crashDir = CrachLogDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:crashDir isDirectory:&isDir];
    if (!(isDir == YES && existed))
    {
        [fileManager createDirectoryAtPath:crashDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *crashFilePath = [NSString stringWithFormat:@"%@/MFWCrash_%@.log", crashDir, crashId];
    [crashInfo writeToFile:crashFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [XTYCrashFinder uploadCrashLogFileToServerWithCrashInfo:crashInfo crashLogFilePath:crashFilePath];
}

+ (void)deleteCrashLogFileList:(NSArray<NSString *> *)crashLogFilePathList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *filePath in crashLogFilePathList)
    {
        [fileManager removeItemAtPath:filePath error:nil];
    }
}

#pragma mark - signal
/** Fatal signals to be monitored.*/
static int monitored_signals[] = {
    SIGABRT,
    SIGBUS,
    SIGFPE,
    SIGILL,
    SIGSEGV,
    SIGEMT,
    SIGKILL,
    SIGTRAP
};

static NSString * xty_signal_machExceptionForSignal(const int sigNum)
{
    switch(sigNum)
    {
        case SIGFPE:
            return @"EXC_ARITHMETIC";
        case SIGSEGV:
            return @"EXC_BAD_ACCESS";
        case SIGBUS:
            return @"EXC_BAD_ACCESS";
        case SIGILL:
            return @"EXC_BAD_INSTRUCTION";
        case SIGTRAP:
            return @"EXC_BREAKPOINT";
        case SIGEMT:
            return @"EXC_EMULATION";
        case SIGABRT:
            // The Apple reporter uses EXC_CRASH instead of EXC_UNIX_ABORT
            return @"EXC_CRASH";
        case SIGKILL:
            return @"EXC_SOFT_SIGNAL";
    }
    return @"";
}

static NSString * xty_signal_SignalStrForSignal(const int sigNum)
{
    switch(sigNum)
    {
        case SIGFPE:
            return @"SIGFPE";
        case SIGSEGV:
            return @"SIGSEGV";
        case SIGBUS:
            return @"SIGBUS";
        case SIGILL:
            return @"SIGILL";
        case SIGTRAP:
            return @"SIGTRAP";
        case SIGEMT:
            return @"SIGEMT";
        case SIGABRT:
            return @"SIGABRT";
        case SIGKILL:
            return @"SIGKILL";
    }
    return @"";
}

/* number of signals in the fatal signals list */
static int monitored_signals_count = (sizeof(monitored_signals) / sizeof(monitored_signals[0]));

/**
 *  Signal Catch Hander
 *
 *  @param signal signal type which lead to app crash
 */
static void SignalHandle(int signal, siginfo_t* signalInfo, void* userContext)
{
    /** 解析signalInfo
     NSString *signalInfoStr =
     [NSString stringWithFormat:@"errno_association:%d\n
                                signal_code:%d\n
                                sending_process:%d\n
                                faulting_instruction%ld\n", 
                                signalInfo->si_errno, 
                                signalInfo->si_code, 
                                signalInfo->si_pid,
                                ((uintptr_t)signalInfo->si_addr)];
     */
    
    NSArray *stackSymbols = [XTYCrashFinder handleStackSymbols:[NSThread callStackSymbols]];
    
    NSString *stackInfo = [stackSymbols componentsJoinedByString:@"\n"];
    NSString *reason = [NSString stringWithFormat: @"%@(%d) Exception:%@\n", xty_signal_SignalStrForSignal(signal), signal, xty_signal_machExceptionForSignal(signal)];
    NSException *exception = [NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
                                                     reason:reason
                                                   userInfo:[NSDictionary dictionaryWithObject:stackInfo
                                                                                        forKey:UncaughtExceptionHandlerSignalExceptionStackInfo]];
    [XTYCrashFinder handleException:exception];
}

static void uncaughtExceptionHandler(NSException *exception)
{
    [XTYCrashFinder handleException:exception];
}

+ (BOOL)installNSExceptionHandler
{
    if (XTYInstalled) return YES;
    XTYInstalled = 1;
    
    [XTYCrashFinder installSignalHandlers];
    
    /** back up previous handler*/
    XTYPreviousUncaughtExceptionHandler =  NSGetUncaughtExceptionHandler();
    
    /** Setting new handler*/
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    /** reupload crashLogs*/
    [XTYCrashFinder uploadAllCrashLogFilesToServer];
    
    return YES;
}

+ (void)installSignalHandlers
{
    struct sigaction action = {{0}};
    action.sa_flags = SA_SIGINFO | SA_ONSTACK;
#ifdef __LP64__
    action.sa_flags |= SA_64REGSET;
#endif
    sigemptyset(&action.sa_mask);
    action.sa_sigaction = &SignalHandle;
    
    if(XTYPreviousSignalHandlers == NULL)
    {
        XTYPreviousSignalHandlers = malloc(sizeof(*XTYPreviousSignalHandlers)* (unsigned)monitored_signals_count);
    }
    
    for (NSInteger i=0; i<monitored_signals_count; i++)
    {
        sigaction(monitored_signals[i], &action, &XTYPreviousSignalHandlers[i]);
    }
}

+ (void)unInstallNSExceptionHandler
{
    if (!XTYInstalled) return;
    
    NSSetUncaughtExceptionHandler(XTYPreviousUncaughtExceptionHandler);
    XTYInstalled = 0;
}

@end