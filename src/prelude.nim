import vmath, raylib
export vmath, raylib

converter toVec*(vector: Vector2): Vec2 {.inline.} =
  cast[Vec2](vector)

converter toVector*(vec: Vec2): Vector2 {.inline.} =
  cast[Vector2](vec)

converter toVector*(vec: Vec3): Vector3 {.inline.} =
  cast[Vector3](vec)

func `+=`*(a: var Vector2, b: Vector2) =
  a = a + b

type Rect* = object
  position*, size*: Vec2

func newRect*(position, size: Vec2): Rect =
  Rect(position: position, size: size)

func newRect*(x, y, w, h: float32): Rect =
  Rect(position: vec2(x, y), size: vec2(w, h))

converter toRectangle*(rect: Rect): Rectangle {.inline.} =
  cast[Rectangle](rect) 

func size*(texture: Texture2D): IVec2 =
  ivec2(texture.width, texture.height)

proc drawTextureVFlipped*(texture: Texture2D, pos: Vec2) =
  drawTexture(texture, Rectangle(width: texture.width.float32, height: -texture.height.float32), pos, White)

proc loadImageSvgImpl(fileName: cstring, width, height: cint): Image
  {.cdecl, importc: "LoadImageSVG", header: "svg_loading/svg_loading.h".}
proc loadImageSvg*(fileName: string, width, height: int32): Image =
  loadImageSvgImpl(fileName.cstring, width, height)

proc loadTextureSvg*(fileName: string, width, height: int32): Texture =
  loadTextureFromImage(loadImageSvg(fileName, width, height))