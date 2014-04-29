/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package botthoughtsgcs;

//import chrriis.dj.nativeswing.swtimpl.components.JWebBrowser;
import java.awt.BorderLayout;
import java.io.File;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.JPanel;


/**
 *
 * @author Michael Shimniok, Christopher Deckers
 */
public class GoogleEarthPanel extends javax.swing.JPanel {

    //private final JWebBrowser webBrowser;
    
    /**
     * Creates new form GEPanel
     */
    public GoogleEarthPanel() {
        /*
        super(new BorderLayout());
        JPanel webBrowserPanel = new JPanel(new BorderLayout());
        webBrowser = new JWebBrowser();
        webBrowser.setBarsVisible(false);
        try {
            File cwd = new File(".");
            System.out.println(cwd.getAbsolutePath());
            File path = new File("c:/earth.html");
            String uri = "file://"+path.toURI().toURL().getPath();
            System.out.println("URI: "+uri);
            //webBrowser.navigate("file:///C:/Documents%20and%20Settings/Michael%20Shimniok/My%20Documents/Projects/DataBus/Software/GCS/BotThoughtsGCS/src/botthoughtsgcs/resources/earth.html");
            webBrowser.navigate(uri);
            webBrowserPanel.add(webBrowser, BorderLayout.CENTER);
            add(webBrowserPanel, BorderLayout.CENTER);
        } catch (IOException ex) {
            Logger.getLogger(GoogleEarthPanel.class.getName()).log(Level.SEVERE, null, ex);
        }
        */
    }
    /*
    JWebBrowser getWebBrowser() {
        return webBrowser;
    }
    
    void initView() {
        Boolean init;
        do {
            init = (Boolean) webBrowser.executeJavascriptWithResult("return isInitialized();");
        } while (init == null);
        do {
            init = (Boolean) webBrowser.executeJavascriptWithResult("return isInitialized();");
        } while (!init.booleanValue());

        webBrowser.executeJavascript("setViewMode(1);");
        webBrowser.executeJavascript("setFollowEnabled(1);");
        webBrowser.executeJavascript("createAircraft(0, 0, '88008800');");
        webBrowser.executeJavascript("clearTrail(0);");
        webBrowser.executeJavascript("showTrail(0);");
    }
    
    void setHome(Double lat, Double lon) {
        String slat = Double.toString(lat);
        String slon = Double.toString(lon);
        webBrowser.executeJavascript("setGCSHome("+slat+","+slon+", 0);");
        webBrowser.executeJavascript("goHome();");
    }
    
    void setPose(Double lat, Double lon, Double hdg) {        
        String slat = Double.toString(lat);
        String slon = Double.toString(lon);
        String shdg = Double.toString(hdg);

        webBrowser.executeJavascript("setAircraftPositionAttitude(0, "+slat+", "+slon+", 0.0, 0.0, 0.0, "+shdg+");");
        webBrowser.executeJavascript("addTrailPosition(0, "+slat+", "+slon+", 0.0)");
    }
    */
    

    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 400, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 300, Short.MAX_VALUE)
        );
    }// </editor-fold>//GEN-END:initComponents

    // Variables declaration - do not modify//GEN-BEGIN:variables
    // End of variables declaration//GEN-END:variables
}