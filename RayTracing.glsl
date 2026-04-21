float hitSphere(vec3 rayOr, vec3 dir, vec3 center, float radius) {
    vec3 oc = rayOr - center;
    float a = dot(dir, dir);
    float h = dot(oc, dir);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = h*h - a*c;
    if (discriminant < 0.0) return -1.0;
    return (-h - sqrt(discriminant)) / a;
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    uv = floor(uv * 100.0) / 100.0;    
    vec3 cam = vec3(0.0, 0.0, -3.0);
    
    float fov = 70.0;
    float r = tan(radians(fov) * 0.5);
    vec3 dir = normalize(vec3(uv * r, 1.0));
    
    vec2 mouse = iMouse.xy / iResolution.xy; 
    if(iMouse.z <= 0.0) mouse = vec2(0.5);

    float pitch = (mouse.y - 0.5) * 3.14;
    float yaw = (mouse.x - 0.5) * 6.28; 

    dir.yz *= rot(pitch);
    dir.xz *= rot(yaw);    vec3 sphere = vec3(0.0, 0.0, 0.0);
    
    float t = hitSphere(cam, dir, sphere, 1.0);
    vec3 col = vec3(0.1,0.3,1.0); 

    if (t > 0.0) {
        vec3 hitPoint = cam + t * dir;
        vec3 N = normalize(hitPoint - sphere);
        
        float u = atan(N.z, N.x) / (2.0 * 3.1415) + 0.5;
        float v = asin(N.y) / 3.1415 + 0.5;
        
        float grid = sin(u * 40.0) * sin(v * 20.0);
        grid = smoothstep(0.0, 0.01, grid);
        
        vec3 baseColor = mix(vec3(0.8, 0.1, 0.1), vec3(0.8, 0.9, 1.0), grid);
        
        vec3 L = normalize(vec3(1.0 , 1.0, -1.0));
        vec3 V = -dir;
        float diff = max(dot(N, L), 0.0);
         vec3 H = normalize(L + V);
        float spec = pow(max(dot(N, H), 0.0),34.0);
        
        col = baseColor * (diff + 0.1) + vec3(1.0) * spec; 
        
    }
    
    fragColor = vec4(pow(col, vec3(1.0/2.2)), 1.0);
}
