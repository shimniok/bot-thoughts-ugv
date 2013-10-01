/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package botthoughtsgcs;

import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Image;
import java.net.URL;
import javax.swing.ImageIcon;
import javax.swing.JPanel;

/**
 *
 * @author Michael Shimniok
 */
public class GaugePanel extends javax.swing.JLayeredPane {

    private int myWidth;
    private int myHeight;
    private Image faceImage;
    private JPanel faceLayer = new JPanel();
    private static final int LAYERS=3;
    private Image[] layerImage;
    private JPanel[] layer;
    private double[] needleAngle;
    private double[] needleX;
    private double[] needleY;
    private double[] sweepMax;
    private double[] min;
    private double[] max;
    private double[] spread;
    private boolean[] wrap;
    private double[] value;
    private double damping;
    
    /** Instantiates a new GaugePanel
     * 
     */
    public GaugePanel() {
        initComponents();

        layer = new JPanel[LAYERS];
        layerImage = new Image[LAYERS];
        needleAngle = new double[LAYERS];
        needleX = new double[LAYERS];
        needleY = new double[LAYERS];
        sweepMax = new double[LAYERS];
        min = new double[LAYERS];
        max = new double[LAYERS];
        spread = new double[LAYERS];
        value = new double[LAYERS];
        wrap = new boolean[LAYERS];
        damping = 1.0;

        for (int i=0; i < LAYERS; i++) {
            layer[i] = new JPanel();
            this.add(layer[i], new Integer(i));      // add needle panel in foreground
        }
        this.add(faceLayer, new Integer(LAYERS));    // add face in background
        
        
    }

    /** returns the default needle angle
     * 
     * @return angle of the default needle
     */
    public double getNeedleAngle() {
        return getNeedleAngle(0);
    }
    
    
    /** returns the specified needle angle
     * 
     * @param i
     * @return angle of the ith needle
     */
    public double getNeedleAngle(int i) {
        return needleAngle[i];
    }
    
    
    /** sets the angle of the default needle
     * 
     * @param angle 
     */
    public void setNeedleAngle(double angle) {
        setNeedleAngle(0, angle);
    }
    
    
    /** sets the angle of the specified needle
     * 
     * @param i
     * @param angle 
     */
    public void setNeedleAngle(int i, double angle) {
        needleAngle[i] = angle;
        //System.out.println("Needle "+i+" angle "+angle);
    }
    
    
    /** sets the center of rotation for the default needle
     * 
     * @param x is the horizontal position of center normalized to image size
     * @param y is the vertical position of center normalized to image size
     */
    public void setNeedleCenter(double x, double y) {
        setNeedleCenter(0, x, y);
    }
    
    
    /** sets the center of rotation for the specified needle
     * 
     * @param i the needle to set
     * @param x is the horizontal position of center normalized to image size
     * @param y is the vertical position of center normalized to image size
     */
    public void setNeedleCenter(int i, double x, double y) {
        if ( i >= 0 && i < LAYERS) {
            needleX[i] = x;
            needleY[i] = y;
        }
    }
    
    
    /**
     * 
     * @param filename
     * @return 
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
                // handle exception...
                System.out.println("Error loading image: " + ex.getMessage().toString());
            }
        }
        return myImage;
    }
        
    
    /** assumes the needle image is in the 0 position
     * 
     * @param minValue
     * @param maxValue
     * @param sweepMax 
     */
    
    //public void calibrate(double minValue, double maxValue, double sweepMax) {
    //    calibrate(0, minValue, maxValue, sweepMax);
    //}

    /** calibrate a continuous/wraparound gauge like a compass
     * 
     * @param maxValue maximum value/wrap point
     * @param maxSweep maximum sweep in radians
     */
    //public void calibrate(double maxValue, double maxSweep) {
    //    calibrate(0, 0.0, maxValue, maxSweep, true);
    //}

    
    /** calibrate a continuous/wraparound gauge like a compass
     * 
     * @param i
     * @param maxValue maximum value/wrap point
     * @param maxSweep maximum sweep in radians
     */
    public void calibrate(int i, double maxValue, double maxSweep) {
        calibrate(i, 0.0, maxValue, maxSweep, true);
    }
    
    /** calibrate a standard gauge like speedometer
     * 
     * @param i
     * @param minValue
     * @param maxValue
     * @param maxSweep 
     */
    public void calibrate(int i, double minValue, double maxValue, double maxSweep) {
        calibrate(i, minValue, maxValue, maxSweep, false);
    }

    /** calibrate a standard gauge like speedometer
     * 
     * @param i
     * @param minValue
     * @param maxValue
     * @param maxSweep 
     * @param doWrap
     */
    public void calibrate(int i, double minValue, double maxValue, double maxSweep, boolean doWrap) {
        if ( i >= 0 && i < LAYERS) {
            min[i] = minValue;
            max[i] = maxValue;
            spread[i] = maxValue - minValue;
            sweepMax[i] = maxSweep;
            wrap[i] = doWrap;
        }
    }

    
    public void setDamping(double d) {
        damping = d;
    }
    
    public void setValue(double value) {
        setValue(0, value);
    }
            
    public void updateValueDamped(double newValue) {
        updateValueDamped(0, newValue);
    }
    
    /** updates the value with some damping */
    public void updateValueDamped(int i, double newValue) {
        if ( i >= 0 && i < LAYERS) {
            if (wrap[i]) {
                while (newValue >= max[i]) {
                    newValue -= spread[i];
                }
                while (newValue < min[i]) {
                    newValue += spread[i];
                }
            }
            /* if you run the algebra on: value = (1-damp)*value + damp*new
             * you get: value = value + damp(new - value)
             * That sets us up to handle a wraparound (modulus) case like
             * 0-360, where we can adjust the delta value to between -180 and 180
             */
            System.out.println("1. newValue="+Double.toString(newValue));
            System.out.println("2. value["+Integer.toString(i)+"]="+Double.toString(value[i]));
            double delta = newValue - value[i];
            System.out.println("3. delta=" + Double.toString(delta));
            if (wrap[i]) {
                /* e.g. if delta < -180, delta += 360 */
                if (delta < -spread[i]/2.0) {
                    delta += spread[i];
                }
                /* e.g., if delta > 180, delta -= 360 */
                if (delta > spread[i]/2.0) {
                    delta -= spread[i];
                }
                System.out.println("4. delta=" + Double.toString(delta));
            }
            /* algebraically equivalent to value[i] = (1-damping) * value[i] + damping * newValue; */
            double theValue = value[i] + delta * damping;
            if (wrap[i]) {
                while (theValue >= max[i]) {
                    theValue -= spread[i];
                }
                while (theValue < min[i]) {
                    theValue += spread[i];
                }
            }
            setValue(i, theValue);
            System.out.println();
        }
    }
    
    public void setValue(int i, double newValue) {
        if ( i >= 0 && i < LAYERS) {
            value[i] = newValue;
            if (value[i] < min[i]) {
                value[i] = 0.8 * min[i];
            }
            if (value[i] > max[i]) {
                value[i] = 1.2 * max[i];
            }
            setNeedleAngle(i, ( value[i] - min[i] ) * sweepMax[i] / ( max[i] - min[i] ));
        }
        this.repaint();
    }
    
    /**
     * 
     * @param filename 
     */
    public void setNeedleImage(String filename) {
        setNeedleImage(0, filename);
    }
    
    
    /**
     * 
     * @param i
     * @param filename 
     */
    public void setNeedleImage(int i, String filename) {
        if ( i >= 0 && i < LAYERS) {
            layerImage[i] = loadImage(filename);
            myWidth = this.getWidth();
            myHeight = this.getHeight();
        }
    }
    
    
    /**
     * Creates new form GaugePanel
     */
    public void setFaceImage(String filename) {
        faceImage = loadImage(filename);
        myWidth = this.getWidth();
        myHeight = this.getHeight();
    }
    
    
    /**
     * 
     * @param g 
     */
    @Override
    public void paintComponent(Graphics g) {
        Graphics2D g2d = (Graphics2D) g;
        
        if (faceImage != null) {
            g2d.drawImage(faceImage, 0, 0, myWidth, myHeight, faceLayer);
            faceLayer.repaint();
        }

        for (int i=0; i < LAYERS; i++) {
            if (layerImage[i] != null) {
                //g2d.translate(needleX, needleY);
                //g2d.rotate(needleAngle, myWidth*140/272, myHeight*189/272);
                g2d.rotate(needleAngle[i], myWidth*needleX[i], myHeight*needleY[i]);
                g2d.drawImage(layerImage[i], 0, 0, myWidth, myHeight, layer[i]);
                g2d.rotate(-needleAngle[i], myWidth*needleX[i], myHeight*needleY[i]);
                layer[i].repaint();
            }
        }
    }
    
    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 400, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 300, Short.MAX_VALUE)
        );
    }// </editor-fold>//GEN-END:initComponents
    // Variables declaration - do not modify//GEN-BEGIN:variables
    // End of variables declaration//GEN-END:variables
}
