/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import java.awt.*;
import java.net.URL;
import javax.swing.ImageIcon;
import javax.swing.JComponent;
import javax.swing.JScrollPane;
import javax.swing.JViewport;

/*
 * Support custom painting on a panel in the form of
 *
 * a) images - that can be scaled, tiled or painted at original size b) non
 * solid painting - that can be done by using a Paint object
 *
 * Also, any component added directly to this panel will be made non-opaque so
 * that the custom painting can show through.
 * 
 * http://tips4java.wordpress.com/2008/10/12/background-panel/
 */
public class BackgroundPanel extends javax.swing.JPanel {

    private Image image;
    private boolean isTransparentAdd = true;

    public BackgroundPanel(String image) {
        initComponents();
        
        Image myImage = null;
        
        if (image != null) {
            try {              
                URL url = getClass().getResource(image);
                if (url != null) {
                    myImage = new ImageIcon(url).getImage();
                }
            } catch (Exception ex) {
                // handle exception...
                System.out.println("Error loading image: " + ex.getMessage().toString());
            }
        }
        setImage(myImage);
        setLayout(new BorderLayout());
    }

    /*
     * Set the image used as the background
     */
    public final void setImage(Image image) {
        this.image = image;
        repaint();
    }

    
    /*
     * Override method so we can make the component transparent
     */
    public void add(JComponent component) {
        add(component, null);
    }

    /*
     * Override method so we can make the component transparent
     */
    public void add(JComponent component, Object constraints) {
        if (isTransparentAdd) {
            makeComponentTransparent(component);
        }

        super.add(component, constraints);
    }

    /*
     * Controls whether components added to this panel should automatically be
     * made transparent. That is, setOpaque(false) will be invoked. The default
     * is set to true.
     */
    public void setTransparentAdd(boolean isTransparentAdd) {
        this.isTransparentAdd = isTransparentAdd;
    }

    /*
     * Try to make the component transparent. For components that use renderers,
     * like JTable, you will also need to change the renderer to be transparent.
     * An easy way to do this it to set the background of the table to a Color
     * using an alpha value of 0.
     */
    private void makeComponentTransparent(JComponent component) {
        component.setOpaque(false);

        if (component instanceof JScrollPane) {
            JScrollPane scrollPane = (JScrollPane) component;
            JViewport viewport = scrollPane.getViewport();
            viewport.setOpaque(false);
            Component c = viewport.getView();

            if (c instanceof JComponent) {
                ((JComponent) c).setOpaque(false);
            }
        }
    }

    /*
     * Add custom painting
     */
    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        
        Graphics2D g2d = (Graphics2D) g;
        if (image != null) {
            g2d.drawImage(image, 0, 0, getWidth(), getHeight(), null);
        }

    }


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