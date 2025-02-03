import std/[random, math]
import chroma except Color
import unroll
import ./prelude, ./queue


const
  shipRadius = 0.036
  shipAccel = 0.28
  shipFuelUse = 0.14
  
  planetRadiusRange = 0.06 .. 0.14
  planetsMinMargin = 0.22
  planetMaxDistance = 0.5
  planetDistanceRange = planetRadiusRange.a+planetsMinMargin*1.1 .. planetMaxDistance+planetsMinMargin

  refuelOrbRadius = 0.02'f32

  gravityStrength = 5

  cameraShakeDistance = 0.15
  cameraShakeStrength = 0.012


type
  Ship = object
    position, velocity: Vec2
    fuel: float32 = 1

  SpaceObjectKind = enum planet, refuel
  SpaceObject = object
    position: Vec2
    case kind: SpaceObjectKind
    of planet:
      radius: float32
      texture: Texture2D
    of refuel:
      active: bool

  PlanetShader = object
    shader: Shader
    locs: tuple[radius, color, randSeed: ShaderLocation]

  PlanetKind = enum rockplanet, moon

randomize()

var
  worldScale: float32
  viewHeight: float32
  shipMinY: float32

  font: Font
  shipTexture: Texture2D
  planetShaders: array[PlanetKind, PlanetShader]

  ship: Ship
  spaceObjects = newQueue[SpaceObject](12)
  lastRefuelOrbDistance: int32
  score: uint64
  scoreStep: float32
  cameraShake: tuple[
    offset: Vec2,
    radius: float32,
    direction: Vec2
  ]
  refuelAnimTrans = 1'f32

proc restartGame*
proc initGame* =
  let screenSize = vec2(float32 getScreenWidth(), float32 getScreenHeight())
  worldScale = screenSize.x
  viewHeight = screenSize.y / screenSize.x
  shipMinY = viewHeight * 0.66

  font = loadFont("resources/font.ttf", int32(0.08*worldScale), [])
  shipTexture = loadTextureSvg("resources/ufo.svg", int32(shipRadius*2*worldScale), 0)

  for kind in unroll(PlanetKind):
    let shader = addr planetShaders[kind]
    shader.shader = loadShaderFromMemory(
      static(staticRead("shader/vert.glsl")),
      static(staticRead("shader/" & $kind & ".glsl"))
    )
    for name, field in shader.locs.fieldPairs:
      field = shader.shader.getShaderLocation(name)

  restartGame()

template `[]=`(pshader: PlanetShader, locField, val: untyped) =
  pshader.shader.setShaderValue(pshader.locs.locField, val)

proc newPlanet(position: Vec2, radius: float32): SpaceObject =
  result = SpaceObject(kind: planet, position: position, radius: radius)
  let size = int32(radius*4*worldScale)
  let camera = Camera2D(zoom: float32(size))
  var renderTexture = loadRenderTexture(size, size)
  template shader: var PlanetShader =
    planetShaders[
      if radius < 0.1: moon
      else: rockplanet
    ] 
  shader[radius] = radius
  let hslColor = hsv(rand(0f32..360f32), rand(20f32..50f32), rand(75f32..95f32))
  shader[color] = cast[Vec4](hslColor.asColor).rgb
  shader[randSeed] = vec3(rand(-420f32 .. 420f32), rand(-420f32 .. 420f32), rand(-420f32 .. 420f32))
  textureMode(renderTexture):
    clearBackground(Color())
    mode2D(camera):
      shaderMode(shader.shader):
        drawRectangle(0, 0, 1, 1, White)
  result.texture = renderTexture.texture

func boundingRadius(obj: SpaceObject): float32 =
  case obj.kind
  of planet: obj.radius
  of refuel: refuelOrbRadius

proc restartGame* =
  ship = Ship(position: vec2(0.5, shipMinY))
  clear spaceObjects
  spaceObjects &= newPlanet(
    vec2(rand(1f32), 0),
    rand(planetRadiusRange)
  )
  lastRefuelOrbDistance = 0
  score = 0
  scoreStep = 0
  cameraShake.direction = vec2(1, 0)

proc screenSpace(pos: Vec2): Vec2 =
  (pos + cameraShake.offset) * worldScale

proc screenSpace(rect: Rect): Rect =
  Rect(
    position: screenSpace(rect.position),
    size: rect.size * worldScale,
  )

proc drawGame* =
  drawing:
    clearBackground(Black)
    for obj in spaceObjects:
      case obj.kind
      of planet:
        drawTexture(obj.texture, screenSpace(obj.position-vec2(obj.radius)), 0, 0.5, White)
      of refuel:
        if obj.active:
          drawCircle(screenSpace(obj.position), obj.boundingRadius*worldScale, Blue)

    block drawPlayer:
      if refuelAnimTrans < 1:
        let bounce = 0.04 * (0.5 - abs(refuelAnimTrans-0.5))
        drawCircle(screenSpace(ship.position), (shipRadius+bounce)*worldScale, Blue)
      drawTexture(shipTexture, screenSpace(ship.position-vec2(shipRadius)), White)

    const uiMargin = 0.03
    block drawFuelBar:
      const width = 0.4
      var rect = screenSpace(newRect(
        x = 1.0 - width - uiMargin,
        y = uiMargin,
        w = width,
        h = 0.05,
      ))
      drawRectangle(rect, Black)
      drawRectangleLines(rect, 2, Blue)
      rect.size.x *= ship.fuel
      drawRectangle(rect, Blue)
    block:
      let p = ivec2()
      drawText(font, $score, screenSpace(vec2(uiMargin)), float32(font.baseSize), 0, White)

iterator planets: lent SpaceObject =
  for obj in spaceObjects:
    if obj.kind == planet:
      yield obj

proc gravityAt(position: Vec2): Vec2 =
  result = vec2(0)
  for planet in planets():
    let v = planet.position - position
    let distance = length(v)
    let direction = normalize(v)
    result += float32(max(0, 1/distance^2 - 0.1) * planet.radius^3) * direction
  result *= gravityStrength

proc distanceToPlanets(position: Vec2): float32 =
  result = high(float32)
  for planet in planets():
    let d = dist(position, planet.position) - planet.radius
    if d < result:
      result = d

proc updateShip(dt: float32) =
  ship.position += ship.velocity * dt

  ship.velocity += gravityAt(ship.position) * dt
  
  if ship.fuel > 0:
    if isGestureDetected(Hold):
      var vec = (getMousePosition()/worldScale - ship.position) * 3.6
      var strength = length(vec)
      if strength > 1:
        strength = 1
        vec /= strength
      ship.velocity += vec * (shipAccel * dt)
      ship.fuel = max(0, ship.fuel - shipFuelUse*strength*dt)

    when not defined(android):
      for (key, vec) in {
        Up: vec2(0, -1), Down: vec2(0, 1),
        Left: vec2(-1, 0), Right: vec2(1, 0),
      }:
        if isKeyDown(key):
          ship.velocity += vec * (shipAccel * dt)
          ship.fuel = max(0, ship.fuel - shipFuelUse*dt)

proc addPlanet =
  let prevObj = addr spaceObjects.last
  let distance = prevObj[].boundingRadius + rand(planetDistanceRange)

  proc getMaxAngle(borderX: float32): float32 =
    let margin = abs(borderX - prevObj.position.x)
    if margin > distance: Pi/2
    else:
      Pi/2 - arccos(margin/distance)

  let angleRange =
    if rand(1f32) < 0.4:
      -getMaxAngle(1) .. getMaxAngle(0)
    elif prevObj.position.x < 0.5:
      -getMaxAngle(1) .. 0f32
    else:
      0f32 .. getMaxAngle(0)

  while true:
    let position = prevObj.position + rotate(rand(angleRange)) * vec2(0, -distance)
    let maxRadius = min(position.distanceToPlanets - planetsMinMargin, -(position.y + planetRadiusRange.a))
    if maxRadius > planetRadiusRange.a:
      spaceObjects.add:
        if lastRefuelOrbDistance > 3 and rand(6 - lastRefuelOrbDistance) == 0:
          lastRefuelOrbDistance = 0
          SpaceObject(kind: refuel, position: position, active: true)
        else:
          inc lastRefuelOrbDistance
          newPlanet(
            position,
            rand(planetRadiusRange.a .. min(planetRadiusRange.b, maxRadius))
          )
      break

proc updateGame*(dt: float32, gameIsOver: var bool) =
  updateShip(dt)
  if (let d = shipMinY - ship.position.y; d > 0):
    ship.position.y = shipMinY
    for obj in spaceObjects.mitems:
      obj.position.y += d

    scoreStep += d * 10
    if scoreStep > 1:
      inc score
      scoreStep -= 1

  refuelAnimTrans = min(1, refuelAnimTrans + dt*6)

  for obj in spaceObjects.mitems:
    if (
      obj.kind == refuel and obj.active and
      dist(ship.position, obj.position) < refuelOrbRadius+shipRadius
    ):
      ship.fuel = 1
      obj.active = false
      refuelAnimTrans = 0
      break
  
  if spaceObjects.last.position.y > -planetRadiusRange.a:
    addPlanet()
  block:
    let first = addr spaceObjects.first
    if first.position.y > viewHeight + first[].boundingRadius:
      spaceObjects.deleteHead()

  block:
    let distance = ship.position.distanceToPlanets
    if distance < shipRadius or ship.position.x notin -0.1..1.1 or ship.position.y > viewHeight:
      gameIsOver = true
    elif distance < cameraShakeDistance:
      cameraShake.radius = ((cameraShakeDistance - distance) / cameraShakeDistance)^2 * cameraShakeStrength
      if length(cameraShake.offset) > cameraShake.radius:
        cameraShake.direction = normalize(rotate(rand(2*Pi).float32) * vec2(cameraShake.radius, 0) - cameraShake.offset)
      cameraShake.offset += cameraShake.direction * dt * (cameraShake.radius / cameraShakeStrength)
    else:
      cameraShake.offset = vec2(0)  # just to be sure