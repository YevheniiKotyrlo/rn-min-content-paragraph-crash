# rn-min-content-paragraph-crash

With `enableFlexboxAutoMinSizeInStrictMode` on, a screen under `<experimental_LayoutConformance mode="strict">` that holds a Text with a View inside it crashes on the JavaScript thread under Yoga's `computeMinContentMainSize` once a later commit lays it out again.

`ReproducerApp/App.tsx` renders, under `<experimental_LayoutConformance mode="strict">`, a ScrollView of pressable Texts that each hold a View of two Texts, and changes the height of a header above the list on each of 120 renders after mount. `ReproducerApp/ios/ReproducerApp/FeatureFlags.mm` turns `enableFlexboxAutoMinSizeInStrictMode` on over the Stable release level's overrides, once `RCTReactNativeFactory` has started.

On a Mac with Xcode, Node and CocoaPods, and an iPhone or iPad that `xcrun devicectl list devices` lists:

```sh
DEVELOPMENT_TEAM=<your team> ./reproduce.sh <device identifier>
```

It runs `yarn install` and `pod install` in `ReproducerApp`, builds it in Release with `xcodebuild` (`BUNDLE_ID` sets the bundle identifier), installs it with `devicectl`, launches it three times for 15 seconds each and reads the crash reports the device writes. It exits 1 while a launch crashes under `computeMinContentMainSize`, 0 once the three launches run without a crash, and 2 when a step fails or a launch crashes elsewhere. The logs and crash reports are in `logs/`.

# How to use this Reproducer

This project has been created with `npx @react-native-community/cli init` and is a vanilla React Native app.

> [!IMPORTANT]  
> Make sure you have completed the [React Native - Environment Setup](https://reactnative.dev/docs/set-up-your-environment) so that you have a working environment locally.

## Step 1: Start the Metro Server

First, you will need to start **Metro**, the JavaScript _bundler_ that ships _with_ React Native.

To start Metro, run the following command from the _root_ of your React Native project:

```bash
# using npm
npm start

# OR using Yarn
yarn start
```

## Step 2: Start your Application

Let Metro Bundler run in its _own_ terminal. Open a _new_ terminal from the _root_ of your React Native project. Run the following command to start your _Android_ or _iOS_ app:

### For Android

```bash
# using npm
npm run android

# OR using Yarn
yarn android
```

### For iOS

First, make sure you install dependencies with:

```bash
cd ios && bundle install && bundle exec pod install
```

Then you can run the iOS app with:

```bash
# using npm
npm run ios

# OR using Yarn
yarn ios
```

If everything is set up _correctly_, you should see your new app running in your _Android Emulator_ or _iOS Simulator_ shortly provided you have set up your emulator/simulator correctly.

This is one way to run your app — you can also run it directly from within Android Studio and Xcode respectively.

## Step 3: Modifying your App

Now that you have successfully run the app, let's modify it.

1. Open `App.tsx` in your text editor of choice and edit some lines.
2. For **Android**: Press the <kbd>R</kbd> key twice or select **"Reload"** from the **Developer Menu** (<kbd>Ctrl</kbd> + <kbd>M</kbd> (on Window and Linux) or <kbd>Cmd ⌘</kbd> + <kbd>M</kbd> (on macOS)) to see your changes!

   For **iOS**: Hit <kbd>Cmd ⌘</kbd> + <kbd>R</kbd> in your iOS Simulator to reload the app and see your changes!
