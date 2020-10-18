//
// --------------------------------------------------------------------------
// ModifierManager.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2020
// Licensed under MIT
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ModifierManager : NSObject

+ (NSDictionary *)getActiveModifiersForDevice:(NSNumber *)devID filterButton:(NSNumber * __nullable)filteredButton;

+ (void)handleButtonModifiersHaveChanged;

@end

NS_ASSUME_NONNULL_END