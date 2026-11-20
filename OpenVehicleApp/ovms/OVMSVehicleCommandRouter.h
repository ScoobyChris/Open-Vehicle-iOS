#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OVMSVehicleCommandRouter : NSObject

+ (BOOL)supportsShellVehicleCommandsForFirmware:(nullable NSString *)firmware;
+ (NSString *)startChargeCommandForFirmware:(nullable NSString *)firmware;
+ (NSString *)stopChargeCommandForFirmware:(nullable NSString *)firmware;
+ (NSString *)climateCommandForEnabled:(BOOL)enabled firmware:(nullable NSString *)firmware;

@end

NS_ASSUME_NONNULL_END
