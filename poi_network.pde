import com.google.gson.reflect.*;
import com.google.gson.internal.*;
import com.google.gson.stream.*;
import com.google.gson.annotations.*;
import com.google.gson.internal.bind.*;
import com.google.gson.*;

import processing.opengl.*;

import codeanticode.glgraphics.*;
import java.util.Arrays;
import java.util.ArrayList;

import de.fhpotsdam.unfolding.mapdisplay.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.tiles.*;
import de.fhpotsdam.unfolding.interactions.*;
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.core.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.events.*;
import de.fhpotsdam.utils.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.Map;

import controlP5.*;

import org.json.*;

BufferedReader reader;

/****** COLORS *****/
color BACKCOLOR = #000000;
color SELECTCOLOR = #333333;
color LISTBACK = 0xffff0000;

/***** SIZES *****/
int w = 1500;
int h = 1000;
int marg = 170;
int checkRowSpace = 15;
int checkColSpace = 100;

/***** UI *****/
ControlP5 cp5;
CheckBox typeCheckBox;
ListBox cityList;
ListBox categoryList;

/**** INIT MEMORY *****/
int NUMPOI = 5000;
Poi[] POIS = new Poi[NUMPOI];
ArrayList selected = new ArrayList();
Network net = new Network();

String cityname = "";
String category = "";
int rad = 1000;

HashMap types = new HashMap();
String URLBASE = "http://a.media.mit.edu:8020/webservice/";

/***** CITY DATA ****/
Map map;
//String City = "New_york"; float LONMAX = -73.5974; float LONMIN = -74.3444; float LATMAX = 41.08763; float LATMIN = 40.48455;
String City = "Boston"; float LONMAX = -70.82199; float LONMIN = -71.28753; float LATMAX = 42.53790; float LATMIN = 42.18579;
//String City = "San_Francisco"; float LONMAX = -122.110290; float LONMIN = -122.552490; float LATMAX = 37.976680; float LATMIN = 37.55328;
//String City = "Rwanda"; float LONMAX = 31.0034; float LONMIN = 28.8116; float LATMAX = -0.9283; float LATMIN = -2.8442;
//String City = "Dominican_Republic"; float LONMAX = -68.2525; float LONMIN = -71.9769; float LATMAX =  20.08172; float LATMIN = 17.71729;

/***** PROGRAM ****/
void setup() {
  size(w, h, GLConstants.GLGRAPHICS);
  smooth();
  background(BACKCOLOR);

  map = new Map(this, marg, 0, w, h, new OpenStreetMap.CloudmadeProvider(MapDisplayFactory.OSM_API_KEY, 48569));
  MapUtils.createDefaultEventDispatcher(this, map);
  map.zoomToLevel(3);
  setupUI();
}

void draw() 
{ 
  background(BACKCOLOR);
  map.draw(); // Draw the open street map

  // Display only those POIs which are selected to be drawn.
  if (net.edges != null) { drawNetwork(); }
}

// Zoom in and out when the key is pressed
void keyPressed()
{
  if (key == 'q')
  {
    save(cityname+".jpg");
    exit();
  }
  else if (key == 'c')
  {
    Iterator iter = types.keySet().iterator();
    while (iter.hasNext ())
    {
      types.put(iter.next().toString(), color(random(255), random(255), random(255)));
    }
    for ( Poi p : POIS ) { 
      p.updateColor();
    }
  } 
}

void drawTypes()
{
  Set keys = types.keySet(); 
  Iterator iter = keys.iterator(); 

  while (iter.hasNext ())
  { 
    String name = iter.next().toString(); 
    println(name);
  }
}

void setupUI()
{
  cp5 = new ControlP5(this);
                    
  cityList = cp5.addListBox("City")
         .setPosition(10, 30)
         .setSize(150, 320)
         .setItemHeight(15)
         .setBarHeight(15)
         .setColorBackground(LISTBACK)
         .setColorActive(color(255, 128))
         ;
  
  categoryList = cp5.addListBox("Category")
         .setPosition(10, 380)
         .setSize(150, 320)
         .setItemHeight(15)
         .setBarHeight(15)
         .setColorBackground(LISTBACK)
         .setColorActive(color(255, 128))
         ;
         
  String url = URLBASE + "cum_dens.php";
  Gson gson = new Gson();
  InputLists lists = gson.fromJson(join(loadStrings(url), ""), InputLists.class); 
  
  for(int i=0; i < lists.cities.length; i++)
  {
    ListBoxItem lbi = cityList.addItem(lists.cities[i],i);
    lbi.setColorBackground(LISTBACK);  
  }
  
  for(int i=0; i < lists.categories.length; i++)
  {
    ListBoxItem lbi = categoryList.addItem(lists.categories[i],i);
    lbi.setColorBackground(LISTBACK);  
  }
      
  cp5.addSlider("Distance")
     .setPosition(10,720)
     .setSize(150,20)
     .setRange(0,5000)
     .setValue(rad)
     .setColorBackground(LISTBACK)
     .setColorForeground(#FFFFFF)
     .setColorActive(#FFFFFF)
     ;
  
  cp5.getController("Distance")
    .getValueLabel()
    .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE)
    .setPaddingX(0)
    ;
  cp5.getController("Distance")
    .getCaptionLabel()
    .align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
    .setPaddingX(0)
    ;
     
     
  cp5.addButton("Calculate")
    .setPosition(10, 770)
    .setSize(50, 20)
    .setColorBackground(LISTBACK)
    ;
}

void controlEvent(ControlEvent theEvent) 
{
 if(theEvent.isGroup() && theEvent.name().equals("City"))
 {  
    cityList.setColorBackground(LISTBACK);
    int ind = (int)theEvent.group().value();
    cityList.getItem(ind).setColorBackground(SELECTCOLOR);
    cityname = cityList.getItem(ind).getName();
 }
 
 if(theEvent.isGroup() && theEvent.name().equals("Category"))
 {  
    categoryList.setColorBackground(LISTBACK);
    int ind = (int)theEvent.group().value();
    categoryList.getItem(ind).setColorBackground(SELECTCOLOR);
    category = categoryList.getItem(ind).getName();
 }
}

void Calculate(int theValue){
  requestPOI();
}

void Distance( float value) {
  rad =  (int) value;
}

void requestPOI()
{
  String url = URLBASE + "network.php?city=" + cityname + "&radius="+rad+"&category="+category;
  Gson gson = new Gson();
  net = gson.fromJson(join(loadStrings(url), ""), Network.class);
  if (net.edges != null){map.zoomAndPanTo(new Location(net.edges[0][0],net.edges[0][1]),11);}
  println("Loaded.");
}


void drawNetwork(){
  // Draw All the Edges
  
  for(int i=0; i < net.edges.length; i++)
    {
    Location loc1 = new Location(net.edges[i][0], net.edges[i][1]);
    Location loc2 = new Location(net.edges[i][2], net.edges[i][3]);
    float[] latlon1  = map.getScreenPositionFromLocation(loc1);
    float[] latlon2  = map.getScreenPositionFromLocation(loc2);
    stroke(#FF0000);
    line(latlon1[0], latlon1[1], latlon2[0], latlon2[1]);
    }
    
 // Draw all the singletons
 for(int i=0; i < net.singletons.length; i+=2){
   Location loc = new Location(net.singletons[i], net.singletons[i+1]);
   float[] latlon = map.getScreenPositionFromLocation(loc);
   fill(#00FF00);
   noStroke();
   ellipse(latlon[0],latlon[1], 3,3);
 }
}

class InputLists{
  String[] cities;
  String[] categories;
  
  InputLists(){}  
}


/******* OLD FUNCTIONS *******/

void loadPOIData() {
  String Ln;
  reader = createReader("../data/"+ cityname +".dat");
  int n = 0;
  try {
    while ( reader.ready () ) {
      Ln = reader.readLine();
      String[] ln = split(Ln, ';');

      if (n > 1000) { 
        break;
      }

      if (n%10000 == 0) { 
        println(n);
      }

      try {
        JSONObject poi = new JSONObject(ln[1]);
        //println(poi.getJSONObject("geometry").getJSONObject("location").getDouble("lng"));

        float lat = (float) poi.getJSONObject("geometry").getJSONObject("location").getDouble("lat");
        float lon = (float) poi.getJSONObject("geometry").getJSONObject("location").getDouble("lng");
        JSONArray temp = poi.getJSONArray("types");

        String[] type = new String[temp.length()] ;
        for ( int t=0; t<temp.length(); t++) {
          type[t] = (String) temp.get(t);
          if (!types.containsKey(type[t])) {
            types.put(type[t], color(random(255), random(255), random(255)));
          }
        }

        Poi p = new Poi( n, lat, lon, type);
        POIS[n] = p;

        n += 1;
      } 
      catch (JSONException e) { 
        println ("There was an error parsing a POI.");
      }
    }
  } 
  catch (IOException e) {
    e.printStackTrace();
  }
  POIS = (Poi[]) subset(POIS, 0, n);
  NUMPOI = n;
}

