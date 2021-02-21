# Accessible-Scale-iOS-app

Make smart scale accessible for visually impaired people (prototype)

# Motivation

There are **Talking Scales** for visually impaired people, but there is no **Smart Scales** that can talk. I have been trying to access smart scale measurement via bluetooth to make those data easily accessible with VoiceOver (screen reading software on iOS).

# Functions

- Minimal functions / simple to use
- Accessible to the measurement
- ToDo: custom notification sound / more scales


# Supported / Not Supported Smart Scales

- Renpho Smart Scale, Model ES-WBE28 (weight and body composition)
 - Procedure
   - Complete welcome page to input information
 - Launch app mode
   - Turn on the app by push the scale and wait the app gets ready
   - Get on the scale, the app reads the weight and fat percentage
 - Background connection mode (with calibration)
   - Turn on the app by push the scale and wait to hear notification
   - Get on the scale and stand still, you will hear the second notification for weight
   - Stand still for several more seconds, you will hear the third notification for fat
 - Background connection mode (without calibration)
   - Step on the scale and stand still to wait completing the measurement
   - Hear the first notification for the bluetooth connection
   - Stand still for several more seconds, you will hear the second notification for weight and fat

- Wyze Scale (not supported, custom service is not easy to reverse engineered)

- Others, please ask at the Issues

# License

MIT
