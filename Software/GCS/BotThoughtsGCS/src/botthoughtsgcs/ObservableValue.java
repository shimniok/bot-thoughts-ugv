/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package botthoughtsgcs;

/**
 *
 * @author mes
 */
public interface ObservableValue<T> {
    public void addListener(ChangeListener<? super T> listener);
    T getValue();
    void removeListener(ChangeListener<? super T> listener);
}
