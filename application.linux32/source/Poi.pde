class Poi {
  int id;
  float lat;
  float lon; 
  String[] type;
  Location loc;
  Integer clr;
  
  Poi (int i, float la, float lo, String[] ty){
    id = i;
    lat = la;
    lon = lo;
    type = ty;
    loc = new Location(lat, lon);
    clr = (Integer) types.get( type[0] );
  }

  void display() {
    float latlon[] = map.getScreenPositionFromLocation(loc);
    if (onScreen(latlon)) {
      if (map.getZoomLevel() < 14.0) {
        stroke(clr);
        point(latlon[0], latlon[1]);
      } 
      else {
        ellipse(latlon[0], latlon[1], 5, 5);
        fill(clr);
        noStroke();
      }
    }
  }

  boolean onScreen(float latlon[]) {
    boolean on = false;
    if ((latlon[0] < width) & (latlon[0] > 0) & (latlon[1] < height-marg) & (latlon[1] > 0)) {
      on = true;
    }

    return on;
  }
  
  boolean selectedType(){
    boolean slctd = false;
    for(int i=0; i < this.type.length; i++){
      if (typeCheckBox.getState(this.type[i])){ 
        slctd = true; 
      }
    }
    return slctd;
  }
  
  void updateColor(){
    this.clr = (Integer) types.get( this.type[0] );  
  }
  
}

