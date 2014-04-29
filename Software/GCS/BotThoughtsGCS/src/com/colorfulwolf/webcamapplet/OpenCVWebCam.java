package com.colorfulwolf.webcamapplet;

import java.awt.Color;
import java.awt.image.BufferedImage;
import com.colorfulwolf.webcamapplet.gui.OpenCVCamPanel;
import com.googlecode.javacv.FrameGrabber;
import com.googlecode.javacv.OpenCVFrameGrabber;
import com.googlecode.javacv.cpp.opencv_core.IplImage;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * A Swing UI component that displays images captured from a webcam via OpenCV.
 * <p> This class uses the CVImageProcessor interface to process the webcam
 * image before it is output. </p>
 *
 * @author Randy van der Heide
 *
 */
@SuppressWarnings("serial")
public class OpenCVWebCam extends OpenCVCamPanel {

    
    private boolean running = false;
    private Thread runner = null;
    private OpenCVFrameGrabber grabber;
    private CVImageProcessor imageProcessor = null;

    public OpenCVWebCam(int device, int width, int height) {
        this.grabber = new OpenCVFrameGrabber(device);
        grabber.setImageWidth(width);
        grabber.setImageHeight(height);
        this.setBackground(Color.white);
    }

    @Override
    public void setImageProcessor(CVImageProcessor imageProcessor) {
        this.imageProcessor = imageProcessor;
    }

    @Override
    public CVImageProcessor getImageProcessor() {
        return imageProcessor;
    }

    private void grabAndPaint() {
        BufferedImage out = null;
        try {
            //grab the raw image from the webcam
            IplImage frame = grabber.grab();
            //if an image processor has been defined, start processing the image
            if (imageProcessor != null) {
                frame = imageProcessor.process(frame);
            }
            //output the final result as a bufferedimage
            out = frame.getBufferedImage();
        } catch (FrameGrabber.Exception ex) {
            Logger.getLogger(OpenCVWebCam.class.getName()).log(Level.SEVERE, null, ex);
        }
        this.setImage(out);
        this.repaint();
    }

    /**
     * Start grabbing frames from the webcam.
     *
     * @throws Exception
     */
    @Override
    public void start() throws Exception {
        if (running) {
            return;
        }

        grabber.start();

        running = true;
        runner = new Thread() {

            @Override
            public void run() {
                System.out.println("runner is running");
                while (running) {
                    grabAndPaint();
                    Thread.yield();
                } 
                try {
                    grabber.stop();
                } catch (FrameGrabber.Exception ex) {
                    Logger.getLogger(OpenCVWebCam.class.getName()).log(Level.SEVERE, null, ex);
                }
                runner = null;
            }
        };
        runner.start();
    }

    @Override
    public boolean isRunnning() {
        return runner != null;
    }

    @Override
    public void stop() {
        running = false;
    }
}