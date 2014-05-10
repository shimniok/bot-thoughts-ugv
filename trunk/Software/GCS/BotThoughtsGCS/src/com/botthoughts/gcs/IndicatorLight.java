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
public class IndicatorLight extends JPanel implements ChangeListener<BooleanProperty> {
    private Image image;
    private boolean value;
    
    public IndicatorLight() {
        value = false;
        this.setOpaque(false);
    }
    
    /** Sets the image for the needle.
     *
     * @param filename is the name of the image file.
     */
    public void setImage(String filename) {
        image = loadImage(filename);
    }
       
    /** loads the specified image as an Image
     * 
     * @param filename is the name of the image file
     * @return Image loaded from the filename
     */
    private Image loadImage(String filename) {
        Image myImage = null;
        
        if (filename != null) {
            try {              
                URL url = getClass().getResource(filename);
                if (url != null) {
                    myImage = new ImageIcon(url).getImage();
                }
            } catch (Exception ex) {
                // handle exception...
                System.out.println("Error loading image: " + ex.getMessage().toString());
            }
        }
        return myImage;
    }
    
    /** paints this component
     * 
     * @param g graphics context for this object
     */
    @Override
    public void paintComponent(Graphics g) {
        Graphics2D g2d = (Graphics2D) g;
       
        super.paintComponent(g);
        if (image != null) {
            if (value) {
                g2d.drawImage(image, 0, 0, this.getWidth(), this.getHeight(), null);
            } else {
                g2d.drawImage(null, 0, 0, this.getWidth(), this.getHeight(), null);
                //g2d.clearRect(0, 0, this.getWidth(), this.getHeight());
            }
        }
    }
    
    
    @Override
    public void changed(BooleanProperty property) {
        value = property.get();
        this.repaint();
    }
    
}
