# LibHoney

A library for sending events to [Honeycomb](https://www.honeycomb.io) written in Swift.

## Installation

### Cocoapods

[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
gem install cocoapods
```

To integrate LibHoney into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
target '<Target name>' do
  # If you're using LibHoney with Objective-C, uncomment use_frameworks!
  # use_frameworks!  
  pod 'LibHoney', '~> 1.0'
end
```

Then run the following command:

```bash
pod install
```

> Since LibHoney depends on `Alamofire`, if you're using LibHoney in Objective-C, you might have to set the `SWIFT_VERSION` variable for Alamofire in the Pods build settings.

## Usage

### Swift

To use LibHoney, you have to first configure the library with your writeKey and dataset name.

In the `AppDelegate` inside `didFinishLaunchingWithOptions`:

```swift
import LibHoney

// ...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {    
    // other code...
    LibHoney.configure(writeKey: "<your write key>", dataset: "<your dataset name>")    
}
```

To send an event, simply create a new event and add fields to it:

```swift
let event = LibHoney.shared?.newEvent()
event?.add(key: "stringValue", value: "Hello, world")
event?.add(key: "intValue", value: 199)
event?.add(key: "boolValue", value: true)
event?.add(key: "doubleValue", value: 3.14159)
LibHoney.shared?.send(event)
```

> If LibHoney is not configured, `LibHoney.shared` returns `nil`. With the code above, you can safely bypass the configuration step in debug environments.

To set values such that it gets sent on every event, add the key to the shared LibHoney object

```swift
LibHoney.shared?.add(key: "user", value: "<user id>")
```

LibHoney automatically extracts device information and send them with each event. To disable this behavior:

```swift
LibHoney.shared?.collectDeviceStats = false
```

### Objective-C

To use LibHoney, you have to first configure the library with your writeKey and dataset name.

In the `AppDelegate` inside `didFinishLaunchingWithOptions`:

```objective-c
@import LibHoney;

// ...

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // other code...
    [LibHoney configureWithWriteKey:@"<your write key>" dataset:@"<your dataset name>"];    
}
```

To send an event, simply create a new event and add fields to it:

```objective-c
HoneyEvent* event = [LibHoney.shared newEvent];
[event addKey: @"stringValue" stringValue: @"Hello, world"];
[event addKey: @"intValue" intValue: 199];
[event addKey: @"boolValue" boolValue: true];
[event addKey: @"doubleValue" doubleValue: 3.14159];
[LibHoney.shared send: event];
```

> If LibHoney is not configured, `LibHoney.shared` returns a nil object.

To set values such that it gets sent on every event, add the key to the shared LibHoney object

```objective-c
[LibHoney.shared addKey:@"user" stringValue:@"<user Id>"];
```

LibHoney automatically extracts device information and send them with each event. To disable this behavior:

```objective-c
LibHoney.shared.collectDeviceStats = NO;
```

## Contributions

Features, bug fixes and other changes to LibHoney are gladly accepted. Please open issues or a pull request with your change. Remember to add your name to the CONTRIBUTORS file!

All contributions will be released under the Apache License 2.0.
