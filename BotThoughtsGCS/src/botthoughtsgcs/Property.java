/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package botthoughtsgcs;

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
