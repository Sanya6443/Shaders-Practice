float random2(int x, int y, int z)
{
    int n = int(x * 374761393 + y * 668265263 + z * 462685258);
    uint u_n = uint(n);
    u_n = (u_n ^ (u_n >> 13u)) * 1274126177u;
    n = int(u_n);
    uint masked_n = uint(n) & 0x7FFFFFFFu;
    return float(masked_n) / 2147483647.0; 

}
float lerp(float a, float b, float c)
{
    return a + (b - a) * c;
}
float smooth2(float t)
{
    return t * t * (3.0 - 2.0 * t);
}
float noice(vec3 v)
{
    int x0 = int(floor(v.x));
    int y0 = int(floor(v.y));
    int z0 = int(floor(v.z));

    int x1 = x0 + 1;
    int y1 = y0 + 1;
    int z1 = z0 + 1;

    float v000 = random2(x0, y0, z0);
    float v001 = random2(x0, y0, z1);
    float v010 = random2(x0, y1, z0);
    float v011 = random2(x0, y1, z1);
    float v100 = random2(x1, y0, z0);
    float v110 = random2(x1, y1, z0);
    float v111 = random2(x1, y1, z1);
    float v101 = random2(x1, y0, z1);

    float fx = v.x - float(x0);
    float fy = v.y - float(y0);
    float fz = v.z - float(z0);
    
    float sx = smooth2(fx);
    float sy = smooth2(fy);
    float sz = smooth2(fz);

    float x_low_y0 = lerp(v000, v100, sx);
    float x_low_y1 = lerp(v010, v110, sx);
    float y_low = lerp(x_low_y0, x_low_y1, sy);

    float x_high_y0 = lerp(v001, v101, sx);
    float x_high_y1 = lerp(v011, v111, sx);
    float y_high = lerp(x_high_y0, x_high_y1, sy);

    return lerp(y_low, y_high, sz);
}
float cloudNoise(vec3 v) {
    vec3 p = v + vec3(iTime * 0.5, 0.0, 0.0);
    float sum = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for(int i = 0; i < 4; i++) {
        sum += noice(p * freq) * amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    
    float density = sum - 0.45;
    return clamp(density * 3.0, 0.0, 1.0);
}

float getLight(vec3 pos, vec3 lightDir) {
    float lightStep = 0.2;
    float shadowDensity = 0.0;
    for(int i = 1; i <= 5; i++) {
        shadowDensity += cloudNoise(pos + lightDir * lightStep * float(i));
    }
    
    float beer = exp(-shadowDensity * 3.0);
    float powder = 1.0 - exp(-shadowDensity * 6.0);
    
    return beer * powder * 2.0;
}




vec4 rayMarching(vec3 origin, vec3 dir, float stepsize, vec3 lightDir) {
    float transmission = 1.0;
    vec3 lightAccum = vec3(0.0);
    float t = 0.0;

    for (int i = 0; i < 20; i++) {
        vec3 pos = origin + dir * t;
        float d = cloudNoise(pos);

        if (d > 0.001) {
            float intensity = getLight(pos, lightDir);
            float stepDensity = d * stepsize;

            vec3 sliceColor = mix(vec3(0.3, 0.4, 0.5), vec3(1.0), intensity);
            
            lightAccum += sliceColor * stepDensity * transmission;
            transmission *= exp(-stepDensity * 4.0);
        }

        t += stepsize;
        if (transmission < 0.01) break;
    }
    return vec4(lightAccum, transmission);
}



void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec3 ro = vec3(0.0, 0.0, -2.5);
    vec3 rd = normalize(vec3(uv, 1.2));
    vec3 lightDir = normalize(vec3(0.5, 0.5, -0.5));

    vec4 scene = rayMarching(ro, rd, 0.15, lightDir);
    vec3 cloudCol = scene.xyz;
    float transmission = scene.w;

    vec3 skyColor = mix(vec3(0.1, 0.1, 0.1), vec3(0.6, 0.6, 0.6), uv.y * 0.5 + 0.5);
    
    float sunFocus = pow(max(dot(rd, lightDir), 0.0), 8.0);
    vec3 sunGlow = vec3(1.0, 0.8, 0.5) * sunFocus * (1.0 - transmission);

    vec3 finalColor = skyColor * transmission + cloudCol + sunGlow;

    finalColor = pow(finalColor, vec3(0.8)); 
    
    fragColor = vec4(finalColor, 1.0);
}
