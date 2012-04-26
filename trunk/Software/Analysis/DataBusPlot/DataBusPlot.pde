// Graphically replay log files from DataBus, my 2012 AVC robot to show position, distance and bearing
// to next waypoint.
//
// Reads in a file waypoints.csv with each line as a waypoint in form 
//   lat,lon
//
// Reads in log file data.csv with fields 
//   millis,estlat,estlon,nextwaypoint,bearing,distance,heading
//

float x = 0.0;        // Current x-coordinate
float y = 0.0;        // Current y-coordinate
float x0 = 0.0;
float y0 = 0.0;
int index;
String[] lines;
String[] pieces;
GeoPosition[] waypoint;
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
  Xw = new float[lines.length];
  Yw = new float[lines.length];
  pieces = split(lines[0], ',');
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
  for (int i=1; i < Xw.length; i++) {
    if (wpt == i) {
      fill(red);
    } else {
      fill(blue);
    }
    ellipse(Xw[i],Yw[i],10,10);
  }
  if (index < lines.length) {
    pieces = split(lines[index], ',');
    wpt = int(pieces[3]);
    x = convertX(pieces[2]);
    y = convertY(pieces[1]);
    float brg = float(pieces[4]);
    float x1 = x + 100*sin(radians(brg));
    float y1 = y + 100*cos(radians(brg));
    h = float(pieces[6]);
    stroke(255);     // Set line drawing color to white
    line(x, y, x1, y1);
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
  rotate(radians(-h+90));
  rectMode(CENTER);
  rect(0, 0, 20, 5);
  popMatrix();
}


void mapping() 
{
  // find the waypoint that's furthest from wpt[0]
  float max = -1.0;
  for (int i=1; i < Xw.length; i++) {
    float d = distance(Yw[0],Xw[0],Yw[i],Xw[i]);
    println(d);
    if (d > max) {
      max = d;
      print("\t");
      println(d);
    }
  }
  println(max);
}


float distance(float fromLat, float fromLon, float toLat, float toLon)
{
  float lat1 = radians(fromLat);
  float lon1 = radians(fromLon);
  float lat2 = radians(toLat);
  float lon2 = radians(toLon);
  float dLat = lat2 - lat1;
  float dLon = lon2 - lon1;
  
  float a = sin(dLat/2.0) * sin(dLat/2.0) + 
             cos(lat1) * cos(lat2) *
             sin(dLon/2.0) * sin(dLon/2.0);
  float c = 2.0 * atan2(sqrt(a), sqrt(1-a));
  
  return 6371000.0 * c;
}
