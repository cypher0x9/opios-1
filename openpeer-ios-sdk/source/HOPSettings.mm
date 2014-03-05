/*
 
 Copyright (c) 2014, SMB Phone Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */

#import "HOPSettings_Internal.h"
#import "OpenPeerSettingsDelegate.h"
#import <zsLib/Log.h>


ZS_DECLARE_SUBSYSTEM(openpeer_sdk)

@interface HOPSettings ()

@property (nonatomic, strong) NSString* authorizedApplicationId;
@property (nonatomic, strong) NSMutableDictionary* mappingDictionary;
@property (nonatomic, strong) NSDictionary* currentSettingsDictionary;

- (id) initSingleton;
@end
@implementation HOPSettings

+ (id)sharedSettings
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initSingleton];
    });
    return _sharedObject;
}

- (id) initSingleton
{
    self = [super init];
    if (self)
    {
        NSString *filePath = nil;
        NSBundle* bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"OpenPeerDataModel" ofType:@"bundle"]];
        if (bundle)
            filePath = [bundle pathForResource:@"KeyMappings" ofType:@"plist"];
        if ([filePath length] > 0)
        {
            self.mappingDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
        }
        else
        {
            self.mappingDictionary = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}
- (void) setupWithDelegate:(id<HOPSettingsDelegate>) inDelegate
{
    openPeerSettingsDelegatePtr = OpenPeerSettingsDelegate::create(inDelegate);
    ISettings::setup(openPeerSettingsDelegatePtr);
}

- (void) setup
{
    openPeerSettingsDelegatePtr = OpenPeerSettingsDelegate::create(nil);
    ISettings::setup(openPeerSettingsDelegatePtr);
}
- (BOOL) applySettings:(NSString*)jsonSettings
{
    BOOL ret = NO;
    if ([jsonSettings length] > 0)
    {
        ret = ISettings::apply([jsonSettings UTF8String]);
    }
    else
    {
        ZS_LOG_ERROR(Debug, [self log:@"Passed empty JSON file."]);
    }
    
    return ret;
}

- (void) applyDefaults
{
    ISettings::applyDefaults();
}


- (void) deleteLocalDelegate
{
    openPeerSettingsDelegatePtr.reset();
}


- (void) storeSettingsFromDictionary:(NSDictionary*) inDictionary
{
    if ([inDictionary count] > 0)
    {
        Class boolClass = [[NSNumber numberWithBool:YES] class];
        Class floatClass = [[NSNumber numberWithFloat:0] class];
        Class doubleClass = [[NSNumber numberWithDouble:0] class];
        Class integerClass = [[NSNumber numberWithInteger:0] class];
        Class unsignedIntegerClass = [[NSNumber numberWithUnsignedInteger:0] class];
        
        for (NSString* tempKey in [inDictionary allKeys])
        {
            id value = [inDictionary objectForKey:tempKey];
            
            NSString* key = [[self.mappingDictionary objectForKey:tempKey] length] == 0 ? tempKey : [self.mappingDictionary objectForKey:tempKey];

            if ([value isKindOfClass:[NSDictionary class]])
            {
                [self storeSettingsFromDictionary:value];
            }
            else if ([value isKindOfClass:boolClass])
            {
                ((OpenPeerSettingsDelegate*)openPeerSettingsDelegatePtr.get())->setBool([key UTF8String], ((NSNumber*)value).boolValue);
                //[[NSUserDefaults standardUserDefaults] setBool:((NSNumber*)value).boolValue forKey:key];
            }
            else if ([value isKindOfClass:floatClass])
            {
                ((OpenPeerSettingsDelegate*)openPeerSettingsDelegatePtr.get())->setFloat([key UTF8String], ((NSNumber*)value).floatValue);
                //[[NSUserDefaults standardUserDefaults] setFloat:((NSNumber*)value).floatValue forKey:key];
            }
            else if ([value isKindOfClass:doubleClass])
            {
                ((OpenPeerSettingsDelegate*)openPeerSettingsDelegatePtr.get())->setDouble([key UTF8String], ((NSNumber*)value).doubleValue);
                //[[NSUserDefaults standardUserDefaults] setDouble:((NSNumber*)value).doubleValue forKey:key];
            }
            else if ([value isKindOfClass:integerClass])
            {
                ((OpenPeerSettingsDelegate*)openPeerSettingsDelegatePtr.get())->setInt([key UTF8String], ((NSNumber*)value).integerValue);
                //[[NSUserDefaults standardUserDefaults] setInteger:((NSNumber*)value).integerValue forKey:key];
            }
            else if ([value isKindOfClass:unsignedIntegerClass])
            {
                ((OpenPeerSettingsDelegate*)openPeerSettingsDelegatePtr.get())->setUInt([key UTF8String], ((NSNumber*)value).integerValue);
                //[[NSUserDefaults standardUserDefaults] setInteger:((NSNumber*)value).integerValue forKey:key];
            }
            else if ([value isKindOfClass:[NSNumber class]])
            {
                ((OpenPeerSettingsDelegate*)openPeerSettingsDelegatePtr.get())->setInt([key UTF8String], ((NSNumber*)value).integerValue);
                //[[NSUserDefaults standardUserDefaults] setInteger:((NSNumber*)value).intValue forKey:key];
            }
            else
            {
                ((OpenPeerSettingsDelegate*)openPeerSettingsDelegatePtr.get())->setString([key UTF8String], [value UTF8String]);
                //[[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
            }
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void) storeSettingsFromPath:(NSString*) path
{
    NSDictionary* customerSpecificDict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    [self storeSettingsFromDictionary:customerSpecificDict];
}

- (String) log:(NSString*) message
{
    return String("HOPSettings: ") + [message UTF8String];
}

- (void) storeAuthorizedApplicationId:(NSString*) inAuthorizedApplicationId
{
    @synchronized(self)
    {
        self.authorizedApplicationId = inAuthorizedApplicationId;
        [[NSUserDefaults standardUserDefaults] setObject:inAuthorizedApplicationId forKey:@"openpeer/calculated/authorizated-application-id"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
- (NSString*) getAuthorizedApplicationId
{
    @synchronized(self)
    {
        if ([self.authorizedApplicationId length] == 0)
            self.authorizedApplicationId = [[NSUserDefaults standardUserDefaults] objectForKey:@"openpeer/calculated/authorizated-application-id"];
    }
    return self.authorizedApplicationId;
}

- (void) storeCalculatedSettingObject:(NSString*) setting key:(NSString*) key
{
    ((OpenPeerSettingsDelegate*)openPeerSettingsDelegatePtr.get())->addSettingWithKey(setting,key);
}

- (NSString*) getCoreKeyForAppKey:(NSString*) key
{
    NSString* ret = [self.mappingDictionary objectForKey:key];
    
    if ([ret length] == 0)
        ret = key;
    
    return ret;
}
- (NSDictionary*) getCurrentSettingsDictionary
{
    return ((OpenPeerSettingsDelegate*)openPeerSettingsDelegatePtr.get())->getCurrentSettingsDictionary();
}
@end