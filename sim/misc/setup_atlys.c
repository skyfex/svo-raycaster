#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <machine/endian.h>
#include <libfpgalink.h>
#include "common.h"
#include "atlys.h"

int buffer_max_size = 2*FB_WIDTH*FB_HEIGHT*8*4;
int buffer_size;
char *buffer;

unsigned int swap_endian(unsigned int value)
{
   char *ptr = (char*)&value;
   char out[4];
   out[0] = ptr[3]; out[1] = ptr[2]; out[2] = ptr[1]; out[3] = ptr[0];
   return *((unsigned int*)out);
}

void writeWord(uint32_t word)
{
   uint8 *word_ptr = (uint8*)&word; 
   char *buffer_ptr = buffer+buffer_size;
   buffer_ptr[0] = word_ptr[3];
   buffer_ptr[1] = word_ptr[2];
   buffer_ptr[2] = word_ptr[1];
   buffer_ptr[3] = word_ptr[0];
   buffer_size+=4;
   
}

int main(int argc, const char *argv[]) {
   // 
   // init();
   // 
   //    if (!isCommCapable) exit(1);
   
   unsigned int address = RAY_DATA_ADR;
   

	
   buffer = malloc(buffer_max_size);
   buffer_size = 0;
	
   // printf("Writing ray data\n");
	// Camera cam;
 //   vec3f_set(&cam.o, 0, 0, -25);
	// int ray_count = writeFrame(writeWord, &cam, FB_WIDTH, FB_HEIGHT, FB_ADR);	
   
   
 //   FILE *f = fopen("ray_data.bin", "wb");
 //   int ray_count_sw = swap_endian(ray_count);
 //   fwrite(&ray_count_sw, 4, 1, f);
 //   fwrite(buffer, 1, buffer_size, f);
 //   fclose(f); 
   
   char sys_cmd[256];
   
   sprintf(sys_cmd, "orlink upload /octree/raydata.bin %d 1", RAY_DATA_ADR);
   printf("\n%s\n------\n", sys_cmd);
   system(sys_cmd);
   printf("------\n");
   
   printf("Writing octree\n");
   
   sprintf(sys_cmd, "orlink upload /octree/dragon1024.bin %d 1", OCTREE_ADR);
   printf("\n%s\n------\n", sys_cmd);
   system(sys_cmd);
   printf("------\n");
   
   // printf("Ray count: %d\n", ray_count);
   printf("Ray data adr: %d %.8x\n", RAY_DATA_ADR, RAY_DATA_ADR);
   printf("Octree adr: %d %.8x\n", OCTREE_ADR, OCTREE_ADR);
   printf("Framebuffer adr: %d %.8x\n", FB_ADR, FB_ADR);
   
   // free(buffer);
}