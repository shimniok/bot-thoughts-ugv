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
    private static char SOH = 0x01;
    private static char EOT = '\n';
    private VehicleStatus vehicleStatus;

    public TelemetryParser(VehicleStatus vs) {
        vehicleStatus = vs;
    }

    /**
     * Implements data parsing for logging stream
     *
     * @param data
     */
    @Override
    public void parseData(String data) {
        int begin;
        int end;
        boolean done = false;

        buffer += data;
        //System.out.println("buf: <"+buffer+">");

        // TODO: incorporate time into the data stream
        while (!done) {
            begin = buffer.indexOf(SOH); // look for start of transmission
            if (begin == -1) {
                System.out.println("no SOH");
                break;     // If we don't have a start yet, wait until next time
            }
            String sentence = buffer.substring(begin); // peel off text after SOT
            end = sentence.indexOf(EOT);                 // look for end of transmission
            if (end == -1) {
                break;                       // if we don't have an end yet, wait until next time
            }
            buffer = sentence.substring(end + 1);        // peel off sentence part of substring
            sentence = sentence.substring(1, end);       // peel off the text before EOT

            ArrayList<String> result;
            result = new ArrayList<>(Arrays.asList(sentence.split(",")));
            Iterator<String> i = result.iterator();
            
            String millis = i.next();
            String voltage = i.next();
            String current = i.next();
            String heading = i.next();
            String latitude = i.next();
            String longitude = i.next();
            String hdop = i.next();
            String satCount = i.next();
            String speed = i.next();
            String bearing = i.next();
            String distance = i.next();
            String steerAngle = i.next();

            System.out.format("m=%s v=%s i=%s h=%s s=%s g=(%s, %s) b=%s d=%s sa=%s\n", 
                    millis, voltage, current, heading, speed, latitude, longitude,
                    bearing, distance, steerAngle);

            if (latitude.charAt(latitude.length()) == 'S') {
                latitude = "-" + latitude;
            }
            if (longitude.charAt(longitude.length()) == 'W') {
                longitude = "-" + longitude;
            }

            vehicleStatus.setVoltage(Double.parseDouble(voltage) / 10.0);
            vehicleStatus.setCurrent(Double.parseDouble(current) / 10.0);
            vehicleStatus.setHeading(Double.parseDouble(heading) / 10.0);
            vehicleStatus.setSpeed(2.23694 * Double.parseDouble(speed) / 10.0); // convert m/s to mph
            vehicleStatus.setLatitude(Double.parseDouble(latitude) / 10e5);
            vehicleStatus.setLongitude(Double.parseDouble(longitude) / 10e5);
            vehicleStatus.setBearing(Double.parseDouble(bearing) / 10.0);
            vehicleStatus.setDistance(Double.parseDouble(distance) / 10.0);

            done = true;
        }
    }
}
