#version 410
precision highp float;

const vec3 randSeed = vec3(2783.44, 893.2317, 4.9341);

uniform float ratio;
uniform float yScroll;

in vec3 fragPosition;
out vec4 finalColor;

float rand(vec3 p){
    return fract(sin(dot(p, vec3(12.9898, 78.233, 7.1845))) * 43758.5453);
}

float distLinePoint(vec3 p, vec3 v) {
    float a = dot(p, normalize(v));
    return sqrt(length(p)*length(p) - a*a);
}

void main() {
    vec2 uv = fragPosition*2.0 - vec2(1.0, ratio);
    uv *= 0.3;
    
    vec3 r = vec3(uv, 1.0);
    for (float i = 5.0; i < 14.0; i += 1.0) {
        vec3 p = r*i;
        p.y += yScroll;
        vec3 id = floor(p);
        vec3 c = fract(randSeed*rand(id))*0.5 + 0.25;
        float d = distLinePoint(c - fract(p), r);
        if (d < 0.01)
            fragColor = vec4(1.0);
    }
}