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
        
    
    printf("those are the results: M = %d, N = %d, , nze = %d\n",M,(*N),(*nze));

    fclose(mtxFp);
    return;
}