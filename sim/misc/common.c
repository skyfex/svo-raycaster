#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "common.h"

float min(float a, float b)
{
   return a<=b?a:b;
}
float max (float a, float b)
{
   return a>=b?a:b;
}
float fabs (float a)
{
   if (a<0) return -a;
   else  return a;
}


void vec3f_set(Vector3f *vec, float x, float y, float z)
{
	vec->x = x; vec->y = y; vec->z = z;
}
void vec3f_normalize(Vector3f *vec)
{
	float len = sqrt(vec->x*vec->x+vec->y*vec->y+vec->z*vec->z);
	vec->x /= len; vec->y /= len; vec->z /= len;
}

Vector3f calcCameraRay(Camera *cam, int width, int height, int x, int y)
{
   
   Vector3f ray;
   float dx = (float)x/(float)width;
   float dy = (float)y/(float)height;
   float aspect = (float)height/(float)width;
   
   float rx = -(dx-0.5)*2;
   float ry = (dy-0.5)*aspect*2;
   
	vec3f_set(&ray, rx, ry, 1.0);
	vec3f_normalize(&ray);
	
   
	// float len = sqrt(rx*rx + ry*ry + 1);
	// ray.x = rx/len; ray.y = ry/len; ray.z = 1.0f/len;
	   
   return ray;
}

int writeRay(write_word_cb writeWord, Ray r, uint32_t fb_adr, int x, int y)
{
	uint32_t dir_mask;
   dir_mask=0;
   
   // printf("%f %f %f\n", r.d.x, r.d.y, r.d.z);
   // printf("%f %f %f\n", r.o.x, r.o.y, r.o.z);
   
   if (r.d.x==0) 
      r.d.x+=0.001; 
   if (r.d.x<0.0) {
      r.o.x = -r.o.x;
      r.d.x = -r.d.x;
      dir_mask |= 4;
   }
   if (r.d.y==0) 
      r.d.y+=0.001;
   if (r.d.y<0.0) {
      r.o.y = -r.o.y; 
      r.d.y = -r.d.y;
      dir_mask |= 2;
   }
   if (r.d.z==0)  
      r.d.z+=0.001; 
   if (r.d.z<0.0) {
      r.o.z = -r.o.z;
      r.d.z = -r.d.z;
      dir_mask |= 1;
   }
   
   

   float size = 100;
   float x0, y0, z0;
   float x1, y1, z1;
   float tx0, tx1, ty0, ty1, tz0, tz1;
   x0 = y0 = z0 = -size/2;
   x1 = y1 = z1 = size/2;
   

   // printf("%f %f %f , %f %f %f\n", x0, y0, z0, x1, y1, z1);
         
   tx0 = (min(x0, x1)-r.o.x)/r.d.x;
   tx1 = (max(x0, x1)-r.o.x)/r.d.x;
   ty0 = (min(y0, y1)-r.o.y)/r.d.y;
   ty1 = (max(y0, y1)-r.o.y)/r.d.y;
   tz0 = (min(z0, z1 )-r.o.z)/r.d.z;
   tz1 = (max(z0, z1 )-r.o.z)/r.d.z;
   
   // printf("Init:\n\t%f %f %f\n\t%f %f %f\n", 
   //                       tx0, ty0, tz0,
   //                        tx1, ty1, tz1);
   // printf("\tdir_mask: %d\n", dir_mask);

   float t_min = min(tx0,min(ty0,tz0));
   float t_max = max(tx1,max(ty1,tz1));
   float t_absmax = max(fabs(t_min),fabs(t_max));
   float tnum_scale = 10000;//(float)INT32_MAX / (t_absmax*2);
   
   // printf("%f %f %f %f\n", abs(t_min), abs(t_max), tnum_scale, t_absmax);
   
   tx0 *= tnum_scale; tx1 *= tnum_scale;
   ty0 *= tnum_scale; ty1 *= tnum_scale;
   tz0 *= tnum_scale; tz1 *= tnum_scale;

   // tx0 *= OT_SCALE; tx1 *= OT_SCALE;
   // ty0 *= OT_SCALE; ty1 *= OT_SCALE;
   // tz0 *= OT_SCALE; tz1 *= OT_SCALE;
   
   // printf("Init:\n\t%.8x %.8x %.8x\n\t%.8x %.8x %.8x\n", 
   //                       (int32_t)tx0, (int32_t)ty0, (int32_t)tz0,
   //                        (int32_t)tx1, (int32_t)ty1, (int32_t)tz1);
 
         
   float t_enter = max(max(tx0, ty0), tz0);
   float t_exit =  min(min(tx1, ty1), tz1);
   if (t_enter < t_exit) {
      writeWord(fb_adr);
      writeWord(dir_mask);
      writeWord((int32_t)tx0);
      writeWord((int32_t)ty0);
      writeWord((int32_t)tz0);
      writeWord((int32_t)tx1);
      writeWord((int32_t)ty1);
      writeWord((int32_t)tz1);
      return 1;
   }
   return 0;
}

int writeFrame(write_word_cb writeWord, Camera *cam, int w, int h, unsigned int fb_adr)
{
   int ray_count = 0;
	int x = 0;
	int y = 0;
   for (y=0;y<h;y++) {
   // y = 32; {
      for (x=0;x<w;x++) {
         // x = 15; {
			Vector3f ray_d = calcCameraRay(cam, w, h, x, y);
			Ray ray;
			ray.o = cam->o;
			ray.d = ray_d;
         int valid = writeRay(writeWord, ray, ( fb_adr + (y*w + x)*3), x, y);
         if (valid) ray_count++;
         // ray_count++;
      }
   }  
   return ray_count;
}