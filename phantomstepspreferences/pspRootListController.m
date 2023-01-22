#import <Foundation/Foundation.h>
#import "pspRootListController.h"

@implementation pspRootListController

- (NSArray *)specifiers {
  if (!_specifiers) {
    _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
  }

  return _specifiers;
}

// ----- dismiss keyboard -----
// - dissmiss on scroll
- (void)loadView {
  [super loadView];
  ((UITableView *)[self table]).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

// - dismiss on tab outside text field
- (void)viewDidLoad {
  [super viewDidLoad];

  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];

  [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
  [self.view endEditing:YES];
}

// - dismiss on press return key
-(void)_returnKeyPressed:(id)arg1 {
  [self.view endEditing:YES];
}

// ---

- (void)generateStepsATOnce {
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"成功 / Success"
                                message:@"假的啦！还没实现功能呢！"
                                preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
    handler:^(UIAlertAction * action) {}];

  [alert addAction:defaultAction];
  [self presentViewController:alert animated:YES completion:nil];
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
