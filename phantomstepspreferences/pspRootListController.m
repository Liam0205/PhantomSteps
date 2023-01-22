#import "pspRootListController.h"
#import <Foundation/Foundation.h>

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
        [NSString stringWithFormat:@"%s\nWARNING: Failed to find key[%s] in Preferences, default[%d] used.",
                                   [error_msg UTF8String], [key UTF8String], d];
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

// - dismiss on tab outside text field
// - (void)viewDidLoad {
//   [super viewDidLoad];

//   UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
//   initWithTarget:self action:@selector(dismissKeyboard)];

//   [self.view addGestureRecognizer:tap];
// }

// -(void)dismissKeyboard {
//   [self.view endEditing:YES];
// }

// - dismiss on press return key
// -(void)_returnKeyPressed:(id)arg1 {
//   [self.view endEditing:YES];
// }

// ----- actions
- (void)generateStepsATOnce {
  load_prefs_to_dict();

  int steps = fetch_int(@"psp_once_input_steps", 1400);
  int distance = fetch_int(@"psp_once_input_distance", 1000);

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
    message = [NSString stringWithFormat:@"steps: %d, distance: %d", steps, distance];
  }

  UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction* action){
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
@end
