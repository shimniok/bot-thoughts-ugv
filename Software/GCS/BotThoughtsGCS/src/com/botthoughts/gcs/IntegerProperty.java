/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.botthoughts.gcs;

/**
 *
 * @author mes
 */
public class IntegerProperty implements Property<Integer> {
    private int value;
    private ChangeListener listener;

    IntegerProperty(Integer v) {
        value = v.intValue();
    }
    
    @Override
    public void setValue(Integer value) {
        this.value = value.intValue();
        if (this.listener != null)
            listener.changed(this); // callback the ChangeListener so it can update
    }

    @Override
    public void addListener(ChangeListener<? super Integer> listener) {
        this.listener = listener;
    }

    @Override
    public Integer getValue() {
        return value;
    }

    @Override
    public void removeListener(ChangeListener<? super Integer> listener) {
        this.listener = null;
    }
    
    /** 
     * Set the new value for this property
     * @param value (int) is the new value of the property to set
     */
    public void set(int value) {
        setValue(value);
    }

    /**
     * Get the value of this property
     * @return (int) the value of this property
     */
    public int get() {
        return getValue().intValue();
    }    
}
