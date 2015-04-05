

#define OT_SCALE     1000.0

typedef unsigned int uint32_t;
typedef signed int int32_t;

float min(float a, float b);
float max (float a, float b);


typedef struct
{
	uint32_t fb_adr;
	uint32_t masks;
	uint32_t tx0, ty0, tz0;
	uint32_t tx1, ty1, tz1;
} __attribute__((packed)) RayData;

typedef struct {
	float x, y, z;
	} Vector3f;
	
void vec3f_set(Vector3f *vec, float x, float y, float z);
void vec3f_normalize(Vector3f *vec);

typedef struct {
    Vector3f o;
    Vector3f d;
	} Ray;

typedef struct {
    Vector3f o;
    float rotX;
    float rotY;
    float rotZ;
    
	} Camera;

Vector3f calcCameraRay(Camera *cam, int width, int height, int x, int y);

typedef void (*write_word_cb)(uint32_t word);

// int writeRay(Ray r, uint32_t fb_adr, int x, int y);
int writeFrame(write_word_cb writeWord, Camera *cam, int w, int h, unsigned int fb_adr);
