const vec3 randSeed = vec3(19.427, 84.31, 87.9081);
const float radius = 0.8;
const float craterScale = 2.6;
const float inset = 0.1;
const vec3 sun = normalize(vec3(0.3, 0.5, 0.3));

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
    float zs = radius*radius - uv.x*uv.x - uv.y*uv.y;
    if (zs < 0.0) return -1;
    else {
        vec3 p = vec3(uv, sqrt(zs));
        inShadow = dot(normalize(p), sun) < 0.0;
        if (randomSpheres(p*craterScale + fract(randSeed))) return 1;
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

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = (fragCoord/iResolution.yy - vec2(0.5)) * 2.0;
    bool inShadow = false;
    int t = surfaceType(uv, inShadow);
    switch (t) {
        case 0:
            if (inShadow) fragColor = vec4(vec3(0.5), 1.0);
            else fragColor = vec4(1.0);
            break;
        case 1:
            if (inShadow) fragColor = vec4(vec3(0.3), 1.0);
            else fragColor = vec4(vec3(0.7), 1.0);
            break;
        case 2:
            fragColor = vec4(vec3(0.3), 1.0);
    }
}