#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "common.h"

FILE *outfile;

int fb_width = 32;
int fb_height = 32;

#define VMEM_SIZE       0x00900000
#define RAY_DATA_ADR	   0
#define OCTREE_ADR	   0x00300000	
#define FB_ADR          0x00600000

// #define VMEM_SIZE    (0x2000000) 
// #define RAY_DATA_ADR 100000
// #define OCTREE_ADR   10485760 
// #define FB_ADR (10485760*2)

size_t current_size = 0;

void writeWord(uint32_t word)
{
   fprintf(outfile, "%.8x\n", word);
   // word = htonl(word);
   // fwrite(&word, 4, 1, binfile);
   current_size+=4;
}

int main()
{
   int i;
   
	FILE *otfile = fopen("/octree/dragon1024.bin", "rb");
	if (!otfile) exit(1);

   FILE *raydfile = fopen("/octree/raydata_sim.bin", "rb");
   if (!raydfile) exit(1);
	
	outfile = fopen("sram.vmem", "wb");
   current_size = 0;
   
   FILE *param_file = fopen("sim_params.v", "w");
   
   while ((current_size)<RAY_DATA_ADR) {
      writeWord(0);
   }

	// Camera cam;
 //   vec3f_set(&cam.o, 0, 0, -100);
   
 //   int ray_count = writeFrame(writeWord, &cam, fb_width, fb_height, FB_ADR);

   uint32_t ray_countf;
   fread(&ray_countf, 4, 1, raydfile);

   int ray_count = 0;
   while (1) {
      uint32_t word;
      size_t read_count = fread(&word, 4, 1, raydfile);
      if (!read_count) break;
      writeWord(word);
      ray_count++;
   }
   ray_count /= 7;

   printf("Ray count:\t%d / %d\n", ray_count, ray_countf); 
   printf("Ray data start:\t%8x\n", RAY_DATA_ADR);	
   printf("Ray data end: \t%8x\n", current_size);
   
   while ((current_size)<OCTREE_ADR) {
      writeWord(0);
   }
   
   // uint32_t ot_root_adr;
   // fread(&ot_root_adr, 4, 1, otfile);
   
   while (1) {
      uint32_t word;
      size_t read_count = fread(&word, 4, 1, otfile);
      if (!read_count) break;
      writeWord(word);
   }
   
   printf("Octree start: \t%8x\n", OCTREE_ADR);	
   printf("Octree end: \t%8x\n", current_size);
   
   
   while ((current_size)<VMEM_SIZE) {
      writeWord(0);
   }
   
   fprintf(param_file, "parameter vmem_size = 32'h%.8x;\n", VMEM_SIZE);
   fprintf(param_file, "parameter vmem_size_log2 = %d;\n", (int)ceil(log(VMEM_SIZE)/log(2)) );
   fprintf(param_file, "parameter ray_data_adr = 32'h%.8x;\n", RAY_DATA_ADR);
   fprintf(param_file, "parameter ray_count = 32'h%.8x;\n", ray_countf);
   fprintf(param_file, "parameter octree_root_adr = 32'h%.8x;\n", OCTREE_ADR);
   fprintf(param_file, "parameter framebuffer_adr = 32'h%.8x;\n", FB_ADR);
   
   fclose(otfile);
   fclose(outfile);
   fclose(param_file);
   

	return 0;
}