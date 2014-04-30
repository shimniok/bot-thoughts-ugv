/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package botthoughtsgcs;

import java.awt.Dimension;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.JFrame;
import javax.swing.SwingWorker;

/**
 *
 * @author Michael Shimniok
 */
public class MainWindow extends JFrame implements VehicleStatus {
    private final GaugeNeedle voltmeterNeedle;
    private final GaugeNeedle ammeterNeedle;
    private final GaugeNeedle gpsNeedle;
    private final GaugeNeedle speedometerNeedle;
    private final GaugeNeedle compassNeedle;
    private final GaugeNeedle bearingNeedle;
    private final GaugeNeedle topNeedle;
    private final GaugeNeedle hourNeedle;
    private final GaugeNeedle minuteNeedle;
    private final GaugeNeedle secondNeedle;
    private final DoubleProperty hourProperty;
    private final DoubleProperty minuteProperty;
    private final DoubleProperty secondProperty;
    private final DoubleProperty voltage;
    private final DoubleProperty current;
    private final DoubleProperty satcount;
    private final DoubleProperty speed;
    private final DoubleProperty bearing;
    private final DoubleProperty heading;
    private final DoubleProperty longitude;
    private final DoubleProperty latitude;
    private final DoubleProperty distance;
    private final DoubleProperty topProperty;
    private final DoubleProperty battery;
    
    /**
     * Creates new form mainWindow
     */
    public MainWindow() {
        initComponents();
 
        speedometerPanel.setSize(new Dimension(310, 310));
        System.out.println(speedometerPanel.getSize());
        //NativeSwing.initialize();

        this.setTitle("Bot Thoughts GCS");
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        // Set the handler for serial panel to parse data
        // This parser points to our model, vehicleStatus
        serialPanel.setHandler(new TelemetryParser(this));

        latitude = new DoubleProperty(0);
        longitude = new DoubleProperty(0);
        distance = new DoubleProperty(0);
        
        voltmeterPanel.setImage("/botthoughtsgcs/resources/voltmeter1.png");
        voltmeterNeedle = new GaugeNeedle();
        voltmeterPanel.addNeedle(voltmeterNeedle);
        voltmeterNeedle.setDamping(0.3);
        voltmeterNeedle.setImage("/botthoughtsgcs/resources/voltmeterneedle1.png");
        voltmeterNeedle.setRotationCenter(139.0/270.0, 189.0/269.0);
        voltmeterNeedle.calibrate(7.0, 9.0, 1.475);
        voltage = new DoubleProperty(0);
        voltage.addListener((ChangeListener) voltmeterNeedle);
        voltage.set(0.1);
        
        ammeterPanel.setImage("/botthoughtsgcs/resources/ammeter3.png");
        ammeterNeedle = new GaugeNeedle();
        ammeterPanel.addNeedle(ammeterNeedle);
        ammeterNeedle.setDamping(0.2);
        ammeterNeedle.setImage("/botthoughtsgcs/resources/ammeterneedle3.png");
        ammeterNeedle.setRotationCenter(139.0/270.0, 189.0/269.0);
        ammeterNeedle.calibrate(0.0, 10.0, -0.7375);
        current = new DoubleProperty(0);
        current.addListener((ChangeListener) ammeterNeedle);
        current.set(0);
  
        gpsPanel.setImage("/botthoughtsgcs/resources/gps.png");
        gpsNeedle = new GaugeNeedle();
        gpsPanel.addNeedle(gpsNeedle);
        gpsNeedle.setDamping(0.4);
        gpsNeedle.setImage("/botthoughtsgcs/resources/gpsneedle.png");
        gpsNeedle.setRotationCenter(261.0/536.0, 381.0/536.0);
        gpsNeedle.calibrate(0.0, 14.0, 1.475);
        satcount = new DoubleProperty(0);
        satcount.addListener((ChangeListener) gpsNeedle);
        satcount.set(0); // TODO: parameterize this, turn into percentage somehow?

        
//        batteryPanel.setImage("/botthoughtsgcs/resources/fuel1.png");
//        batteryNeedle = new GaugeNeedle();
//        batteryPanel.addNeedle(batteryNeedle);
//        batteryNeedle.setImage("/botthoughtsgcs/resources/fuelneedle1.png");
//        batteryNeedle.calibrate(200.0, 4000.0, 1.5);
//        batteryNeedle.setRotationCenter(159.0/310.0, 219.0/308.0);
        battery = new DoubleProperty(0);
//        battery.addListener((ChangeListener) batteryNeedle);
        battery.set(4000); // TODO: parameterize this, turn into percentage somehow?
                
        speedometerPanel.setImage("/botthoughtsgcs/resources/speedometer1.png");
        speedometerNeedle = new GaugeNeedle();
        speedometerPanel.addNeedle(speedometerNeedle);
        speedometerNeedle.setImage("/botthoughtsgcs/resources/speedometerneedle1.png");
        speedometerNeedle.setRotationCenter(0.5, 0.5);
        speedometerNeedle.calibrate(0, 60.0, 4.7);
        speedometerNeedle.setDamping(0.3);
        speed = new DoubleProperty(0);
        speed.addListener((ChangeListener) speedometerNeedle);
        speed.set(0);
        
        compassPanel.setImage("/botthoughtsgcs/resources/compass.png");
        compassNeedle = new GaugeNeedle();
        compassPanel.addNeedle(compassNeedle);
        compassNeedle.setImage("/botthoughtsgcs/resources/compassneedle.png");
        compassNeedle.setDamping(0.3);
        compassNeedle.setRotationCenter(0.5, 0.5);
        compassNeedle.calibrate(0, 360, -6.2832, true);
        heading = new DoubleProperty(0);
        heading.addListener((ChangeListener) compassNeedle);
        heading.set(0);
        
        bearingNeedle = new GaugeNeedle();
        compassPanel.addNeedle(bearingNeedle);
        bearingNeedle.setImage("/botthoughtsgcs/resources/compassbearing.png");
        bearingNeedle.setRotationCenter(0.5, 0.5);
        bearingNeedle.calibrate(0, 360, 6.2832, true);
        bearing = new DoubleProperty(0);;
        bearing.addListener((ChangeListener) bearingNeedle);
        bearing.set(0);

        topNeedle = new GaugeNeedle();
        compassPanel.addNeedle(topNeedle);
        topNeedle.setImage("/botthoughtsgcs/resources/compasstop.png");
        topNeedle.setRotationCenter(0.5, 0.5);
        topNeedle.calibrate(0, 360, 6.2832);
        topProperty = new DoubleProperty(0);
        topProperty.addListener((ChangeListener) topNeedle);
        topProperty.set(0);
        
        clockPanel.setImage("/botthoughtsgcs/resources/clock.png");
        hourNeedle = new GaugeNeedle();
        clockPanel.addNeedle(hourNeedle);
        hourNeedle.setImage("/botthoughtsgcs/resources/clockhour.png");
        hourNeedle.setRotationCenter(0.5, 0.5);
        hourNeedle.calibrate(12, 6.2832);
        hourProperty = new DoubleProperty(0);
        hourProperty.addListener((ChangeListener) hourNeedle);

        minuteNeedle = new GaugeNeedle();
        clockPanel.addNeedle(minuteNeedle);
        minuteNeedle.setImage("/botthoughtsgcs/resources/clockminute.png");
        minuteNeedle.setRotationCenter(0.5, 0.5);
        minuteNeedle.calibrate(60, 6.2832);
        minuteProperty = new DoubleProperty(0);
        minuteProperty.addListener((ChangeListener) minuteNeedle);
        
        secondNeedle = new GaugeNeedle();
        clockPanel.addNeedle(secondNeedle);
        secondNeedle.setImage("/botthoughtsgcs/resources/clocksecond.png");
        secondNeedle.setRotationCenter(0.5, 0.5);
        secondNeedle.calibrate(60, 6.2832);
        secondProperty = new DoubleProperty(0);
        secondProperty.addListener((ChangeListener) secondNeedle);
        
        ClockUpdater cu = new ClockUpdater();
        try {
            cu.doInBackground();
        } catch (Exception ex) {
            Logger.getLogger(MainWindow.class.getName()).log(Level.SEVERE, null, ex);
        }
    }


    /** updates clock
     *
     */
    class ClockUpdater extends SwingWorker<Void, String> {
        private GregorianCalendar cal = new GregorianCalendar();
        private TimerTask clkTask;
        private Timer clkTimer = new Timer(true);
        
        public void pause() {
            clkTimer.cancel();
        }
        
        public void start() {
            clkTimer.scheduleAtFixedRate(clkTask, 0, 1000);
        }
        
        @Override
        protected Void doInBackground() throws Exception {
            // Setup clock updater
            clkTask = new TimerTask() {
                @Override
                public void run() {
                    cal.setTime(new Date());
                    int hour = cal.get(Calendar.HOUR);
                    int min = cal.get(Calendar.MINUTE);
                    int sec = cal.get(Calendar.SECOND);
                    hourProperty.set(hour + min/60.0);
                    minuteProperty.set(min + sec/60.0);
                    secondProperty.set(sec);   
                };
            };
            start();
            return null;        
        }
    }
    
    public void initializeUI() {
        try {
            //gePanel.initView();
            Thread.sleep(500);
            //Double homeLat = 39.597751;
            //Double homeLon = -104.933216;
            //gePanel.setHome(homeLat, homeLon);
            initialized = true;
        } catch (InterruptedException ex) {
            Logger.getLogger(MainWindow.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    public void updateDisplay() {
    /*
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
        //gePanel.setPose(vStat.getLatitude(), vStat.getLongitude(), vStat.getHeading());        
        */
    }
    
    @Override
    public double getVoltage() {
        return voltage.get();
    }

    @Override
    public double getCurrent() {
        return current.get();
    }

    @Override
    public double getBattery() {
        return satcount.get();
    }

    @Override
    public double getSpeed() {
        return speed.get();
    }

    @Override
    public double getHeading() {
        return heading.get();
    }

    @Override
    public double getLatitude() {
        return latitude.get();
    }

    @Override
    public double getLongitude() {
        return longitude.get();
    }

    @Override
    public double getSatCount() {
        return satcount.get();
    }

    @Override
    public double getBearing() {
        return bearing.get();
    }

    @Override
    public double getDistance() {
        return distance.get();
    }

        @Override
    public void setVoltage(double v) {
        voltage.set(v);
    }

    @Override
    public void setCurrent(double v) {
        current.set(v);        
    }

    @Override
    public void setBattery(double v) {
        satcount.set(v);
    }

    @Override
    public void setSpeed(double v) {
        speed.set(v);
    }

    @Override
    public void setHeading(double v) {
        heading.set(v);
    }

    @Override
    public void setLatitude(double v) {
        latitude.set(v);
    }

    @Override
    public void setLongitude(double v) {
        longitude.set(v);
    }

    @Override
    public void setSatCount(double v) {
        satcount.set(v);
    }
    
    @Override
    public void setBearing(double v) {
        bearing.set(v);
    }

    @Override
    public void setDistance(double v) {
        distance.set(v);
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
        gpsPanel = new botthoughtsgcs.GaugePanel();
        ammeterPanel = new botthoughtsgcs.GaugePanel();
        clockPanel = new botthoughtsgcs.GaugePanel();
        compassPanel = new botthoughtsgcs.GaugePanel();
        controlPanel = new javax.swing.JPanel();
        serialPanel = new com.botthoughts.SerialPanel();
        logPanel = new botthoughtsgcs.LogPanel();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setBackground(new java.awt.Color(102, 102, 102));
        setMaximumSize(new java.awt.Dimension(1000, 400));
        setMinimumSize(new java.awt.Dimension(1000, 400));
        setPreferredSize(new java.awt.Dimension(1000, 400));
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
        voltmeterPanel.setName(""); // NOI18N
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

        gpsPanel.setBackground(new java.awt.Color(204, 204, 204));
        gpsPanel.setMaximumSize(new java.awt.Dimension(150, 150));
        gpsPanel.setMinimumSize(new java.awt.Dimension(150, 150));
        gpsPanel.setPreferredSize(new java.awt.Dimension(150, 150));
        gpsPanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                gaugePanelMouseClicked(evt);
            }
        });

        javax.swing.GroupLayout gpsPanelLayout = new javax.swing.GroupLayout(gpsPanel);
        gpsPanel.setLayout(gpsPanelLayout);
        gpsPanelLayout.setHorizontalGroup(
            gpsPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );
        gpsPanelLayout.setVerticalGroup(
            gpsPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 150, Short.MAX_VALUE)
        );

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        backgroundPanel.add(gpsPanel, gridBagConstraints);

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
        controlPanel.setMaximumSize(new java.awt.Dimension(10000, 10000));
        controlPanel.setMinimumSize(new java.awt.Dimension(900, 60));
        controlPanel.setPreferredSize(new java.awt.Dimension(900, 60));
        controlPanel.setLayout(new java.awt.GridBagLayout());
        controlPanel.add(serialPanel, new java.awt.GridBagConstraints());
        controlPanel.add(logPanel, new java.awt.GridBagConstraints());

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridy = 1;
        getContentPane().add(controlPanel, gridBagConstraints);

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void formWindowClosing(java.awt.event.WindowEvent evt) {//GEN-FIRST:event_formWindowClosing
        //if (serialPanel1 != null) serialPanel1.handleClose();
    }//GEN-LAST:event_formWindowClosing

    private void gaugePanelMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_gaugePanelMouseClicked
//TODO Remove this
//        GaugePanel gaugePanel = (GaugePanel) evt.getComponent();
//        gaugePanel.setNeedleAngle(gaugePanel.getNeedleAngle() + 0.05);
//        gaugePanel.repaint();
    }//GEN-LAST:event_gaugePanelMouseClicked

    private void clockPanelMouseClicked(java.awt.event.MouseEvent evt) {//GEN-FIRST:event_clockPanelMouseClicked
//TODO Remove this
//        GaugePanel gaugePanel = (GaugePanel) evt.getComponent();
//        gaugePanel.setNeedleAngle(0, gaugePanel.getNeedleAngle(1) / 10);
//        gaugePanel.setNeedleAngle(1, gaugePanel.getNeedleAngle(1) + 5 * (0.105));
//        gaugePanel.repaint();
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
        } catch (ClassNotFoundException | InstantiationException | IllegalAccessException | javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /*
         * Create and display the form
         */
        java.awt.EventQueue.invokeLater(new Runnable() {

            @Override
            public void run() {
                new MainWindow().setVisible(true);
                
                // Setup DJ NativeSwing web browser
                //UIUtils.setPreferredLookAndFeel();
                //NativeInterface.open();

                //gePanel = new GoogleEarthPanel();
                System.out.println("in run");
                /*
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
                */
                //cvPanel = new OpenCVWebCam(0, 800, 600);
            }
        });
    }
    
 
    
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private botthoughtsgcs.GaugePanel ammeterPanel;
    private javax.swing.JPanel backgroundPanel;
    private botthoughtsgcs.GaugePanel clockPanel;
    private botthoughtsgcs.GaugePanel compassPanel;
    private javax.swing.JPanel controlPanel;
    private botthoughtsgcs.GaugePanel gpsPanel;
    private botthoughtsgcs.LogPanel logPanel;
    private com.botthoughts.SerialPanel serialPanel;
    private botthoughtsgcs.GaugePanel speedometerPanel;
    private botthoughtsgcs.GaugePanel voltmeterPanel;
    // End of variables declaration//GEN-END:variables
    //private static botthoughtsgcs.GoogleEarthPanel gePanel;
    //private static OpenCVWebCam cvPanel;
    //private static WebCamWindow cvf;
    boolean initialized=false;
}
