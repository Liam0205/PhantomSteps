#import "pspRootListController.h"
#import <Foundation/Foundation.h>
#import <HealthKit/HKDevice.h>
#import <HealthKit/HKHealthStore.h>
#import <HealthKit/HKObjectType.h>
#import <HealthKit/HKQuantity.h>
#import <HealthKit/HKQuantitySample.h>
#import <HealthKit/HKSampleQuery.h>
#import <HealthKit/HKSource.h>
#import <HealthKit/HKSourceQuery.h>
#import <HealthKit/HKSourceRevision.h>
#import <HealthKit/HKUnit.h>

#define PreferencesFilePath                                      \
  [NSString stringWithFormat:@"/var/mobile/Library/Preferences/" \
                             @"page.liam.phantomstepspreferences.plist"]

static NSDictionary* preferences;
static NSString* error_msg;

void load_prefs_to_dict() {
  error_msg = @"";
  preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
  if (!preferences) {
    error_msg = [NSString stringWithFormat:@"ERROR: Failed to load Preference File!"];
  }
}

int fetch_int(NSString* key, int d) {
  if ([preferences objectForKey:key] == nil) {
    error_msg =
        [NSString stringWithFormat:@"%@\nWARNING: Failed to find key[%@] in Preferences, default[%d] used.",
                                   error_msg, key, d];
    return d;
  } else {
    return [[preferences valueForKey:key] intValue];
  }
}

NSDate* maxDate(NSDate* lhs, NSDate* rhs) {
  if (!lhs) {
    return rhs;
  } else if (!rhs) {
    return lhs;
  } else {
    if ([lhs compare:rhs] == NSOrderedDescending) {
      return lhs;
    } else {
      return rhs;
    }
  }
}

NSDate* minDate(NSDate* lhs, NSDate* rhs) {
  if (!lhs) {
    return rhs;
  } else if (!rhs) {
    return lhs;
  } else {
    if ([lhs compare:rhs] == NSOrderedAscending) {
      return lhs;
    } else {
      return rhs;
    }
  }
}

@implementation pspRootListController

- (NSArray*)specifiers {
  if (!_specifiers) {
    _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
  }

  return _specifiers;
}

- (void)alertTitle:(NSString*)title Message:(NSString*)message {
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction* action) {
                                                          return;
                                                        }];

  [alert addAction:defaultAction];
  [self presentViewController:alert animated:YES completion:nil];
}

// ----- dismiss keyboard -----
// - dissmiss on scroll
- (void)loadView {
  [super loadView];
  ((UITableView*)[self table]).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

// ----- actions
- (void)checkSettings {
  load_prefs_to_dict();

  int steps = fetch_int(@"psp_once_input_steps", 1400);
  double distance = steps * 0.72;

  NSString* title;
  NSString* message;

  if ([error_msg rangeOfString:@"ERROR"].location != NSNotFound) {
    title = @"Failed with ERROR";
    message = error_msg;
  } else if ([error_msg rangeOfString:@"WARNING"].location != NSNotFound) {
    title = @"Success with WARNING";
    message = error_msg;
  } else {
    title = @"Success";
    message = [NSString stringWithFormat:@"steps: %d, distance: %.2lf", steps, distance];
  }

  [self alertTitle:title Message:message];
}

- (void)generateStepsATOnce {
  load_prefs_to_dict();

  if (![HKHealthStore isHealthDataAvailable]) {
    [self alertTitle:@"Phantom Steps"
             Message:[NSString stringWithFormat:@"执行失败，健康数据不可用。/ "
                                                @"The execution is failed. Health data is not available."]];
    return;
  }
  int input_steps = fetch_int(@"psp_once_input_steps", 2800);

  // step data
  HKQuantityType* step_qtype = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
  HKQuantity* step_quantity = [HKQuantity quantityWithUnit:[HKUnit unitFromString:@"count"]
                                               doubleValue:input_steps];

  // distance data
  HKQuantityType* dist_qtype =
      [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
  HKQuantity* dist_quantity = [HKQuantity quantityWithUnit:[HKUnit unitFromString:@"m"]
                                               doubleValue:input_steps * 0.72];

  // sample time
  NSDate* time_end = [NSDate dateWithTimeIntervalSinceNow:-10];
  NSDate* hour_before_time_end = [time_end dateByAddingTimeInterval:-3600];
  NSDate* step_edate = [self fetchLatestSampleEndDate:step_qtype];
  NSDate* dist_edate = [self fetchLatestSampleEndDate:dist_qtype];
  NSDate* time_begin =
      minDate(time_end, maxDate(hour_before_time_end, maxDate([step_edate dateByAddingTimeInterval:1],
                                                              [dist_edate dateByAddingTimeInterval:1])));
  NSLog(@"time_end: %@, hour_before_time_end:%@, step_edate: %@, dist_edate: %@, time_begin: %@", time_end,
        hour_before_time_end, step_edate, dist_edate, time_begin);

  // sample device
  HKDevice* device = [HKDevice localDevice];

  // metadata
  NSDictionary* metadata = @{};

  // build samples
  HKQuantitySample* step_sample = [HKQuantitySample quantitySampleWithType:step_qtype
                                                                  quantity:step_quantity
                                                                 startDate:time_begin
                                                                   endDate:time_end
                                                                    device:device
                                                                  metadata:metadata];
  HKQuantitySample* dist_sample = [HKQuantitySample quantitySampleWithType:dist_qtype
                                                                  quantity:dist_quantity
                                                                 startDate:time_begin
                                                                   endDate:time_end
                                                                    device:device
                                                                  metadata:metadata];

  // callback
  // -- this callback runs in background (another thread), hence synchronization is required.
  __block bool flag = false;
  __block NSCondition* cond = [[NSCondition alloc] init];
  // -- callback shared data
  __block BOOL succ = NO;
  __block NSError* err = nil;
  void (^callback)(BOOL success, NSError* error) = ^(BOOL success, NSError* error) {
    [cond lock];
    succ = success;
    err = nil;
    flag = true;
    [cond signal];
    [cond unlock];
    return;
  };

  // do save
  HKHealthStore* store = [[HKHealthStore alloc] init];
  [store saveObjects:@[ step_sample, dist_sample ] withCompletion:callback];

  // report
  [cond lock];
  while (!flag) {
    [cond wait];
  }
  [cond unlock];
  NSString* msg;
  if (succ) {
    msg = [NSString stringWithFormat:@"执行完成，请打开「健康.app」检查是否成功写入。/ "
                                     @"The execution is complete, please open the \"Health.app\" to "
                                     @"check whether the writing is successful."];
  } else {
    msg = [NSString stringWithFormat:@"执行失败：/ "
                                     @"The execution is failed: %@",
                                     err];
  }
  [self alertTitle:@"Phantom Steps" Message:msg];
}

- (void)openBlogZH {
  NSDictionary* URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://liam.page/"]
                                     options:URLOptions
                           completionHandler:nil];
}

- (void)openBlogEN {
  NSDictionary* URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://liam.page/en/"]
                                     options:URLOptions
                           completionHandler:nil];
}

- (HKSource*)fetchSource {
  if (![HKHealthStore isHealthDataAvailable]) {
    return nil;
  }

  HKQuantityType* step_qtype = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
  NSDate* curr = [NSDate date];
  NSPredicate* last_one_day_pred =
      [HKQuery predicateForSamplesWithStartDate:[curr dateByAddingTimeInterval:-86400]
                                        endDate:curr
                                        options:HKQueryOptionNone];
  // callback, the result handler
  // -- this callback runs in background (another thread), hence synchronization is required.
  __block bool flag = false;
  __block NSCondition* cond = [[NSCondition alloc] init];
  // -- res
  __block HKSource* target;
  void (^callback)(HKSourceQuery* query, NSSet<HKSource*>* sources, NSError* error) =
      ^(HKSourceQuery* query, NSSet<HKSource*>* sources, NSError* error) {
        [cond lock];
        for (HKSource* source in sources) {
          NSString* bundleID = source.bundleIdentifier;
          if ([bundleID hasPrefix:@"com.apple.health."]) {
            target = source;
            flag = true;
            break;
          }
        }
        [cond signal];
        [cond unlock];
        return;
      };

  // source query
  HKSourceQuery* query = [[HKSourceQuery alloc] initWithSampleType:step_qtype
                                                   samplePredicate:last_one_day_pred
                                                 completionHandler:callback];
  HKHealthStore* store = [[HKHealthStore alloc] init];
  [store executeQuery:query];
  [cond lock];
  while (!flag) {
    [cond wait];
  }
  [cond unlock];
  return target;
}

- (HKSample*)fetchLatestSample:(HKSampleType*)type {
  if (![HKHealthStore isHealthDataAvailable]) {
    return nil;
  }
  // predicate
  NSDate* curr = [NSDate date];
  NSPredicate* last_one_day_pred =
      [HKQuery predicateForSamplesWithStartDate:[curr dateByAddingTimeInterval:-86400]
                                        endDate:curr
                                        options:HKQueryOptionNone];
  // sort key
  NSSortDescriptor* sort_by_time_desc = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate
                                                                      ascending:false];
  // callback, the result handler
  // -- resultsHandler runs in background (another thread), hence synchronization is required.
  __block bool flag = false;
  __block NSCondition* cond = [[NSCondition alloc] init];
  // -- callback shared data
  __block HKSample* res = nil;
  void (^callback)(HKSampleQuery* query, NSArray<__kindof HKSample*>* results, NSError* error) =
      ^(HKSampleQuery* query, NSArray<__kindof HKSample*>* results, NSError* error) {
        [cond lock];
        if (results.count > 0) {
          res = (HKSample*)[results firstObject];
        } else {
          res = nil;
        }
        flag = true;
        [cond signal];
        [cond unlock];
      };
  // sample query
  HKSampleQuery* sample_query = [[HKSampleQuery alloc] initWithSampleType:type
                                                                predicate:last_one_day_pred
                                                                    limit:(NSInteger)1
                                                          sortDescriptors:@[ sort_by_time_desc ]
                                                           resultsHandler:callback];
  HKHealthStore* store = [[HKHealthStore alloc] init];
  [store executeQuery:sample_query];

  [cond lock];
  while (!flag) {
    [cond wait];
  }
  [cond unlock];
  return res;
}

- (NSDate*)fetchLatestSampleEndDate:(HKSampleType*)type {
  HKSample* sample = [self fetchLatestSample:type];
  if (sample) {
    return sample.endDate;
  } else {
    return nil;
  }
}

- (HKSourceRevision*)fetchCorrectSourceRevision:(HKSampleType*)type {
  if (![HKHealthStore isHealthDataAvailable]) {
    return nil;
  }
  // predicate
  NSDate* curr = [NSDate date];
  NSPredicate* last_one_day_pred =
      [HKQuery predicateForSamplesWithStartDate:[curr dateByAddingTimeInterval:-86400]
                                        endDate:curr
                                        options:HKQueryOptionNone];
  // sort key
  NSSortDescriptor* sort_by_time_desc = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate
                                                                      ascending:false];
  // callback, the result handler
  // -- resultsHandler runs in background (another thread), hence synchronization is required.
  __block bool flag = false;
  __block NSCondition* cond = [[NSCondition alloc] init];
  // -- callback shared data
  __block HKSourceRevision* res = nil;
  void (^callback)(HKSampleQuery* query, NSArray<__kindof HKSample*>* results, NSError* error) =
      ^(HKSampleQuery* query, NSArray<__kindof HKSample*>* results, NSError* error) {
        [cond lock];
        for (HKSample* sample in results) {
          if ([sample.sourceRevision.source.bundleIdentifier hasPrefix:@"com.apple.health."]) {
            res = sample.sourceRevision;
            break;
          }
        }
        flag = true;
        [cond signal];
        [cond unlock];
      };
  // sample query
  HKSampleQuery* sample_query = [[HKSampleQuery alloc] initWithSampleType:type
                                                                predicate:last_one_day_pred
                                                                    limit:(NSInteger)1000
                                                          sortDescriptors:@[ sort_by_time_desc ]
                                                           resultsHandler:callback];
  HKHealthStore* store = [[HKHealthStore alloc] init];
  [store executeQuery:sample_query];

  [cond lock];
  while (!flag) {
    [cond wait];
  }
  [cond unlock];
  return res;
}

- (void)do_debug {
  HKSourceRevision* sourceRevision =
      [self fetchCorrectSourceRevision:[HKQuantityType
                                           quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]];
  NSLog(@"%@", sourceRevision);
}
@end
