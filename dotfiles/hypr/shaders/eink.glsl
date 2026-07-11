#version 320 es

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

float getBayer(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));

    const mat4 bayer = mat4(
         0.0, 12.0,  3.0, 15.0,
         8.0,  4.0, 11.0,  7.0,
         2.0, 14.0,  1.0, 13.0,
        10.0,  6.0,  9.0,  5.0
    );

    return bayer[x][y] / 16.0;
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    float gray = dot(pixColor.rgb, vec3(0.299, 0.587, 0.114));

    gray = pow(gray, 1.08);

    float contrast = 1.10;
    gray = (gray - 0.5) * contrast + 0.5;

    gray = mix(gray, sqrt(max(gray, 0.0)), 0.18);

    float bayerValue = getBayer(gl_FragCoord.xy);
    float ditherMask = smoothstep(0.18, 0.92, gray);
    gray += (bayerValue - 0.5) * 0.010 * ditherMask;

    gray = clamp(gray, 0.0, 1.0);
    
    vec3 paperColor = vec3(0.94, 0.89, 0.78);
    vec3 inkColor   = vec3(0.075, 0.076, 0.078);
    
    vec3 finalColor = mix(inkColor, paperColor, gray);

    fragColor = vec4(finalColor, pixColor.a);
}
