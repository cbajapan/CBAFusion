# CBAFusion
![CBALogo](cbaLogo.png)
## This example is a release candidate. 


An important note: When your device is on a private focus such as **Do Not Disturb** you must add the app to the allowed apps or turn of the Private Focus to receive Calls.

## Documenation
 In order to see an example of how to use this SDK we have provided a tutorial for you. Once you have fetched the fcsdk-ios package in your project press ``Command + control + shift + d``  and you will build the documentation. Then in the side bar find ``fcsdk-ios -> Build an awesome app using FCSDK-iOS`` and enjoy!


## CBAFusion is an app for Voice and Video needs. It also has an AED API that allows for message transportation.

**Getting Started**
Please clone the project and then checkout the release of your choice. When you do this, CBAFusion may know which version of FCSDKiOS to fetch that works with the corresponding release, if not you will have to fetch via Swift Package Manager. Please see the release notes for which version of FCSDKiOS corresponds to the version of CBAFusion you wish to use.

Please make sure you reset your Swift Package Cache via ``File -> Packages -> Reset Package Cache`` so that Xcode will fetch the needed Packages for this Sample App to work.

**Features**

- Voice/Video Calls
- CallKit
- MetalKit
- Written in SwiftUI
- Async/Await

**Limitations**
- CallKit is not fully implemented
- Calls only work while that app is open


**Bugs**
- *Intermittent audio issue while receiving calls*
- *If Do Not Disturb is on calls and then you turn it off an then try to make another call they fail. The app must be removed from memory and then reopened.*
