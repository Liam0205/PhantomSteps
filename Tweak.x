#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSUserDefaults+Private.h>
#import "phantomstepspreferences/pspRootListController.h"

static NSString *nsNotificationString = @"page.liam.phantom_steps/preferences.changed";

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name,
                                 const void *object, CFDictionaryRef userInfo) {
  // load_prefs_to_dict();
}

%ctor {
  // Set variables on start up
  // load_prefs_to_dict();

  // Register for 'PostNotification' notifications
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback,
                                  (CFStringRef)nsNotificationString, NULL,
                                  CFNotificationSuspensionBehaviorCoalesce);

  // Add any personal initializations
}
