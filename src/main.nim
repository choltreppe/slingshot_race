import ./prelude, ./game, ./gameoverscreen


when not defined(android):
  import std/os
  setCurrentDir getAppDir()


proc main =

  const windowTitle = "Slingshot Race"
  when defined(android):
    initWindow(0, 0, windowTitle)
  else:
    initWindow(450, 800, windowTitle)
  
  let windowSize = vec2(float32 getScreenWidth(), float32 getScreenHeight())

  block loadingScreen:
    let logo = loadTextureSvg("resources/chol_logo.svg", int32 windowSize.x / 3, 0)
    drawing:
      clearBackground(Black)
      drawTexture(logo, vec2(
        windowSize.x / 3,
        (windowSize.y / 2) - logo.height.float32
      ), White)

  try:
    setTargetFPS(60)
    waitTime(1)
    initGame()
    gameoverscreen.loadAssets()

    var gameIsOver = false
    while not windowShouldClose():
      if gameIsOver:
        drawGameOver()
        if isGestureDetected(Tap):
          gameIsOver = false
          restartGame()
      else:
        updateGame(getFrameTime(), gameIsOver)
        drawGame()

  finally:
    closeWindow()

main()