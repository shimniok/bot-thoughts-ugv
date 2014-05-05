/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

import java.util.EventListener;
import java.util.EventObject;

/**
 *
 * @author Michael Shimniok
 */
public interface LogEventListener extends EventListener {
    public void handleLogEvent(EventObject e);
}
