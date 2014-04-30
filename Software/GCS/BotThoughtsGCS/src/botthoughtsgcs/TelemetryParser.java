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
        buffer += data;
        begin = buffer.lastIndexOf(SOH); // look for start of transmission
        end = buffer.indexOf(EOT);
        if (begin >= 0 && end >= 0) {
            String sentence = buffer.substring(begin+1, end); // peel off text after SOT
            System.out.format("sentence: <%s>\n", sentence);
            buffer = buffer.substring(end+1);

            String[] result = sentence.split(",\\s*");

            if (result.length >= 11) {
                try {
                    vehicleStatus.setVoltage(Double.parseDouble(result[1]));
                    vehicleStatus.setCurrent(Double.parseDouble(result[2]));
                    vehicleStatus.setHeading(Double.parseDouble(result[3]));
                    vehicleStatus.setLatitude(Double.parseDouble(result[4]));
                    vehicleStatus.setLongitude(Double.parseDouble(result[5]));
                    vehicleStatus.setSpeed(2.23694 * Double.parseDouble(result[8])); // convert m/s to mph
                    vehicleStatus.setBearing(Double.parseDouble(result[9]));
                    vehicleStatus.setDistance(Double.parseDouble(result[10]));
                } catch (NumberFormatException e) {
                    System.out.println("Number format exception");
                }
            } else {
                System.out.println("Something wrong with result");
            }
        }       
             
//
//            if (latitude.charAt(latitude.length()) == 'S') {
//                latitude = "-" + latitude;
//            }
//            if (longitude.charAt(longitude.length()) == 'W') {
//                longitude = "-" + longitude;
//            }
//
//            vehicleStatus.setVoltage(Double.parseDouble(voltage) / 10.0);
//            vehicleStatus.setCurrent(Double.parseDouble(current) / 10.0);
//            vehicleStatus.setHeading(Double.parseDouble(heading) / 10.0);
//            vehicleStatus.setSpeed(2.23694 * Double.parseDouble(speed) / 10.0); // convert m/s to mph
//            vehicleStatus.setLatitude(Double.parseDouble(latitude) / 10e5);
//            vehicleStatus.setLongitude(Double.parseDouble(longitude) / 10e5);
//            vehicleStatus.setBearing(Double.parseDouble(bearing) / 10.0);
//            vehicleStatus.setDistance(Double.parseDouble(distance) / 10.0);
//
//            done = true;
//        }
    }
}
