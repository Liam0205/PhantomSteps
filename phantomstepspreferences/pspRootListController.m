#import "pspRootListController.h"
#import <Foundation/Foundation.h>
#import <HealthKit/HKDevice.h>
#import <HealthKit/HKHealthStore.h>
#import <HealthKit/HKObjectType.h>
#import <HealthKit/HKQuantity.h>
#import <HealthKit/HKQuantitySample.h>
#import <HealthKit/HKSampleQuery.h>
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

@implementation pspRootListController

- (NSArray*)specifiers {
  if (!_specifiers) {
    _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
  }

  return _specifiers;
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

- (void)generateStepsATOnce {
  load_prefs_to_dict();

  if ([HKHealthStore isHealthDataAvailable]) {
    int input_steps = fetch_int(@"psp_once_input_steps", 2800);
    HKQuantityType* step_qtype = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    HKQuantity* step_quantity = [HKQuantity quantityWithUnit:[HKUnit unitFromString:@"count"]
                                                 doubleValue:input_steps];
    HKQuantityType* dist_qtype =
        [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    HKQuantity* dist_quantity = [HKQuantity quantityWithUnit:[HKUnit unitFromString:@"m"]
                                                 doubleValue:input_steps * 0.72];
    NSDate* time_begin = [NSDate dateWithTimeIntervalSinceNow:-3610];
    NSDate* time_end = [NSDate dateWithTimeIntervalSinceNow:-10];
    HKDevice* device = [HKDevice localDevice];
    NSDictionary* metadata = @{};  // TODO(Liam): Fullfill metadata to do a better mock.
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

    HKHealthStore* store = [[HKHealthStore alloc] init];
    [store saveObjects:@[ step_sample, dist_sample ]
        withCompletion:^(BOOL success, NSError* error) {
          // TODO(Liam): write this callback.
          return;
        }];
  }
  UIAlertController* alert = [UIAlertController
      alertControllerWithTitle:@"Phantom Steps"
                       message:[NSString stringWithFormat:
                                             @"执行完成，请打开「健康.app」检查是否成功写入。/ "
                                             @"The execution is complete, please open the \"Health.app\" to "
                                             @"check whether the writing is successful."]
                preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction* action) {
                                                          return;
                                                        }];

  [alert addAction:defaultAction];
  [self presentViewController:alert animated:YES completion:nil];
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

- (NSDate*)fetchLatestSampleEndDate:(HKSampleType*)qtype {
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
  __block NSDate* res = nil;
  __block NSCondition* cond = [[NSCondition alloc] init];
  void (^callback)(HKSampleQuery* query, NSArray<__kindof HKSample*>* results, NSError* error) =
      ^(HKSampleQuery* query, NSArray<__kindof HKSample*>* results, NSError* error) {
        [cond lock];
        if (results.count > 0) {
          HKQuantitySample* sample = (HKQuantitySample*)[results firstObject];
          res = sample.endDate;
        } else {
          res = nil;
        }
        flag = true;
        [cond signal];
        [cond unlock];
      };
  // sample query
  HKSampleQuery* sample_query = [[HKSampleQuery alloc] initWithSampleType:qtype
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

- (void)do_debug {
  load_prefs_to_dict();
  HKQuantityType* step_qtype = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
  NSDate* step_edate = [self fetchLatestSampleEndDate:step_qtype];
  HKQuantityType* dist_qtype =
      [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
  NSDate* dist_edate = [self fetchLatestSampleEndDate:dist_qtype];
  NSLog(@"OUTSIDE RESULT_HANDLER, step: %@", step_edate);
  NSLog(@"OUTSIDE RESULT_HANDLER, dist: %@", dist_edate);
  NSLog(@"OUTSIDE RESULT_HANDLER, max: %@", MAX(step_edate, dist_edate));
}
@end
