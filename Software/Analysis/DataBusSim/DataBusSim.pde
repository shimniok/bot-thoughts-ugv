// Graphically replay log files from DataBus, my 2012 AVC robot to show position, distance and bearing
// to next waypoint.
//
// Reads in a file waypoints.csv with each line as a waypoint in form 
//   lat,lon
//
// Reads in log file data.csv with fields 
//   millis,estlat,estlon,nextwaypoint,bearing,distance,headingf
//

// simulation variables
float turnGain = 0.08;
float intercept=0.15;
float speed=3;
float lim=8; // curvature limit
float slop=5; // curvature slop
float bias=1; // curvature bias
float hdgErr=0; // initial heading error

// Pure Pursuit variables
float u;
float lookAhead = 60;
int segPrev;
int segNext;

float minDist = 5;    // minimum size of distance line
int padding = 200;    // pixel padding around waypoints at edges
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
float brg;            // vehicle bearing to next waypoint
float distNext;           // distance to next waypoint
float hdgRate;        // heading rate of change
float hdg;            // vehicle heading
// speed, m/s
int index;
String[] lines;
String[] pieces;
float Xw[];
float Yw[];
int prev = 0;        // previous waypoint
int next = 1;         // next waypoint
color red = color(255,0,0);
color green = color(0,255,0);
color blue = color(0,0,255);
color yellow = color(240,240,0);

void setup() 
{
  Xw = new float[4];
  Yw = new float[4];

  Xw[0] = 0; Yw[0] = 20;
  Xw[1] = -20; Yw[1] = 400-20;
  Xw[2] = 600+20; Yw[2] = 400;
  Xw[3] = 600; Yw[3] = -20;

  // initialize next, x, y, brg, dist, h
  segPrev = prev = 0;
  segNext = next = 1;
  x = Xw[0];
  y = Yw[0];
  hdg = bearing(x, y, Xw[0], Yw[0]) + hdgErr; // add initial heading error
  print("h0=");
  println(hdg);

  size(sizeX,sizeY);
  background(0);
  noStroke();
  smooth();
}

void draw() 
{
  // Path fadeout
  fill(0, 5);
  rectMode(CORNER);
  rect(0, 0, width, height);
  // Draw waypoints
  //translate(-lonMin, -latMin);
  //translate(padding, sizeY/2+padding);
  drawWaypoints();
  // PLAYBACK
  // if (index < lines.length) {
    // pieces = split(lines[index], ',');
    // next = int(pieces[3]);
    // convert from lat/lon to x and y
    // x = lonToX( float(pieces[2]) );
    // y = latToY( float(pieces[1]) );
    // calculate bearing and distance
    // float brg = float(pieces[4]);
    // float dist = float(pieces[5]);
    // hdg= float(pieces[6]);
    // Go to the next line for the next run through draw()
    // index = index + 1;
  // } 
  
  // SIMULATION
  // calculate next, x, y, brg, dist, h
  x += speed * sin(radians(hdg));
  y += speed * cos(radians(hdg));
  hdg += hdgRate;
  if (hdg >= 360.0)
    hdg -= 360.0;
  if (hdg < 0)
    hdg += 360.0;

  brg = bearing(x, y, Xw[next], Yw[next]);
  distNext = distance(x, y, Xw[next], Yw[next]);

  drawBearing(x, y, brg, distNext);
  // draw the car with the specified heading
  drawCar(x, y, hdg);

  /////////////////////////////////
  // Steering control
  /////////////////////////////////


//  float c = purePursuit(x, y, hdg, prev, next);
  float c = dumbPursuit(x, y, hdg, next);
 
  print(" curvature=");
  print(c);
  println();
  
  // simulate sloppy steering with bias (misalignment)
  if (c > -slop && c < slop)
    c = bias;
  
  // Simulate limited turning radius (would be based on lateral g)
  if (c > lim) c = lim;
  if (c < -lim) c = -lim;

  // Compute hdgRate from SA and speed
  hdgRate = speed * c / radians(360);
  
  // Navigation calculations
  if (distNext < lookAhead) {
    prev = next;
    next++;
    if (next >= Xw.length) next = 0;
    // calculate new line parameters
  }
}

float purePursuit(float x, float y, float hdg, int prev, int next)
{
  ////////////////////////////////////////////////////////////
  // Pure Pursuit
  ////////////////////////////////////////////////////////////
  // Previous waypoint coordinates
  float Ax = Xw[prev];
  float Ay = Yw[prev];
  // Robot coordinates
  float Bx = x;
  // Next waypoint coordinates
  float By = y;
  float Cx = Xw[next];
  float Cy = Yw[next];
  // Compute rise for prev wpt to bot; or compute vector offset by A(x,y)
  float Rx = (Bx - Ax);
  // compute run for prev wpt to bot; or compute vector offset by A(x,y)
  float Ry = (By - Ay);
  // dx is the run for the path
  float dx = Cx - Ax;
  // dy is the rise for the path
  float dy = Cy - Ay;
  // this is hypoteneuse length squared
  float ACd2 = dx*dx+dy*dy;
  // length of hyptoenuse
  float ACd = sqrt( ACd2 );
  
  float Rd = Rx*dx + Ry*dy;  
  float t = Rd / ACd2;
  // nearest point on current segment
  float Nx = Ax + dx*t; 
  float Ny = Ay + dy*t;  
  // Cross track error
  float NBx = Nx-Bx;
  float NBy = Ny-By;
  float cte = sqrt(NBx*NBx + NBy*NBy);
  drawGoal(Nx, Ny);
  print(" cte=");
  print(cte);
  
  // Pure pursuit derives down to r = l**2 / 2x in bot frame
  // We know (rather, define) l, the lookahead distance. We
  // don't know G(x,y) yet but can find it. 
  // We just solved for cross track error and a triangle is
  // formed by the vertices of the robot, the goal point, G,
  // and the closest point to the robot, N, which we just found.
  // If we find the length of the segment NG, we can then find
  // G itself easily. It's just distance NG along NG from N
  float NGd = sqrt( lookAhead*lookAhead - cte*cte );
  print(" NGd=");
  print(NGd);
  print(" L=");
  print(lookAhead);
  float Gx = NGd * dx/ACd + Nx;
  float Gy = NGd * dy/ACd + Ny;
  
  drawGoal(Gx, Gy);
 
  float BGx = (Gx-Bx)*cos(radians(hdg)) - (Gy-By)*sin(radians(hdg));
  float c = (2 * BGx) / lookAhead*lookAhead;

  return c;
}


float dumbPursuit(float x, float y, float hdg, int next)
{

  float brg = bearing(x, y, Xw[next], Yw[next]);
  float distNext = distance(x, y, Xw[next], Yw[next]);

  // would be nice to add in some noise to heading info
  float relBrg = brg-hdg;
  if (relBrg < -180.0) 
    relBrg += 360.0;
  if (relBrg >= 180.0)
    relBrg -= 360.0;
  //print("relBrg=");
  //print(relBrg);
  
  // steering angle <- relBrg, lookahead distance
  // turn radius <- steering angle & understeer factor, 
  // heading rate <- turn radius & speed

  /*
  // STEERING BASED ONLY ON RELATIVE BEARING
  hdgRate = relBrg * turnGain;
  print("  hdgRate");
  println(hdgRate);
  */
  
  // STEERING BASED ON RELATIVE BEARING & LOOKAHEAD DISTANCE
  float theta = relBrg;
  
  // I haven't had time to work out why the equation is slightly offset such
  // that negative angle produces slightly less steering angle
  //
  float sign;
  if (relBrg < 0)
    sign = -1;
  else
    sign = 1;
     
  // The equation peaks out at 90* so clamp theta artifically to 90, so that
  // if theta is actually > 90, we select max steering
  if (theta > 90.0) theta = 90.0;

  // Compute radius based on intercept distance and specified angle    
  float radius = sign * intercept/(2*sin(radians(abs(theta))));
  float limit=10.0;
  // limit radius as specified
  if (radius > limit)  radius =  limit;
  if (radius < -limit) radius = -limit;

   drawBearing(x, y, brg, distNext);
   
  //print("  radius=");
  //print(radius);

  // Now calculate steering angle based on wheelbase and track width
  //float SA = degrees(asin(wheelbase / (radius - track/2)));
  //if (relBrg < 0) SA *= -1.0;

  return 1/radius;
}


void drawWaypoints()
{
  pushMatrix();
  translate(padding/2.0,-padding/2.0);
  stroke(255);
  for (int i=0; i < Xw.length; i++) {
    if (next == i) {
      fill(red);
    } else {
      fill(blue);
    }
    ellipse(Xw[i],sizeY-Yw[i],10,10);
  }
  popMatrix();
}


void drawGoal(float Gx, float Gy)
{
  pushMatrix();
  translate(Gx+padding/2.0,-(Gy+padding/2.0));
  stroke(255);     // Set line drawing color to white
  fill(green, 20);
  ellipse(0, sizeY, 10, 10);
  popMatrix();
}


void drawBearing(float x, float y, float brg, float dist)
{
  pushMatrix();
  translate(x+padding/2.0,-(y+padding/2.0));
  // calculate ratios for plotting target and bearing indicators
  float x1 = sin(radians(brg));
  float y1 = cos(radians(brg));
  if (dist < minDist) {
    x1 *= minDist;
    y1 *= minDist;
  } else {
    x1 *= dist;
    y1 *= dist;
  }
  // determine vehicle heading
  stroke(255);     // Set line drawing color to white
  line(0,sizeY-0,x1,sizeY-y1);
  // draw bearing indicator at least minDist in length
  // Draw distance target
  fill(green, 20);
  ellipse(x1, sizeY-y1, 20, 20);
  popMatrix();
}

void drawCar(float x, float y, float h)
{
  pushMatrix();
  translate(x+padding/2.0,sizeY-(y+padding/2.0));
  rotate(radians(h+90));
  stroke(255);
  fill(yellow);
  rectMode(CENTER);
  stroke(255);
  rect(0, 0, 30, 10);
  stroke(62,227,247);
  line(0, 0, -lookAhead, 0);
  popMatrix();
}


float bearing(float x, float y, float x1, float y1)
{
  return degrees( atan2(x1-x,y1-y) );
}

float distance(float x, float y, float x1, float y1)
{
  return sqrt( pow(y1-y,2) + pow(x1-x,2) );
}


float getSlope(float x1, float y1, float x2, float y2)
{
  float slope;
  
  print(" y2-y1=");
  print(y2-y1);
  print(" x2-x1=");
  print(x2-x1);
  
  if (x2 == x1) {
    
  }
  
  return (y2-y1)/(x2-x1);
}

float getIntercept(float x, float y, float m)
{
  float b=y-m*x;
  print(" b=");
  println(b);
  return b;
}

float getDist(float x1, float y1, float x2, float y2)
{
  return 0.0;
}
