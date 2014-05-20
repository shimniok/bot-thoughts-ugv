/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

/** Cartesian coordinates
 *
 * @author mes
 */
public class Coordinate {
    private double x;
    private double y;
    
    public Coordinate() {
        this.x = Double.NaN;
        this.y = Double.NaN;
    }
    
    public Coordinate(double x, double y) {
        this.x = x;
        this.y = y;
    }
    
    public double getX() {
        return x;
    }
    
    public double getY() {
        return y;
    }
    
    /**
     * @param x the x to set
     */
    public void setX(double x) {
        this.x = x;
    }

    /**
     * @param y the y to set
     */
    public void setY(double y) {
        this.y = y;
    }

    public void setLocation(double x, double y) {
        this.setX(x);
        this.setY(y);
    }
}
