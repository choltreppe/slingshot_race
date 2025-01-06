import std/[options, random, sequtils, math]
import fusion/matching
import ./prelude, ./queue


const
  shipAccel = 0.2
  shipFuelUse = 0.14
  
  planetRadiusRange = 0.04 .. 0.12
  planetsMinMargin = 0.1
  planetMaxDistance = 0.6
  planetDistanceRange = planetRadiusRange.a+planetsMinMargin*1.1 .. planetMaxDistance+planetsMinMargin

  gravityStrength = 5

  cameraShakeDistance = 0.1
  cameraShakeStrength = 0.01


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
    of refuel:
      discard

var
  camera: Camera2D
  viewHeight: float32
  shipMinY: float32

  ship: Ship
  spaceObjects = newQueue[SpaceObject](cap = 16)
  lastRefuelOrbDistance: int32
  score: uint64
  scoreStep: float32
  cameraShake: tuple[
    radius: float32,
    direction: Vec2
  ]

randomize()

func newPlanet*(position: Vec2, radius: float32): SpaceObject =
  SpaceObject(kind: planet, position: position, radius: radius)

func boundingRadius*(obj: SpaceObject): float32 =
  case obj.kind
  of planet: obj.radius
  of refuel: 0.02

proc initGame* =
  let screenSize = vec2(float32 getScreenWidth(), float32 getScreenHeight())
  camera = Camera2D(zoom: screenSize.x)
  viewHeight = screenSize.y / screenSize.x
  shipMinY = viewHeight * 0.66

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

proc drawGame* =
  drawing:
    clearBackground(Black)
    drawText($score, 340, 10, 30, White)
    mode2D(camera):
      for obj in spaceObjects:
        drawCircleLines(obj.position, obj.boundingRadius):
          case obj.kind
          of planet: White
          of refuel: Blue
      drawCircle(ship.position, 0.01, White)

      block drawFuelBar:
        var rect = Rectangle(
          x: 0.02, y: 0.02,
          width: 0.4,
          height: 0.05
        )
        drawRectangleLines(rect, 0.005, White)
        rect.width *= ship.fuel
        drawRectangle(rect, White)

iterator planets: SpaceObject =
  for obj in spaceObjects:
    if obj.kind == planet:
      yield obj

proc gravityAt(position: Vec2): Vec2 =
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
    for (key, vec) in {
      Up: vec2(0, -1), Down: vec2(0, 1),
      Left: vec2(-1, 0), Right: vec2(1, 0),
    }:
      if isKeyDown(key):
        ship.velocity += vec * (shipAccel * dt)
        ship.fuel = max(0, ship.fuel - shipFuelUse*dt)

proc addPlanet =
  let prevObj = spaceObjects.last
  let distance = prevObj.boundingRadius + rand(planetDistanceRange)

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

  let newObjectKind =
    if rand(1f32) < 0.2: refuel
    else: planet

  while true:
    let position = prevObj.position + rotate(rand(angleRange)) * vec2(0, -distance)
    let maxRadius = min(position.distanceToPlanets - planetsMinMargin, -(position.y + planetRadiusRange.a))
    if maxRadius > planetRadiusRange.a:
      spaceObjects.add:
        if lastRefuelOrbDistance > 3 and rand(6 - lastRefuelOrbDistance) == 0:
          lastRefuelOrbDistance = 0
          SpaceObject(kind: refuel, position: position)
        else:
          inc lastRefuelOrbDistance
          newPlanet(
            position,
            rand(planetRadiusRange.a .. min(planetRadiusRange.b, maxRadius))
          )
      break

proc updateGame*(dt: float32) =
  updateShip(dt)
  if (let d = shipMinY - ship.position.y; d > 0):
    ship.position.y = shipMinY
    for obj in spaceObjects.mitems:
      obj.position.y += d

    scoreStep += d
    if scoreStep > 1:
      inc score
      scoreStep -= 1

  for obj in spaceObjects:
    if obj.kind == refuel and dist(ship.position, obj.position) < 0.04:
      ship.fuel = 1
      break
  
  if spaceObjects.last.position.y > -planetRadiusRange.a:
    addPlanet()
  if (
    (Some(@first) ?= spaceObjects.first) and
    first.position.y > viewHeight + first.boundingRadius
  ):
    spaceObjects.deleteHead()

  block:
    let distance = ship.position.distanceToPlanets
    if distance < 0 or ship.position.x notin -0.1..1.1 or ship.position.y > viewHeight:
      initGame()
    elif distance < cameraShakeDistance:
      cameraShake.radius = ((cameraShakeDistance - distance) / cameraShakeDistance)^2 * cameraShakeStrength
      debugEcho cameraShake.radius
      if length(camera.target) > cameraShake.radius:
        cameraShake.direction = normalize(rotate(rand(2*Pi).float32) * vec2(cameraShake.radius, 0) - camera.target)
      camera.target += cameraShake.direction * dt * (cameraShake.radius / cameraShakeStrength)
    else:
      camera.target = vec2(0)  # just to be sure