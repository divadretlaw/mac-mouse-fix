//
//  Mouse_Remap.h
//  Mouse Remap
//
//  Created by Noah Nübling on 09.08.18.
//  Copyright © 2018 Noah Nuebling Enterprises Ltd. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface Mouse_Remap : NSPreferencePane

- (void)mainViewDidLoad;
@property (weak) IBOutlet NSButton *checkbox;

@end