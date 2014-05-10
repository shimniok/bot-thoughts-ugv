/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import java.util.Timer;
import java.util.TimerTask;
import javax.swing.SwingWorker;

/**
 *
 * @author mes
 */
public class WatchDog extends SwingWorker<Void, String> {
    private final int timeout;
    private final Timer clkTimer;
    private int count;
    private TimerTask clkTask;
    private BooleanProperty timeoutExceeded;
    
    /**
     * 
     * @param interval is the maximum interval in seconds before the watchdog throws an error
     */
    public WatchDog(int timeout, BooleanProperty timeoutExceeded) {
        this.timeout = timeout;
        clkTimer = new Timer(true);
        this.timeoutExceeded = timeoutExceeded;
    }
    
    public void stop() {
        clkTimer.cancel();
    }

    public void start() {
        // Start off assuming we've exceeded our timeout
        count = timeout;
        timeoutExceeded.set(true);
        clkTimer.scheduleAtFixedRate(clkTask, 0, 1000);
    }
    
    public void reset() {
        count = 0;
        timeoutExceeded.set(false);
    }

    @Override
    protected Void doInBackground() throws Exception {
        // Setup clock updater
        clkTask = new TimerTask() {
            @Override
            public void run() {
//                System.out.print("wd run() count=");
//                System.out.print(count);
//                System.out.print(" timeout=");
//                System.out.print(timeout);
//                System.out.println();
                if (count >= timeout) {
                    timeoutExceeded.set(true);
                } else {
                    count++;
                }
            };
        };
        return null;   
    }
}
