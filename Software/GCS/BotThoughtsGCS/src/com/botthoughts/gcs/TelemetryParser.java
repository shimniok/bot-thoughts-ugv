/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import com.botthoughts.Parser;
import java.util.ArrayList;

/**
 *
 * @author mes
 */
public class TelemetryParser implements Parser {

    private String buffer;
    private static char SOP = '`';
    private static char EOP = '\n';
    private VehicleStatus vehicleStatus;
    private int begin = -1;
    private int end = -1;
    private WatchDog watchdog;

    public TelemetryParser(VehicleStatus vs, WatchDog wd) {
        vehicleStatus = vs;
        buffer = "";
        watchdog = wd;
    }

    /**
     * Implements data parsing for logging stream
     *
     * @param data
     */
    @Override
    public void parseData(String data) {
//        System.out.println("parseData() enter");
        buffer += data;
//        System.out.println("<"+buffer+">");
        begin = buffer.lastIndexOf(SOP); // look for start of transmission
        buffer = buffer.substring(begin);
        end = buffer.indexOf(EOP);
//        System.out.format("%d %d\n", begin, end);
        if (begin >= 0 && end >= 0) {
            String sentence = buffer.substring(1, end); // peel off text after SOT
//            System.out.format("sentence: <%s>\n", sentence);
            buffer = buffer.substring(end+1);

            String[] result = sentence.split(",\\s*");

            String messageType = result[0];
            
            try {
                
                if ("00".equals(messageType)) { // standard status message

//                    String millis = result[1];
                    String voltage = result[2];
                    String current = result[3];
                    String heading = result[4];
//                    String latitude = result[5];
//                    String longitude = result[6];
                    String x = result[5];
                    String y = result[6];
                    String sats = result[8];
                    String speed_ms = result[9];
                    String nextWaypoint = result[10];
                    String bearing = result[11];
                    String distance = result[12];
                    String steerAngle = result[13];
                    String LAbrg = result[14];
                    String LAx = result[15];
                    String LAy = result[16];
                    
                    vehicleStatus.setVoltage(Double.parseDouble(voltage));
                    vehicleStatus.setCurrent(Double.parseDouble(current));
                    vehicleStatus.setHeading(Double.parseDouble(heading));
    //                vehicleStatus.setLatitude(Double.parseDouble(result[4]));
    //                vehicleStatus.setLongitude(Double.parseDouble(result[5]));
                    vehicleStatus.setPosition(new Coordinate(Double.parseDouble(x), Double.parseDouble(y)));
                    vehicleStatus.setNextWaypoint(Integer.parseInt(nextWaypoint));
                    vehicleStatus.setLookahead(
                            new Coordinate(Double.parseDouble(LAx), Double.parseDouble(LAy))
                            );
                    vehicleStatus.setSatCount(Double.parseDouble(sats));
                    vehicleStatus.setSpeed(2.23694 * Double.parseDouble(speed_ms)); // convert m/s to mph
                    vehicleStatus.setBearing(Double.parseDouble(bearing));
                    vehicleStatus.setDistance(Double.parseDouble(distance));
                    System.out.print("v="+voltage);
                    System.out.print(" a="+current);
                    System.out.print(" h="+heading);
                    System.out.print(" brg="+bearing);
                    System.out.print(" x="+x);
                    System.out.print(" y="+y);
                    System.out.print(" sats="+sats);
                    System.out.print(" SA="+steerAngle);
                    System.out.print(" LAbrg="+LAbrg);
                    System.out.print(" LAx="+LAx);
                    System.out.print(" LAy="+LAy);
                    System.out.println();
                    buffer = "";
                } else if ("01".equals(messageType)) {
                    int count = Integer.parseInt(result[1]);
                    int i = 2;
                    ArrayList<Coordinate> wpt = new ArrayList<>();
                    System.out.println("Waypoints");
                    while (count-- > 0) {
                        Coordinate c = new Coordinate();
                        c.setX(Double.parseDouble(result[i++]));
                        c.setY(Double.parseDouble(result[i++]));
                        wpt.add(c);
                        System.out.print(c.getX());
                        System.out.print(", ");
                        System.out.println(c.getY());
                    }
                    vehicleStatus.setWaypoints(wpt);
                }
                watchdog.reset();
                
            } catch (NumberFormatException e) {
                System.out.println("Number format exception");
            }
        }       
//        System.out.println("parseData() exit");
    }
}
