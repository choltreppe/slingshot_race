import shady, vmath


proc vertShaderImpl(
  mvp: Uniform[Mat4],
  vertexPosition: Vec3,
  fragPosition: var Vec3,
  gl_Position: var Vec4,
) =
  fragPosition = vertexPosition
  gl_Position = mvp*vec4(vertexPosition, 1.0)

const vertShader* = toGLSL(vertShaderImpl)


#const sunDirection = getNormalize(vec3(-0.2, 0.6, 1))

func hash1(n: float32): float32 =
  fract( n*17.0*fract( n*0.3183099 ) )

func noise(x: Vec3): float32 =

  let p = floor(x)
  let w = fract(x)
  
  when true:
    let u = w*w*w*(w*(w*6.0-15.0)+10.0)
  else:
    let u = w*w*(3.0-2.0*w)
  
  let
    n = p.x + 317.0*p.y + 157.0*p.z
  
    a = hash1(n+0.0)
    b = hash1(n+1.0)
    c = hash1(n+317.0)
    d = hash1(n+318.0)
    e = hash1(n+157.0)
    f = hash1(n+158.0)
    g = hash1(n+474.0)
    h = hash1(n+475.0)

    k0 =   a
    k1 =   b - a
    k2 =   c - a
    k3 =   e - a
    k4 =   a - b - c + d
    k5 =   a - c - e + g
    k6 =   a - b - e + f
    k7 = - a + b + c - d + e - f - g + h

  return k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z

func mountainNoise(p: Vec3): float32 =
  0.5 * (
    noise((p + vec3(2, 5, 4))) +
    noise((p + vec3(7, 1, 9))*2)/2 +
    noise((p + vec3(0, 3, 2))*4)/4 +
    noise((p + vec3(1, 8, 8))*8)/8
  )

proc planetShaderImpl(
  noiseOffset: Uniform[Vec3],
  fragPosition: Vec3,
  finalColor: var Vec4,
) =

  proc getDistance(p: Vec3): float32 =
    length(p) - 0.8 -
    mountainNoise((normalize(p)+noiseOffset)*2).max(0.3) * 0.2

  proc getNormal(p: Vec3): Vec3 =
    let e = vec2(0.0001, 0)
    let d = getDistance(p)
    return normalize(vec3(
      d - getDistance(p-e.xyy),
      d - getDistance(p-e.yxy),
      d - getDistance(p-e.yyx),
    ))

  proc march(r0, rd: Vec3): Vec3 =
    result = r0
    var d = getDistance(result)
    while true:
      result += d * rd
      d = getDistance(result)
      if d < 0.0001 or length(result) > 2:
        break

  let sun: Vec3 = normalize(vec3(-0.2, -0.6, -1))

  let screenPos = (fragPosition.xy * 2) - vec2(1)
  let p = march(vec3(screenPos, 1), vec3(0, 0, -1))
  if getDistance(p) < 0.0002:
    let n = getNormal(p)
    let lightAngle = dot(n, -sun)
    var color = vec3(0.7, 0.68, 0.65) * (max(0.4, lightAngle) - 0.3)
    #if getDistance(march(p, -sun)) < 0.00005:
    #  color = vec3(0)
    color += vec3(0.7, 0.8, 1.0) * (0.6 * (1 - dot(n, vec3(0, 0, 1)).clamp(0, 0.6)/0.6))
    finalColor = vec4(color, 1)
  else:
    finalColor = vec4(0)

const planetFragShader* = toGLSL(planetShaderImpl)

debugEcho planetFragShader