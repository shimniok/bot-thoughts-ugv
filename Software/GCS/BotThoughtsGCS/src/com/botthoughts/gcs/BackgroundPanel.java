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

    public static final int SCALED = 0;
    public static final int TILED = 1;
    public static final int ACTUAL = 2;
    private Paint painter;
    private Image image;
    private int style = SCALED;
    private float alignmentX = 0.5f;
    private float alignmentY = 0.5f;
    private boolean isTransparentAdd = true;

    /*
     * Set image as the background with the SCALED style
     */
    public BackgroundPanel(Image image) {
        this(image, SCALED);
    }
    
    public BackgroundPanel(String image) {
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
        setStyle(SCALED);
        setLayout(new BorderLayout());
    }

    /*
     * Set image as the background with the specified style
     */
    public BackgroundPanel(Image image, int style) {
        setImage(image);
        setStyle(style);
        setLayout(new BorderLayout());
    }

    /*
     * Set image as the backround with the specified style and alignment
     */
    public BackgroundPanel(Image image, int style, float alignmentX, float alignmentY) {
        setImage(image);
        setStyle(style);
        setImageAlignmentX(alignmentX);
        setImageAlignmentY(alignmentY);
        setLayout(new BorderLayout());
    }

    /*
     * Use the Paint interface to paint a background
     */
    public BackgroundPanel(Paint painter) {
        setPaint(painter);
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
     * Set the style used to paint the background image
     */
    public final void setStyle(int style) {
        this.style = style;
        repaint();
    }

    /*
     * Set the Paint object used to paint the background
     */
    public void setPaint(Paint painter) {
        this.painter = painter;
        repaint();
    }

    /*
     * Specify the horizontal alignment of the image when using ACTUAL style
     */
    public final void setImageAlignmentX(float alignmentX) {
        this.alignmentX = alignmentX > 1.0f ? 1.0f : alignmentX < 0.0f ? 0.0f : alignmentX;
        repaint();
    }

    /*
     * Specify the horizontal alignment of the image when using ACTUAL style
     */
    public final void setImageAlignmentY(float alignmentY) {
        this.alignmentY = alignmentY > 1.0f ? 1.0f : alignmentY < 0.0f ? 0.0f : alignmentY;
        repaint();
    }

    /*
     * Override method so we can make the component transparent
     */
    public void add(JComponent component) {
        add(component, null);
    }

    /*
     * Override to provide a preferred size equal to the image size
     */
    @Override
    public Dimension getPreferredSize() {
        if (image == null) {
            return super.getPreferredSize();
        } else {
            return new Dimension(image.getWidth(null), image.getHeight(null));
        }
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

        //  Invoke the painter for the background

        if (painter != null) {
            Dimension d = getSize();
            Graphics2D g2 = (Graphics2D) g;
            g2.setPaint(painter);
            g2.fill(new Rectangle(0, 0, d.width, d.height));
        }

        //  Draw the image

        if (image == null) {
            return;
        }

        switch (style) {
            case SCALED:
                drawScaled(g);
                break;

            case TILED:
                drawTiled(g);
                break;

            case ACTUAL:
                drawActual(g);
                break;

            default:
                drawScaled(g);
        }
    }

    /*
     * Custom painting code for drawing a SCALED image as the background
     */
    private void drawScaled(Graphics g) {
        Dimension d = getSize();
        g.drawImage(image, 0, 0, d.width, d.height, null);
    }

    /*
     * Custom painting code for drawing TILED images as the background
     */
    private void drawTiled(Graphics g) {
        Dimension d = getSize();
        int width = image.getWidth(null);
        int height = image.getHeight(null);

        for (int x = 0; x < d.width; x += width) {
            for (int y = 0; y < d.height; y += height) {
                g.drawImage(image, x, y, null, null);
            }
        }
    }

    /*
     * Custom painting code for drawing the ACTUAL image as the background. The
     * image is positioned in the panel based on the horizontal and vertical
     * alignments specified.
     */
    private void drawActual(Graphics g) {
        Dimension d = getSize();
        Insets insets = getInsets();
        int width = d.width - insets.left - insets.right;
        int height = d.height - insets.top - insets.left;
        float x = (width - image.getWidth(null)) * alignmentX;
        float y = (height - image.getHeight(null)) * alignmentY;
        g.drawImage(image, (int) x + insets.left, (int) y + insets.top, this);
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