package waypointplanner;

/*
 * SerialGUI.java
 *
 * Created on November 5, 2007, 3:45 PM
 *
 * @author  Goldscott
 * @author Michael Shimniok http://www.bot-thoughts.com/
 * 
 * Modified UI and equipped with a simple automatic file download protocol
 * 
 * Icon 
 * Author   : mattahan
 * HomePage : http://mattahan.deviantart.com
 * License  : Free for personal non-commercial use, Includes a link back to author site. Zombie.jpg
 */

public class WaypointPlannerGUI extends javax.swing.JFrame {
    private MercatorProjection projection;

    /** Creates new form SerialGUI */
    public WaypointPlannerGUI() {
        initComponents();
        this.pack();
    	this.setVisible(true);        
        
        // we know lat/lon origin 40.071000,-105.229500
        projection = new MercatorProjection(40.071000,-105.229500);
    }
    
    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        imageLabel = new javax.swing.JLabel();
        controlPanel = new javax.swing.JPanel();

        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
        setTitle("Waypoint Planner Tool");
        setMaximumSize(new java.awt.Dimension(650, 720));
        setMinimumSize(new java.awt.Dimension(650, 720));
        setPreferredSize(new java.awt.Dimension(650, 720));
        setResizable(false);
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosing(java.awt.event.WindowEvent evt) {
                formWindowClosing(evt);
            }
        });
        getContentPane().setLayout(new java.awt.FlowLayout());

        imageLabel.setIcon(new javax.swing.ImageIcon(getClass().getResource("/waypointplanner/resources/AVC.png"))); // NOI18N
        imageLabel.setMaximumSize(new java.awt.Dimension(640, 640));
        imageLabel.setMinimumSize(new java.awt.Dimension(640, 640));
        imageLabel.setPreferredSize(new java.awt.Dimension(640, 640));
        imageLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                imageLabelMouseClicked(evt);
            }
        });
        getContentPane().add(imageLabel);

        controlPanel.setBackground(new java.awt.Color(220, 170, 170));
        controlPanel.setMaximumSize(new java.awt.Dimension(640, 60));
        controlPanel.setMinimumSize(new java.awt.Dimension(640, 60));
        controlPanel.setPreferredSize(new java.awt.Dimension(640, 60));

        org.jdesktop.layout.GroupLayout controlPanelLayout = new org.jdesktop.layout.GroupLayout(controlPanel);
        controlPanel.setLayout(controlPanelLayout);
        controlPanelLayout.setHorizontalGroup(
            controlPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(0, 640, Short.MAX_VALUE)
        );
        controlPanelLayout.setVerticalGroup(
            controlPanelLayout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(0, 60, Short.MAX_VALUE)
        );

        getContentPane().add(controlPanel);

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void formWindowClosing(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_formWindowClosing
        //when user closes, make sure to close open ports and open I/O streams
    }//GEN-LAST:event_formWindowClosing

    private void imageLabelMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_imageLabelMouseClicked
        Point p = new Point( evt.getPoint() );
        System.out.println(p.x+" "+p.y);
        long numTiles = 1 << 19; // currently using image with zoom==19
        /*
        var numTiles = 1 << map.getZoom();
        var projection = new MercatorProjection();
        var worldCoordinate = projection.fromLatLngToPoint(chicago);
        var pixelCoordinate = new google.maps.Point(
            worldCoordinate.x * numTiles,
            worldCoordinate.y * numTiles);
        var tileCoordinate = new google.maps.Point(
            Math.floor(pixelCoordinate.x / TILE_SIZE),
            Math.floor(pixelCoordinate.y / TILE_SIZE));
        */
    }//GEN-LAST:event_imageLabelMouseClicked

    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {
            @Override
            public void run() {
                new WaypointPlannerGUI().setVisible(true);
            }
        });
    }

    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JPanel controlPanel;
    private javax.swing.JLabel imageLabel;
    // End of variables declaration//GEN-END:variables

}