#import <Foundation/Foundation.h>
#import "pspRootListController.h"

@implementation pspRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

@end
