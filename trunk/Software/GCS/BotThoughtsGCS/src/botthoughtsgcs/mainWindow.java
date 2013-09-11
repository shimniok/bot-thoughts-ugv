/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package botthoughtsgcs;

import java.awt.event.MouseEvent;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author Michael Shimniok
 */
public class mainWindow extends javax.swing.JFrame {

    /**
     * Creates new form mainWindow
     */
    public mainWindow() {
        initComponents();
        
        gaugePanel1.setFaceImage("/botthoughtsgcs/resources/voltmeter1.png");
        gaugePanel1.setNeedleImage("/botthoughtsgcs/resources/voltmeterneedle1.png");
        gaugePanel1.setNeedleCenter(139.0/270.0, 189.0/269.0);
        gaugePanel1.calibrate(4.0, 12.0, 1.475);
        gaugePanel1.setValue(8.4);
                
        gaugePanel2.setFaceImage("/botthoughtsgcs/resources/ammeter1.png");
        gaugePanel2.setNeedleImage("/botthoughtsgcs/resources/ammeterneedle1.png");
        gaugePanel2.setNeedleCenter(0.5, 0.5);
        gaugePanel2.calibrate(-16, 15, 5);
        gaugePanel2.setValue(3.5);

        gaugePanel3.setFaceImage("/botthoughtsgcs/resources/fuel1.png");
        gaugePanel3.setNeedleImage("/botthoughtsgcs/resources/fuelneedle1.png");
        gaugePanel3.calibrate(200, 4000, 1.5);
        gaugePanel3.setNeedleCenter(159.0/310.0, 219.0/308.0);
        gaugePanel3.setValue(3200);
        
        gaugePanel4.setFaceImage("/botthoughtsgcs/resources/speedometer1.png");
        gaugePanel4.setNeedleImage("/botthoughtsgcs/resources/speedometerneedle1.png");
        gaugePanel4.setNeedleCenter(0.5, 0.5);
        gaugePanel4.calibrate(0, 120.0, 4.7);
        gaugePanel4.setValue(22.0);
        
        gaugePanel5.setFaceImage("/botthoughtsgcs/resources/compass.png");
        gaugePanel5.setNeedleImage(0, "/botthoughtsgcs/resources/compassneedle.png");
        gaugePanel5.setNeedleCenter(0, 0.5, 0.5);
        gaugePanel5.calibrate(0, 360, 0, 6.3);
        gaugePanel5.setValue(0, 120.0);
        gaugePanel5.setNeedleImage(1, "/botthoughtsgcs/resources/compassbearing.png");
        gaugePanel5.setNeedleCenter(1, 0.5, 0.5);
        gaugePanel5.calibrate(1, 360, 0, 6.3);
        gaugePanel5.setValue(1, 20);
        gaugePanel5.setNeedleImage(2, "/botthoughtsgcs/resources/compasstop.png");
        gaugePanel5.setNeedleAngle(2, 0);
        
        gaugePanel6.setFaceImage("/botthoughtsgcs/resources/clock.png");
        gaugePanel6.setNeedleImage(0, "/botthoughtsgcs/resources/clockhour.png");
        gaugePanel6.setNeedleCenter(0, 0.5, 0.5);
        gaugePanel6.calibrate(0, 0, 12, 6.2832);
        gaugePanel6.setValue(0, 4.1);
        gaugePanel6.setNeedleImage(1, "/botthoughtsgcs/resources/clockminute.png");
        gaugePanel6.setNeedleCenter(1, 0.5, 0.5);
        gaugePanel6.calibrate(1, 0, 60, 6.2832);
        gaugePanel6.setValue(1, 4);
        
        backgroundPanel.setFaceImage("/botthoughtsgcs/resources/background.jpg");
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        backgroundPanel = new botthoughtsgcs.GaugePanel();
        gaugePanel1 = new botthoughtsgcs.GaugePanel();
        gaugePanel2 = new botthoughtsgcs.GaugePanel();
        gaugePanel5 = new botthoughtsgcs.GaugePanel();
        gaugePanel3 = new botthoughtsgcs.GaugePanel();
        gaugePanel4 = new botthoughtsgcs.GaugePanel();
        gaugePanel6 = new botthoughtsgcs.GaugePanel();
        jMenuBar1 = new javax.swing.JMenuBar();
        jMenu1 = new javax.swing.JMenu();
        jMenu2 = new javax.swing.JMenu();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setBackground(new java.awt.Color(102, 102, 102));

        backgroundPanel.setBackground(new java.awt.Color(255, 255, 255));
        backgroundPanel.addComponentListener(new java.awt.event.ComponentAdapter() {
            public void componentResized(java.awt.event.ComponentEvent evt) {
                backgroundPanelComponentResized(evt);
            }
        });

        gaugePanel1.setBackground(new java.awt.Color(204, 204, 204));
        gaugePanel1.setPreferredSize(new java.awt.Dimension(150, 150));
        gaugePanel1.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout gaugePanel1Layout = new javax.swing.GroupLayout(gaugePanel1);
        gaugePanel1.setLayout(gaugePanel1Layout);
        gaugePanel1Layout.setHorizontalGroup(
            gaugePanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 151, Short.MAX_VALUE)
        );
        gaugePanel1Layout.setVerticalGroup(
            gaugePanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 0, Short.MAX_VALUE)
        );

        gaugePanel2.setMinimumSize(new java.awt.Dimension(150, 150));
        gaugePanel2.setPreferredSize(new java.awt.Dimension(150, 150));
        gaugePanel2.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout gaugePanel2Layout = new javax.swing.GroupLayout(gaugePanel2);
        gaugePanel2.setLayout(gaugePanel2Layout);
        gaugePanel2Layout.setHorizontalGroup(
            gaugePanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );
        gaugePanel2Layout.setVerticalGroup(
            gaugePanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 0, Short.MAX_VALUE)
        );

        gaugePanel5.setMinimumSize(new java.awt.Dimension(150, 150));
        gaugePanel5.setPreferredSize(new java.awt.Dimension(300, 300));
        gaugePanel5.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout gaugePanel5Layout = new javax.swing.GroupLayout(gaugePanel5);
        gaugePanel5.setLayout(gaugePanel5Layout);
        gaugePanel5Layout.setHorizontalGroup(
            gaugePanel5Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 300, Short.MAX_VALUE)
        );
        gaugePanel5Layout.setVerticalGroup(
            gaugePanel5Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 300, Short.MAX_VALUE)
        );

        gaugePanel3.setBackground(new java.awt.Color(204, 204, 204));
        gaugePanel3.setMinimumSize(new java.awt.Dimension(150, 150));
        gaugePanel3.setPreferredSize(new java.awt.Dimension(150, 150));
        gaugePanel3.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout gaugePanel3Layout = new javax.swing.GroupLayout(gaugePanel3);
        gaugePanel3.setLayout(gaugePanel3Layout);
        gaugePanel3Layout.setHorizontalGroup(
            gaugePanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 153, Short.MAX_VALUE)
        );
        gaugePanel3Layout.setVerticalGroup(
            gaugePanel3Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );

        gaugePanel4.setMinimumSize(new java.awt.Dimension(300, 300));
        gaugePanel4.setPreferredSize(new java.awt.Dimension(300, 300));
        gaugePanel4.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout gaugePanel4Layout = new javax.swing.GroupLayout(gaugePanel4);
        gaugePanel4.setLayout(gaugePanel4Layout);
        gaugePanel4Layout.setHorizontalGroup(
            gaugePanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 300, Short.MAX_VALUE)
        );
        gaugePanel4Layout.setVerticalGroup(
            gaugePanel4Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 300, Short.MAX_VALUE)
        );

        gaugePanel6.setPreferredSize(new java.awt.Dimension(150, 150));
        gaugePanel6.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanel6MouseClicked(evt);
            }
        });

        javax.swing.GroupLayout backgroundPanelLayout = new javax.swing.GroupLayout(backgroundPanel);
        backgroundPanel.setLayout(backgroundPanelLayout);
        backgroundPanelLayout.setHorizontalGroup(
            backgroundPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, backgroundPanelLayout.createSequentialGroup()
                .addContainerGap()
                .addComponent(gaugePanel4, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addGroup(backgroundPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(backgroundPanelLayout.createSequentialGroup()
                        .addComponent(gaugePanel2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(gaugePanel6, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                    .addGroup(backgroundPanelLayout.createSequentialGroup()
                        .addComponent(gaugePanel1, javax.swing.GroupLayout.PREFERRED_SIZE, 151, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(gaugePanel3, javax.swing.GroupLayout.PREFERRED_SIZE, 153, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addComponent(gaugePanel5, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)))
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );
        backgroundPanelLayout.setVerticalGroup(
            backgroundPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(backgroundPanelLayout.createSequentialGroup()
                .addContainerGap()
                .addGroup(backgroundPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(backgroundPanelLayout.createSequentialGroup()
                        .addGroup(backgroundPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(gaugePanel3, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(gaugePanel1, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(backgroundPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(gaugePanel2, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addGroup(backgroundPanelLayout.createSequentialGroup()
                                .addGap(0, 0, Short.MAX_VALUE)
                                .addComponent(gaugePanel6, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))))
                    .addGroup(backgroundPanelLayout.createSequentialGroup()
                        .addGroup(backgroundPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(gaugePanel4, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(gaugePanel5, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                        .addGap(0, 0, Short.MAX_VALUE)))
                .addContainerGap())
        );

        jMenu1.setText("File");
        jMenuBar1.add(jMenu1);

        jMenu2.setText("Edit");
        jMenuBar1.add(jMenu2);

        setJMenuBar(jMenuBar1);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(backgroundPanel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(backgroundPanel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void backgroundPanelComponentResized(java.awt.event.ComponentEvent evt) {//GEN-FIRST:event_backgroundPanelComponentResized
        // TODO add your resize handling code here:
    }//GEN-LAST:event_backgroundPanelComponentResized

    private void gaugePanelMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_gaugePanelMouseClicked
        GaugePanel gaugePanel = (GaugePanel) evt.getComponent();
        gaugePanel.setNeedleAngle(gaugePanel.getNeedleAngle()+0.1);
        gaugePanel.repaint();
    }//GEN-LAST:event_gaugePanelMouseClicked

    private void gaugePanel6MouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_gaugePanel6MouseClicked
        GaugePanel gaugePanel = (GaugePanel) evt.getComponent();
        gaugePanel.setNeedleAngle(0, gaugePanel.getNeedleAngle(1)/10);
        gaugePanel.setNeedleAngle(1, gaugePanel.getNeedleAngle(1)+5*(0.105));
        gaugePanel.repaint();
     }//GEN-LAST:event_gaugePanel6MouseClicked
    
    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /*
         * Set the Nimbus look and feel
         */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /*
         * If Nimbus (introduced in Java SE 6) is not available, stay with the
         * default look and feel. For details see
         * http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(mainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(mainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(mainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(mainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /*
         * Create and display the form
         */
        java.awt.EventQueue.invokeLater(new Runnable() {

            public void run() {
                new mainWindow().setVisible(true);
            }
        });
    }
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private botthoughtsgcs.GaugePanel backgroundPanel;
    private botthoughtsgcs.GaugePanel gaugePanel1;
    private botthoughtsgcs.GaugePanel gaugePanel2;
    private botthoughtsgcs.GaugePanel gaugePanel3;
    private botthoughtsgcs.GaugePanel gaugePanel4;
    private botthoughtsgcs.GaugePanel gaugePanel5;
    private botthoughtsgcs.GaugePanel gaugePanel6;
    private javax.swing.JMenu jMenu1;
    private javax.swing.JMenu jMenu2;
    private javax.swing.JMenuBar jMenuBar1;
    // End of variables declaration//GEN-END:variables
}