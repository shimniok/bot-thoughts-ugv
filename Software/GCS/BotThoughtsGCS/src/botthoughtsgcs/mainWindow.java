/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package botthoughtsgcs;

import chrriis.common.UIUtils;
import chrriis.dj.nativeswing.NativeSwing;
import chrriis.dj.nativeswing.swtimpl.NativeInterface;
import com.colorfulwolf.webcamapplet.OpenCVWebCam;
import java.awt.BorderLayout;
import java.awt.GridBagConstraints;
import java.awt.Image;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.JFrame;
import javax.swing.SwingWorker;

/**
 *
 * @author Michael Shimniok
 */
public class mainWindow extends javax.swing.JFrame implements com.botthoughts.Parser {

    /**
     * Creates new form mainWindow
     */
    public mainWindow() {
        initComponents();
 
        NativeSwing.initialize();

        this.setTitle("Bot Thoughts GCS");
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        
        vStat = new VehicleStatus();
        vStat.setBattery(4000.0);
        vStat.setHeading(90.0);
        vStat.setCurrent(0.0);

        voltmeterPanel.setFaceImage("/botthoughtsgcs/resources/voltmeter1.png");
        voltmeterPanel.setNeedleImage("/botthoughtsgcs/resources/voltmeterneedle1.png");
        voltmeterPanel.setNeedleCenter(139.0/270.0, 189.0/269.0);
        voltmeterPanel.calibrate(0, 4.0, 12.0, 1.475);
        voltmeterPanel.setValue(vStat.getVoltage());

        ammeterPanel.setFaceImage("/botthoughtsgcs/resources/ammeter2.png");
        ammeterPanel.setNeedleImage("/botthoughtsgcs/resources/ammeterneedle2.png");
        ammeterPanel.setNeedleCenter(262.0/536.0, 382.0/536.0);
        ammeterPanel.calibrate(0, 0.0, 60.0, -0.775);
        ammeterPanel.setValue(vStat.getCurrent());
        ammeterPanel.setDamping(0.2);

        /*
        ammeterPanel.setFaceImage("/botthoughtsgcs/resources/ammeter1.png");
        ammeterPanel.setNeedleImage("/botthoughtsgcs/resources/ammeterneedle1.png");
        ammeterPanel.setNeedleCenter(295.0/596.0, 406.0/593.0);
        ammeterPanel.calibrate(0, -16.0, 15.0, 5.0);
        ammeterPanel.setValue(vStat.getCurrent());
        ammeterPanel.setDamping(0.2);
        */

        
        battPanel.setFaceImage("/botthoughtsgcs/resources/fuel1.png");
        battPanel.setNeedleImage("/botthoughtsgcs/resources/fuelneedle1.png");
        battPanel.calibrate(0, 200.0, 4000.0, 1.5);
        battPanel.setNeedleCenter(159.0/310.0, 219.0/308.0);
        battPanel.setValue(vStat.getBattery());
        
        speedometerPanel.setFaceImage("/botthoughtsgcs/resources/speedometer1.png");
        speedometerPanel.setNeedleImage("/botthoughtsgcs/resources/speedometerneedle1.png");
        speedometerPanel.setNeedleCenter(0.5, 0.5);
        speedometerPanel.calibrate(0, 120.0, 4.7);
        speedometerPanel.setValue(vStat.getSpeed());
        speedometerPanel.setDamping(0.3);
        /* Speedometer Panel */
        
        compassPanel.setFaceImage("/botthoughtsgcs/resources/compass.png");
        compassPanel.setNeedleImage(0, "/botthoughtsgcs/resources/compassneedle.png");
        compassPanel.setNeedleCenter(0, 0.5, 0.5);
        compassPanel.calibrate(0, 360, -6.2832);
        compassPanel.setValue(0, vStat.getHeading());
        compassPanel.setNeedleImage(1, "/botthoughtsgcs/resources/compassbearing.png");
        compassPanel.setNeedleCenter(1, 0.5, 0.5);
        compassPanel.calibrate(1, 360, 6.2832);
        compassPanel.setValue(1, 0);
        compassPanel.setNeedleImage(2, "/botthoughtsgcs/resources/compasstop.png");
        compassPanel.setNeedleAngle(2, 0);
        compassPanel.setDamping(0.5);
        
        clockPanel.setFaceImage("/botthoughtsgcs/resources/clock.png");
        clockPanel.setNeedleImage(0, "/botthoughtsgcs/resources/clockhour.png");
        clockPanel.setNeedleCenter(0, 0.5, 0.5);
        clockPanel.calibrate(0, 12, 6.2832);
        clockPanel.setValue(0, 4 + (25.0/60.0));
        clockPanel.setNeedleImage(1, "/botthoughtsgcs/resources/clockminute.png");
        clockPanel.setNeedleCenter(1, 0.5, 0.5);
        clockPanel.calibrate(1, 60, 6.2832);
        clockPanel.setValue(1, 25 + (10.0/60.0));
        clockPanel.setNeedleImage(2, "/botthoughtsgcs/resources/clocksecond.png");
        clockPanel.setNeedleCenter(2, 0.5, 0.5);
        clockPanel.calibrate(2, 60, 6.2832);
        clockPanel.setValue(2, 10);

        ClockUpdater cu = new ClockUpdater();
        try {
            cu.doInBackground();
        } catch (Exception ex) {
            Logger.getLogger(mainWindow.class.getName()).log(Level.SEVERE, null, ex);
        }

        buffer = "";
        serialPanel1.setHandler(this);
        logPanel1.setHandler(this);
    }

     
    /** updates clock
     *
     */
    class ClockUpdater extends SwingWorker<Void, String> {
        private GregorianCalendar cal = new GregorianCalendar();
        private TimerTask clkTask;
        private Timer clkTimer = new Timer(true);
        
        private void setClock(int h, int m, int s) {
            clockPanel.setValue(0, h + m/60.0);
            clockPanel.setValue(1, m + s/60.0);
            clockPanel.setValue(2, s);
        }
        
        public void pause() {
            clkTimer.cancel();
        }
        
        public void start() {
            clkTimer.scheduleAtFixedRate(clkTask, 0, 200);
        }
        
        @Override
        protected Void doInBackground() throws Exception {
            // Setup clock updater
            clkTask = new TimerTask() {
                public void run() {
                    cal.setTime(new Date());
                    int hour = cal.get(Calendar.HOUR);
                    int min = cal.get(Calendar.MINUTE);
                    int sec = cal.get(Calendar.SECOND);
                    setClock(hour, min, sec);
                    //System.out.println("Updating clock "+Integer.toString(hour)+":"+Integer.toString(min)+":"+Integer.toString(sec));
                };
            };
            start();
            return null;        
        }
    }
    
    public void initializeUI() {
        try {
            gePanel.initView();
            Thread.sleep(500);
            Double homeLat = 39.597751;
            Double homeLon = -104.933216;
            gePanel.setHome(homeLat, homeLon);
            initialized = true;
        } catch (InterruptedException ex) {
            Logger.getLogger(mainWindow.class.getName()).log(Level.SEVERE, null, ex);
        }
    }
    
    @Override
    public void parseData(String data) {
        int begin;
        int end;
        boolean done = false;
        
        buffer += data;
        //System.out.println("buf: <"+buffer+">");

        // TODO: incorporate time into the data stream
        while (!done) {
            begin = buffer.indexOf(SOH); // look for start of transmission
            if (begin == -1) break;     // If we don't have a start yet, wait until next time

            String sentence = buffer.substring(begin); // peel off text after SOT
            end = sentence.indexOf(EOT);                 // look for end of transmission
            if (end == -1) break;                       // if we don't have an end yet, wait until next time

            buffer = sentence.substring(end+1);        // peel off sentence part of substring
            sentence = sentence.substring(1, end);       // peel off the text before EOT
            
            String volts = sentence.substring(0,3);
            String amps = sentence.substring(3,7);
            String speed = sentence.substring(7,10);
            String heading = sentence.substring(10,14);
            String lat = sentence.substring(14,23);
            char ns = sentence.charAt(23);
            String lon = sentence.substring(24,33);
            char ew = sentence.charAt(33);
            String brg = sentence.substring(34,38);
            String dst = sentence.substring(38,42);

            if (ns == 'S') lat = "-" + lat;
            if (ew == 'W') lon = "-" + lon;

            /*
            System.out.println("volts = " + volts);
            System.out.println("amps = " + amps);
            System.out.println("speed = " + speed);
            System.out.println("heading = " + heading);
            System.out.println("lat = " + lat);
            System.out.println("lon = " + lon);
            System.out.println("brg = " + brg);
            System.out.println("dst = " + dst);
            * 
            */

            try {
                vStat.setVoltage( Double.parseDouble(volts) / 10.0 );
                vStat.setCurrent( Double.parseDouble(amps) / 10.0 );
                vStat.setHeading( Double.parseDouble(heading) / 10.0 );
                vStat.setSpeed( 2.23694 * Double.parseDouble(speed) / 10.0 ); // convert m/s to mph
                vStat.setLatitude( Double.parseDouble(lat) / 10e5 );
                vStat.setLongitude( Double.parseDouble(lon) / 10e5 );
                vStat.setBearing( Double.parseDouble(brg) / 10.0 );
                vStat.setDistance( Double.parseDouble(dst) / 10.0 );
                updateDisplay();
            } catch (Exception e) {
                // parsing error 
            }

            done = true;
        }
    }
    
    
    public void updateDisplay() {
        voltmeterPanel.updateValueDamped(vStat.getVoltage());
        ammeterPanel.updateValueDamped(vStat.getCurrent());
        speedometerPanel.updateValueDamped(vStat.getSpeed());
        compassPanel.updateValueDamped(0, vStat.getHeading());
        Double relbrg = vStat.getBearing() - vStat.getHeading();
        if (relbrg < 0) relbrg -= 360.0;
        if (relbrg >= 360) relbrg -= 360.0;
        compassPanel.updateValueDamped(1, relbrg);

        if (initialized == false) {
            initializeUI();
        }
        gePanel.setPose(vStat.getLatitude(), vStat.getLongitude(), vStat.getHeading());        
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

        backgroundPanel = new BackgroundPanel("/botthoughtsgcs/resources/background.jpg");
        speedometerPanel = new botthoughtsgcs.GaugePanel();
        voltmeterPanel = new botthoughtsgcs.GaugePanel();
        battPanel = new botthoughtsgcs.GaugePanel();
        ammeterPanel = new botthoughtsgcs.GaugePanel();
        clockPanel = new botthoughtsgcs.GaugePanel();
        compassPanel = new botthoughtsgcs.GaugePanel();
        controlPanel = new javax.swing.JPanel();
        serialPanel1 = new com.botthoughts.SerialPanel();
        logPanel1 = new botthoughtsgcs.LogPanel();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setBackground(new java.awt.Color(102, 102, 102));
        setMaximumSize(new java.awt.Dimension(1000, 450));
        setMinimumSize(new java.awt.Dimension(1000, 450));
        setPreferredSize(new java.awt.Dimension(1000, 450));
        setResizable(false);
        addWindowListener(new java.awt.event.WindowAdapter() {
            public void windowClosing(java.awt.event.WindowEvent evt) {
                formWindowClosing(evt);
            }
        });
        getContentPane().setLayout(new java.awt.GridBagLayout());

        backgroundPanel.setLayout(new java.awt.GridBagLayout());

        speedometerPanel.setMaximumSize(new java.awt.Dimension(310, 310));
        speedometerPanel.setMinimumSize(new java.awt.Dimension(310, 310));
        speedometerPanel.setPreferredSize(new java.awt.Dimension(310, 310));
        speedometerPanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout speedometerPanelLayout = new javax.swing.GroupLayout(speedometerPanel);
        speedometerPanel.setLayout(speedometerPanelLayout);
        speedometerPanelLayout.setHorizontalGroup(
            speedometerPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 310, Short.MAX_VALUE)
        );
        speedometerPanelLayout.setVerticalGroup(
            speedometerPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 310, Short.MAX_VALUE)
        );

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.gridheight = 2;
        backgroundPanel.add(speedometerPanel, gridBagConstraints);

        voltmeterPanel.setBackground(new java.awt.Color(204, 204, 204));
        voltmeterPanel.setMaximumSize(new java.awt.Dimension(150, 150));
        voltmeterPanel.setMinimumSize(new java.awt.Dimension(150, 150));
        voltmeterPanel.setName("");
        voltmeterPanel.setPreferredSize(new java.awt.Dimension(150, 150));
        voltmeterPanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout voltmeterPanelLayout = new javax.swing.GroupLayout(voltmeterPanel);
        voltmeterPanel.setLayout(voltmeterPanelLayout);
        voltmeterPanelLayout.setHorizontalGroup(
            voltmeterPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );
        voltmeterPanelLayout.setVerticalGroup(
            voltmeterPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );

        backgroundPanel.add(voltmeterPanel, new java.awt.GridBagConstraints());

        battPanel.setBackground(new java.awt.Color(204, 204, 204));
        battPanel.setMaximumSize(new java.awt.Dimension(150, 150));
        battPanel.setMinimumSize(new java.awt.Dimension(150, 150));
        battPanel.setPreferredSize(new java.awt.Dimension(150, 150));
        battPanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout battPanelLayout = new javax.swing.GroupLayout(battPanel);
        battPanel.setLayout(battPanelLayout);
        battPanelLayout.setHorizontalGroup(
            battPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );
        battPanelLayout.setVerticalGroup(
            battPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        backgroundPanel.add(battPanel, gridBagConstraints);

        ammeterPanel.setMaximumSize(new java.awt.Dimension(150, 150));
        ammeterPanel.setMinimumSize(new java.awt.Dimension(150, 150));
        ammeterPanel.setPreferredSize(new java.awt.Dimension(150, 150));
        ammeterPanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout ammeterPanelLayout = new javax.swing.GroupLayout(ammeterPanel);
        ammeterPanel.setLayout(ammeterPanelLayout);
        ammeterPanelLayout.setHorizontalGroup(
            ammeterPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );
        ammeterPanelLayout.setVerticalGroup(
            ammeterPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );

        backgroundPanel.add(ammeterPanel, new java.awt.GridBagConstraints());

        clockPanel.setMaximumSize(new java.awt.Dimension(150, 150));
        clockPanel.setMinimumSize(new java.awt.Dimension(150, 150));
        clockPanel.setPreferredSize(new java.awt.Dimension(150, 150));
        clockPanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                clockPanelMouseClicked(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 1;
        backgroundPanel.add(clockPanel, gridBagConstraints);

        compassPanel.setMaximumSize(new java.awt.Dimension(310, 310));
        compassPanel.setMinimumSize(new java.awt.Dimension(310, 310));
        compassPanel.setPreferredSize(new java.awt.Dimension(310, 310));
        compassPanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout compassPanelLayout = new javax.swing.GroupLayout(compassPanel);
        compassPanel.setLayout(compassPanelLayout);
        compassPanelLayout.setHorizontalGroup(
            compassPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 310, Short.MAX_VALUE)
        );
        compassPanelLayout.setVerticalGroup(
            compassPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 310, Short.MAX_VALUE)
        );

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 3;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.gridheight = 2;
        backgroundPanel.add(compassPanel, gridBagConstraints);

        getContentPane().add(backgroundPanel, new java.awt.GridBagConstraints());

        controlPanel.setBorder(javax.swing.BorderFactory.createEtchedBorder());
        controlPanel.setMaximumSize(new java.awt.Dimension(1000, 60));
        controlPanel.setMinimumSize(new java.awt.Dimension(1000, 60));
        controlPanel.setPreferredSize(new java.awt.Dimension(1000, 60));
        controlPanel.setLayout(new java.awt.GridBagLayout());
        controlPanel.add(serialPanel1, new java.awt.GridBagConstraints());
        controlPanel.add(logPanel1, new java.awt.GridBagConstraints());

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridy = 1;
        getContentPane().add(controlPanel, gridBagConstraints);

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void formWindowClosing(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_formWindowClosing
        //if (serialPanel1 != null) serialPanel1.handleClose();
    }//GEN-LAST:event_formWindowClosing

    private void gaugePanelMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_gaugePanelMouseClicked
        GaugePanel gaugePanel = (GaugePanel) evt.getComponent();
        gaugePanel.setNeedleAngle(gaugePanel.getNeedleAngle() + 0.05);
        gaugePanel.repaint();
    }//GEN-LAST:event_gaugePanelMouseClicked

    private void clockPanelMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_clockPanelMouseClicked
        GaugePanel gaugePanel = (GaugePanel) evt.getComponent();
        gaugePanel.setNeedleAngle(0, gaugePanel.getNeedleAngle(1) / 10);
        gaugePanel.setNeedleAngle(1, gaugePanel.getNeedleAngle(1) + 5 * (0.105));
        gaugePanel.repaint();
    }//GEN-LAST:event_clockPanelMouseClicked
       
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

            @Override
            public void run() {
                new mainWindow().setVisible(true);

                // Setup DJ NativeSwing web browser
                UIUtils.setPreferredLookAndFeel();
                NativeInterface.open();

                gePanel = new GEPanel();
                System.out.println("in run");
                JFrame gef = new JFrame("Google Earth View");
                gef.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                gef.getContentPane().add(gePanel, BorderLayout.CENTER);
                gef.setSize(800, 600);
                gef.setLocationByPlatform(true);
                gef.setVisible(true);
                //NativeInterface.runEventPump(); // this doesn't seem to want to work
                cvf = new WebCamWindow();
                Runnable loader = new Runnable() {
                    @Override
                    public void run() {
                        cvf.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
                        //cvf.getContentPane().add(cvPanel, BorderLayout.CENTER);
                        cvf.setSize(800, 600);
                        cvf.setLocationByPlatform(true);
                        cvf.setVisible(true);
                    }
                };
                new Thread(loader).start();                
                
                //                cvPanel = new OpenCVWebCam(0, 800, 600);
            }
        });
    }
    
 
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private botthoughtsgcs.GaugePanel ammeterPanel;
    private javax.swing.JPanel backgroundPanel;
    private botthoughtsgcs.GaugePanel battPanel;
    private botthoughtsgcs.GaugePanel clockPanel;
    private botthoughtsgcs.GaugePanel compassPanel;
    private javax.swing.JPanel controlPanel;
    private botthoughtsgcs.LogPanel logPanel1;
    private com.botthoughts.SerialPanel serialPanel1;
    private botthoughtsgcs.GaugePanel speedometerPanel;
    private botthoughtsgcs.GaugePanel voltmeterPanel;
    // End of variables declaration//GEN-END:variables
    private static botthoughtsgcs.GEPanel gePanel;
    private static OpenCVWebCam cvPanel;
    private static WebCamWindow cvf;
    String buffer;
    static char SOH=0x01;
    static char EOT='\n';
    VehicleStatus vStat;
    boolean initialized=false;
}
