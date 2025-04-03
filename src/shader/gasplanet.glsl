#version 410
precision highp float;

uniform vec3 randSeed;
uniform float radius;
uniform vec3 color;
uniform vec3 sun;

in vec3 fragPosition;
out vec4 finalColor;

float hash(float n){
    return fract( n*17.0*fract( n*0.3183099 ) );
}

float noise(vec3 x){
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);

    float n = p.x + 317.0*p.y + 157.0*p.z;
    
    float a = hash(n+0.0);
    float b = hash(n+1.0);
    float c = hash(n+317.0);
    float d = hash(n+318.0);
    float e = hash(n+157.0);
  float f = hash(n+158.0);
    float g = hash(n+474.0);
    float h = hash(n+475.0);

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z;
}

float fractalNoise(vec3 p) {
    float result = 0.0;
    for (float i = 2.0; i < 10.0; i *= 2.0)
        result += noise(p*i + fract(randSeed*i)) / i;
    return result;
}

void main() {
    vec2 uv = fragPosition.xy*2.0 - vec2(1.0);
    float zs = 1.0 - uv.x*uv.x - uv.y*uv.y;
    if (zs < 0.0)
        finalColor = vec4(0.0);
    else {
        finalColor = vec4(color, 1.0);
        vec3 p = vec3(uv, sqrt(zs));
        float n = fractalNoise(cross(p,normalize(randSeed))*vec3(1.0, 8.0, 1.0)*8.0*radius);
        if (n < 0.3)
            finalColor.rgb *= vec3(1.4, 1.2, 1.2);
        else if (n < 0.6)
            finalColor.rgb *= vec3(0.6, 0.8, 0.6);
        if (dot(normalize(p), sun) < 0.0)
            finalColor.rgb = mix(finalColor.rgb, vec3(0.0, 0.0, 0.2), 0.4);
        else
            finalColor.rgb += vec3(0.2, 0.2, 0.1);
    }
}