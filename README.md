# Slingshot Racer

a little space racing game, where you play a ufo and have to dodge planets and use their gravity.

![Screenshot](https://raw.githubusercontent.com/choltreppe/slingshot_race/master/screenshot.png)

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