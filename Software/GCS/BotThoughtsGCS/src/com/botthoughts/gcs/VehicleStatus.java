/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

/**
 *
 * @author Michael Shimniok
 */
public interface VehicleStatus {
    public double getVoltage();
    public void setVoltage(double v);
    public double getCurrent();
    public void setCurrent(double v);
    public double getBattery();
    public void setBattery(double v);
    public double getSpeed();
    public void setSpeed(double v);
    public double getHeading();
    public void setHeading(double v);
    public double getLatitude();
    public void setLatitude(double v);
    public double getLongitude();
    public void setLongitude(double v);
    public double getSatCount();
    public void setSatCount(double parseDouble);
    public double getBearing();
    public void setBearing(double v);
    public double getDistance();
    public void setDistance(double v);
}
