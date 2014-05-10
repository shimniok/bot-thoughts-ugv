/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Image;
import java.net.URL;
import javax.swing.ImageIcon;
import javax.swing.JPanel;

    
/**
 *
 * @author mes
 */
public final class GaugeNeedle extends JPanel implements ChangeListener<DoubleProperty> {
    private double min;
    private double max;
    private double spread;
    private double sweepMax;
    private boolean wrap;
    private double value;
    private double damping;
    private boolean isDamped;
    private double needleAngle;
    private double needleX;
    private double needleY;
    public Image image;
    private int myWidth;
    private int myHeight;
       
    /** Create a new GaugeNeedle.  The needle is given an image (setImage())
     * which it rotates according to its calibration (see calibrate()) to display
     * the new value.
     */
    public GaugeNeedle() {
        this.setOpaque(false);
        min = max = spread = sweepMax = value = damping = 0;
        needleAngle = needleX = needleY = myWidth = myHeight = 0;
        image = null;
        wrap = isDamped = false;
    }
    
            
    /** Sets the image for the needle.
     *
     * @param filename is the name of the image file.
     */
    public void setImage(String filename) {
        image = loadImage(filename);
        myWidth = this.getWidth();
        myHeight = this.getHeight();
    }
        
    /** calibrate a continuous/wraparound needle like a compass
     * 
     * @param maxValue maximum value/wrap point
     * @param maxSweep maximum sweep in radians
     */
    public void setCalibration(double maxValue, double maxSweep) {
        setCalibration(0.0, maxValue, maxSweep, true);
    }
    
    /**
     * calibrate a standard needle like speedometer
     *
     * @param minValue
     * @param maxValue
     * @param maxSweep
     */
    public void setCalibration(double minValue, double maxValue, double maxSweep) {
        setCalibration(minValue, maxValue, maxSweep, false);
    }
    
    // TODO: create an optional 'Off' value so the needle goes < min when gauge is
    // 'turned off' or at least when not connected to serial or replaying a log
    
    // TODO: add warning LEDs for various values.

    /**
     * calibrate a standard needle like speedometer
     *
     * @param minValue is the minimum value displayable by the needle
     * @param maxValue is the maximum value displayable by the needle
     * @param maxSweep is the maximum needle sweep in radians
     * @param doWrap determines if the needle wraps around as in clocks and compasses
     */
    public void setCalibration(double minValue, double maxValue, double maxSweep, boolean doWrap) {
        min = minValue;
        max = maxValue;
        spread = maxValue - minValue;
        sweepMax = maxSweep;
        wrap = doWrap;
    }
    
    
    /** returns the specified needle angle
     * 
     * @return angle of the needle
     */
    public double getAngle() {
        return needleAngle;
    }
    
       
    /** sets the angle of the specified needle
     * 
     * @param i
     * @param angle 
     */
    public void setAngle(double angle) {
        needleAngle = angle;
        //System.out.println("Needle "+i+" angle "+angle);
    }

    
    /** sets the center of rotation for the specified needle
     * 
     * @param x is the horizontal position of center normalized to image size
     * @param y is the vertical position of center normalized to image size
     */
    public void setRotationCenter(double x, double y) {
        needleX = x;
        needleY = y;
    }
    
    
    /** sets the new value for the needle to display.
     * 
     * @param newValue (double) is the new value to be displayed
     */
    public void setValue(double newValue) {
        value = newValue;
        if (value < min) {
            value = min;
        }
        if (value > max) {
            value = max;
        }
        setAngle((value - min) * sweepMax / (max - min));
    }
  
    
    public boolean isDamped() {
        return (isDamped);
    }
    
    
    /** Set damping value for needle. See setValueDamped.
     * 
     * @param d (double) damping value of 0-1, with 0 and 1.0 being no damping
     */
    public void setDamping(double d) {
        if (damping >= 1.0 || damping < 0) {
            damping = 0;
            isDamped = false;            
        } else {
            damping = d;
            isDamped = true;
        }
    }
    
    
    /**
     * Sets the value using exponential filter for damping, if enabled.
     *   value = (1-damping)*value + damping*newValue;
     * Thus you'd have to call this multiple times for value == newValue.
     * If damping is not enabled, this just calls setValue with the new value.
     * 
     * @param newValue (double) is the target update value
     */
    public void setValueDamped(double newValue) {
        if (!isDamped) {
            setValue(newValue);
        } else {
            if (wrap) { // TODO make this a method or something
                while (newValue >= max) {
                    newValue -= spread;
                }
                while (newValue < min) {
                    newValue += spread;
                }
            }
            /* if you run the algebra on: value = (1-damp)*value + damp*new
             * you get: value = value + damp(new - value)
             * That sets us up to handle a wraparound (modulus) case like
             * 0-360, where we can adjust the delta value to between -180 and 180
             */
    //        System.out.println("1. newValue=" + Double.toString(newValue));
    //        System.out.println("2. value=" + Double.toString(value));
            double delta = newValue - value;
    //        System.out.println("3. delta=" + Double.toString(delta));
            if (wrap) {
                /* e.g., if delta > 180, delta -= 360 */
                if (delta >= spread/2.0) {
                    delta -= spread;
                }
                /* e.g. if delta < -180, delta += 360 */
                if (delta < -spread/2.0) {
                    delta += spread;
                }
    //            System.out.println("4. delta=" + Double.toString(delta));
            }
            /* algebraically equivalent to value = (1-damping) * value[i] + damping * newValue; */
            double theValue = this.value + delta * damping;
            if (wrap) {
                while (theValue >= max) {
                    theValue -= spread;
                }
                while (theValue < min) {
                    theValue += spread;
                }
            }
            setValue(theValue);
//            System.out.println();
        }
    }

    /**
     * 
     * @param g is the graphic context passed in
     */
    @Override
    public void paintComponent(Graphics g) {
        Graphics2D g2d = (Graphics2D) g;
        
        if (image != null) {
            g2d.rotate(needleAngle, myWidth*needleX, myHeight*needleY);
            g2d.drawImage(this.image, 0, 0, myWidth, myHeight, this);
            g2d.rotate(-needleAngle, myWidth*needleX, myHeight*needleY);
            this.validate();
        }
    }

    
    @Override
    public void changed(DoubleProperty property) {
//        System.out.println("property changed " + Double.toString(property.get()));
        //setValue(property.get());
        if (isDamped())
            setValueDamped(property.get());
        else
            setValue(property.get());
        this.repaint();
    }
    
    /**
     * Load image of the needle.
     * @param filename is the filename of the image to load
     * @return (Image) is the image loaded
     */
    private Image loadImage(String filename) {
        Image myImage = null;
        
        if (filename != null) {
            try {              
                URL url = getClass().getResource(filename);
                if (url != null) {
                    myImage = new ImageIcon(url).getImage();
                    myWidth = this.getWidth();
                    myHeight = this.getHeight();
                }
            } catch (Exception ex) {
                System.out.println("Error loading image: " + ex.getMessage().toString());
            }
        }
        return myImage;
    }

}
