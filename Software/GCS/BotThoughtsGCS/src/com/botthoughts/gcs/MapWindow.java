/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import java.awt.Color;
import java.awt.Graphics;
import java.awt.event.ComponentEvent;
import java.awt.event.ComponentListener;
import java.util.ArrayList;
import javax.swing.JPanel;

/**
 *
 * @author mes
 */
public class MapWindow extends JPanel implements ComponentListener {
    private static int roverRadius = 6;
    private static int wptRadius = 8;
    private static int margin = 50;
    private int screenWidth = 600;
    private int screenHeight = 600;
    private double heading;
    private Coordinate lookahead;
    private Coordinate position;
    private Coordinate next;
    private ArrayList<Coordinate> wpt;
    private double xmax;
    private double xmin;
    private double ymax;
    private double ymin;
    private double scale;

    /** Create new MapWindow frame */
    public MapWindow() {
        //Set JFrame title  
        super.setBackground(Color.black);
               
        scale = 0.0;
                
        position = new Coordinate(0, 0);
        lookahead = new Coordinate(0, 0);
        heading = 0;
        wpt = new ArrayList<>();
        next = null;
         
        setLocation(0, 0);
        setVisible(true); 
    }
    
    @Override
    public void setSize(int width, int height) {
        super.setSize(width, height);
        screenWidth = getWidth();
        screenHeight = getHeight();
    }
    
    /** Set vehicle heading
     * @param h is the heading in degrees
     */
    public void setHeading(double h) {
        heading = h;
    }
    
    /** Set vehicle position on the map 
     * 
     * @param x is the x coordinate of vehicle
     * @param y is the y coordinate of vehicle
     */
    public void setPosition(double x, double y) {
        position.setLocation(x, y);
        repaint();
    }
    
    /** Sets the lookahead data to update the map display
     * 
     * @param x is the x coordinate for the lookahead point
     * @param y is the y coordinate for the lookahead point
     */
    public void setLookAhead(double x, double y) {
        lookahead.setLocation(x, y);
        repaint();
    }
    
    /** Sets the next waypoint index to update the map display
     * 
     * @param w is the next waypoint index
     */
    public void setNextWaypoint(int w) {
        if (wpt != null) {
            next = wpt.get(w);
        }
    }
    
    /** Set the list of waypoints for the rover
     * 
     * @param wpt is an ArrayList of Coordinates for each waypoint
     */
    public void setWaypoints(ArrayList<Coordinate> wpt) {
        this.wpt = wpt;
        for (Coordinate c: wpt) {
            xmax = Math.max(c.getX(), xmax);
            xmin = Math.min(c.getX(), xmin);
            ymax = Math.max(c.getY(), ymax);
            ymin = Math.min(c.getY(), ymin);
        }
        adjustScale();
    }
    
    public void adjustScale() {
        // We want margin on left, right, top, bottom
        // So subtract 2x margin from screenwidth to get proper scale
        // and offset when scaling raw x and y later
        // TODO 2: fix scaling to work better
        int dim = Math.min(screenWidth, screenHeight) - (margin*2);
        double xscale = dim / (xmax - xmin);
        double yscale = dim / (ymax - ymin);
        scale = Math.min(xscale, yscale);       
    }
    
    /** Scale the x coordinate to fit the display
     * 
     * @param x is the x coordinate to scale
     * @return the new x coordinate, scaled
     */
    private int scaleX(double x) {
        int result = margin + (int) ((x - xmin) * scale);
        
        return result;
    }
    
    /** Scale and invert the y coordinate to fit the display.
     * In Java, y=0 is at the top but in our coordinate system, 0 is at the bottom.
     * 
     * @param y is the y coordinate to scale
     * @return the new y coordinate, scaled and flipped
     */
    private int scaleY(double y) {
        int result;
        
        result = margin + (int) ((y - ymin) * scale);
        result = screenHeight - result;
        
        return result;
    }

    @Override
    public void paint(Graphics g) {  
        super.paint(g);

//        g.fillRect(0, 0, this.getWidth(), this.getHeight());
        
        if (scale > 0) {
            
            int x1 = scaleX(position.getX()); // scaled rover position
            int y1 = scaleY(position.getY()); // scaled rover position

            // Draw rover heading line
            int r = roverRadius*10; // length of the heading line
            int x2; // end of the heading line indicator
            int y2;
            double hdg = Math.toRadians(heading-90);
            x2 = x1 + (int) (r*Math.cos(hdg));
            y2 = y1 + (int) (r*Math.sin(hdg));
            g.setColor(new Color(150, 150, 150));
            g.drawLine(x1, y1, x2, y2);

            // Draw all the waypoints
            for (Coordinate c: wpt) {
                g.setColor(Color.RED);
                g.fillOval(
                    scaleX(c.getX())-wptRadius/2, 
                    scaleY(c.getY())-wptRadius/2, 
                    wptRadius, 
                    wptRadius);
            }

            // Draw the next waypoint (overlay)
            if (next != null) {
                g.setColor(Color.GREEN);
                g.fillOval(
                    scaleX(next.getX())-wptRadius/2, 
                    scaleY(next.getY())-wptRadius/2, 
                    wptRadius, 
                    wptRadius);
            }
                        
            // Draw rover circle
            g.setColor(Color.YELLOW);  
            g.fillOval(
                    x1-roverRadius/2, 
                    y1-roverRadius/2,
                    roverRadius, 
                    roverRadius);

            // Draw Lookahead point
            g.setColor(new Color(160, 230, 255));
            g.fillOval(
                scaleX(lookahead.getX())-wptRadius/2, 
                scaleY(lookahead.getY())-wptRadius/2, 
                wptRadius, 
                wptRadius);

        }
        
    }      

    @Override
    public void componentResized(ComponentEvent e) {
        System.out.println("Resized MapWindow");
        screenWidth = getWidth();
        screenHeight = getHeight();
        adjustScale();
        repaint();
    }

    @Override
    public void componentMoved(ComponentEvent e) {
    }

    @Override
    public void componentShown(ComponentEvent e) {
    }

    @Override
    public void componentHidden(ComponentEvent e) {
    }

}
