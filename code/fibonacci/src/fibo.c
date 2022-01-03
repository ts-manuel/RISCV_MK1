/*
    File: fibo.c

    Computes the first N terms of the fibonacci sequence
*/


#define _NUM 10

int values[_NUM];


int fibo(int n)
{
    if (n == 0 || n == 1)
        return 1;
    else
        return fibo(n - 1) + fibo(n - 2);
}


int main()
{

    for (int i = 0; i < _NUM; i++)
    {
        values[i] = fibo(i);
    }
    
}