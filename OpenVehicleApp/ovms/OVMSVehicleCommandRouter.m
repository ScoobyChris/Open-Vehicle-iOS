#import "OVMSVehicleCommandRouter.h"

@implementation OVMSVehicleCommandRouter

+ (BOOL)supportsShellVehicleCommandsForFirmware:(NSString *)firmware
{
  if (firmware.length == 0) return NO;

  NSScanner *scanner = [NSScanner scannerWithString:firmware];
  [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
  NSInteger major = 0;
  return [scanner scanInteger:&major] && major >= 3;
}

+ (NSString *)startChargeCommandForFirmware:(NSString *)firmware
{
  return [self supportsShellVehicleCommandsForFirmware:firmware] ? @"7,charge start" : @"11";
}

+ (NSString *)stopChargeCommandForFirmware:(NSString *)firmware
{
  return [self supportsShellVehicleCommandsForFirmware:firmware] ? @"7,charge stop" : @"12";
}

+ (NSString *)climateCommandForEnabled:(BOOL)enabled firmware:(NSString *)firmware
{
  if ([self supportsShellVehicleCommandsForFirmware:firmware])
    return enabled ? @"7,climatecontrol on" : @"7,climatecontrol off";
  return enabled ? @"26,1" : @"26,0";
}

@end
