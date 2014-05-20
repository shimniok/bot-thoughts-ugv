/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import java.awt.Color;
import java.awt.Graphics;
import java.util.ArrayList;
import javax.swing.JFrame;

/**
 *
 * @author mes
 */
public class MapWindow extends JFrame {
    private static int screenWidth = 600;
    private static int screenHeight = 600;
    private static int margin = 100;
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
        super("Map");  
  
        //Set default close operation for JFrame  
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);  

        scale = 0.0;
                
        position = new Coordinate(0, 0);
        lookahead = new Coordinate(0, 0);
        wpt = new ArrayList<>();
        next = null;

        //Set JFrame size  
        setSize(screenWidth, screenHeight);  

        //Make JFrame visible   
        setVisible(true); 
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
        // We want margin on left, right, top, bottom
        // So subtract 2x margin from screenwidth to get proper scale
        // and offset when scaling raw x and y later
        double xscale = (screenWidth - (margin*2)) / (xmax - xmin);
        double yscale = (screenWidth - (margin*2)) / (ymax - ymin);
        scale = Math.min(xscale, yscale);
//        System.out.print("setWaypoints scale: ");
//        System.out.print(xscale);
//        System.out.print(" ");
//        System.out.print(yscale);
//        System.out.println();
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

        if (scale > 0) {
        
            // TODO 0: scaling
            int roverRadius = 5;
            int wptRadius = 9;

            g.setColor(new Color(160, 230, 255));
            g.fillOval(
                scaleX(lookahead.getX())-wptRadius/2, 
                scaleY(lookahead.getY())-wptRadius/2, 
                wptRadius, 
                wptRadius);

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
                    scaleX(position.getX())-roverRadius/2, 
                    scaleY(position.getY())-roverRadius/2,
                    roverRadius, 
                    roverRadius);
    //        g.setColor(Color.BLACK);
    //        g.drawOval(centerX, centerY, roverRadius+2, roverRadius+2);  


        }
        
    }      

}
