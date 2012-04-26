// Graphically replay log files from DataBus, my 2012 AVC robot to show position, distance and bearing
// to next waypoint.
//
// Reads in a file waypoints.csv with each line as a waypoint in form 
//   lat,lon
//
// Reads in log file data.csv with fields 
//   millis,estlat,estlon,nextwaypoint,bearing,distance,heading
//

float Scale = 10.0;  // overall scale
float x = 0.0;        // Current x-coordinate
float y = 0.0;        // Current y-coordinate
float x0 = 0.0;
float y0 = 0.0;
int index;
String[] lines;
String[] pieces;
GeoPosition[] waypoint;
GeoPosition[] position;
float [] distance;
float scaleX;
float scaleY;
float Xw[];
float Yw[];
float h;
int wpt = 1;
color red = color(255,0,0);
color green = color(0,255,0);
color blue = color(0,0,255);
color yellow = color(240,240,0);

float convertX(String x)
{
  return (float(x) - x0)*1000000.0;
}

float convertY(String y)
{
  return (float(y) - y0)*1000000.0;
}

void setup() 
{
  size(640, 640);
  background(0);
  noStroke();
  smooth();
  lines = loadStrings("waypoints.csv");
  waypoint = new GeoPosition[lines.length];
  Xw = new float[lines.length];
  Yw = new float[lines.length];
  pieces = split(lines[0], ',');

  for (int i=0; i < lines.length; i++) {
    pieces = split(lines[i], ',');
    waypoint[i] = new GeoPosition(pieces[0], pieces[1]);
  }
  
  x0 = float(pieces[1]);
  y0 = float(pieces[0]);
  for (int i=1; i < lines.length; i++) {
    pieces = split(lines[i], ',');
    Xw[i] = convertX(pieces[1]);
    Yw[i] = convertY(pieces[0]);
  }
  lines = loadStrings("data.csv");
  mapping();
  index = 2;
}

void draw() 
{
  fill(0, 10);
  rectMode(CORNER);
  rect(0, 0, width, height);
  translate(320,320);
  rotate(radians(-90));
  for (int i=0; i < waypoint.length; i++) {
    if (wpt == i) {
      fill(red);
    } else {
      fill(blue);
    }
    float x = maptransX( waypoint[i].longitude() );
    float y = maptransY( waypoint[i].latitude() );
    ellipse(x,y,10,10);
  }
  if (index < lines.length) {
    pieces = split(lines[index], ',');
    wpt = int(pieces[3]);
    // convert from lat/lon to x and y
    x = maptransX( float(pieces[2]) );
    y = maptransY( float(pieces[1]) );
    float brg = float(pieces[4]);
    float dist = float(pieces[5]);
    float x1 = cos(radians(brg-90));
    float y1 = sin(radians(brg-90));
    h = float(pieces[6]);
    stroke(255);     // Set line drawing color to white
    if (dist < 5) {
      line(x, y, x+Scale*5*x1, y+Scale*5*y1);
    } else {
      line(x, y, x+Scale*dist*x1, y+Scale*dist*y1);
    }
    // Draw distance target
    fill(green, 20);
    ellipse(x+Scale*dist*x1, y+Scale*dist*y1, 20, 20);
    // Go to the next line for the next run through draw()
    index = index + 1;
  }
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
  // find the waypoint that's furthest from wpt[0]
  float max = -1.0;
  int j = -1;;
  for (int i=1; i < waypoint.length; i++) {
    float d = waypoint[0].distance(waypoint[i]);
    if (d > max) {
       max = d;
       j = i;
    }
  }
  
  if (j > 0) {
    // Now establish the mapping coordinates, four corners of rectangle described
    // by position[0] and position[3]
    position = new GeoPosition[4];
    position[0] = new GeoPosition(waypoint[0]);
    position[1] = new GeoPosition(waypoint[0].latitude(), waypoint[j].longitude());
    position[2] = new GeoPosition(waypoint[j].latitude(), waypoint[0].longitude());
    position[3] = new GeoPosition(waypoint[j]);
    // Now establish the distances along each edge of the rectangle
    distance = new float[2];
    distance[0] = position[0].distance(position[1]);
    distance[1] = position[0].distance(position[2]);
    // Now figure out the scaling from lat to meters and lon to meters
    scaleX = Scale * distance[0] / (waypoint[j].longitude() - waypoint[0].longitude());
    scaleY = Scale * distance[1] / (waypoint[j].latitude() - waypoint[0].latitude());;
  }
}

float maptransX(float lon)
{
  return scaleX * (lon - position[0].longitude());
}


float maptransY(float lat)
{
  return scaleY * (lat - position[0].latitude());
}

