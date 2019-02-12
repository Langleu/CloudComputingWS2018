#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

// gcc -O -o fork fork.c -lm

double sum(double a, double b) {
    if (a == b) {
        printf("%d\n", (int) a);
        return (int) a;
    }

    int status;
    pid_t pid1;
    pid_t pid2;

    int cValue1 = -1;
    int cValue2 = -2;

    pid1 = fork();

    if (pid1 == 0) { // child1
        return sum(a, floor((a+b)/2));
    } else if (pid1 < 0) { // child1 failed
        return sum(a, b); // in case it fails try again
    } else {// parent
        wait(&cValue1);
    }

    pid2 = fork();

    if (pid2 == 0) { // child1
        double c = b + 1;
        return sum(ceil((a+c)/2), b);
    } else if (pid2 < 0) { // child1 failed
        return sum(a, b); // in case it fails try again
    } else {// parent
        wait(&cValue2);
    }
}

int main(int argc, char* argv[]) {
    sum(atof(argv[1]), atof(argv[2]));

    return 0;
}