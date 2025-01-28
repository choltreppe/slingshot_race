import ./prelude

var
  gameOverTexture: Texture2D
  gameOverPos: Vec2

proc loadAssets* =
  let screenWidth = getScreenWidth()
  gameOverTexture = loadTextureSvg("resources/game_over.svg", screenWidth * 2 div 3, 0)
  gameOverPos.x = screenWidth / 6
  gameOverPos.y = (getScreenHeight() - gameOverTexture.height) / 2

proc drawGameOver* =
  drawing:
    clearBackground(Black)
    drawTexture(gameOverTexture, gameOverPos, White)