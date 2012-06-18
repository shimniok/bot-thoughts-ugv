#ifndef __CARTPOSITION_H
#define __CARTPOSITION_H

class CartPosition {
public:
    CartPosition(void);
    CartPosition(float x, float y);
    void set(float x, float y);
    void set(CartPosition p);
    float bearingTo(CartPosition to);
    float distanceTo(CartPosition to);
    void move(float bearing, float distance);
    float _x;
    float _y;
};
#endif