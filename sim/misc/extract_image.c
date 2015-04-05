#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// #include <machine/endian.h>
#include <libfpgalink.h>
#include "common.h"
#include "atlys.h"

#define CMD_WRITE 0x01
#define CMD_READ 0x02

#define FAIL(x) exit(x)

#define CHECK(x) \
	if ( status != FL_SUCCESS ) {       \
		fprintf(stderr, "%s\n", error); \
		flFreeError(error);             \
		FAIL(x);									\
	}

struct FLContext *handle = NULL;
FLStatus status;
const char *error = NULL;
bool flag;
uint8 byte = 0;

char *vp = "1443:0007";
char *ivp = "1443:0007";

bool isNeroCapable, isCommCapable;

unsigned int swap_endian(unsigned int value)
{
   char *ptr = (char*)&value;
   char out[4];
   out[0] = ptr[3]; out[1] = ptr[2]; out[2] = ptr[1]; out[3] = ptr[0];
   return *((unsigned int*)out);
}

void savebmp(const char *filename, char *img, int w, int h )
{
    int i;
    FILE *f;
    int filesize = 54 + 3*w*h;

    unsigned char bmpfileheader[14] = {'B','M', 0,0,0,0, 0,0, 0,0, 54,0,0,0};
    unsigned char bmpinfoheader[40] = {40,0,0,0, 0,0,0,0, 0,0,0,0, 1,0, 24,0};
    unsigned char bmppad[3] = {0,0,0};

    bmpfileheader[ 2] = (unsigned char)(filesize    );
    bmpfileheader[ 3] = (unsigned char)(filesize>> 8);
    bmpfileheader[ 4] = (unsigned char)(filesize>>16);
    bmpfileheader[ 5] = (unsigned char)(filesize>>24);
    bmpinfoheader[ 4] = (unsigned char)(       w    );
    bmpinfoheader[ 5] = (unsigned char)(       w>> 8);
    bmpinfoheader[ 6] = (unsigned char)(       w>>16);
    bmpinfoheader[ 7] = (unsigned char)(       w>>24);
    bmpinfoheader[ 8] = (unsigned char)(       h    );
    bmpinfoheader[ 9] = (unsigned char)(       h>> 8);
    bmpinfoheader[10] = (unsigned char)(       h>>16);
    bmpinfoheader[11] = (unsigned char)(       h>>24);

    //f = fopen("img.raw","wb");
    //fwrite(img,3,w*h,f);
    //fclose(f);

    f = fopen(filename,"wb");
    fwrite(bmpfileheader,1,14,f);
    fwrite(bmpinfoheader,1,40,f);
    for(i=0; i<h; i++)
    {
        fwrite(img+(w*(h-i-1)*3),3,w,f);
        fwrite(bmppad,1,(4-(w*3)%4)%4,f);
    }
    fclose(f);
}


void init(void)
{
	
	flInitialise();
	
	printf("Attempting to open connection to FPGALink device %s...\n", vp);
	status = flOpen(vp, &handle, NULL);
	if (status ) {
		
		printf("Loading firmware...\n");
		status = flLoadStandardFirmware(ivp, vp, &error);

		int count = 60;
		printf("Awaiting renumeration");
		flSleep(1000);
		do {
			printf(".");
			fflush(stdout);
			flSleep(100);
			status = flIsDeviceAvailable(vp, &flag, &error);
			CHECK(9);
			count--;
		} while ( !flag && count );
		printf("\n");
		if ( !flag ) {
			fprintf(stderr, "FPGALink device did not renumerate properly as %s\n", vp);
			FAIL(10);
		}
		flSleep(2000);
		printf("Attempting to open connection to FPGLink device %s again...\n", vp);
		status = flOpen(vp, &handle, &error);
		CHECK(11);
		
	}
	
	printf("Connection open\n");
	
	isNeroCapable = flIsNeroCapable(handle);
	isCommCapable = flIsCommCapable(handle);
}


int main(int argc, const char *argv[]) {

	init();
	
   if (!isCommCapable) exit(1);

   unsigned int address = FB_ADR;
   
   //    uint8 *addr_ptr = (uint8*)&address; 
   // status = flWriteRegister(handle, 1000, 0x01, 1, &addr_ptr[3], &error); CHECK(21);
   // status = flWriteRegister(handle, 1000, 0x02, 1, &addr_ptr[2], &error); CHECK(22);
   // status = flWriteRegister(handle, 1000, 0x03, 1, &addr_ptr[1], &error); CHECK(23);
   // status = flWriteRegister(handle, 1000, 0x04, 1, &addr_ptr[0], &error); CHECK(24);
   // 
 
	int Bpp = 3;
	
   int buffer_size = FB_WIDTH*FB_HEIGHT*Bpp;
   char *buffer = malloc(buffer_size);
   
   int length = buffer_size/4;
   
   unsigned int cmd[3] = {
       swap_endian(CMD_READ),
       swap_endian(length),
       swap_endian(address)
       };
    status = flWriteRegister(handle, 1000, 0x01, 12, (unsigned char*)cmd, &error); CHECK(19);
   
    buffer_size = length*4;
   
   int block_size = 32;
   int n_write = 0;
   while (n_write<buffer_size) {
      printf(".");
      int delta = buffer_size-n_write;
      int c = (delta)>block_size ? block_size : delta;
      status = flReadRegister(handle, 2000, 0x01, c, buffer+n_write, &error); CHECK(30);
      n_write += c;
   }
   printf("\n");
   
    int i;
   // for (i=0;i<length;i++) {   
   //    printf(".");   
   //    status = flReadRegister(handle, 2000, 0x01, 4, buffer+i*4, &error); CHECK(30);
   //    
   // }
   // printf("\n");
   
   // status = flReadRegister(handle, 2000, 0x06, FB_WIDTH*FB_HEIGHT, buffer, &error); CHECK(30);
	
   
	
   char *img = malloc(FB_WIDTH*FB_HEIGHT*3);
   // int i;
   for (i=0;i<FB_WIDTH*FB_HEIGHT;i++) {
      img[i*3] =   buffer[i*Bpp+2];
      img[i*3+1] = buffer[i*Bpp+1];
      img[i*3+2] = buffer[i*Bpp];
   }
   
   savebmp("out.bmp", img, FB_WIDTH, FB_HEIGHT);
}
