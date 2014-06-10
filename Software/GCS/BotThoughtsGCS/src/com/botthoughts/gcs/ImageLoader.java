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

/** Generic dashboard panel object
 *
 * @author mes
 */
public class ImageLoader {
    protected Image image;
    
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
    
       
    /** Creates new form GaugePanel.
     * @param filename is the filename of the image to load
     */
    public void setImage(String filename) {
        image = loadImage(filename);
    }

    /** Gets the loaded image.
     * 
     * @return Image
     */
    public Image getImage() {
        return image;
    }
      
}
