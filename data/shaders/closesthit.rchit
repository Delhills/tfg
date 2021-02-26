#version 460
#extension GL_EXT_ray_tracing : require
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_EXT_scalar_block_layout : enable
#extension GL_GOOGLE_include_directive : enable

#include "raycommon.glsl"
#include "helpers.glsl"

layout(location = 0) rayPayloadInEXT hitPayload prd;
layout(location = 1) rayPayloadEXT bool shadowed;
hitAttributeEXT vec3 attribs;

layout(set = 0, binding = 0) uniform accelerationStructureEXT topLevelAS;
layout(set = 0, binding = 3, scalar) buffer Vertices { Vertex v[]; } vertices[];
layout(set = 0, binding = 4) buffer Indices { int i[]; } indices[];
layout(set = 0, binding = 5, scalar) buffer Matrices { mat4 m[]; } matrices;
layout(set = 0, std140, binding = 6) buffer Lights { Light lights[]; } lightsBuffer;
layout(set = 0, binding = 7) buffer MaterialBuffer { Material mat[]; } materials;
layout(set = 0, binding = 8) buffer sceneBuffer { vec4 idx[]; } objIndices;
layout(set = 0, binding = 9) uniform sampler2D[] textures;

void main()
{
  // Do all vertices, indices and barycentrics calculations
  const vec3 barycentricCoords = vec3(1.0f - attribs.x - attribs.y, attribs.x, attribs.y);

  vec4 objIdx = objIndices.idx[gl_InstanceCustomIndexEXT];

  int instanceID        = int(objIdx.x);
  int materialID        = int(objIdx.y);
  int transformationID  = int(objIdx.z);
  int firstIndex        = int(objIdx.w);

  ivec3 ind     = ivec3(indices[instanceID].i[3 * gl_PrimitiveID + firstIndex + 0], 
                        indices[instanceID].i[3 * gl_PrimitiveID + firstIndex + 1], 
                        indices[instanceID].i[3 * gl_PrimitiveID + firstIndex + 2]);

  Vertex v0     = vertices[instanceID].v[ind.x];
  Vertex v1     = vertices[instanceID].v[ind.y];
  Vertex v2     = vertices[instanceID].v[ind.z];

  mat4 model = matrices.m[transformationID];

  // Use above results to calculate normal vector
  // Calculate worldPos by using ray information
  vec3 normal   = v0.normal.xyz * barycentricCoords.x + v1.normal.xyz * barycentricCoords.y + v2.normal.xyz * barycentricCoords.z;
  vec2 uv       = v0.uv.xy * barycentricCoords.x + v1.uv.xy * barycentricCoords.y + v2.uv.xy * barycentricCoords.z;
  vec3 N        = normalize(model * vec4(normal, 0)).xyz;
  vec3 worldPos = gl_WorldRayOriginEXT + gl_WorldRayDirectionEXT * gl_HitTEXT;

  // Init values used for lightning
	vec3 color = vec3(0);
	float attenuation = 1.0;
  float shadowFactor = 0.0;
  float light_intensity = 1.0;

  Material mat    = materials.mat[materialID];
  int shadingMode = int(mat.shadingMetallicRoughness.x);
  vec3 albedo     = mat.textures.x > -1 ? texture(textures[int(mat.textures.x)], uv).xyz : vec3(1);
  vec3 emissive   = mat.textures.z > -1 ? texture(textures[int(mat.textures.z)], uv).xyz : vec3(0);

  // Calculate light influence for each light
  for(int i = 0; i < lightsBuffer.lights.length(); i++)
  {
    // Init basic light information
    Light light = lightsBuffer.lights[i];
    bool isDirectional = light.pos.w < 0;

		vec3 L                    = isDirectional ? light.pos.xyz : light.pos.xyz - worldPos;
		float light_max_distance  = light.pos.w;
		float light_distance      = length(L);
    L                         = normalize(L);
		float NdotL               = clamp(dot(N, L), 0.0, 1.0);
		light_intensity           = isDirectional ? 1.0 : light.color.w / (light_distance * light_distance);

    // Check if light has impact, then calculate shadow
    if( NdotL > 0 )
    {
      // init as shadowed
      shadowed = true;
      
      //L = vec3(0, 1, 0);
      //vec3 perpL = normalize(cross(L, vec3(0, 1, 0)));
      //if(perpL == vec3(0.0))
      //  perpL = vec3(1.0, 0.0, 0.0);
      
      // We get a vector from origin to the edge of the light
      //const vec3 toLightEdge = normalize((light.pos.xyz + perpL * 5.0) - worldPos);
      const float phi = rnd(prd.seed) * 2 * PI;
      const float cosTheta = (rnd(prd.seed) - 0.5) * 2;
      const float u = rnd(prd.seed);

      const float theta = acos(cosTheta);
      const float r = 2 * pow(u, 1/3);

      const float x = r * sin(theta) * cos(phi);
      const float y = r * sin(theta) * sin(phi);
      const float z = r * cos(theta);

      //calculate the angle betwee L and toLightEdge and multiply by 2
      //const float angle = acos(dot(L, toLightEdge)) * 2.0;

      //vec3 dir = uniformSampleCone(rnd(prd.seed), rnd(prd.seed), angle);
      //mat3 R = AngleAxis3x3(angle, L);//makeDirectionMatrix(L);
      //dir = R * dir;
      vec3 dir = L;
      //const vec3 dir = getConeSample(prd.seed, L, angle);
      //const vec3 dir = normalize(vec3(x, y, z) - worldPos);

      // Shadow ray cast
      float tmin = 0.001, tmax = light_distance + 1;
      traceRayEXT(topLevelAS, 
        gl_RayFlagsOpaqueEXT | gl_RayFlagsTerminateOnFirstHitEXT | gl_RayFlagsSkipClosestHitShaderEXT, 
        0xFF, 
        1, 0, 1, 
        worldPos + dir * 1e-2, tmin, 
        dir, tmax, 
        1);

        if(!shadowed)
        {
          shadowFactor++;
        }
    }

    // Calculate attenuation factor
		attenuation = light_max_distance - light_distance;
		attenuation /= light_max_distance;
		attenuation = max(attenuation, 0.0);
		attenuation = attenuation * attenuation;

    vec3 difColor = vec3(0);

    if(shadingMode == 0)  // DIFUS
    {
      difColor  = computeDiffuse(mat, N, L) * albedo;
      color    += difColor * light_intensity * light.color.xyz * attenuation * shadowFactor;
      color    += emissive;
      prd       = hitPayload(vec4(color, gl_HitTEXT), vec4(1, 1, 1, 0), worldPos, prd.seed);
    }
    else if(shadingMode == 3) // MIRALL
    {
      const vec3 reflected    = reflect(normalize(gl_WorldRayDirectionEXT), N);
      const bool isScattered  = dot(reflected, N) > 0;

      difColor = isScattered ? computeDiffuse(mat, N, L) : vec3(1);
      //specular = computeSpecular(mat, N, L, -gl_WorldRayDirectionEXT);
      color += difColor * light_intensity * light.color.xyz * attenuation * shadowFactor;

      prd = hitPayload(vec4(color, gl_HitTEXT), vec4(reflected, isScattered ? 1 : 0), worldPos, prd.seed);
    }
    else if(shadingMode == 4) // VIDRE
    {
      const float ior       = mat.diffuse.w;
      const float NdotV     = dot( N, normalize(gl_WorldRayDirectionEXT) );
			const vec3 refrNormal = NdotV > 0.0 ? -N : N;
			const float refrEta   = NdotV > 0.0 ? 1 / ior : ior;

      color += mat.diffuse.xyz * light_intensity * light.color.xyz;

      float radicand = 1 + pow(refrEta, 2.0) * (NdotV * NdotV - 1);
			const vec3 direction = radicand < 0.0 ? 
                  reflect(gl_WorldRayDirectionEXT, N) : 
                  refract( gl_WorldRayDirectionEXT, refrNormal, refrEta );

      prd = hitPayload(vec4(color, gl_HitTEXT), vec4(direction, 1), worldPos, prd.seed);
    }
  }
  //prd.colorAndDist.xyz = N;
}