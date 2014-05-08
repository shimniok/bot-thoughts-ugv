/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

/**
 *
 * @author mes
 */
public class BooleanProperty implements Property<Boolean> {
    private Boolean value;
    private ChangeListener listener;

    public BooleanProperty(Boolean v) {
        value = v.booleanValue();
    }
    
    @Override
    public void setValue(Boolean value) {
        this.value = value.booleanValue();
        if (this.listener != null)
            listener.changed(this); // callback the ChangeListener so it can update
    }

    @Override
    public void addListener(ChangeListener<? super Boolean> listener) {
        this.listener = listener;
    }

    @Override
    public Boolean getValue() {
        return value;
    }

    @Override
    public void removeListener(ChangeListener<? super Boolean> listener) {
        listener = null;
    }

        /** 
     * Set the new value for this property
     * @param value (double) is the new value of the property to set
     */
    public void set(boolean value) {
        setValue(value);
    }

    /**
     * Get the value of this property
     * @return (double) the value of this property
     */
    public boolean get() {
        return getValue().booleanValue();
    }  
}
