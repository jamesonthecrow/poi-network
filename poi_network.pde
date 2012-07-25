import processing.opengl.*;
import java.util.Arrays;
import java.util.ArrayList;

import codeanticode.glgraphics.*;

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

import org.json.*;

import controlP5.*;

BufferedReader reader;

/****** COLORS *****/
color BACKCOLOR = #000000;

/***** SIZES *****/
int w = 1500;
int h = 1000;
int marg = 200;
int checkRowSpace = 15;
int checkColSpace = 100;

/***** UI *****/
ControlP5 cp5;
CheckBox typeCheckBox;

/**** INIT MEMORY *****/
int NUMPOI = 500000;
Poi[] POIS = new Poi[NUMPOI];
ArrayList selected = new ArrayList();

HashMap types = new HashMap();

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
  
  map = new Map(this, 0,0, w, h-marg, new OpenStreetMap.CloudmadeProvider(MapDisplayFactory.OSM_API_KEY, 48569));
  
  //map.zoomAndPanTo(new Location(38.7286f,-9.173584f),5); //Lisbon
  //map.zoomAndPanTo(new Location(41.149968,-8.610243),10);
  MapUtils.createDefaultEventDispatcher(this, map);

  loadPOIData();
  map.zoomAndPanTo(new Location(POIS[0].lat, POIS[0].lon),10);
  
  setupUI();
}

void draw() {
  background(BACKCOLOR);
  map.draw();
  for (int i=0 ; i < selected.size(); i++) {
    POIS[(Integer)selected.get(i)].display();
  }

  
}

void loadPOIData() {
  String Ln;
  reader = createReader("../data/"+ City+".dat");
  int n = 0;
  try {
    while ( reader.ready () ) {
      Ln = reader.readLine();
      String[] ln = split(Ln, ';');

      //if (n > 1000) { break;}
      
      if (n%10000 == 0){ println(n);}

      try {
        JSONObject poi = new JSONObject(ln[1]);
        //println(poi.getJSONObject("geometry").getJSONObject("location").getDouble("lng"));

        float lat = (float) poi.getJSONObject("geometry").getJSONObject("location").getDouble("lat");
        float lon = (float) poi.getJSONObject("geometry").getJSONObject("location").getDouble("lng");
        JSONArray temp = poi.getJSONArray("types");
        
        String[] type = new String[temp.length()] ;
        for( int t=0; t<temp.length(); t++){
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


// Zoom in and out when the key is pressed
void keyPressed() {
  if (key == 'q'){
    save(City+".jpg");
    exit(); 
  }
  else if (key == 'c'){
    println("FUCKKKK");
    Iterator iter = types.keySet().iterator();
    while (iter.hasNext()){
      types.put(iter.next().toString(), color(random(255),random(255),random(255)));
    }
    for( Poi p : POIS ){ p.updateColor(); }  
  }
}

void drawTypes(){
  Set keys = types.keySet(); 
  Iterator iter = keys.iterator(); 
  
  while(iter.hasNext()){ 
    String name = iter.next().toString(); 
    println(name);
  }
}

void setupUI(){
  cp5 = new ControlP5(this);
  typeCheckBox = cp5.addCheckBox("typeCheckBox")
                .setPosition(10,height-marg+10)
                .setColorForeground(color(120))
                .setColorActive(color(255))
                .setColorLabel(color(255))
                .setSize(10, 10)
                .setItemsPerRow(width/checkColSpace-1)
                .setSpacingColumn(checkColSpace)
                .setSpacingRow(checkRowSpace)
                ;
  Object[] keys = types.keySet().toArray(); 
  Arrays.sort(keys);
  for( Object l : keys){
    String k = (String)l;
    typeCheckBox.addItem(k, 0);
    typeCheckBox.deactivate(k);
  }
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(typeCheckBox)) {
    selected.clear();
    for(int i=0; i<NUMPOI;i++){
      if (POIS[i].selectedType()) {
         selected.add(i); 
      }
    }
  }
}


