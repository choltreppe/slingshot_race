#version 330

uniform int planetCount;
uniform vec2[12] planetPositions;
uniform float[12] planetRadii;

uniform int refuelCount;
uniform vec2[12] refuelPositions;
uniform float refuelRadius;

in vec3 fragPosition;
out vec4 finalColor;

void main() {
  finalColor = vec4(0.0);
  for (int i = 0; i < planetCount; i++) {
    if (distance(planetPositions[i], fragPosition.xy) < planetRadii[i]) {
      finalColor = vec4(1.0);
      return;
    }
  }
  for (int i = 0; i < refuelCount; i++) {
    if (distance(refuelPositions[i], fragPosition.xy) < refuelRadius) {
      finalColor = vec4(0.0, 0.0, 1.0, 1.0);
      return;
    }
  }
}