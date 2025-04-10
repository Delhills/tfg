const uvec3 SURFEL_GRID_DIMENSIONS = uvec3(128, 64, 128) ; //(64, 32, 64)   (128, 64, 128)
const uint SURFEL_TABLE_SIZE = SURFEL_GRID_DIMENSIONS.x * SURFEL_GRID_DIMENSIONS.y * SURFEL_GRID_DIMENSIONS.z; //1048576, 131072
const float SURFEL_MAX_RADIUS = 1;
const uint SURFEL_CAPACITY = 100000;
const uint SURFEL_INDIRECT_NUMTHREADS = 32;
const float SURFEL_TARGET_COVERAGE = 0.5;


vec3 fakepos = vec3(0.0, 5.0, 5.0);

#define PI 3.14159265358979323846

const uint SURFEL_CELL_LIMIT = 100;

struct Surfel
{
	vec3 position;
    float pad0;
	vec3 normal;
    float pad1;
	vec3 color;
	float radius;
};


struct SurfelData
{
	vec3 mean;
	float pad0;

	vec3 shortMean;
	float vbbr;

	vec3 variance;
	float inconsistency;

	vec3 hitpos;
	float padding0;

	vec3 hitnormal;
	float padding1;

	vec3 hitenergy;
	float padding2;

	vec3 traceresult;
	float padding3;
};

bool surfel_cellvalid(ivec3 cell){
	if (cell.x < 0 || cell.x >= SURFEL_GRID_DIMENSIONS.x)
		return false;
	if (cell.y < 0 || cell.y >= SURFEL_GRID_DIMENSIONS.y)
		return false;
	if (cell.z < 0 || cell.z >= SURFEL_GRID_DIMENSIONS.z)
		return false;
	return true;
}

uint flatten3D(uvec3 coord, uvec3 dim)
{
	return (coord.z * dim.x * dim.y) + (coord.y * dim.x) + coord.x;
}

uint surfel_cellindex(ivec3 cell)
{
	return flatten3D(uvec3(cell), SURFEL_GRID_DIMENSIONS);
    // const uint p1 = 73856093;   // some large primes 
	// const uint p2 = 19349663;
	// const uint p3 = 83492791;
	// int n = int(p1 * pow(cell.x, p2) * pow(cell.y, p3) * cell.z);
	// n %= int(SURFEL_TABLE_SIZE);
	// return n;
}

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

ivec3 surfel_cell(vec3 position, vec3 campos){
	//return ivec3(floor((position - floor(campos)) / SURFEL_MAX_RADIUS) + SURFEL_GRID_DIMENSIONS / 2);

	return ivec3(floor((position - floor(campos)) / SURFEL_MAX_RADIUS) + SURFEL_GRID_DIMENSIONS / 2);
    //return ivec3(floor(position / SURFEL_MAX_RADIUS));
}

bool surfel_cellintersects(Surfel surfel, ivec3 cell, vec3 campos)
{
	if (!surfel_cellvalid(cell)){
		return false;
    }

    // vec3 gridmin = cell * SURFEL_MAX_RADIUS;
	// vec3 gridmax = (cell + 1) * SURFEL_MAX_RADIUS;

	vec3 gridmin = cell - SURFEL_GRID_DIMENSIONS / 2 * SURFEL_MAX_RADIUS + floor(campos);
	vec3 gridmax = (cell + 1) - SURFEL_GRID_DIMENSIONS / 2 * SURFEL_MAX_RADIUS + floor(campos);

	vec3 closestPointInAabb = min(max(surfel.position, gridmin), gridmax);
	float dist = distance(closestPointInAabb, surfel.position);
	if (dist < SURFEL_MAX_RADIUS){
		return true;
	}
	return false;
}

vec3 reconstructPosition(vec2 uv, float z, mat4 inverseProj)
{
	float x = uv.x * 2 - 1;
	//float y = (1 - uv.y) * 2 - 1;
    float y = uv.y * 2 - 1;
	vec4 position_s = vec4(x, y, z, 1);
	vec4 position_v = inverseProj * position_s;
	return position_v.xyz / position_v.w;
}

float getLinearDepth(float z, float near, float far)
{
	float z_n = 2 * z - 1;
	float lin = 2 * far * near / (near + far - z_n * (near - far));
	return lin;
}

float linearize_depth(float d,float zNear,float zFar)
{
    return zNear * zFar / (zFar + d * (zNear - zFar));
	// float z_n = 2.0 * d - 1.0;
    // return 2.0 * zNear * zFar / (zFar + zNear - z_n * (zFar - zNear));
}

const vec3 surfel_neighbor_offsets[27] = {
	vec3(-1, -1, -1),
	vec3(-1, -1, 0),
	vec3(-1, -1, 1),
	vec3(-1, 0, -1),
	vec3(-1, 0, 0),
	vec3(-1, 0, 1),
	vec3(-1, 1, -1),
	vec3(-1, 1, 0),
	vec3(-1, 1, 1),
	vec3(0, -1, -1),
	vec3(0, -1, 0),
	vec3(0, -1, 1),
	vec3(0, 0, -1),
	vec3(0, 0, 0),
	vec3(0, 0, 1),
	vec3(0, 1, -1),
	vec3(0, 1, 0),
	vec3(0, 1, 1),
	vec3(1, -1, -1),
	vec3(1, -1, 0),
	vec3(1, -1, 1),
	vec3(1, 0, -1),
	vec3(1, 0, 0),
	vec3(1, 0, 1),
	vec3(1, 1, -1),
	vec3(1, 1, 0),
	vec3(1, 1, 1),
};

mat3 GetTangentSpace(in vec3 normal)
{
	// Choose a helper vector for the cross product
	vec3 helper = abs(normal.x) > 0.99 ? vec3(0, 0, 1) : vec3(1, 0, 0);

	// Generate vectors
	vec3 tangent = normalize(cross(normal, helper));
	vec3 binormal = normalize(cross(normal, tangent));
	return mat3(tangent, binormal, normal);
}

float rand(inout float seed, in vec2 uv)
{
	float result = fract(sin(seed * dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
	seed += 1;
	return result;
}

vec3 hemispherepoint_cos(float u, float v) {
	float phi = v * 2 * PI;
	float cosTheta = sqrt(1 - u);
	float sinTheta = sqrt(1 - cosTheta * cosTheta);
	return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
}

vec3 SampleHemisphere_cos(in vec3 normal, inout float seed, in vec2 pixel)
{
	return (hemispherepoint_cos(rand(seed, pixel), rand(seed, pixel)) * GetTangentSpace(normal));
}