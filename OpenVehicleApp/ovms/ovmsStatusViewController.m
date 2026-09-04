//
//  ovmsStatusViewController.m
//  ovms
//
//  Created by Mark Webb-Johnson on 16/11/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import "ovmsStatusViewController.h"
#import "JHNotificationManager.h"

@interface OVMSChargingViewController : UIViewController
- (void)showStartConfirmation;
- (void)showStopConfirmation;
- (void)showChargingSettings;
@end

@implementation OVMSChargingViewController

- (UILabel *)valueLabel:(NSString *)text size:(CGFloat)size
{
  UILabel *label = [[UILabel alloc] init];
  label.text = text;
  label.textColor = [UIColor whiteColor];
  label.font = [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
  label.numberOfLines = 0;
  return label;
}

- (UIView *)metricWithTitle:(NSString *)title value:(NSString *)value
{
  UIStackView *stack = [[UIStackView alloc] init];
  stack.axis = UILayoutConstraintAxisVertical;
  stack.spacing = 5.0;
  stack.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
  stack.layoutMarginsRelativeArrangement = YES;
  stack.backgroundColor = [UIColor colorWithRed:0.086 green:0.125 blue:0.196 alpha:1.0];
  stack.layer.cornerRadius = 14.0;
  UILabel *heading = [self valueLabel:title size:12.0];
  heading.textColor = [UIColor colorWithWhite:0.70 alpha:1.0];
  [stack addArrangedSubview:heading];
  [stack addArrangedSubview:[self valueLabel:value size:21.0]];
  return stack;
}

- (UIButton *)actionButton:(NSString *)title selector:(SEL)selector color:(UIColor *)color
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.backgroundColor = color;
  button.layer.cornerRadius = 12.0;
  button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
  [button.heightAnchor constraintEqualToConstant:50.0].active = YES;
  return button;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Charging";
  self.view.backgroundColor = [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:1.0];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                           target:self
                           action:@selector(close:)];

  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  UIScrollView *scroll = [[UIScrollView alloc] init];
  scroll.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:scroll];
  UIStackView *content = [[UIStackView alloc] init];
  content.translatesAutoresizingMaskIntoConstraints = NO;
  content.axis = UILayoutConstraintAxisVertical;
  content.spacing = 12.0;
  [scroll addSubview:content];
  [NSLayoutConstraint activateConstraints:@[
    [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
    [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:16.0],
    [content.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:16.0],
    [content.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-16.0],
    [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20.0]
  ]];

  UILabel *soc = [self valueLabel:[NSString stringWithFormat:@"%d%%", app.car_soc] size:52.0];
  UILabel *state = [self valueLabel:[app.car_chargestate length] ? [app.car_chargestate capitalizedString] : @"Not charging" size:18.0];
  state.textColor = [UIColor colorWithRed:0.32 green:0.84 blue:0.48 alpha:1.0];
  [content addArrangedSubview:soc];
  [content addArrangedSubview:state];

  UIStackView *electrical = [[UIStackView alloc] init];
  electrical.axis = UILayoutConstraintAxisHorizontal;
  electrical.distribution = UIStackViewDistributionFillEqually;
  electrical.spacing = 12.0;
  [electrical addArrangedSubview:[self metricWithTitle:@"VOLTAGE" value:[NSString stringWithFormat:@"%d V", app.car_linevoltage]]];
  [electrical addArrangedSubview:[self metricWithTitle:@"CURRENT" value:[NSString stringWithFormat:@"%d A", app.car_chargecurrent]]];
  [content addArrangedSubview:electrical];

  double power = (app.car_linevoltage * app.car_chargecurrent) / 1000.0;
  NSString *remaining = app.car_minutestofull > 0
    ? [NSString stringWithFormat:@"%dh %02dm", app.car_minutestofull / 60, app.car_minutestofull % 60]
    : @"—";
  UIStackView *progress = [[UIStackView alloc] init];
  progress.axis = UILayoutConstraintAxisHorizontal;
  progress.distribution = UIStackViewDistributionFillEqually;
  progress.spacing = 12.0;
  [progress addArrangedSubview:[self metricWithTitle:@"POWER" value:[NSString stringWithFormat:@"%.1f kW", power]]];
  [progress addArrangedSubview:[self metricWithTitle:@"TO FULL" value:remaining]];
  [content addArrangedSubview:progress];

  NSString *limits = [NSString stringWithFormat:@"Mode: %@\nCurrent limit: %d A\nSOC limit: %@\nRange limit: %@",
                      [app.car_chargemode length] ? [app.car_chargemode capitalizedString] : @"Standard",
                      app.car_chargelimit,
                      app.car_soclimit > 0 ? [NSString stringWithFormat:@"%d%%", app.car_soclimit] : @"Not set",
                      app.car_rangelimit > 0 ? [NSString stringWithFormat:@"%d", app.car_rangelimit] : @"Not set"];
  [content addArrangedSubview:[self metricWithTitle:@"CHARGING LIMITS" value:limits]];

  UIButton *settings = [self actionButton:@"Charging settings" selector:@selector(showChargingSettings) color:[UIColor colorWithRed:0.12 green:0.34 blue:0.62 alpha:1.0]];
  [content addArrangedSubview:settings];
  UIStackView *actions = [[UIStackView alloc] init];
  actions.axis = UILayoutConstraintAxisHorizontal;
  actions.distribution = UIStackViewDistributionFillEqually;
  actions.spacing = 12.0;
  [actions addArrangedSubview:[self actionButton:@"Start charging" selector:@selector(showStartConfirmation) color:[UIColor colorWithRed:0.12 green:0.55 blue:0.32 alpha:1.0]]];
  [actions addArrangedSubview:[self actionButton:@"Stop charging" selector:@selector(showStopConfirmation) color:[UIColor colorWithRed:0.72 green:0.20 blue:0.20 alpha:1.0]]];
  [content addArrangedSubview:actions];
}

- (void)close:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showStartConfirmation
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Start charging?" message:@"The vehicle will begin charging immediately when supported." preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Start" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [[ovmsAppDelegate myRef] commandDoStartCharge];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showStopConfirmation
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Stop charging?" message:@"Charging will stop before the configured limit is reached." preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Stop" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
    [[ovmsAppDelegate myRef] commandDoStopCharge];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showChargingSettings
{
  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Charging settings" message:@"Set the maximum charging current supported by your vehicle and supply." preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
    field.placeholder = @"Current limit (A)";
    field.keyboardType = UIKeyboardTypeNumberPad;
    field.text = [NSString stringWithFormat:@"%d", app.car_chargelimit];
  }];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSInteger current = [alert.textFields.firstObject.text integerValue];
    if (current > 0) [[ovmsAppDelegate myRef] commandDoSetChargeCurrent:(int)current];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

@end

@interface ovmsStatusViewController ()

@property (strong, nonatomic) UIScrollView *modernScrollView;
@property (strong, nonatomic) UIStackView *modernContentStack;
@property (strong, nonatomic) UIImageView *modernCarImage;
@property (strong, nonatomic) UILabel *modernConnectionLabel;
@property (strong, nonatomic) UILabel *modernSOCLabel;
@property (strong, nonatomic) UIProgressView *modernSOCProgress;
@property (strong, nonatomic) UILabel *modernChargeLabel;
@property (strong, nonatomic) UILabel *modernIdealRangeLabel;
@property (strong, nonatomic) UILabel *modernEstimatedRangeLabel;
@property (strong, nonatomic) UILabel *modernParkingLabel;
@property (assign, nonatomic) BOOL screenshotScenarioHandled;

@end

@implementation ovmsStatusViewController
@synthesize m_car_connection_image;
@synthesize m_car_connection_state;
@synthesize m_car_image;
@synthesize m_car_charge_state;
@synthesize m_car_charge_type;
@synthesize m_car_soc;
@synthesize m_battery_front;
@synthesize m_battery_front_width;
@synthesize m_car_parking_image;
@synthesize m_car_parking_state;
@synthesize m_car_range_ideal;
@synthesize m_car_range_estimated;
@synthesize m_charger_plug;
@synthesize m_charger_slider;
@synthesize m_battery_button;
@synthesize m_car_charge_message;
@synthesize m_car_charge_mode;
@synthesize m_car_charge_time;
@synthesize m_car_charge_remaining_time;
@synthesize m_car_chargekwh;
@synthesize m_battery_charging;

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  
  UIImage *stetchLeftTrack= [[UIImage imageNamed:@"Nothing.png"]
                             stretchableImageWithLeftCapWidth:30.0 topCapHeight:0.0];
  UIImage *stetchRightTrack= [[UIImage imageNamed:@"Nothing.png"]
                              stretchableImageWithLeftCapWidth:30.0 topCapHeight:0.0];
  
  // this code to set the slider ball image
  [m_charger_slider setThumbImage: [UIImage imageNamed:@"charger_button.png"] forState:UIControlStateNormal];
  [m_charger_slider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
  [m_charger_slider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];

  [self setupModernHome];
  
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;

  [self update];
}

- (UIColor *)modernBackgroundColor
{
  return [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:1.0];
}

- (UIColor *)modernCardColor
{
  return [UIColor colorWithRed:0.086 green:0.125 blue:0.196 alpha:1.0];
}

- (UIView *)modernCardWithTitle:(NSString *)title content:(UIView *)content
{
  UIView *card = [[UIView alloc] init];
  card.translatesAutoresizingMaskIntoConstraints = NO;
  card.backgroundColor = [self modernCardColor];
  card.layer.cornerRadius = 16.0;
  card.layer.masksToBounds = YES;

  UILabel *heading = [[UILabel alloc] init];
  heading.translatesAutoresizingMaskIntoConstraints = NO;
  heading.text = title;
  heading.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
  heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

  content.translatesAutoresizingMaskIntoConstraints = NO;
  [card addSubview:heading];
  [card addSubview:content];
  [NSLayoutConstraint activateConstraints:@[
    [heading.topAnchor constraintEqualToAnchor:card.topAnchor constant:16.0],
    [heading.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
    [heading.trailingAnchor constraintLessThanOrEqualToAnchor:card.trailingAnchor constant:-16.0],
    [content.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:8.0],
    [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
    [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16.0],
    [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16.0]
  ]];
  return card;
}

- (UILabel *)modernValueLabel
{
  UILabel *label = [[UILabel alloc] init];
  label.textColor = [UIColor whiteColor];
  label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
  label.adjustsFontForContentSizeCategory = YES;
  label.numberOfLines = 0;
  return label;
}

- (UIButton *)modernNavigationButton:(NSString *)title tabIndex:(NSInteger)tabIndex
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.tag = tabIndex;
  button.backgroundColor = [UIColor colorWithRed:0.10 green:0.35 blue:0.66 alpha:1.0];
  button.layer.cornerRadius = 12.0;
  button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:@selector(openPrimaryTab:) forControlEvents:UIControlEventTouchUpInside];
  [button.heightAnchor constraintEqualToConstant:48.0].active = YES;
  return button;
}

- (UIButton *)modernChargingButton
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.backgroundColor = [UIColor colorWithRed:0.12 green:0.55 blue:0.32 alpha:1.0];
  button.layer.cornerRadius = 12.0;
  button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [button setTitle:@"Charging" forState:UIControlStateNormal];
  [button addTarget:self action:@selector(openCharging) forControlEvents:UIControlEventTouchUpInside];
  [button.heightAnchor constraintEqualToConstant:52.0].active = YES;
  return button;
}

- (OVMSChargingViewController *)openCharging
{
  OVMSChargingViewController *charging = [[OVMSChargingViewController alloc] init];
  UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:charging];
  navigation.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:navigation animated:YES completion:nil];
  return charging;
}

- (void)openPrimaryTab:(UIButton *)sender
{
  self.tabBarController.selectedIndex = sender.tag;
}

- (void)setupModernHome
{
  for (UIView *subview in [self.view.subviews copy])
    subview.hidden = YES;

  self.view.backgroundColor = [self modernBackgroundColor];
  self.modernScrollView = [[UIScrollView alloc] init];
  self.modernScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.modernScrollView.alwaysBounceVertical = YES;
  self.modernScrollView.backgroundColor = [self modernBackgroundColor];
  [self.view addSubview:self.modernScrollView];

  self.modernContentStack = [[UIStackView alloc] init];
  self.modernContentStack.translatesAutoresizingMaskIntoConstraints = NO;
  self.modernContentStack.axis = UILayoutConstraintAxisVertical;
  self.modernContentStack.spacing = 12.0;
  [self.modernScrollView addSubview:self.modernContentStack];

  [NSLayoutConstraint activateConstraints:@[
    [self.modernScrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
    [self.modernScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.modernScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.modernScrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    [self.modernContentStack.topAnchor constraintEqualToAnchor:self.modernScrollView.contentLayoutGuide.topAnchor constant:16.0],
    [self.modernContentStack.leadingAnchor constraintEqualToAnchor:self.modernScrollView.frameLayoutGuide.leadingAnchor constant:16.0],
    [self.modernContentStack.trailingAnchor constraintEqualToAnchor:self.modernScrollView.frameLayoutGuide.trailingAnchor constant:-16.0],
    [self.modernContentStack.bottomAnchor constraintEqualToAnchor:self.modernScrollView.contentLayoutGuide.bottomAnchor constant:-20.0]
  ]];

  UIStackView *identityRow = [[UIStackView alloc] init];
  identityRow.axis = UILayoutConstraintAxisHorizontal;
  identityRow.alignment = UIStackViewAlignmentCenter;
  identityRow.distribution = UIStackViewDistributionEqualSpacing;
  UILabel *vehicleLabel = [[UILabel alloc] init];
  vehicleLabel.text = @"VEHICLE STATUS";
  vehicleLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
  vehicleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
  self.modernConnectionLabel = [[UILabel alloc] init];
  self.modernConnectionLabel.textColor = [UIColor colorWithRed:0.25 green:0.85 blue:0.55 alpha:1.0];
  self.modernConnectionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
  [identityRow addArrangedSubview:vehicleLabel];
  [identityRow addArrangedSubview:self.modernConnectionLabel];
  [self.modernContentStack addArrangedSubview:identityRow];

  self.modernCarImage = [[UIImageView alloc] init];
  self.modernCarImage.contentMode = UIViewContentModeScaleAspectFit;
  [self.modernCarImage.heightAnchor constraintEqualToConstant:190.0].active = YES;
  [self.modernContentStack addArrangedSubview:self.modernCarImage];

  UIStackView *batteryStack = [[UIStackView alloc] init];
  batteryStack.axis = UILayoutConstraintAxisVertical;
  batteryStack.spacing = 10.0;
  self.modernSOCLabel = [self modernValueLabel];
  self.modernSOCLabel.font = [UIFont systemFontOfSize:42.0 weight:UIFontWeightSemibold];
  self.modernSOCProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
  self.modernSOCProgress.progressTintColor = [UIColor colorWithRed:0.30 green:0.82 blue:0.42 alpha:1.0];
  self.modernSOCProgress.trackTintColor = [UIColor colorWithWhite:1.0 alpha:0.12];
  self.modernSOCProgress.layer.cornerRadius = 3.0;
  self.modernSOCProgress.clipsToBounds = YES;
  [self.modernSOCProgress.heightAnchor constraintEqualToConstant:7.0].active = YES;
  self.modernChargeLabel = [[UILabel alloc] init];
  self.modernChargeLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
  self.modernChargeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
  [batteryStack addArrangedSubview:self.modernSOCLabel];
  [batteryStack addArrangedSubview:self.modernSOCProgress];
  [batteryStack addArrangedSubview:self.modernChargeLabel];
  [self.modernContentStack addArrangedSubview:[self modernCardWithTitle:@"BATTERY" content:batteryStack]];

  UIStackView *rangeRow = [[UIStackView alloc] init];
  rangeRow.axis = UILayoutConstraintAxisHorizontal;
  rangeRow.distribution = UIStackViewDistributionFillEqually;
  rangeRow.spacing = 12.0;
  self.modernEstimatedRangeLabel = [self modernValueLabel];
  self.modernIdealRangeLabel = [self modernValueLabel];
  [rangeRow addArrangedSubview:[self modernCardWithTitle:@"ESTIMATED RANGE" content:self.modernEstimatedRangeLabel]];
  [rangeRow addArrangedSubview:[self modernCardWithTitle:@"IDEAL RANGE" content:self.modernIdealRangeLabel]];
  [self.modernContentStack addArrangedSubview:rangeRow];

  self.modernParkingLabel = [self modernValueLabel];
  self.modernParkingLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  [self.modernContentStack addArrangedSubview:[self modernCardWithTitle:@"CURRENT STATE" content:self.modernParkingLabel]];

  [self.modernContentStack addArrangedSubview:[self modernChargingButton]];

  UIStackView *quickActions = [[UIStackView alloc] init];
  quickActions.axis = UILayoutConstraintAxisHorizontal;
  quickActions.distribution = UIStackViewDistributionFillEqually;
  quickActions.spacing = 10.0;
  [quickActions addArrangedSubview:[self modernNavigationButton:@"Controls" tabIndex:1]];
  [quickActions addArrangedSubview:[self modernNavigationButton:@"Location" tabIndex:2]];
  [quickActions addArrangedSubview:[self modernNavigationButton:@"Messages" tabIndex:3]];
  [self.modernContentStack addArrangedSubview:quickActions];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
#if DEBUG && TARGET_OS_SIMULATOR
  if (self.screenshotScenarioHandled) return;
  NSString *scenario = [[[NSProcessInfo processInfo] environment] objectForKey:@"OVMS_SCREENSHOT_SCENARIO"];
  if (![scenario hasPrefix:@"charging"]) return;
  self.screenshotScenarioHandled = YES;
  OVMSChargingViewController *charging = [self openCharging];
  if ([scenario isEqualToString:@"charging-start-confirmation"])
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [charging showStartConfirmation]; });
  else if ([scenario isEqualToString:@"charging-stop-confirmation"])
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [charging showStopConfirmation]; });
  else if ([scenario isEqualToString:@"charging-settings"])
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [charging showChargingSettings]; });
#endif
}

- (void)dealloc
{
  [self setM_car_image:nil];
  [self setM_car_charge_state:nil];
  [self setM_car_charge_type:nil];
  [self setM_car_charge_time:nil];
  [self setM_car_charge_remaining_time:nil];
  [self setM_car_chargekwh:nil];
  [self setM_car_soc:nil];
  [self setM_battery_front:nil];
  [self setM_car_connection_state:nil];
  [self setM_car_connection_image:nil];
  [self setM_car_parking_image:nil];
  [self setM_car_parking_state:nil];
  [self setM_battery_charging:nil];
  [self setM_car_range_ideal:nil];
  [self setM_car_range_estimated:nil];
  [self setM_car_charge_mode:nil];
  [self setM_charger_plug:nil];
  [self setM_charger_slider:nil];
  [self setM_car_charge_message:nil];
  [self setM_battery_button:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
  
  [[ovmsAppDelegate myRef] registerForUpdate:self];

  [self update];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
  [[ovmsAppDelegate myRef] deregisterFromUpdate:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

-(void) update
  {
  NSString* units;
  if ([[ovmsAppDelegate myRef].car_units isEqualToString:@"K"])
    units = @"km";
  else
    units = @"m";
  
  int connected = [ovmsAppDelegate myRef].car_connected;
  time_t lastupdated = [ovmsAppDelegate myRef].car_lastupdated;
  int seconds = (int)(time(0)-lastupdated);
  int minutes = (int)(time(0)-lastupdated)/60;
  int hours = minutes/60;
  int days = minutes/(60*24);
  
  NSString* mode;

  NSString* c_good;
  NSString* c_bad;
  NSString* c_unknown;
  if ([ovmsAppDelegate myRef].car_paranoid)
    {
    c_good = @"connection_good_paranoid.png";
    c_bad = @"connection_bad_paranoid.png";
    c_unknown = @"connection_unknown_paranoid.png";
    }
  else
    {
    c_good = @"connection_good.png";
    c_bad = @"connection_bad.png";
    c_unknown = @"connection_unknown.png";
    }

  NSString* imagewanted;
  
  if (connected>0)
    {
    imagewanted = c_good;
    }
  else
    {
    imagewanted = c_unknown;
    }
  
  if (lastupdated == 0)
    {
    m_car_connection_state.text = @"";
    m_car_connection_state.textColor = [UIColor whiteColor];
    }
  else if (minutes == 0)
    {
    m_car_connection_state.text = @"live";
    m_car_connection_state.textColor = [UIColor whiteColor];
    }
  else if (minutes == 1)
    {
    m_car_connection_state.text = @"1 min";
    m_car_connection_state.textColor = [UIColor whiteColor];
    }
  else if (days > 1)
    {
    m_car_connection_state.text = [NSString stringWithFormat:@"%d days",days];
    m_car_connection_state.textColor = [UIColor redColor];
    imagewanted = c_bad;
    }
  else if (hours > 1)
    {
    m_car_connection_state.text = [NSString stringWithFormat:@"%d hours",hours];
    m_car_connection_state.textColor = [UIColor redColor];
    imagewanted = c_bad;
    }
  else if (minutes > 60)
    {
    m_car_connection_state.text = [NSString stringWithFormat:@"%d mins",minutes];
    m_car_connection_state.textColor = [UIColor redColor];
    imagewanted = c_bad;
    }
  else
    {
    m_car_connection_state.text = [NSString stringWithFormat:@"%d mins",minutes];
    m_car_connection_state.textColor = [UIColor whiteColor];
    }

  if ([ovmsAppDelegate myRef].car_online)
    {
    m_battery_button.enabled=YES;
    [m_car_connection_image stopAnimating];
    m_car_connection_image.animationImages = nil;
    m_car_connection_image.image=[UIImage imageNamed:imagewanted];
    }
  else
    {
    m_battery_button.enabled=NO;
    NSArray *images = [[NSArray alloc] initWithObjects:
                        [UIImage imageNamed:@"Nothing.png"],
                        [UIImage imageNamed:imagewanted],
                        nil];
    m_car_connection_image.image = nil;
    m_car_connection_image.animationImages = images;
    m_car_connection_image.animationDuration = 1.0;
    m_car_connection_image.animationRepeatCount = 0;
    [m_car_connection_image startAnimating];
    }

  int parktime = [ovmsAppDelegate myRef].car_parktime;
  int chargetime = [ovmsAppDelegate myRef].car_chargeduration;
  int chargeremainingtime = [ovmsAppDelegate myRef].car_minutestofull;
  int chargekWh = [ovmsAppDelegate myRef].car_chargekwh;
  if ((parktime > 0)&&(lastupdated>0)) parktime += seconds;
  
  if (parktime == 0)
    {
    m_car_parking_image.hidden = 1;
    m_car_parking_state.text = @"";
    }
  else if (parktime < 120)
    {
    m_car_parking_image.hidden = 0;
    m_car_parking_state.text = @"just now";
    }
  else if (parktime < (3600*2))
    {
    m_car_parking_image.hidden = 0;
    m_car_parking_state.text = [NSString stringWithFormat:@"%d mins",parktime/60];
    }
  else if (parktime < (3600*24*2))
    {
    m_car_parking_image.hidden = 0;
    m_car_parking_state.text = [NSString stringWithFormat:@"%02d:%02d",
                                parktime/3600,
                                (parktime%3600)/60];
    }
  else
    {
    m_car_parking_image.hidden = 0;
    m_car_parking_state.text = [NSString stringWithFormat:@"%d days",parktime/(3600*24)];
    }

  if (chargetime == 0 || m_charger_plug.hidden == 1)
    {
    m_car_charge_time.text = @"";
    }
  else if (chargetime < 120)
    {
    m_car_charge_time.text = @"CHARGING STARTED";
    }
  else if (chargetime < 3600)
    {
    m_car_charge_time.text = [NSString stringWithFormat:@"%d mins",chargetime/60];
    }
  else if (chargetime < (3600*24*2))
    {
    m_car_charge_time.text = [NSString stringWithFormat:@"%02d:%02d",
                                       chargetime/3600,
                                       (chargetime%3600)/60];
    }

  if (chargeremainingtime <= 0)
    {
    m_car_charge_remaining_time.text = @"";
    }
  else if (chargeremainingtime < 60)
    {
    m_car_charge_remaining_time.text = [NSString stringWithFormat:@"%d mins",chargeremainingtime];
    }
  else
    {
    m_car_charge_remaining_time.text = [NSString stringWithFormat:@"%02d:%02d",
                               chargeremainingtime/60,
                               chargeremainingtime%60];
    }

  if ( chargekWh==0 )
    {
    m_car_chargekwh.text = @"";
    }
  else
    {
    float effect=([ovmsAppDelegate myRef].car_linevoltage*[ovmsAppDelegate myRef].car_chargecurrent)/1000.0;
    if ((effect>0)&&(effect<250))
      {
      m_car_chargekwh.text = [NSString stringWithFormat:@"%dkWh@%0.1fkW",chargekWh,effect];
      }
    else
      {
      m_car_chargekwh.text = [NSString stringWithFormat:@"%dkWh",chargekWh];
      }
    }

  m_car_image.image=[UIImage imageNamed:[ovmsAppDelegate myRef].sel_imagepath];
  m_car_soc.text = [NSString stringWithFormat:@"%d%%",[ovmsAppDelegate myRef].car_soc];
  m_car_range_ideal.text = [ovmsAppDelegate myRef].car_idealrange_s;
  m_car_range_estimated.text = [ovmsAppDelegate myRef].car_estimatedrange_s;

  self.modernCarImage.image = [UIImage imageNamed:[ovmsAppDelegate myRef].sel_imagepath];
  self.modernSOCLabel.text = [NSString stringWithFormat:@"%d%%", [ovmsAppDelegate myRef].car_soc];
  self.modernSOCProgress.progress = MAX(0.0, MIN(1.0, [ovmsAppDelegate myRef].car_soc / 100.0));
  self.modernEstimatedRangeLabel.text = [ovmsAppDelegate myRef].car_estimatedrange_s;
  self.modernIdealRangeLabel.text = [ovmsAppDelegate myRef].car_idealrange_s;
  self.modernConnectionLabel.text = lastupdated == 0 ? @"Waiting for data" : m_car_connection_state.text;
  self.modernConnectionLabel.textColor = m_car_connection_state.textColor;
  NSString *chargeSummary = [[ovmsAppDelegate myRef].car_chargestate length] > 0
    ? [[ovmsAppDelegate myRef].car_chargestate capitalizedString] : @"Not charging";
  self.modernChargeLabel.text = chargeSummary;
  self.modernParkingLabel.text = parktime > 0
    ? [NSString stringWithFormat:@"Parked %@", m_car_parking_state.text]
    : @"Vehicle state is live";
      
  CGRect bounds = m_battery_front.bounds;
  CGPoint center = m_battery_front.center;
  CGFloat oldwidth = bounds.size.width;
  CGFloat newwidth = (((0.0+[ovmsAppDelegate myRef].car_soc)/100.0)*(233-17))+18;
  bounds.size.width = newwidth;
  center.x = center.x + ((newwidth - oldwidth)/2);
  m_battery_front_width.constant = newwidth;
  //m_battery_front.bounds = bounds;
  //m_battery_front.center = center;
  //bounds = m_battery_front.bounds;

  center = m_car_charge_remaining_time.center;
      center.x = (m_battery_front.center.x+bounds.size.width/2 + 233+17)/2;
  m_car_charge_remaining_time.center = center;
      
  if ((([ovmsAppDelegate myRef].car_doors1 & 0x04)==0)||
      ([ovmsAppDelegate myRef].car_chargesubstate == 0x07))
    { // Charge port is closed, or connect-pwr-cable charge sub-state
    m_charger_plug.hidden = 1;            // The plug image
    m_charger_slider.hidden = 1;          // The slider control on the plug
    m_charger_slider.enabled = 0;         // The slider control on the plug
    m_car_charge_state.hidden = 1;        // The car charge state label (left of slider)
    m_car_charge_type.hidden = 1;         // The car charge type label (left of slider)
    m_car_charge_message.hidden = 1;      // The car charge message (right of slider)
    m_battery_charging.hidden = 1;        // Copper tops on the battery
    m_car_charge_mode.hidden = 1;         // The car charge mode message (copper on battery)
    }
  else
    { // Charge port is open and plugged in
    m_charger_plug.hidden = 0;            // The plug image
    m_charger_slider.hidden = 0;          // The slider control on the plug
    m_charger_slider.enabled =            // The slider control on the plug
      connected &&
      ([ovmsAppDelegate myRef].car_chargestateN<0x100) &&
      ([ovmsAppDelegate myRef].car_online);
    m_car_charge_state.hidden = 0;        // The car charge state label (left of slider)
    m_car_charge_type.hidden = 0;         // The car charge type label (left of slider)
    switch ([ovmsAppDelegate myRef].car_chargestateN)
      {
      case 0x04:    // Done
      case 0x115:   // Stopping
      case 0x15:    // Stopped
      case 0x16:    // Stopped
      case 0x17:    // Stopped
      case 0x18:    // Stopped
      case 0x19:    // Stopped
        m_car_charge_message.text = @"SLIDE TO CHARGE";
        m_car_charge_state.text = @"";
        m_car_charge_type.text = @"";
        m_car_charge_mode.text = @"";
        // Slider on the left, message is "Slide to charge"
        m_charger_slider.value = 0.0;
        m_car_charge_message.hidden = 0;
        m_car_charge_state.hidden = 1;
        m_car_charge_type.hidden = 1;
        m_battery_charging.hidden = 1;
        m_car_charge_mode.hidden = 1;
        
        break;

      case 0x0e:    // Wait for schedule charge
        m_car_charge_message.text = @"TIMED CHARGE";
        m_car_charge_state.text = @"";
        m_car_charge_type.text = @"";
        m_car_charge_mode.text = @"";
        // Slider on the left, message is "Slide to charge"
        m_charger_slider.value = 0.0;
        m_car_charge_message.hidden = 0;
        m_car_charge_state.hidden = 1;
        m_car_charge_type.hidden = 1;
        m_battery_charging.hidden = 1;
        m_car_charge_mode.hidden = 1;
        break;

      case 0x01:    // Charging
      case 0x101:   // Starting
      case 0x02:    // Top-off
      case 0x0d:    // Preparing to charge
      case 0x0f:    // Heating
        m_car_charge_state.text = [[ovmsAppDelegate myRef].car_chargestate uppercaseString];
        m_car_charge_type.text = [NSString stringWithFormat:@"%dV @%dA",
                                  [ovmsAppDelegate myRef].car_linevoltage,
                                  [ovmsAppDelegate myRef].car_chargecurrent];
        
        if( [ovmsAppDelegate myRef].car_chargetype==1 ){
            mode = @"Type 1";
        }else if( [ovmsAppDelegate myRef].car_chargetype==2 ){
            mode = @"ChaDeMo";
        }else{
            mode = [[ovmsAppDelegate myRef].car_chargemode uppercaseString];
        }
        m_car_charge_mode.text = [NSString stringWithFormat:@"%@ %dA",
                                mode,
                                [ovmsAppDelegate myRef].car_chargelimit];
        // Slider on the right, message blank
        m_charger_slider.value = 1.0;        
        m_car_charge_message.hidden = 1;
        m_car_charge_state.hidden = 0;
        m_car_charge_type.hidden = 0;
        m_battery_charging.hidden = 0;
        m_car_charge_mode.hidden = 0;
        break;

      default:
        m_car_charge_state.text = @"";
        m_car_charge_type.text = @"";
        m_car_charge_mode.text = @"";
        // Slider on the right, message blank
        m_charger_slider.value = 1.0;
        m_car_charge_message.hidden = 1;
        m_car_charge_state.hidden = 0;
        m_car_charge_type.hidden = 0;
        m_battery_charging.hidden = 1;
        m_car_charge_mode.hidden = 1;
        break;
      }
    }
  }

- (IBAction)ChargeSliderTouch:(id)sender
  {
  if (([[ovmsAppDelegate myRef].car_chargestate isEqualToString:@"done"])||
      ([[ovmsAppDelegate myRef].car_chargestate isEqualToString:@"stopped"])||
      ([[ovmsAppDelegate myRef].car_chargestate isEqualToString:@"timerwait"]))
    {
    // The slider is on the left, and should spring back there
    if (m_charger_slider.value == 1.0)
      {
      // We are done, and should start the charge
      [[ovmsAppDelegate myRef] commandDoStartCharge];
      }
    else
      {
      // Spring back
      [UIView beginAnimations: @"SlideCanceled" context: nil];
      [UIView setAnimationDelegate: self];
      [UIView setAnimationDuration: 0.35];
      // use CurveEaseOut to create "spring" effect
      [UIView setAnimationCurve: UIViewAnimationCurveEaseOut]; 
      m_charger_slider.value = 0.0;      
      [UIView commitAnimations];
      }
    }
  else
    {
    // The slider is on the right, and should sprint back there
    if (m_charger_slider.value == 0.0)
      {
      // We are done, and should stop the charge
      [[ovmsAppDelegate myRef] commandDoStopCharge];
      }
    else
      {
      // Spring back
      [UIView beginAnimations: @"SlideCanceled" context: nil];
      [UIView setAnimationDelegate: self];
      [UIView setAnimationDuration: 0.35];
      // use CurveEaseOut to create "spring" effect
      [UIView setAnimationCurve: UIViewAnimationCurveEaseOut]; 
      m_charger_slider.value = 1.0;      
      [UIView commitAnimations];
      }
    }
  }

- (IBAction)ChargeSliderValue:(id)sender
  {
  }

@end
