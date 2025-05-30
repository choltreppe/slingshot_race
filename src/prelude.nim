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


proc saveFileDataImpl(filename: cstring, data: pointer, size: cint)
  {.cdecl, importc: "SaveFileData", header: "raylib.h".}
proc saveFileData*(filename: string, data: auto) =
  saveFileDataImpl(filename.cstring, addr data, cint sizeof(data))

proc loadFileDataImpl(filename: cstring, size: ptr cint): pointer
  {.cdecl, importc: "LoadFileData", header: "raylib.h".}
proc loadFileData*[T](filename: string): T =
  let size = cint sizeof(T)
  cast[ptr T](loadFileDataImpl(filename.cstring, addr size))[]

proc raylibFileExists*(filename: string): bool =
  let size = cint 1
  loadFileDataImpl(filename, addr size) != nil


type PermaVar*[filename: static string, T] = object
  val: T

proc load*[filename, T](v: var PermaVar[filename, T]): bool =
  if raylibFileExists(filename):
    v.val = loadFileData[T](filename)
    true
  else: false

proc `<-`*[filename, T](v: var PermaVar[filename, T], val: T) =
  v.val = val
  saveFileData(filename, val)

converter val*[filename, T](v: PermaVar[filename, T]): T = v.val