/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author Michael Shimniok
 */
public class WebCamWindow extends javax.swing.JFrame {

    //private List<Integer> devices = new ArrayList<Integer>();
    //private OpenCVWebCam webCam;
    
    /**
     * Creates new form WebCamWindow
     */
    public WebCamWindow() {
        this.setTitle("Web Cam View");
        initComponents();
        //OpenCVWebCam cv = new OpenCVWebCam(0, 800, 600);
        //this.add(cv);
        int fps = (int) camPanel.getFps();
        fpsLabel.setText(Integer.toString(fps)+" fps");
        fpsSlider.setValue(fps);        
    }
    
    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {
        java.awt.GridBagConstraints gridBagConstraints;

        camPanel = new com.colorfulwolf.webcamapplet.gui.OpenCVCamPanel();
        jPanel1 = new javax.swing.JPanel();
        jPanel2 = new javax.swing.JPanel();
        jPanel3 = new javax.swing.JPanel();
        startStopButton = new javax.swing.JToggleButton();
        fpsSlider = new javax.swing.JSlider();
        fpsLabel = new java.awt.Label();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosing(java.awt.event.WindowEvent evt) {
                formWindowClosing(evt);
            }
        });
        getContentPane().setLayout(new java.awt.GridBagLayout());

        camPanel.setFocusable(false);
        camPanel.setMaximumSize(new java.awt.Dimension(320, 240));
        camPanel.setMinimumSize(new java.awt.Dimension(320, 240));
        camPanel.setPreferredSize(new java.awt.Dimension(320, 240));

        javax.swing.GroupLayout camPanelLayout = new javax.swing.GroupLayout(camPanel);
        camPanel.setLayout(camPanelLayout);
        camPanelLayout.setHorizontalGroup(
            camPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 702, Short.MAX_VALUE)
        );
        camPanelLayout.setVerticalGroup(
            camPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 501, Short.MAX_VALUE)
        );

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipadx = 382;
        gridBagConstraints.ipady = 261;
        gridBagConstraints.insets = new java.awt.Insets(5, 0, 5, 0);
        getContentPane().add(camPanel, gridBagConstraints);

        javax.swing.GroupLayout jPanel1Layout = new javax.swing.GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 0, Short.MAX_VALUE)
        );
        jPanel1Layout.setVerticalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 0, Short.MAX_VALUE)
        );

        getContentPane().add(jPanel1, new java.awt.GridBagConstraints());

        javax.swing.GroupLayout jPanel2Layout = new javax.swing.GroupLayout(jPanel2);
        jPanel2.setLayout(jPanel2Layout);
        jPanel2Layout.setHorizontalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 0, Short.MAX_VALUE)
        );
        jPanel2Layout.setVerticalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 0, Short.MAX_VALUE)
        );

        getContentPane().add(jPanel2, new java.awt.GridBagConstraints());

        startStopButton.setText("Start");
        startStopButton.setMaximumSize(new java.awt.Dimension(70, 23));
        startStopButton.setMinimumSize(new java.awt.Dimension(70, 23));
        startStopButton.setPreferredSize(new java.awt.Dimension(70, 23));
        startStopButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                startStopButtonActionPerformed(evt);
            }
        });
        jPanel3.add(startStopButton);

        fpsSlider.setMaximum(30);
        fpsSlider.setMinimum(5);
        fpsSlider.setMinorTickSpacing(1);
        fpsSlider.setValue(10);
        fpsSlider.setMaximumSize(new java.awt.Dimension(200, 25));
        fpsSlider.setMinimumSize(new java.awt.Dimension(200, 25));
        fpsSlider.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                fpsSliderMouseClicked(evt);
            }
        });
        fpsSlider.addMouseMotionListener(new java.awt.event.MouseMotionAdapter() {
            public void mouseDragged(java.awt.event.MouseEvent evt) {
                fpsSliderMouseDragged(evt);
            }
        });
        jPanel3.add(fpsSlider);

        fpsLabel.setText("10 fps");
        jPanel3.add(fpsLabel);
        fpsLabel.getAccessibleContext().setAccessibleName("fpsLabel");

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        getContentPane().add(jPanel3, gridBagConstraints);

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void formWindowClosing(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_formWindowClosing
        camPanel.stop();
    }//GEN-LAST:event_formWindowClosing

    private void startStopButtonActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_startStopButtonActionPerformed
        if (startStopButton.getText().equals("Start")) {
            try {
                camPanel.start();
                startStopButton.setText("Stop");
                fpsSlider.setEnabled(false);
            } catch (Exception ex) {
                Logger.getLogger(WebCamWindow.class.getName()).log(Level.SEVERE, null, ex);
            }

        } else {
            startStopButton.setText("Start");
            camPanel.stop();
            fpsSlider.setEnabled(true);
        }
    }//GEN-LAST:event_startStopButtonActionPerformed

    private void adjustFps() {
        int fps = fpsSlider.getValue();
        fpsLabel.setText(Integer.toString(fps)+" fps");
        camPanel.setFps(fps);
        System.out.println("FPS: "+Double.toString(camPanel.getFps()));
    }
    
    private void fpsSliderMouseDragged(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_fpsSliderMouseDragged
        adjustFps();
    }//GEN-LAST:event_fpsSliderMouseDragged

    private void fpsSliderMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_fpsSliderMouseClicked
        adjustFps();
    }//GEN-LAST:event_fpsSliderMouseClicked

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
            java.util.logging.Logger.getLogger(WebCamWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(WebCamWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(WebCamWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(WebCamWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /*
         * Create and display the form
         */
        java.awt.EventQueue.invokeLater(new Runnable() {

            @Override
            public void run() {
                new WebCamWindow().setVisible(true);
            }
        });
    }
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private com.colorfulwolf.webcamapplet.gui.OpenCVCamPanel camPanel;
    private java.awt.Label fpsLabel;
    private javax.swing.JSlider fpsSlider;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JPanel jPanel3;
    private javax.swing.JToggleButton startStopButton;
    // End of variables declaration//GEN-END:variables
}