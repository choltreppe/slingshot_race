import vmath, raylib
export vmath, raylib

converter toVec*(vector: Vector2): Vec2 =
  vec2(vector.x, vector.y)

converter toVector*(vec: Vec2): Vector2 =
  Vector2(x: vec.x, y: vec.y)

func `+=`*(a: var Vector2, b: Vector2) =
  a = a + b

func size*(texture: Texture2D): IVec2 =
  ivec2(texture.width, texture.height)

proc drawTextureVFlipped*(texture: Texture2D, pos: Vec2) =
  drawTexture(texture, Rectangle(width: texture.width.float32, height: -texture.height.float32), pos, White)