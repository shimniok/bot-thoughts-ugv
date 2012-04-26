/** Geographical position and calculation. Most of this comes from http://www.movable-type.co.uk/scripts/latlong.html
 *
 */
class GeoPosition {
    float _R;          /** Earth's mean radius */
    float _latitude;   /** The position's latitude */
    float _longitude;  /** The position's longitude */

    /** Create a new position with the specified latitude and longitude. See set()
     *
     *  @param latitude is the latitude to set
     *  @param longitude is the longitude to set
     */
    GeoPosition(float latitude, float longitude) { 
      _R = 6371000.0;
      _latitude = latitude;
      _longitude = longitude;
    }
 
    /** Get the position's latitude
     *
     *  @returns the position's latitude
     */
    float latitude() {
      return _latitude;
    }
    
    /** Get the position's longitude
     *
     *  @returns the position's longitude
     */
    float longitude() {
      return _longitude;
    }
    
    /** Set the position's location to another position's coordinates
     *
     *  @param pos is another position from which coordinates will be copied
     */
    void set(GeoPosition pos) {
      _latitude = pos.latitude();
      _longitude = pos.longitude();
    }
    
    /** Set the position's location to the specified coordinates
     *
     *  @param latitude is the new latitude to set
     *  @param longitude is the new longitude to set
     */
    void set(float latitude, float longitude) {
      _latitude = latitude;
      _longitude = longitude;
    }
    
    /** Move the location of the position by the specified distance and in
     *  the specified direction
     *
     *  @param course is the direction of movement in degrees, absolute not relative
     *  @param distance is the distance of movement along the specified course in meters
     */
    void move(float course, float distance) {
    }

    /** Get the bearing from the specified origin position to this position.  To get
     *  relative bearing, subtract the result from your heading.
     *
     *  @param from is the position from which to calculate bearing
     *  @returns the bearing in degrees
     */
    float bearing(GeoPosition from) {
      float lat1 = radians(from.latitude());
      float lon1 = radians(from.longitude());
      float lat2 = radians(_latitude);
      float lon2 = radians(_longitude);
      float dLon = lon2 - lon1;
  
      float y = sin(dLon) * cos(lat2);
      float x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  
      return degrees(atan2(y, x)); 
    }
    
    /** Get the distance from the specified origin position to this position
     *
     *  @param from is the position from which to calculate distance
     *  @returns the distance in meters
     */
    float distance(GeoPosition from) {
      float lat1 = radians(from.latitude());
      float lon1 = radians(from.longitude());
      float lat2 = radians(_latitude);
      float lon2 = radians(_longitude);
      float dLat = lat2 - lat1;
      float dLon = lon2 - lon1;
  
      float a = sin(dLat/2.0) * sin(dLat/2.0) + 
                 cos(lat1) * cos(lat2) *
                 sin(dLon/2.0) * sin(dLon/2.0);
      float c = 2.0 * atan2(sqrt(a), sqrt(1-a));
      
      return _R * c;
    }

};

