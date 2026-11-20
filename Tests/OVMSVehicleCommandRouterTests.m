#import <Foundation/Foundation.h>
#import "OVMSVehicleCommandRouter.h"

static void require(BOOL condition, NSString *message) { if (!condition) { NSLog(@"FAIL: %@", message); exit(1); } }

int main(int argc, const char *argv[])
{
  @autoreleasepool {
    require(argc == 2, @"fixture path is required");
    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];
    NSArray *fixtures = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    require(fixtures.count > 0, @"fixtures must load");
    for (NSDictionary *fixture in fixtures) {
      NSString *firmware = fixture[@"firmware"];
      require([OVMSVehicleCommandRouter supportsShellVehicleCommandsForFirmware:firmware] == [fixture[@"shell"] boolValue], @"shell capability mismatch");
      require([[OVMSVehicleCommandRouter startChargeCommandForFirmware:firmware] isEqualToString:fixture[@"start"]], @"start route mismatch");
      require([[OVMSVehicleCommandRouter stopChargeCommandForFirmware:firmware] isEqualToString:fixture[@"stop"]], @"stop route mismatch");
      require([[OVMSVehicleCommandRouter climateCommandForEnabled:YES firmware:firmware] isEqualToString:fixture[@"climateOn"]], @"climate on route mismatch");
      require([[OVMSVehicleCommandRouter climateCommandForEnabled:NO firmware:firmware] isEqualToString:fixture[@"climateOff"]], @"climate off route mismatch");
    }
    NSLog(@"PASS: %lu command routing fixtures", (unsigned long)fixtures.count);
  }
  return 0;
}
