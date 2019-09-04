#include <stdio.h>
#include <stdlib.h>
#include "check_bounds.xh"

struct _bounds_map *_BOUNDS_MAP = NULL;

void *mymalloc(size_t size)
{
    void *tmp = malloc(size);
    if (_BOUNDS_MAP == NULL) {
        _BOUNDS_MAP = _boundsmap_new();
    }
    _boundsmap_insert(_BOUNDS_MAP, tmp, size);
    return tmp;
}

int main(int argc, char *argv[])
{
    int * check x = mymalloc(5 * sizeof(int));
    x[0] = 0;
    x[7] = 1;

    return 0; 
}
