
#include "test.h"
#include "args.h"
#include "cudaTriangles.h"


#include <cuda.h>
#include <cuda_runtime.h>
int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s [test|]\n", argv[0]);
    } else if (0 == strcmp(argv[1], "test")){
        test();
    } else {
        fprintf(stderr, "unrecognized option: %s\n", argv[1]);
    }
    
    int sum=0;
    for (size_t i = 0; i < 5; i++)
    {
        sum+= i;
    }
    return 0;

}

