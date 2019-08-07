

// implement checkbox functionality, setup AddingField mouse tracking and other minor stuff



#import <PreferencePanes/PreferencePanes.h>
#import <ServiceManagement/SMLoginItem.h>
#import "Mouse_Remap.h"

@implementation Mouse_Remap


- (void)mainViewDidLoad {
    NSLog(@"PREF PANEEE");
    
    //setup
    
    // Checkbox
    
    if ([self helperIsActive]) {
        [_checkbox setState: 1];
    } else {
        [_checkbox setState: 0];
    }
    
}

- (IBAction)enableMouseRemap:(id)sender {
    BOOL checkboxState = [sender state];
    [self enableHelperAsUserAgent: checkboxState];
}


/* registering/unregistering the helper as a User Agent with launchd - also launches/terminates helper */
- (void)enableHelperAsUserAgent: (BOOL) enable {

    
    // repair config file if checkbox state is changed
    [self repairUserAgentConfigFile];

    

    /* preparing strings for NSTask and then construct(we'll use NSTask for loading/unloading the helper as a User Agent) */
    
    
    
    
    /* path for the executable of the launchctl command-line-tool (which can interface with launchd) */
    NSString *launchctlPath = @"/bin/launchctl";
    
    /* preparing arguments for the command-line-tool */
    
    // path to user library
    NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if ([libraryPaths count] == 1) {
        // argument: path to launch-agent-config-file
        NSString *launchAgentPlistPath = [[libraryPaths objectAtIndex:0] stringByAppendingPathComponent: @"LaunchAgents/mouse.remap.helper.plist"];
        
        // if macOS version 10.13+
        if (@available(macOS 10.13, *)) {
            // argument: specifies that the target domain is the current users "gui" domain
            NSString *GUIDomainArgument = [NSString stringWithFormat:@"gui/%d", geteuid()];
            // argument: specifies whether we want to load/unload the helper app
            NSString *OnOffArgument = (enable) ? @"bootstrap": @"bootout";
            // convert launchctlPath to URL
            NSURL *launchctlURL = [NSURL fileURLWithPath: launchctlPath];
            
            //NSLog(@"arguments: %@ %@ %@", OnOffArgument, GUIDomainArgument, launchAgentPlistPath);
            
            // start the cmd line tool which can enable/disable the helper
            [NSTask launchedTaskWithExecutableURL: launchctlURL arguments:@[OnOffArgument, GUIDomainArgument, launchAgentPlistPath] error: nil terminationHandler: nil];
        } else {
            // Fallback on earlier versions
            NSString *OnOffArgumentOld = (enable) ? @"load": @"unload";
            [NSTask launchedTaskWithLaunchPath: launchctlPath arguments: @[OnOffArgumentOld, launchAgentPlistPath] ];
        }
    }
    else {
        NSLog(@"To this program, it looks like the number of user libraries != 1. Your computer is weird...");
    }
}

- (void) repairUserAgentConfigFile {
    @autoreleasepool {
        
        NSLog(@"repairing User Agent Config File");
        // what this does:
        
        // get path of executable of helper app based on path of bundle of this class (prefpane bundle)
        // check if the "User/Library/LaunchAgents/mouse.remap.helper.plist" UserAgent Config file exists, if the Launch Agents Folder exists, and if the exectuable path within the plist file is correct
        // if not:
        // create correct file based on "default_mouse.remap.helper.plist" and helperExecutablePath
        // write correct file to "User/Library/LaunchAgents"
        
        // get helper executable path
        NSBundle *prefPaneBundle = [NSBundle bundleForClass: [Mouse_Remap class]];
        NSString *prefPaneBundlePath = [prefPaneBundle bundlePath];
        NSString *helperExecutablePath = [prefPaneBundlePath stringByAppendingPathComponent: @"Contents/Library/LoginItems/Mouse Remap Helper.app/Contents/MacOS/Mouse Remap Helper"];
        
        // get User Library path
        NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        if ([libraryPaths count] == 1) {
            // create path to launch agent config file
            NSString *launchAgentPlistPath = [[libraryPaths objectAtIndex:0] stringByAppendingPathComponent: @"LaunchAgents/mouse.remap.helper.plist"];
            
            // check if file exists
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            BOOL LAConfigFile_exists = [fileManager fileExistsAtPath: launchAgentPlistPath isDirectory: nil];
            BOOL LAConfigFile_executablePathIsCorrect = TRUE;
            if (LAConfigFile_exists == TRUE) {
                
                // load data from launch agent config file into a dictionary
                NSData *LAConfigFile_data = [NSData dataWithContentsOfFile:launchAgentPlistPath];
                NSDictionary *LAConfigFile_dict = [NSPropertyListSerialization propertyListWithData:LAConfigFile_data options:NSPropertyListImmutable format:0 error:nil];
                
                // check if the executable path inside the config file is correct, if not, set flag to false
                
                NSString *helperExecutablePathFromFile = [LAConfigFile_dict objectForKey: @"Program"];
                
                //NSLog(@"objectForKey: %@", OBJForKey);
                //NSLog(@"helperExecutablePath: %@", helperExecutablePath);
                //NSLog(@"OBJ == Path: %d", OBJForKey isEqualToString: helperExecutablePath);
                
                if ( [helperExecutablePath isEqualToString: helperExecutablePathFromFile] == FALSE ) {
                    LAConfigFile_executablePathIsCorrect = FALSE;
                    
                }
                
                
            }
            
            NSLog(@"LAConfigFileExists %hhd, LAConfigFileIsCorrect: %hhd", LAConfigFile_exists,LAConfigFile_executablePathIsCorrect);
            // the config file doesn't exist, or the executable path within it is not correct
            if ( (LAConfigFile_exists == FALSE) || (LAConfigFile_executablePathIsCorrect == FALSE) ) {
                NSLog(@"repairing file...");
                
                //check if "User/Library/LaunchAgents" folder exists, if not, create it
                NSString *launchAgentsFolderPath = [launchAgentPlistPath stringByDeletingLastPathComponent];
                BOOL launchAgentsFolderExists = [fileManager fileExistsAtPath: launchAgentsFolderPath isDirectory: nil];
                
                if (launchAgentsFolderExists == FALSE) {
                    NSLog(@"LaunchAgentsFolder doesn't exist");
                }
                if (launchAgentsFolderExists == FALSE) {
                    NSError *error;
                    [fileManager createDirectoryAtPath:launchAgentsFolderPath withIntermediateDirectories:FALSE attributes:nil error:&error];
                    if (error == nil) {
                        NSLog(@"LaunchAgents Folder Created");
                    } else {
                        NSLog(@"Error while creating LaunchAgents Folder: %@", error);
                    }
                }
                
                
                
                
                NSError *error;
                // read contents of default_mouse.remap.helper.plist (aka default-launch-agent-config-file or defaultLAConfigFile) into a dictionary
                NSString *defaultLAConfigFile_path = [prefPaneBundle pathForResource:@"default_mouse.remap.helper" ofType:@"plist"];
                NSData *defaultLAConfigFile_data = [NSData dataWithContentsOfFile:defaultLAConfigFile_path];
                NSMutableDictionary *newLAConfigFile_dict = [NSPropertyListSerialization propertyListWithData:defaultLAConfigFile_data options:NSPropertyListMutableContainersAndLeaves format:nil error:&error];
                
                // set the executable path to the correct value
                [newLAConfigFile_dict setValue: helperExecutablePath forKey:@"Program"];
                
                // write the dict to User/Library/LaunchAgents/mouse.remap.helper.plist
                NSData *newLAConfigFile_data = [NSPropertyListSerialization dataWithPropertyList:newLAConfigFile_dict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
                NSAssert(error == nil, @"Should not have encountered an error");
                [newLAConfigFile_data writeToFile:launchAgentPlistPath atomically:YES];
                if (error != nil) {
                    NSLog(@"repairUserAgentConfigFile() -- Data Serialization Error: %@", error);
                }
            } else {
                NSLog(@"nothing to repair");
            }
        }
        else {
            // no library path found
            NSLog(@"To this program, it looks like the number of user libraries != 1. Your computer is weird...");
        }
        
        
    }
}


- (BOOL) helperIsActive {
    
    // using NSTask to ask launchd about mouse.remap.helper status
    
    NSString *launchctlPath = @"/bin/launchctl";
    NSString *listArgument = @"list";
    NSString *launchdHelperIdentifier = @"mouse.remap.helper";
    
    NSPipe * launchctlOutput;
    
    // macOS version 10.13+
    
    if (@available(macOS 10.13, *)) {
        NSURL *launchctlURL = [NSURL fileURLWithPath: launchctlPath];
        
        NSTask *task = [[NSTask alloc] init];
        [task setExecutableURL: launchctlURL];
        [task setArguments: @[listArgument, launchdHelperIdentifier] ];
        launchctlOutput = [NSPipe pipe];
        [task setStandardOutput: launchctlOutput];
        
        [task launchAndReturnError:nil];
        
    } else {
     
        // Fallback on earlier versions
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath: launchctlPath];
        [task setArguments: @[listArgument, launchdHelperIdentifier] ];
        launchctlOutput = [NSPipe pipe];
        [task setStandardOutput: launchctlOutput];
        
        [task launch];
        
    }
    
    
    NSFileHandle * launchctlOutput_fileHandle = [launchctlOutput fileHandleForReading];
    NSData * launchctlOutput_data = [launchctlOutput_fileHandle readDataToEndOfFile];
    NSString * launchctlOutput_string = [[NSString alloc] initWithData:launchctlOutput_data encoding:NSUTF8StringEncoding];
    if (
        [launchctlOutput_string rangeOfString: @"\"Label\" = \"mouse.remap.helper\";"].location != NSNotFound &&
        [launchctlOutput_string rangeOfString: @"\"LastExitStatus\" = 0;"].location != NSNotFound
        )
    {
        NSLog(@"MOUSE REMAPOR FOUNDD AND ACTIVE");
        return TRUE;
    }
    else {
        return FALSE;
    }
    
}

@end