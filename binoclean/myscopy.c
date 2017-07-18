#include <stdio.h>
#include "misc.h"
#include <string.h>

#define STRSIZE 1024

char *myscopy(char *s1, char *s2)
{
    
    int i;
    static int nsalloc = 0;
    static int nsfree = 0;
    
    if(s1 == s2)
        return(s1);
	if(s1 != NULL && strlen(s2) >= STRSIZE){
		free(s1);
        nsfree++;
        s1 = NULL;
    }
	if(s2 == NULL)
		return(NULL);
	else if((i = strlen(s2)) == 0)
		return(NULL);
	else
	{
        if (i >= STRSIZE){
            s1 = (char *)malloc(sizeof(char) *(i+3));
            nsalloc++;
        }
        else if (s1 == NULL){
            s1 = (char *)malloc(sizeof(char) *(STRSIZE+3));
            nsalloc++;
        }
        s1 = strcpy(s1,s2);
	}
	return(s1);
}

char *mysncopy(char *s1,char *s2, int n)
{
	char *calloc();
    
	if(s1 != NULL)
		free(s1);
	if(s2 == NULL)
		return(NULL);
	else if(strlen(s2) == 0)
		return(NULL);
	else
	{
        s1 = calloc(1,(strlen(s2)+1));
        strncpy(s1,s2,n);
	}
	return(s1);
}

char *nonewline(char *s)
{
	int i;
	if(s == NULL) return(NULL);
	i = strlen(s) - 1;
	while(s[i] == '\n' && i >= 0)
		s[i--] = '\0';
	return(s);
}
