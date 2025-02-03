#version 410
precision highp float;

uniform mat4 mvp;
in vec3 vertexPosition;
out vec3 fragPosition;

void main() {
  fragPosition = vertexPosition;
  gl_Position = mvp*vec4(vertexPosition, 1.0);
}