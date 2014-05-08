/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import com.botthoughts.Parser;

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

    public TelemetryParser(VehicleStatus vs) {
        vehicleStatus = vs;
        buffer = "";
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

            try {
                vehicleStatus.setVoltage(Double.parseDouble(result[1]));
                vehicleStatus.setCurrent(Double.parseDouble(result[2]));
                vehicleStatus.setHeading(Double.parseDouble(result[3]));
                vehicleStatus.setLatitude(Double.parseDouble(result[4]));
                vehicleStatus.setLongitude(Double.parseDouble(result[5]));
                vehicleStatus.setSatCount(Double.parseDouble(result[7]));
                vehicleStatus.setSpeed(2.23694 * Double.parseDouble(result[8])); // convert m/s to mph
                vehicleStatus.setBearing(Double.parseDouble(result[9]));
                vehicleStatus.setDistance(Double.parseDouble(result[10]));
                System.out.print("v="+result[1]);
                System.out.print(" a="+result[2]);
                System.out.print(" h="+result[3]);
                System.out.print(" lat="+result[4]);
                System.out.print(" lon="+result[5]);
                System.out.print(" sats="+result[7]);
                System.out.println();
                System.out.println();
                buffer = "";

            } catch (NumberFormatException e) {
                System.out.println("Number format exception");
            }
        }       
//        System.out.println("parseData() exit");
    }
}
