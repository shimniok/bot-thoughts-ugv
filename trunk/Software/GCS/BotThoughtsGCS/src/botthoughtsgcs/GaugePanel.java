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
    private double[] value;
    
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
        value = new double[LAYERS];

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
        System.out.println("Needle "+i+" angle "+angle);
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
    
    public void calibrate(double minValue, double maxValue, double sweepMax) {
        calibrate(0, minValue, maxValue, sweepMax);
    }
    
    
    /**
     * 
     * @param i
     * @param minValue
     * @param maxValue
     * @param maxSweep 
     */
    public void calibrate(int i, double minValue, double maxValue, double maxSweep) {
        if ( i >= 0 && i < LAYERS) {
            min[i] = minValue;
            max[i] = maxValue;
            sweepMax[i] = maxSweep;
        }
    }
    
    
    public void setValue(double value) {
        setValue(0, value);
    }
            
    public void setValue(int i, double newValue) {
        if ( i >= 0 && i < LAYERS) {
            value[i] = newValue;
            setNeedleAngle(i, ( value[i] - min[i] ) * sweepMax[i] / ( max[i] - min[i] ));
        }
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
