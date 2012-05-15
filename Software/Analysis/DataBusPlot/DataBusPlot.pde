// Graphically replay log files from DataBus, my 2012 AVC robot to show position, distance and bearing
// to next waypoint.
//
// Reads in a file waypoints.csv with each line as a waypoint in form 
//   lat,lon
//
// Reads in log file data.csv with fields 
//   millis,estlat,estlon,nextwaypoint,bearing,distance,heading
// use nav.pl to create this file.
//

float minDist = 5;    // minimum size of distance line
int padding = 400;    // pixel padding around waypoints at edges
float lonMin=360.0;   // x minimum boundary
float lonMax=-360.0;  // x maximum boundary
float latMin=360.0;   // y minimum boundary
float latMax=-360.0;  // y maximum boundary
int sizeX=800;        // screen size, x
int sizeY=600;        // screen size, y
float AR;             // aspect ratio
float scaleLon;       // Scale latitude to pixels
float scaleLat;       // Scale longitude to pixels
float scaleMx;        // scale meters to pixels
float scaleMy;
float x = 0.0;        // Current x-coordinate
float y = 0.0;        // Current y-coordinate
float x0 = 0.0;
float y0 = 0.0;
int index;
String[] lines;
String[] pieces;
GeoPosition[] waypoint;
GeoPosition[] position;
float Xw[];
float Yw[];
float h;
int wpt = 1;
color red = color(255,0,0);
color green = color(0,255,0);
color blue = color(0,0,255);
color yellow = color(240,240,0);

void setup() 
{
  lines = loadStrings("waypoints.csv");
  waypoint = new GeoPosition[lines.length];
  Xw = new float[lines.length];
  Yw = new float[lines.length];
  pieces = split(lines[0], ',');

  for (int i=0; i < lines.length; i++) {
    pieces = split(lines[i], ',');
    waypoint[i] = new GeoPosition(pieces[0], pieces[1]);
  }
  
  lines = loadStrings("data.csv");
  mapping();
  index = 2;

  size(sizeX,sizeY);
  background(0);
  noStroke();
  smooth();

}

void draw() 
{
  // Path fadeout
  fill(0, 20);
  rectMode(CORNER);
  rect(0, 0, width, height);
  // Draw waypoints
  //translate(-lonMin, -latMin);
  //translate(padding, sizeY/2+padding);
  for (int i=0; i < waypoint.length; i++) {
    if (wpt == i) {
      fill(red);
    } else {
      fill(blue);
    }
    float wx = lonToX( waypoint[i].longitude() );
    float wy = latToY( waypoint[i].latitude() );
/*
    print("i=");
    print(i);
    print(" wx=");
    print(wx);
    print(" wy=");
    print(wy);
    println();
*/
    ellipse(wx,wy,10,10);
  }
  // Draw bearing and car
  if (index < lines.length) {
    pieces = split(lines[index], ',');
    wpt = int(pieces[3]);
    // convert from lat/lon to x and y
    x = lonToX( float(pieces[2]) );
    y = latToY( float(pieces[1]) );
    // calculate bearing and distance
    float brg = float(pieces[4]);
    float dist = float(pieces[5]);
    // calculate ratios for plotting target and bearing indicators
    float x1 = cos(radians(brg-90));
    float y1 = sin(radians(brg-90));
    // determine vehicle heading
    h = float(pieces[6]);
    stroke(255);     // Set line drawing color to white
    // draw bearing indicator at least minDist in length
    if (dist < minDist) {
      line(x, y, x+scaleMx*minDist*x1, y+scaleMy*minDist*y1);
    } else {
      line(x, y, x+scaleMx*dist*x1, y+scaleMy*dist*y1);
    }
    // Draw distance target
    fill(green, 20);
    ellipse(x+scaleMx*dist*x1, y+scaleMy*dist*y1, 20, 20);
    // Go to the next line for the next run through draw()
    index = index + 1;
  }
  // draw the car with the specified heading
  drawCar(x, y, h);
}

void drawCar(float x, float y, float h)
{
  pushMatrix();
  stroke(255);
  fill(yellow);
  translate(x,y);
  rotate(radians(h+90));
  rectMode(CENTER);
  rect(0, 0, 20, 5);
  popMatrix();
}


void mapping() 
{
  // calculate the aspect ratio to square up the plot
  AR=float(sizeY)/float(sizeX);
  print("AR=");
  println(AR);
  // Find the minimum and maximum bounds of lat and lon
  for (int i=1; i < waypoint.length; i++) {
    float Y = waypoint[i].latitude();
    float X = waypoint[i].longitude();
    if (lonMax < X) lonMax = X;
    if (lonMin > X) lonMin = X;
    if (latMax < Y) latMax = Y;
    if (latMin > Y) latMin = Y;
  }
  print("lonMin=");
  print(lonMin);
  print(" lonMax=");
  println(lonMax);
  print("latMin=");
  print(latMin);
  print(" latMax=");
  println(latMax);
  
  // Now establish the mapping coordinates, four corners of rectangle described
  // by max and min values
  position = new GeoPosition[4];
  position[0] = new GeoPosition(latMin, lonMin);
  position[1] = new GeoPosition(latMin, lonMax);
  position[2] = new GeoPosition(latMax, lonMin);
  position[3] = new GeoPosition(latMax, lonMax);
  
  // Find the maximum X and Y distances in meters
  float Xdist = position[0].distance(position[1]);
  float Ydist = position[0].distance(position[2]);
  print("Xdist=");
  print(Xdist);  
  print("  Ydist=");
  print(Ydist);
  println();  
  // Figure out meters to pixels scale
  scaleMx = AR * (sizeX-padding) / Xdist;
  scaleMy = (sizeY-padding) / Ydist;
  // Now figure out the scaling from lat to meters to pixels and lon to meters to pixels
  scaleLon = AR * (sizeX-padding) / (lonMax - lonMin);
  scaleLat = (sizeY-padding) / (latMax - latMin);
  print("scaleMx=");
  print(scaleMx);
  print(" scaleMy=");
  print(scaleMy);
  println();
  print(" scaleLon=");
  print(scaleLon);
  print(" scaleLat=");
  print(scaleLat);
  println();
}

/** Scale longitude and translate to screen X pixels
 */
float lonToX(float lon)
{
  return scaleLon*(lon - lonMin) + float(padding)/2.0;
}


/** Scale latitude and translate to screen Y pixels
 */
float latToY(float lat)
{
  return sizeY - (scaleLat*(lat - latMin) + float(padding)/2.0);
}

