/*
**
** memsweep.c        Benchmark to measure memory access performance
**                   (measures time to access large heap array at
**                   varying locations)
**
** To compile:  gcc -O -o memsweep memsweep.c -lm
**
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <float.h>

/** change magic numbers to fit execution time 10-20 seconds, in this case array size */
#define ARR_SIZE (8096 * 8096)

static double second(void)
{
    return ((double)((double)clock()/(double)CLOCKS_PER_SEC));
}

void main(void)
{
  unsigned int i;
  double time;
  volatile char* array;
  struct timeval tv;
  
  array = (char*) malloc(sizeof(char)*ARR_SIZE);
  
  time = second();
  for (i = 0; i < 10 * ARR_SIZE; i++)
  {
    array[(4096 * i + i) % ARR_SIZE] = 1 + array[i % ARR_SIZE];
  }
  free((void*)array);
  time = second() - time;

  gettimeofday(&tv, NULL);
  
  //printf("%lu", tv.tv_sec); 
  printf("%.3f\n", time);
}
