import ./prelude

var
  gameOverTexture: Texture2D
  gameOverPos: Vec2
  scorePos, highscorePos: Vec2
  font: Font
  highscore: PermaVar["highscore", uint64]

proc loadAssets* =
  let screenWidth = getScreenWidth()
  gameOverTexture = loadTextureSvg("resources/game_over.svg", screenWidth * 2 div 3, 0)
  gameOverPos.x = screenWidth / 6
  gameOverPos.y = (getScreenHeight() - gameOverTexture.height) / 2
  scorePos = gameOverPos + vec2(gameOverTexture.size) * vec2(0.125, 0.55)
  highscorePos = gameOverPos + vec2(gameOverTexture.size) * vec2(0.125, 0.68)
  font = loadFont("resources/font.ttf", screenWidth div 12, [])
  if not highscore.load():
    highscore <- 0

proc drawGameOver*(score: uint64) =
  if score > highscore:
    highscore <- score
  drawing:
    clearBackground(Black)
    drawTexture(gameOverTexture, gameOverPos, White)
    drawText(font, "SCORE " & $score, scorePos, float32(font.baseSize), 0, White)
    drawText(font, "HIGHSCORE " & $highscore, highscorePos, float32(font.baseSize)*0.7, 0, White)