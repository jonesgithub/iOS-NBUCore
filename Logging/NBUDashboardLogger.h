//
//  NBUDashboardLogger.h
//  NBUCore
//
//  Created by 利辺羅 on 2012/12/17.
//
//

/**
 Logger to display log messages on device.
 
 - Compatible with NBULog and DDLog.
 - Supports colors for log levels.
 - Expands and collapses text.
 
 To enable simply add this to your `didFinishLaunchingWithOptions` method:
 
    if (!AmIBeingDebugged())
    {
        [DDLog addLogger:[NBUDashboardLogger sharedInstance]];
    }
 
 @warning Only for debug and testing configurations.
 */
@interface NBUDashboardLogger : DDAbstractLogger

/// @name Getting the Logger

/// Get the shared logger instance.
+ (NBUDashboardLogger *)sharedInstance;

/// @name Outlets

/// The UITableView used to display log messages.
@property (assign, nonatomic) IBOutlet UITableView * tableView;

/// Maximize/minimize the log dashboard.
/// @param sender The sender object.
- (IBAction)toggle:(id)sender;

@end
