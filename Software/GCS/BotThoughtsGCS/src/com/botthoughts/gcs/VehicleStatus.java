/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import java.util.ArrayList;

/**
 *
 * @author Michael Shimniok
 */
public interface VehicleStatus {
    public double getVoltage();
    public double getCurrent();
    public double getBattery();
    public double getSpeed();
    public double getHeading();
    public double getLatitude();
    public double getLongitude();
    public double getSatCount();
    public double getBearing();
    public double getDistance();
    public void setVoltage(double v);
    public void setCurrent(double v);
    public void setBattery(double v);
    public void setSpeed(double v);
    public void setHeading(double v);
    public void setLatitude(double v);
    public void setLongitude(double v);
    public void setPosition(Coordinate v);
    public void setLookahead(Coordinate v);
    public void setWaypoints(ArrayList<Coordinate> wpt);
    public void setSatCount(double parseDouble);
    public void setBearing(double v);
    public void setDistance(double v);
    public void setNextWaypoint(int v);
}
