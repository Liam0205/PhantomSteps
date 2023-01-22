#import <Foundation/Foundation.h>
#import "pspRootListController.h"

@implementation pspRootListController

- (NSArray *)specifiers {
  if (!_specifiers) {
    _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
  }

  return _specifiers;
}

- (void)openBlogZH {
  NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
  [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"https://liam.page/"] options: URLOptions completionHandler: nil];
}

- (void)openBlogEN {
  NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
  [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"https://liam.page/en/"] options: URLOptions completionHandler: nil];
}
@end
