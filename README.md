# Slingshot Racer

a little space racing game, where you play a ufo and have to dodge planets and use their gravity.
It should be a mobile game, but it doesnt run on android, and I dont know why
But it works on desktop in a window

## compile / run

first make sure you have java and android sdk & ndk and `JAVA_HOME`, `ANDROID_HOME` and `ANDROID_NDK` env-vars are set.

### desktop
```sh
nimble build -r
```

### android
```sh
nimble setupAndroid
nimble buildAndroid
nimble deploy
```