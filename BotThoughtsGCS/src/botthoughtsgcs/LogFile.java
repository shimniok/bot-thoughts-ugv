/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package botthoughtsgcs;

import java.io.*;
import java.util.Scanner;

/**
 *
 * @author Michael Shimniok
 */
public class LogFile {
    BufferedReader reader;
    private int lineCount;
    
    public LogFile() {
    }

    public LogFile(File file) throws FileNotFoundException {
        if (file != null)
            open(file.getAbsolutePath());
    }
    
    public LogFile(String filename) throws FileNotFoundException {
        if (filename != null)
            open(filename);
    }

    public int getLines() {
        return lineCount;
    }
    
    public final void open(String filename) throws FileNotFoundException {
        lineCount = 0;
        // Count lines
        File f = new File(filename);
        Scanner input = new Scanner(f);
        while (input.hasNextLine()) {
            String line = input.nextLine();
            lineCount++;
        }
        FileInputStream fstream = new FileInputStream(filename);
        DataInputStream in = new DataInputStream(fstream);
        reader = new BufferedReader(new InputStreamReader(in));
    }
    
    public final void close() throws IOException {
        reader.close();
    }
    
    public String readLine() throws IOException {
        return reader.readLine();
    }
}
