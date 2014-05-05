/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

/**
 *
 * @author mes
 */
public final class DoubleProperty implements Property<Number> {
    private double value;
    private ChangeListener listener;

    DoubleProperty(Number v) {
        value = v.doubleValue();
    }

    @Override
    public void setValue(Number value) {
        this.value = value.floatValue();
    }

    @Override
    public void addListener(ChangeListener<? super Number> listener) {
        this.listener = listener;
    }

    @Override
    public Number getValue() {
        return value;
    }

    @Override
    public void removeListener(ChangeListener<? super Number> listener) {
        this.listener = null;
    }
    
    /** 
     * Set the new value for this property
     * @param value (double) is the new value of the property to set
     */
    public void set(double value) {
        setValue(value);
        if (this.listener != null)
            listener.changed(this); // callback the ChangeListener so it can update
    }

    /**
     * Get the value of this property
     * @return (double) the value of this property
     */
    public double get() {
        return getValue().doubleValue();
    }    
}
