//
//  NBULog.m
//  NBUCore
//
//  Created by 利辺羅 on 2012/12/06.
//  Copyright (c) 2012年 CyberAgent Inc. All rights reserved.
//

#import "NBULog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

#ifdef DEBUG
    static int _appLogLevel = LOG_LEVEL_VERBOSE;
#elif defined (TESTING)
    static int _appLogLevel = LOG_LEVEL_INFO;
#endif

@implementation NBULog

+ (void)initialize
{
    id<DDLogFormatter> nbuFormatter = [NSClassFromString(@"NBULogFormatter") new];
#ifdef DEBUG
    // Set log to Xcode debug console/Terminal
    DDTTYLogger * ttyLogger = [DDTTYLogger sharedInstance];
    ttyLogger.logFormatter = nbuFormatter;
    
    // Colors for iOS are not working yet...
    //    [ttyLogger setColorsEnabled:YES];
    //    [ttyLogger setForegroundColor:[UIColor redColor]
    //                  backgroundColor:nil
    //                          forFlag:LOG_FLAG_VERBOSE];
    [DDLog addLogger:ttyLogger];
#else
    // Set log to a file
    DDFileLogger * fileLogger = [DDFileLogger new];
    fileLogger.logFileManager.maximumNumberOfLogFiles = 10;
    fileLogger.logFormatter = nbuFormatter;
    [DDLog addLogger:fileLogger];
#endif
}

+ (int)appLogLevel
{
#if defined (DEBUG) || defined (TESTING)
    return _appLogLevel;
#else
    return APP_LOG_LEVEL;
#endif
}

+ (void)setAppLogLevel:(int)LOG_LEVEL
{
#if defined (DEBUG) || defined (TESTING)
    _appLogLevel = LOG_LEVEL;
#endif
}

@end

#pragma mark - Log Formatter based on DispatchQueueLogFormatter

#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>
#import "DDLog.h"

/**
 * Welcome to Cocoa Lumberjack!
 *
 * The project page has a wealth of documentation if you have any questions.
 * https://github.com/robbiehanson/CocoaLumberjack
 *
 * If you're new to the project you may wish to read the "Getting Started" page.
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/GettingStarted
 *
 *
 * This class provides a log formatter that prints the dispatch_queue label instead of the mach_thread_id.
 *
 * A log formatter can be added to any logger to format and/or filter its output.
 * You can learn more about log formatters here:
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/CustomFormatters
 *
 * A typical NSLog (or DDTTYLogger) prints detailed info as [<process_id>:<thread_id>].
 * For example:
 *
 * 2011-10-17 20:21:45.435 AppName[19928:5207] Your log message here
 *
 * Where:
 * - 19928 = process id
 * -  5207 = thread id (mach_thread_id printed in hex)
 *
 * When using grand central dispatch (GCD), this information is less useful.
 * This is because a single serial dispatch queue may be run on any thread from an internally managed thread pool.
 * For example:
 *
 * 2011-10-17 20:32:31.111 AppName[19954:4d07] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.112 AppName[19954:5207] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.113 AppName[19954:2c55] Message from my_serial_dispatch_queue
 *
 * This formatter allows you to replace the standard [box:info] with the dispatch_queue name.
 * For example:
 *
 * 2011-10-17 20:32:31.111 AppName[img-scaling] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.112 AppName[img-scaling] Message from my_serial_dispatch_queue
 * 2011-10-17 20:32:31.113 AppName[img-scaling] Message from my_serial_dispatch_queue
 *
 * If the dispatch_queue doesn't have a set name, then it falls back to the thread name.
 * If the current thread doesn't have a set name, then it falls back to the mach_thread_id in hex (like normal).
 *
 * Note: If manually creating your own background threads (via NSThread/alloc/init or NSThread/detachNeThread),
 * you can use [[NSThread currentThread] setName:(NSString *)].
 **/
@interface NBULogFormatter : NSObject <DDLogFormatter> {
@protected
	
	NSString *dateFormatString;
}

/**
 * Standard init method.
 * Configure using properties as desired.
 **/
- (id)init;

/**
 * The minQueueLength restricts the minimum size of the [detail box].
 * If the minQueueLength is set to 0, there is no restriction.
 *
 * For example, say a dispatch_queue has a label of "diskIO":
 *
 * If the minQueueLength is 0: [diskIO]
 * If the minQueueLength is 4: [diskIO]
 * If the minQueueLength is 5: [diskIO]
 * If the minQueueLength is 6: [diskIO]
 * If the minQueueLength is 7: [diskIO ]
 * If the minQueueLength is 8: [diskIO  ]
 *
 * The default minQueueLength is 0 (no minimum, so [detail box] won't be padded).
 *
 * If you want every [detail box] to have the exact same width,
 * set both minQueueLength and maxQueueLength to the same value.
 **/
@property (assign) NSUInteger minQueueLength;

/**
 * The maxQueueLength restricts the number of characters that will be inside the [detail box].
 * If the maxQueueLength is 0, there is no restriction.
 *
 * For example, say a dispatch_queue has a label of "diskIO":
 *
 * If the maxQueueLength is 0: [diskIO]
 * If the maxQueueLength is 4: [disk]
 * If the maxQueueLength is 5: [diskI]
 * If the maxQueueLength is 6: [diskIO]
 * If the maxQueueLength is 7: [diskIO]
 * If the maxQueueLength is 8: [diskIO]
 *
 * The default maxQueueLength is 0 (no maximum, so [detail box] won't be truncated).
 *
 * If you want every [detail box] to have the exact same width,
 * set both minQueueLength and maxQueueLength to the same value.
 **/
@property (assign) NSUInteger maxQueueLength;

/**
 * Sometimes queue labels have long names like "com.apple.main-queue",
 * but you'd prefer something shorter like simply "main".
 *
 * This method allows you to set such preferred replacements.
 * The above example is set by default.
 *
 * To remove/undo a previous replacement, invoke this method with nil for the 'shortLabel' parameter.
 **/
- (NSString *)replacementStringForQueueLabel:(NSString *)longLabel;
- (void)setReplacementString:(NSString *)shortLabel forQueueLabel:(NSString *)longLabel;

@end

#import <libkern/OSAtomic.h>

/**
 * Welcome to Cocoa Lumberjack!
 *
 * The project page has a wealth of documentation if you have any questions.
 * https://github.com/robbiehanson/CocoaLumberjack
 *
 * If you're new to the project you may wish to read the "Getting Started" wiki.
 * https://github.com/robbiehanson/CocoaLumberjack/wiki/GettingStarted
 **/

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static NSString * _processName;

@implementation NBULogFormatter
{
	int32_t atomicLoggerCount;
	NSDateFormatter *threadUnsafeDateFormatter; // Use [self stringFromDate]
	
	OSSpinLock lock;
	
	NSUInteger _minQueueLength;           // _prefix == Only access via atomic property
	NSUInteger _maxQueueLength;           // _prefix == Only access via atomic property
	NSMutableDictionary *_replacements;   // _prefix == Only access from within spinlock
}

+ (void)initialize
{
    _processName = [[NSProcessInfo processInfo] processName];
}

- (id)init
{
	if ((self = [super init]))
	{
		dateFormatString = @"yyyy-MM-dd HH:mm:ss:SSS";
		
		atomicLoggerCount = 0;
		threadUnsafeDateFormatter = nil;
		
		_minQueueLength = 0;
		_maxQueueLength = 0;
		_replacements = [[NSMutableDictionary alloc] init];
		
		// Set default replacements:
		
		[_replacements setObject:@"main" forKey:@"com.apple.main-thread"];
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize minQueueLength = _minQueueLength;
@synthesize maxQueueLength = _maxQueueLength;

- (NSString *)replacementStringForQueueLabel:(NSString *)longLabel
{
	NSString *result = nil;
	
	OSSpinLockLock(&lock);
	{
		result = [_replacements objectForKey:longLabel];
	}
	OSSpinLockUnlock(&lock);
	
	return result;
}

- (void)setReplacementString:(NSString *)shortLabel forQueueLabel:(NSString *)longLabel
{
	OSSpinLockLock(&lock);
	{
		if (shortLabel)
			[_replacements setObject:shortLabel forKey:longLabel];
		else
			[_replacements removeObjectForKey:longLabel];
	}
	OSSpinLockUnlock(&lock);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogFormatter
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)stringFromDate:(NSDate *)date
{
	int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
	
	if (loggerCount <= 1)
	{
		// Single-threaded mode.
		
		if (threadUnsafeDateFormatter == nil)
		{
			threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
			[threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
			[threadUnsafeDateFormatter setDateFormat:dateFormatString];
		}
		
		return [threadUnsafeDateFormatter stringFromDate:date];
	}
	else
	{
		// Multi-threaded mode.
		// NSDateFormatter is NOT thread-safe.
		
		NSString *key = @"DispatchQueueLogFormatter_NSDateFormatter";
		
		NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
		NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
		
		if (dateFormatter == nil)
		{
			dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
			[dateFormatter setDateFormat:dateFormatString];
			
			[threadDictionary setObject:dateFormatter forKey:key];
		}
		
		return [dateFormatter stringFromDate:date];
	}
}

- (NSString *)queueThreadLabelForLogMessage:(DDLogMessage *)logMessage
{
	// As per the DDLogFormatter contract, this method is always invoked on the same thread/dispatch_queue
	
	NSUInteger minQueueLength = self.minQueueLength;
	NSUInteger maxQueueLength = self.maxQueueLength;
	
	// Get the name of the queue, thread, or machID (whichever we are to use).
	
	NSString *queueThreadLabel = nil;
	
	BOOL useQueueLabel = YES;
	BOOL useThreadName = NO;
	
	if (logMessage->queueLabel)
	{
		// If you manually create a thread, it's dispatch_queue will have one of the thread names below.
		// Since all such threads have the same name, we'd prefer to use the threadName or the machThreadID.
		
		char *names[] = { "com.apple.root.low-priority",
            "com.apple.root.default-priority",
            "com.apple.root.high-priority",
            "com.apple.root.low-overcommit-priority",
            "com.apple.root.default-overcommit-priority",
            "com.apple.root.high-overcommit-priority"     };
		
		int length = sizeof(names) / sizeof(char *);
		
		int i;
		for (i = 0; i < length; i++)
		{
			if (strcmp(logMessage->queueLabel, names[i]) == 0)
			{
				useQueueLabel = NO;
				useThreadName = [logMessage->threadName length] > 0;
				break;
			}
		}
	}
	else
	{
		useQueueLabel = NO;
		useThreadName = [logMessage->threadName length] > 0;
	}
	
	if (useQueueLabel || useThreadName)
	{
		NSString *fullLabel;
		NSString *abrvLabel;
		
		if (useQueueLabel)
			fullLabel = @(logMessage->queueLabel);
		else
			fullLabel = logMessage->threadName;
		
		OSSpinLockLock(&lock);
		{
			abrvLabel = [_replacements objectForKey:fullLabel];
		}
		OSSpinLockUnlock(&lock);
		
		if (abrvLabel)
			queueThreadLabel = abrvLabel;
		else
			queueThreadLabel = fullLabel;
	}
	else
	{
		queueThreadLabel = [NSString stringWithFormat:@"%x", logMessage->machThreadID];
	}
	
	// Now use the thread label in the output
	
	NSUInteger labelLength = [queueThreadLabel length];
	
	// labelLength > maxQueueLength : truncate
	// labelLength < minQueueLength : padding
	//                              : exact
	
	if ((maxQueueLength > 0) && (labelLength > maxQueueLength))
	{
		// Truncate
		
		return [queueThreadLabel substringToIndex:maxQueueLength];
	}
	else if (labelLength < minQueueLength)
	{
		// Padding
		
		NSUInteger numSpaces = minQueueLength - labelLength;
		
		char spaces[numSpaces + 1];
		memset(spaces, ' ', numSpaces);
		spaces[numSpaces] = '\0';
		
		return [NSString stringWithFormat:@"%@%s", queueThreadLabel, spaces];
	}
	else
	{
		// Exact
		
		return queueThreadLabel;
	}
}

//- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
//{
//	NSString *timestamp = [self stringFromDate:(logMessage->timestamp)];
//	NSString *queueThreadLabel = [self queueThreadLabelForLogMessage:logMessage];
//
//	return [NSString stringWithFormat:@"%@ [%@] %@", timestamp, queueThreadLabel, logMessage->logMsg];
//}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    // One-charecter log level
    NSString * logLevel;
    switch (logMessage->logFlag)
    {
        case LOG_FLAG_ERROR : logLevel = @"E"; break;
        case LOG_FLAG_WARN  : logLevel = @"W"; break;
        case LOG_FLAG_INFO  : logLevel = @"I"; break;
        default             : logLevel = @"V"; break;
    }
    
    return [NSString stringWithFormat:@"%@ %@[%@] %@ %@:%d %@",
            [self stringFromDate:(logMessage->timestamp)],
            _processName,
            [self queueThreadLabelForLogMessage:logMessage],
            logLevel,
            logMessage.fileName,
            logMessage->lineNumber,
            logMessage->logMsg];
}

- (void)didAddToLogger:(id <DDLogger>)logger
{
	OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger
{
	OSAtomicDecrement32(&atomicLoggerCount);
}

@end