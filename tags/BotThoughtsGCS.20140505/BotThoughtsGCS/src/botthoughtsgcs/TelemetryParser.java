/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package botthoughtsgcs;

import com.botthoughts.Parser;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;

/**
 *
 * @author mes
 */
public class TelemetryParser implements Parser {

    private String buffer;
    private static char SOH = '^';
    private static char EOT = '\n';
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
        System.out.println("parseData() enter");
        buffer += data;
        begin = buffer.lastIndexOf(SOH); // look for start of transmission
        end = buffer.indexOf(EOT);
        if (begin >= 0 && end >= 0) {
            String sentence = buffer.substring(begin+1, end); // peel off text after SOT
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
                    System.out.println();
                    System.out.print("lat="+result[4]);
                    System.out.print(" lon="+result[5]);
                    System.out.println();
                    System.out.println();
                           
                } catch (NumberFormatException e) {
                    System.out.println("Number format exception");
                }
        }       
        System.out.println("parseData() exit");
    }
}
