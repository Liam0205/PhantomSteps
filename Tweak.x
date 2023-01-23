#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSUserDefaults+Private.h>
#import <HealthKit/HKHealthStore.h>
#import <HealthKit/HKObjectType.h>
#import <HealthKit/HKQuantity.h>
#import <HealthKit/HKQuantitySample.h>
#import <HealthKit/HKSampleQuery.h>
#import <HealthKit/HKSource.h>
#import <HealthKit/HKSourceRevision.h>

// static HKSourceRevision* sourceRevision__;
// static HKSource* source__;
// static NSString* name__;
// static NSString* bundleIdentifier__;
// static NSString* version__;
// static NSOperatingSystemVersion operatingSystemVersion__;
// static NSString* productType__;

// HKSourceRevision* fetchCorrectSourceRevision(HKSampleType* type) {
//   if (![HKHealthStore isHealthDataAvailable]) {
//     return nil;
//   }
//   // predicate
//   NSDate* curr = [NSDate date];
//   NSPredicate* last_one_day_pred =
//       [HKQuery predicateForSamplesWithStartDate:[curr dateByAddingTimeInterval:-86400]
//                                         endDate:curr
//                                         options:HKQueryOptionNone];
//   // sort key
//   NSSortDescriptor* sort_by_time_desc = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate
//                                                                       ascending:false];
//   // callback, the result handler
//   // -- resultsHandler runs in background (another thread), hence synchronization is required.
//   __block bool flag = false;
//   __block NSCondition* cond = [[NSCondition alloc] init];
//   // -- callback shared data
//   __block HKSourceRevision* res = nil;
//   void (^callback)(HKSampleQuery* query, NSArray<__kindof HKSample*>* results, NSError* error) =
//       ^(HKSampleQuery* query, NSArray<__kindof HKSample*>* results, NSError* error) {
//         [cond lock];
//         for (HKSample* sample in results) {
//           if ([sample.sourceRevision.source.bundleIdentifier hasPrefix:@"com.apple.health."]) {
//             res = sample.sourceRevision;
//             break;
//           }
//         }
//         flag = true;
//         [cond signal];
//         [cond unlock];
//       };
//   // sample query
//   HKSampleQuery* sample_query = [[HKSampleQuery alloc] initWithSampleType:type
//                                                                 predicate:last_one_day_pred
//                                                                     limit:(NSInteger)1000
//                                                           sortDescriptors:@[ sort_by_time_desc ]
//                                                            resultsHandler:callback];
//   HKHealthStore* store = [[HKHealthStore alloc] init];
//   [store executeQuery:sample_query];

//   [cond lock];
//   while (!flag) {
//     [cond wait];
//   }
//   [cond unlock];
//   return res;
// }

// %hook HKObject
// // -(void)_setSourceRevision:(id)arg1 {
// //   self->_sourceRevision = fetchCorrectSourceRevision([HKQuantityType
// //                                            quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]);
// // }

// -(HKSourceRevision *)sourceRevision {
//   NSLog(@"LiamHook: calling HKObject::sourceRevision.");
//   if (!sourceRevision__) {
//     return %orig;
//   } else {
//     return sourceRevision__;
//   }
// }

// -(HKSource *)source {
//   NSLog(@"LiamHook: calling HKObject::source.");
//   if (!source__) {
//     return %orig;
//   } else {
//     return source__;
//   }
// }
// %end

// %hook HKSource
// -(NSString *)name {
//   NSLog(@"LiamHook: calling HKSource::name.");
//   if (!name__) {
//     return %orig;
//   } else {
//     return name__;
//   }
// }

// -(NSString *)bundleIdentifier {
//   NSLog(@"LiamHook: calling HKSource::bundleIdentifier.");
//   if (!bundleIdentifier__) {
//     return %orig;
//   } else {
//     return bundleIdentifier__;
//   }
// }
// %end

// %hook HKSourceRevision
// -(NSString *) version {
//   NSLog(@"LiamHook: calling HKSourceRevision::version.");
//   if (!version__) {
//     return %orig;
//   } else {
//     return version__;
//   }
// }

// -(NSOperatingSystemVersion) operatingSystemVersion {
//   NSLog(@"LiamHook: calling HKSourceRevision::operatingSystemVersion.");
//   return operatingSystemVersion__;
// }

// -(NSString *) productType {
//   NSLog(@"LiamHook: calling HKSourceRevision::productType.");
//   if (!productType__) {
//     return %orig;
//   } else {
//     return productType__;
//   }
// }
// %end

%ctor {
  // sourceRevision__ = fetchCorrectSourceRevision([HKQuantityType
  //                                           quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]);
  // source__ = sourceRevision__.source;
  // name__ = source__.name;
  // bundleIdentifier__ = source__.bundleIdentifier;
  // version__ = sourceRevision__.version;
  // operatingSystemVersion__ = sourceRevision__.operatingSystemVersion;
  // productType__ = sourceRevision__.productType;
}
