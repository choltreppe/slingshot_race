import std/[options, random, sequtils, math]
import fusion/matching
import ./prelude, ./queue


const
  shipAccel = 0.15
  shipFuelUse = 0.1
  
  planetRadiusRange = 0.04 .. 0.12
  planetsMinMargin = 0.1
  planetMaxDistance = 0.4
  planetDistanceRange = planetRadiusRange.a+planetsMinMargin*1.1 .. planetMaxDistance+planetsMinMargin

  gravityStrength = 5

  cameraShakeDistance = 0.1
  cameraShakeStrength = 0.01


type
  Ship = object
    position, velocity: Vec2
    fuel: float32 = 1

  Planet = object
    position: Vec2
    radius: float32

  FuelOrb = object
    position: Vec2
    fuel: float32

var
  camera: Camera2D
  viewHeight: float32
  shipMinY: float32

  ship: Ship
  space = (
    planets: newQueue[Planet](cap = 16),
    fuelOrbs: newQueue[FuelOrb](cap = 10),
  )
  score: uint64
  scoreStep: float32
  cameraShake: tuple[
    radius: float32,
    direction: Vec2
  ]

randomize()


func radius(orb: FuelOrb): float32 = orb.fuel * 0.02

proc initGame* =
  let screenSize = vec2(float32 getScreenWidth(), float32 getScreenHeight())
  camera = Camera2D(zoom: screenSize.x)
  viewHeight = screenSize.y / screenSize.x
  shipMinY = viewHeight * 0.66

  ship = Ship(position: vec2(0.5, shipMinY))
  for objs in space.fields:
    clear objs
  space.planets &= Planet(
    position: vec2(rand(1f32), 0),
    radius: rand(planetRadiusRange)
  )
  score = 0
  scoreStep = 0

  cameraShake.direction = vec2(1, 0)

proc drawGame* =
  drawing:
    clearBackground(Black)
    drawText($score, 340, 10, 30, White)
    mode2D(camera):
      for planet in space.planets:
        drawCircleLines(planet.position, planet.radius, White)
      for orb in space.fuelOrbs:
        drawCircle(orb.position, orb.radius, Blue)
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

proc gravityAt(position: Vec2): Vec2 =
  for planet in space.planets:
    let v = planet.position - position
    let distance = length(v)
    let direction = normalize(v)
    result += float32(max(0, 1/distance^2 - 0.1) * planet.radius^3) * direction
  result *= gravityStrength

proc distanceToPlanets(position: Vec2): float32 =
  result = high(float32)
  for planet in space.planets:
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
  let prevPlanet = space.planets.last
  let distance = prevPlanet.radius + rand(planetDistanceRange)

  proc getMaxAngle(borderX: float32): float32 =
    let margin = abs(borderX - prevPlanet.position.x)
    if margin > distance: Pi/2
    else:
      Pi/2 - arccos(margin/distance)

  let angleRange =
    if rand(1f32) < 0.4:
      -getMaxAngle(1) .. getMaxAngle(0)
    elif prevPlanet.position.x < 0.5:
      -getMaxAngle(1) .. 0f32
    else:
      0f32 .. getMaxAngle(0)

  var newPlanet: Planet
  while true:
    let position = prevPlanet.position + rotate(rand(angleRange)) * vec2(0, -distance)
    let maxRadius = min(position.distanceToPlanets - planetsMinMargin, -(position.y + planetRadiusRange.a))
    if maxRadius > planetRadiusRange.a:
      newPlanet = Planet(
        position: position,
        radius: rand(planetRadiusRange.a .. min(planetRadiusRange.b, maxRadius))
      )
      space.planets &= newPlanet
      break

  let surfaceDistance = distance - prevPlanet.radius - newPlanet.radius
  if surfaceDistance < 2*planetsMinMargin:
    let position = newPlanet.position + normalize(prevPlanet.position - newPlanet.position) * (newPlanet.radius + surfaceDistance/2)
    if position.x in 0.3 .. 0.7:
      space.fuelOrbs &= FuelOrb(position: position, fuel: 1)

proc updateGame*(dt: float32) =
  updateShip(dt)
  if (let d = shipMinY - ship.position.y; d > 0):
    ship.position.y = shipMinY
    for objs in space.fields:
      for obj in objs.mitems:
        obj.position.y += d

    scoreStep += d
    if scoreStep > 1:
      inc score
      scoreStep -= 1

  for orb in space.fuelOrbs:
    if dist(ship.position, orb.position) < orb.radius+0.01:
      ship.fuel = 1
      break
  
  if space.planets.last.position.y > -planetRadiusRange.a:
    addPlanet()
  for objs in space.fields:
    if (
      (Some(@first) ?= objs.first) and
      first.position.y > viewHeight + first.radius
    ):
      objs.deleteHead()

  block:
    let distance = ship.position.distanceToPlanets
    if distance < 0 or ship.position.x notin -0.1..1.1 or ship.position.y > viewHeight:
      quit 0
    elif distance < cameraShakeDistance:
      cameraShake.radius = ((cameraShakeDistance - distance) / cameraShakeDistance)^2 * cameraShakeStrength
      if length(camera.target) > cameraShake.radius:
        cameraShake.direction = rotate(rand(2*Pi).float32) * vec2(1, 0) - camera.target
      camera.target += cameraShake.direction * dt * (cameraShake.radius / cameraShakeStrength)