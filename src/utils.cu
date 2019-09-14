#include "utils.h"

void readMtxFile(char *filepath, int **rowVec, int **colVec, int *N, int * nze){
    // char *filepath2 = "../graphs/chesapeake.mtx";
    printf("Path for graph is %s\n",filepath);
    // printf("path2 is %s\n",filepath2);
    FILE* mtxFp = fopen(filepath,"r+");
    // FILE* mtxFp = fopen(filepath2,"r+");
    char buf[1024];

    fgets(buf,1024,mtxFp); 

    // printf("1: %s \n",buf);

    int i = 0;
    // KEEP FGETTING UNTIL COMMENTS ARE FINISHED
    while(buf[0] == '%'){
        fgets(buf,1024,mtxFp); 
        i += 1;
    }
    
    // int i = 0;

    char delim[2] = " ";
    char *token = strtok(buf,delim);

    // printf("%s\n",token);
    char *tokens[3];
    
    i=0;
    while (token!=NULL){
        tokens[i] = token;
        i++;
        token = strtok(NULL,delim);
    }

    // printf("tokens array: %s , %s, %s \n",tokens[0],tokens[1],tokens[2]);
    int M = atoi(tokens[0]);
    *N = atoi(tokens[1]);
    *nze = atoi(tokens[2]);

    *rowVec = (int *)malloc((*nze)*sizeof(int));
    *colVec = (int *)malloc((*nze)*sizeof(int));

    int rowTmp;
    int colTmp;

    for(i=0;i<(*nze);i++){
        fscanf(mtxFp,"%d %d",&colTmp,&rowTmp);
        (*rowVec)[i] = rowTmp;
        (*colVec)[i] = colTmp;
        // printf("%d. (%d , %d) \n",i,colVec[i],rowVec[i]);
    }
        
    // while(buf[0] == '%')
    //     fscanf(buf,mtxFp,\n);
        
    
    // printf("those are the results: M = %d, N = %d, , nze = %d\n",M,(*N),(*nze));

    fclose(mtxFp);
    return;
}


void separateRows(int nze,int N,int *rowVec, int *colVec, int **rowIndex){

    *rowIndex = (int *)malloc(sizeof(int)*N);
    
    // convert from base-1 to base-0
    int counter = rowVec[0]-1;
    // if starting from 
    for(int i=0;i<=counter;i++){
        (*rowIndex)[i] = 0;
    }
    
    
    for(int i=1;i<nze;i++){
        if(rowVec[i]!=rowVec[i-1]){
            counter ++;
            (*rowIndex)[counter]=i;
            // printf("Row %d index: %d\n ---Pair: %d. (%d, %d) \n ---To Pair: %d. (%d, %d) \n",i,(*rowIndex)[i],i-1,colVec[i-1],rowVec[i-1],i,colVec[i],rowVec[i]);
        }
    }
    
    for(int i=counter;i<N;i++){
        (*rowIndex)[i] = nze-1;
        // printf("-- %d \n --- %d\n --- %d\n",)
    }
    
    // for(int i=0;i<N;i++){
    //     printf("Row %d index: %d\n",i,(*rowIndex)[i]);
    // }
}



void pairsort(int a[], int b[], int n) 
{ 
    struct pair pairt[n]; 
  
    // Storing the respective array 
    // elements in pairs. 
    for (int i = 0; i < n; i++)  
    { 
        pairt[i].col = a[i]; 
        pairt[i].row = b[i]; 
    } 
  
    // Sorting the pair array.

    qsort(pairt, n, sizeof(struct pair), comparator);

    // sort(pairt, pairt + n); 
      
    // Modifying original arrays 
    for (int i = 0; i < n; i++)  
    { 
        a[i] = pairt[i].col; 
        b[i] = pairt[i].row; 
    } 
} 

int comparator(const void *p, const void *q)
{
    int l = ((struct pair *)p)->col;
    int r = ((struct pair *)q)->col;
    return (l - r);
}


void arraysToPairs(int *rowVec, int* colVec, int nze, pair *pairs){
    for(int i=0;i<nze;i++){
        (pairs[i]).row = rowVec[i];   
        (pairs[i]).col = colVec[i];   
    }
}


double get_time()
{
    struct timeval time;
    if (gettimeofday(&time,NULL)){
        return 0;
    }
    return (double)time.tv_sec + (double)time.tv_usec * .000001;
}
