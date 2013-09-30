public class flatlanderThread extends Thread {

  private boolean running;          
  private int wait;  
  public PGraphics myBuffer, tempBuf;
  private PApplet parent;
  private Blob[] blobsArray;
  private OpenCV opencv;
  private PImage myTemp;
  private BufferedImage bI;
  
  public flatlanderThread (PApplet pa, int wt) {
    parent = pa;
    wait = wt;
    blobsArray = null;
    myBuffer = createGraphics(widthCapture, heightCapture, JAVA2D);
    tempBuf = createGraphics(widthCapture, heightCapture, JAVA2D);
    running = false;
    opencv = new OpenCV(pa);
  }

  public void start() {
    running = true;
    opencv.allocate(widthCapture, heightCapture);
    super.start();
  }

  public void run() {
    while (running) {
      updateThings();
      try {
        System.gc();
        sleep((long)(wait));
      }
      catch (Exception e) {
      }
    }
  }
  
  public void setBuffer(PGraphics b){
    myTemp = b.get();
  }
    
  public void updateThings() {
    myBuffer.beginDraw();
    if (cam.available()) {
      myBuffer.background(0);
      myBuffer.noFill();
      myBuffer.strokeWeight(0.5);
      myBuffer.stroke(255);
      cam.read();
      PImage temp = cam.get();
      opencv.copy(temp);
      opencv.blur(7);
      opencv.threshold(.8);
      //        blobsArray = opencv.blobs(opencv.area()/256, opencv.area()/2, 50, false, 2000, false);
      blobsArray = opencv.blobs(20, widthCapture/2*heightCapture/2, 200, true, 5000, false);
      for (int i = 0; i < blobsArray.length ; i++) {
        myBuffer.beginShape();
        for (int j = 0 ; j < blobsArray[i].points.length ; j++) {
          myBuffer.vertex(blobsArray[i].points[j].x, blobsArray[i].points[j].y);
        }
        myBuffer.endShape(CLOSE);
      }
      temp = null;
      blobsArray = null;
    }
    myBuffer.endDraw();
    setTempBuffer(myBuffer);
  }
  
  public void setTempBuffer(PGraphics pg){
    tempBuf.beginDraw();
    tempBuf.image(pg,0,0);
    tempBuf.endDraw();
  }
  
  public PGraphics getTempBuffer(){
    return tempBuf;
  }

  public void quit()
  {
    running = false;   
    interrupt(); 
    try {
      sleep(100l);
    } 
    catch (Exception e) {
    }
  }
}

