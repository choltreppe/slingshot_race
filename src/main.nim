import ./prelude, ./game


when not defined(android):
  import std/os
  setCurrentDir getAppDir()


proc main =

  const windowTitle = "Slingshot Race"
  when defined(android):
    initWindow(0, 0, windowTitle)
    windowSize = vec2(getScreenWidth(), getScreenHeight())
  else:
    initWindow(450, 800, windowTitle)

  #[block loadingScreen:
    let logo = loadTextureSvg("resources/chol_logo.svg", int32 windowSize.x / 3, 0)
    drawing:
      clearBackground(Black)
      drawTexture(logo, vec2(
        windowSize.x / 3,
        (windowSize.y / 2) - logo.height.float32
      ), White)]#

  try:
    setTargetFPS(60)
    
    initGame()

    while not windowShouldClose():
      updateGame(getFrameTime())
      drawGame()

  finally:
    closeWindow()

main()