/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import com.botthoughts.SerialPanel;
import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.EventQueue;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.BorderFactory;
import javax.swing.BoxLayout;
import javax.swing.GroupLayout;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.SwingWorker;
import javax.swing.UIManager;
import javax.swing.UnsupportedLookAndFeelException;
import javax.swing.WindowConstants;

/**
 *
 * @author Michael Shimniok
 */
public final class MainWindow extends JFrame implements VehicleStatus, ActionListener {
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
    private final IndicatorLight timeoutIndicator;
    private final IndicatorLight gpsIndicator;
    private final IndicatorLight batteryIndicator;
    private final DoubleProperty hourProperty;
    private final DoubleProperty minuteProperty;
    private final DoubleProperty secondProperty;
    private final DoubleProperty voltage;
    private final BooleanProperty volterr;
    private final DoubleProperty current;
    private final DoubleProperty satcount;
    private final BooleanProperty gpserr;
    private final DoubleProperty speed;
    private final DoubleProperty bearing;
    private final DoubleProperty heading;
    private final DoubleProperty longitude;
    private final DoubleProperty latitude;
    private final DoubleProperty distance;
    private final DoubleProperty topProperty;
    private final DoubleProperty battery;
    private final BooleanProperty timeout;
    private static int largeSize = 300;
    private static int smallSize = 120;
    private IndicatorPanel indicatorPanel;
    private GaugePanel ammeterPanel;
    private JPanel backgroundPanel;
    private GaugePanel clockPanel;
    private GaugePanel compassPanel;
    private JPanel controlPanel;
    private GaugePanel gpsPanel;
    private LogPanel logPanel;
    private SerialPanel serialPanel;
    private GaugePanel speedometerPanel;
    private GaugePanel voltmeterPanel;
    private static JFrame mapFrame;
    private static MapWindow mapWindow;
    //private static botthoughtsgcs.GoogleEarthPanel gePanel;
    //private static OpenCVWebCam cvPanel;
    //private static WebCamWindow cvf;
    boolean initialized=false;
    private final IntegerProperty nextWaypoint;
    private JButton reset;
    
    /**
     * Creates new form mainWindow
     */
    public MainWindow() {
        initComponents();
        
        speedometerPanel.setSize(new Dimension(largeSize, largeSize));
        System.out.println(speedometerPanel.getSize());
        //NativeSwing.initialize();

        this.setTitle("Bot Thoughts GCS");
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        
        latitude = new DoubleProperty(0);
        longitude = new DoubleProperty(0);
        distance = new DoubleProperty(0);
        timeout = new BooleanProperty(false);
        gpserr = new BooleanProperty(false);
        volterr = new BooleanProperty(false);
        nextWaypoint = new IntegerProperty(0);

        /* Comm watchdog */
        WatchDog wd = new WatchDog(3, timeout);
        try {
            wd.doInBackground();
            wd.start();
        } catch (Exception ex) {
            Logger.getLogger(MainWindow.class.getName()).log(Level.SEVERE, null, ex);
        }
        
        // Set the handler for serial panel to parse data
        // This parser points to our model, vehicleStatus
        serialPanel.setHandler(new TelemetryParser(this, wd));       
        
        indicatorPanel.setImage("resources/indicatorpanel.png");
        timeoutIndicator = new IndicatorLight();
        timeoutIndicator.setImage("resources/indicator_comm_red.png");
        indicatorPanel.addIndicator(timeoutIndicator);
        timeout.addListener((ChangeListener) timeoutIndicator);
        
        gpsIndicator = new IndicatorLight();
        gpsIndicator.setImage("resources/indicator_gps_red.png");
        indicatorPanel.addIndicator(gpsIndicator);
        gpserr.addListener((ChangeListener) gpsIndicator);
        
        batteryIndicator = new IndicatorLight();
        batteryIndicator.setImage("resources/indicator_batt_red.png");
        indicatorPanel.addIndicator(batteryIndicator);
        volterr.addListener((ChangeListener) batteryIndicator);                
        
        voltmeterPanel.setImage("resources/voltmeter1.png");
        voltmeterNeedle = new GaugeNeedle();
        voltmeterPanel.addNeedle(voltmeterNeedle);
        voltmeterNeedle.setImage("resources/voltmeterneedle1.png");
        voltmeterNeedle.setRotationCenter(139.0/270.0, 189.0/269.0);
        voltmeterNeedle.setCalibration(7.0, 9.0, 1.475);
        voltage = new DoubleProperty(0);
        voltage.addListener((ChangeListener) voltmeterNeedle);
        setVoltage(0);
        voltmeterNeedle.setDamping(0.3);
        
        ammeterPanel.setImage("resources/ammeter3.png");
        ammeterNeedle = new GaugeNeedle();
        ammeterPanel.addNeedle(ammeterNeedle);
        ammeterNeedle.setImage("resources/ammeterneedle3.png");
        ammeterNeedle.setRotationCenter(139.0/270.0, 189.0/269.0);
        ammeterNeedle.setCalibration(0.0, 10.0, -0.7375);
        current = new DoubleProperty(0);
        current.addListener((ChangeListener) ammeterNeedle);
        current.set(0);
        ammeterNeedle.setDamping(0.2);
  
        gpsPanel.setImage("resources/gps.png");
        gpsNeedle = new GaugeNeedle();
        gpsPanel.addNeedle(gpsNeedle);
        gpsNeedle.setImage("resources/gpsneedle.png");
        gpsNeedle.setRotationCenter(261.0/536.0, 381.0/536.0);
        gpsNeedle.setCalibration(0.0, 14.0, 1.475);
        satcount = new DoubleProperty(0);
        satcount.addListener((ChangeListener) gpsNeedle);
        setSatCount(0);
        gpsNeedle.setDamping(0.4);

        
//        batteryPanel.setImage("resources/fuel1.png");
//        batteryNeedle = new GaugeNeedle();
//        batteryPanel.addNeedle(batteryNeedle);
//        batteryNeedle.setImage("resources/fuelneedle1.png");
//        batteryNeedle.calibrate(200.0, 4000.0, 1.5);
//        batteryNeedle.setRotationCenter(159.0/largeSize.0, 219.0/308.0);
        battery = new DoubleProperty(0);
//        battery.addListener((ChangeListener) batteryNeedle);
        battery.set(4000); // TODO: parameterize this, turn into percentage somehow?
                
        speedometerPanel.setImage("resources/speedometer1.png");
        speedometerNeedle = new GaugeNeedle();
        speedometerPanel.addNeedle(speedometerNeedle);
        speedometerNeedle.setImage("resources/speedometerneedle1.png");
        speedometerNeedle.setRotationCenter(0.5, 0.5);
        speedometerNeedle.setCalibration(0, 60.0, 4.7);
        speed = new DoubleProperty(0);
        speed.addListener((ChangeListener) speedometerNeedle);
        speed.set(0);
        speedometerNeedle.setDamping(0.3);
        
        compassPanel.setImage("resources/compass.png");
        compassNeedle = new GaugeNeedle();
        compassPanel.addNeedle(compassNeedle);
        compassNeedle.setImage("resources/compassneedle.png");
        compassNeedle.setRotationCenter(0.5, 0.5);
        compassNeedle.setCalibration(0, 360, -6.2832, true);
        heading = new DoubleProperty(0);
        heading.addListener((ChangeListener) compassNeedle);
        heading.set(0);
        compassNeedle.setDamping(0.3);
        
        bearingNeedle = new GaugeNeedle();
        compassPanel.addNeedle(bearingNeedle);
        bearingNeedle.setImage("resources/compassbearing.png");
        bearingNeedle.setRotationCenter(0.5, 0.5);
        bearingNeedle.setCalibration(0, 360, 6.2832, true);
        bearing = new DoubleProperty(0);
        bearing.addListener((ChangeListener) bearingNeedle);
        bearing.set(0);

        topNeedle = new GaugeNeedle();
        compassPanel.addNeedle(topNeedle);
        topNeedle.setImage("resources/compasstop.png");
        topNeedle.setRotationCenter(0.5, 0.5);
        topNeedle.setCalibration(0, 360, 6.2832);
        topProperty = new DoubleProperty(0);
        topProperty.addListener((ChangeListener) topNeedle);
        topProperty.set(0);
        
        clockPanel.setImage("resources/clock.png");
        hourNeedle = new GaugeNeedle();
        clockPanel.addNeedle(hourNeedle);
        hourNeedle.setImage("resources/clockhour.png");
        hourNeedle.setRotationCenter(0.5, 0.5);
        hourNeedle.setCalibration(12, 6.2832);
        hourProperty = new DoubleProperty(0);
        hourProperty.addListener((ChangeListener) hourNeedle);

        minuteNeedle = new GaugeNeedle();
        clockPanel.addNeedle(minuteNeedle);
        minuteNeedle.setImage("resources/clockminute.png");
        minuteNeedle.setRotationCenter(0.5, 0.5);
        minuteNeedle.setCalibration(60, 6.2832);
        minuteProperty = new DoubleProperty(0);
        minuteProperty.addListener((ChangeListener) minuteNeedle);
        
        secondNeedle = new GaugeNeedle();
        clockPanel.addNeedle(secondNeedle);
        secondNeedle.setImage("resources/clocksecond.png");
        secondNeedle.setRotationCenter(0.5, 0.5);
        secondNeedle.setCalibration(60, 6.2832);
        secondProperty = new DoubleProperty(0);
        secondProperty.addListener((ChangeListener) secondNeedle);
        
        ClockUpdater cu = new ClockUpdater();
        try {
            cu.doInBackground();
        } catch (Exception ex) {
            Logger.getLogger(MainWindow.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    @Override
    public void actionPerformed(ActionEvent e) {
        Object source = e.getSource();
        if (source.getClass() == JButton.class) {
            JButton b = (JButton) source;
            if (b.getName() == "reset") {
                System.out.println("Reset!!");
            }
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
        volterr.set(v < 3.5 * 2); // TODO: parametric thresholds
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
        mapWindow.setHeading(v);
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
    public void setPosition(Coordinate v) {
        mapWindow.setPosition(v.getX(), v.getY());
    }
    
    @Override
    public void setLookahead(Coordinate v) {
        mapWindow.setLookAhead(v.getX(), v.getY());
    }
        
    @Override
    public void setWaypoints(ArrayList<Coordinate> wpt) {
        mapWindow.setWaypoints(wpt);
    }

    @Override
    public void setSatCount(double v) {
        satcount.set(v);
        // too few satellites?
        gpserr.set( v < 4 ); // TODO: parametric thresholds
    }
    
    @Override
    public void setBearing(double v) {
        bearing.set(v);
    }

    @Override
    public void setDistance(double v) {
        distance.set(v);
    }
    
    @Override
    public void setNextWaypoint(int v) {
        mapWindow.setNextWaypoint(v);
    }


    private void initComponents() {
        GridBagConstraints c;

        backgroundPanel = new BackgroundPanel("resources/background.jpg");
        speedometerPanel = new GaugePanel();
        voltmeterPanel = new GaugePanel();
        gpsPanel = new GaugePanel();
        ammeterPanel = new GaugePanel();
        clockPanel = new GaugePanel();
        compassPanel = new GaugePanel();
        controlPanel = new JPanel();
        serialPanel = new SerialPanel();
//        logPanel = new LogPanel();
        indicatorPanel = new IndicatorPanel();
        
        setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
        setBackground(new Color(102, 102, 102));
        setMaximumSize(new Dimension(1500, 600));
        setMinimumSize(new Dimension(500, 200));
        setPreferredSize(new Dimension(1000, 400));
        setResizable(true);
        addWindowListener(new WindowAdapter() {
            @Override
            public void windowClosing(WindowEvent evt) {
                formWindowClosing(evt);
            }
        });
//        getContentPane().setLayout(new GridBagLayout());
        
        backgroundPanel.setLayout(new GridBagLayout());
        
        speedometerPanel.setMaximumSize(new Dimension(largeSize, largeSize));
        speedometerPanel.setMinimumSize(new Dimension(largeSize, largeSize));
        speedometerPanel.setPreferredSize(new Dimension(largeSize, largeSize));

        GroupLayout speedometerPanelLayout = new GroupLayout(speedometerPanel);
        speedometerPanel.setLayout(speedometerPanelLayout);
        speedometerPanelLayout.setHorizontalGroup(
            speedometerPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, largeSize, Short.MAX_VALUE)
        );
        speedometerPanelLayout.setVerticalGroup(
            speedometerPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, largeSize, Short.MAX_VALUE)
        );

        c = new GridBagConstraints();
        c.gridx = 0;
        c.gridy = 0;
        c.gridheight = 3;
        backgroundPanel.add(speedometerPanel, c);

        indicatorPanel.setMaximumSize(new Dimension(smallSize*2, 40));
        indicatorPanel.setMinimumSize(new Dimension(smallSize*2, 40));
        indicatorPanel.setPreferredSize(new Dimension(smallSize*2, 40));
        indicatorPanel.setName(""); // NOI18N
        GroupLayout indicatorPanelLayout = new GroupLayout(indicatorPanel);
        indicatorPanel.setLayout(indicatorPanelLayout);
        indicatorPanelLayout.setHorizontalGroup(
            indicatorPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, 400, Short.MAX_VALUE)
        );
        indicatorPanelLayout.setVerticalGroup(
            indicatorPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, 50, Short.MAX_VALUE)
        );
        c = new GridBagConstraints();
        c.gridx = 1;
        c.gridy = 0;
        c.gridwidth = 2;   
        backgroundPanel.add(indicatorPanel, c);
        
        voltmeterPanel.setBackground(new Color(204, 204, 204));
        voltmeterPanel.setMaximumSize(new Dimension(smallSize, smallSize));
        voltmeterPanel.setMinimumSize(new Dimension(smallSize, smallSize));
        voltmeterPanel.setName(""); // NOI18N
        voltmeterPanel.setPreferredSize(new Dimension(smallSize, smallSize));

        GroupLayout voltmeterPanelLayout = new GroupLayout(voltmeterPanel);
        voltmeterPanel.setLayout(voltmeterPanelLayout);
        voltmeterPanelLayout.setHorizontalGroup(
            voltmeterPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, smallSize, Short.MAX_VALUE)
        );
        voltmeterPanelLayout.setVerticalGroup(
            voltmeterPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, smallSize, Short.MAX_VALUE)
        );
        c = new GridBagConstraints();
        c.gridx = 1;
        c.gridy = 1;  
        backgroundPanel.add(voltmeterPanel, c);

        gpsPanel.setBackground(new Color(204, 204, 204));
        gpsPanel.setMaximumSize(new Dimension(smallSize, smallSize));
        gpsPanel.setMinimumSize(new Dimension(smallSize, smallSize));
        gpsPanel.setPreferredSize(new Dimension(smallSize, smallSize));
        GroupLayout gpsPanelLayout = new GroupLayout(gpsPanel);
        gpsPanel.setLayout(gpsPanelLayout);
        gpsPanelLayout.setHorizontalGroup(
            gpsPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, smallSize, Short.MAX_VALUE)
        );
        gpsPanelLayout.setVerticalGroup(
            gpsPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, smallSize, Short.MAX_VALUE)
        );
        c = new GridBagConstraints();
        c.gridx = 1;
        c.gridy = 2;
        backgroundPanel.add(gpsPanel, c);

        ammeterPanel.setMaximumSize(new Dimension(smallSize, smallSize));
        ammeterPanel.setMinimumSize(new Dimension(smallSize, smallSize));
        ammeterPanel.setPreferredSize(new Dimension(smallSize, smallSize));

        GroupLayout ammeterPanelLayout = new GroupLayout(ammeterPanel);
        ammeterPanel.setLayout(ammeterPanelLayout);
        ammeterPanelLayout.setHorizontalGroup(
            ammeterPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, smallSize, Short.MAX_VALUE)
        );
        ammeterPanelLayout.setVerticalGroup(
            ammeterPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, smallSize, Short.MAX_VALUE)
        );
        c = new GridBagConstraints();
        c.gridx = 2;
        c.gridy = 1;
        backgroundPanel.add(ammeterPanel, c);

        clockPanel.setMaximumSize(new Dimension(smallSize, smallSize));
        clockPanel.setMinimumSize(new Dimension(smallSize, smallSize));
        clockPanel.setPreferredSize(new Dimension(smallSize, smallSize));
        c = new GridBagConstraints();
        c.gridx = 2;
        c.gridy = 2;
        backgroundPanel.add(clockPanel, c);

        compassPanel.setMaximumSize(new Dimension(largeSize, largeSize));
        compassPanel.setMinimumSize(new Dimension(largeSize, largeSize));
        compassPanel.setPreferredSize(new Dimension(largeSize, largeSize));

        GroupLayout compassPanelLayout = new GroupLayout(compassPanel);
        compassPanel.setLayout(compassPanelLayout);
        compassPanelLayout.setHorizontalGroup(
            compassPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, largeSize, Short.MAX_VALUE)
        );
        compassPanelLayout.setVerticalGroup(
            compassPanelLayout.createParallelGroup(GroupLayout.Alignment.LEADING)
            .addGap(0, largeSize, Short.MAX_VALUE)
        );

        c = new GridBagConstraints();
        c.gridx = 3;
        c.gridy = 0;
        c.gridheight = 3;
        backgroundPanel.add(compassPanel, c);

        getContentPane().setLayout(new BoxLayout(getContentPane(), BoxLayout.PAGE_AXIS));
        getContentPane().add(backgroundPanel);

        controlPanel.setBorder(BorderFactory.createEtchedBorder());
        controlPanel.setMaximumSize(new Dimension(10000, 10000));
        controlPanel.setMinimumSize(new Dimension(900, 60));
        controlPanel.setPreferredSize(new Dimension(900, 60));
        controlPanel.setLayout(new GridBagLayout());
        controlPanel.add(serialPanel, new GridBagConstraints());
//        controlPanel.add(logPanel, new GridBagConstraints());

        reset = new JButton("Reset");
        reset.setName("reset");
        controlPanel.add(reset);
        reset.addActionListener(this);

//        c = new GridBagConstraints();
//        c.gridy = 1;
        getContentPane().add(controlPanel);

        
        pack();
    }// </editor-fold>//GEN-END:initComponents

    
    
    //<editor-fold defaultstate="collapsed" desc="Deal with window closing">
    private void formWindowClosing(WindowEvent evt) {
        // nothing to do at this time
    }
    //</editor-fold>
       
    
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
            for (UIManager.LookAndFeelInfo info : UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException | InstantiationException | IllegalAccessException | UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(MainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /*
         * Create and display the form
         */
        EventQueue.invokeLater(new Runnable() {
            private Component gePanel;

            @Override
            public void run() {

                System.setProperty("java.library.path", "/");
                System.out.println(System.getProperty("java.library.path"));
                
                MainWindow main = new MainWindow();
                mapFrame = new JFrame("Map");
                mapFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);  
                mapFrame.setSize(500, 500);
                mapWindow = new MapWindow();
                mapWindow.setSize(500, 500);
                mapFrame.add(mapWindow);
                mapFrame.addComponentListener(mapWindow);

                mapFrame.setLocation(0, 0);
                mapFrame.setVisible(true);
                main.setLocation(0, mapFrame.getHeight()+5);
                main.setVisible(true);
                
                
                // Setup DJ NativeSwing web browser
                //UIUtils.setPreferredLookAndFeel();
                //NativeInterface.open();

                /*
                gePanel = new GoogleEarthPanel();
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
                */
                //cvPanel = new OpenCVWebCam(0, 800, 600);
            }
        });
    }
}
