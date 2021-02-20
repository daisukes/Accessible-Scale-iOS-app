# Accessible-Scale-iOS-app

Make smart scale accessible for visually impaired people (prototype)

# Motivation

There are **Talking Scales** for visually impaired people, but there is no **Smart Scales** that can talk. I have been trying to access smart scale measurement via bluetooth to make those data easily accessible with VoiceOver (screen reading software on iOS).

# Functions

- Simple to use
- Accessible to the measurement
- ToDo: support Health Kit / more scales


# Supported / Not Supported Smart Scales

- Renpho Smart Scale, Model ES-WBE28 (weight and body composition)
 - Procedure
   - Complete welcome page to input information
 - Launch app mode
   - Turn on the app by push the scale and wait the app gets ready
   - Get on the scale, the app reads the weight and fat percentage
 - Background connection mode
   - Turn on the app by push the scale and wait to hear notification
   - Get on the scale, you hear the second notification for weight
   - Get on the scale, you hear the third notification for fat

- Wyze Scale (not supported, custom service is not easy to reverse engineered)

- Others, please ask at the Issues

# License

MIT
