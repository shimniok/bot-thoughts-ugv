#ifndef __MAPPING_H
#define __MAPPING_H

#include "GeoPosition.h"
#include "CartPosition.h"

class Mapping {
public:
    void init(int count, GeoPosition *p);
    void geoToCart(GeoPosition pos, CartPosition *cart);
    void cartToGeo(float x, float y, GeoPosition *pos);
    void cartToGeo(CartPosition cart, GeoPosition *pos);

private:
    double lonToX;
    double latToY;
    double latZero;
    double lonZero;
};
#endif
