#include <stdio.h>
#include <cuda.h>

#define WIDTH 800
#define HEIGHT 600
#define MAX_ITER 256

__global__ void mandelbrot(unsigned char *img)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= WIDTH || y >= HEIGHT) return;

    float real = (x - WIDTH/2.0)*4.0/WIDTH;
    float imag = (y - HEIGHT/2.0)*4.0/WIDTH;

    float zr = 0.0, zi = 0.0;
    int i;

    for(i=0;i<MAX_ITER;i++)
    {
        float temp = zr*zr - zi*zi + real;
        zi = 2*zr*zi + imag;
        zr = temp;

        if(zr*zr + zi*zi > 4.0) break;
    }

    img[y*WIDTH+x] = i;
}

int main()
{
    unsigned char *img, *d_img;
    img = (unsigned char*)malloc(WIDTH*HEIGHT);

    cudaMalloc(&d_img, WIDTH*HEIGHT);

    dim3 threads(16,16);
    dim3 blocks((WIDTH+15)/16,(HEIGHT+15)/16);

    mandelbrot<<<blocks,threads>>>(d_img);

    cudaMemcpy(img,d_img,WIDTH*HEIGHT,cudaMemcpyDeviceToHost);

    FILE *fp = fopen("mandelbrot.pgm","wb");
    fprintf(fp,"P5\n%d %d\n255\n",WIDTH,HEIGHT);
    fwrite(img,1,WIDTH*HEIGHT,fp);
    fclose(fp);

    cudaFree(d_img);
    free(img);

    return 0;
}