#version 410
precision highp float;

uniform vec3 randSeed;
uniform float radius;
uniform vec3 color;
uniform vec3 sun;

const float craterScale = 14.0;
const float inset = 0.1;

in vec3 fragPosition;
out vec4 finalColor;

float rand(vec3 p){
    return fract(sin(dot(p, vec3(12.9898, 78.233, 7.1845))) * 43758.5453);
}

bool randomSpheres(vec3 p) {
    vec3 id = floor(p);
    vec3 uv = fract(p);
    vec3 c = fract(randSeed*rand(id))*0.5 + 0.25;
    float maxr = 0.5 - distance(c, vec3(0.5));
    float r = maxr*0.9;
    return (distance(uv, c) - r) < 0.0;
}

// -1 = space; 0 = surface; 1 = crater; 2 = crater-rim
int surfaceTypeV1(vec2 uv, out bool inShadow) {
    float zs = 1 - uv.x*uv.x - uv.y*uv.y;
    if (zs < 0.0) return -1;
    else {
        vec3 p = vec3(uv, sqrt(zs));
        inShadow = dot(normalize(p), sun) < 0.0;
        vec3 x = p*craterScale*radius + fract(randSeed);
        if (
            randomSpheres(x) ||
            randomSpheres(x + floor(randSeed) + vec3(0.5))
        ) return 1;
        else return 0;
    }
}
int surfaceType(vec2 uv, out bool inShadow) {
    int t = surfaceTypeV1(uv, inShadow);
    if (t != 1) return t;
    else if (surfaceTypeV1(uv * (1.0+inset), inShadow) == 1)
        return 1;
    else return 2;
}

void main() {
    vec2 uv = fragPosition.xy*2.0 - vec2(1.0);

    vec3 colorLight = color + vec3(0.2, 0.2, 0.1);
    vec3 colorShadow = mix(color, vec3(0.0, 0.0, 0.2), 0.4);
    vec3 colorDarkest = mix(color, vec3(0.0, 0.0, 0.24), 0.6);

    bool inShadow = false;
    int t = surfaceType(uv, inShadow);
    finalColor.a = 1.0;
    switch (t) {
        case 0:
            if (inShadow) finalColor.rgb = colorShadow;
            else finalColor.rgb = colorLight;
            break;
        case 1:
            if (inShadow) finalColor.rgb = colorDarkest;
            else finalColor.rgb = color;
            break;
        case 2:
            finalColor.rgb = colorDarkest;
            break;
        default:
            finalColor = vec4(0.0);
    }
}