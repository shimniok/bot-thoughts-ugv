/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

/**
 *
 * @author mes
 */
public interface Property<T> extends ObservableValue<T> {
    
    /**
     * Sets the value of the property
     * 
     * @param value the new value
     */
    void setValue(T value);
}
