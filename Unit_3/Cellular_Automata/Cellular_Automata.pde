/* PARAMETERS */
String dataFile = "dataset1.json";
int numCols = 20; // Set to the "columns" property in the data file. Cannot be set automatically due to the limits of Processing.
int numRows = 4;

float framerate = 60;

int outlineWeight = 4;
int cellWidth = 60;
int cellHeight = 60;
boolean showText = true;
boolean coloredFill = false;

float trainingRate = 10;
/* END OF PARAMETERS */

JSONObject dataObject;
JSONArray data;
int dataSize;
Cell[][] cells;
int iterationRow, phase;
DummyCell dummyCell;

void settings() {
  int windowWidth = numCols * cellWidth;
  int windowHeight = numRows * cellHeight;
  size(windowWidth, windowHeight);
  noSmooth(); // Turn off antialiasing, to make borders look nicer (because everything is vertical/horizontal).
}

void setup() {
  // Drawing settings
  frameRate(framerate);
  colorMode(RGB, 1.0, 1.0, 1.0);
  strokeWeight(outlineWeight);
  textFont(createFont("Consolas", 11));

  dataObject = loadJSONObject(dataFile);
  data = dataObject.getJSONArray("data");
  dataSize = data.size();

  // Initialize variables
  cells = new Cell[numRows][numCols];
  dummyCell = new DummyCell(); // Initialize singleton DummyCell
  iterationRow = 0;
  phase = 1;

  initializeCells();
  updateStimuli();
}

void draw() {
  updateCells();
  drawCells();
}

void keyPressed() {
  if (key == 'f' || key == 'F') {
    frameRate(120);
  }
  else if (key == 's' || key == 'S') {
    frameRate(2);
  }
}

void updateCells() {
  if (iterationRow == 0)
    updateStimuli();
  else if (iterationRow < numRows)
    updateNeurons(iterationRow);
  else // iterationRow == numRow
    updateNodeDeltas();

  if (phase == 1) {
    iterationRow++;
    if (iterationRow == numRows) {
      phase = 2;
    }
  }
  else { // phase == 2
    iterationRow--;
    if (iterationRow == 0) {
      phase = 1;
    }
  }
}

void initializeCells() {
  int row = 0;

  // Initialize top row of stimuli Cells
  for (int col = 0; col < numCols; col++) {
    cells[row][col] = new Cell();
  }

  // Initialize Neurons
  for (row = 1; row < numRows-1; row++) {
    for (int col = 0; col < numCols; col++) {
      cells[row][col] = new Neuron();
    }
  }

  // Initialize bottom row of OutputNeurons
  for (int col = 0; col < numCols; col++) {
    cells[row][col] = new OutputNeuron();
  }
}

void updateStimuli() {
  int i = int(random(dataSize));
  JSONObject dataItem = data.getJSONObject(i);
  JSONArray inputs = dataItem.getJSONArray("input");
  JSONArray outputs = dataItem.getJSONArray("output");

  // Initialize stimuli (in row 0)
  for (int col = 0; col < numCols; col++) {
    float input = inputs.getFloat(col);
    float output = outputs.getFloat(col);
    cells[0][col].setActivation(input);

    OutputNeuron outputNeuron = (OutputNeuron) cells[numRows-1][col];
    outputNeuron.setTarget(output); // Temporarily using input as target output >:)
  }
}

void updateNeurons(int row) {
  for (int col = 0; col < numCols; col++) {
    Neuron cell = (Neuron) cells[row][col];
    Cell[] parents = getAdjacent(row - 1, col);
    if (phase == 1) // Phase 1: Forward propagation
      cell.forward(parents);
    else // Phase 2: Backpropagation
      cell.backpropagate(parents);
  }
}

void updateNodeDeltas() {
  int row = numRows - 1;
  for (int col = 0; col < numCols; col++) {
    OutputNeuron cell = (OutputNeuron) cells[row][col];
    cell.updateNodeDelta();
  }
  for (row = numRows-2; row > 1; row--) {
    for (int col = 0; col < numCols; col++) {
      Cell[] children = getAdjacent(row + 1, col);
      Neuron cell = (Neuron) cells[row][col];
      cell.updateNodeDelta(children);
    }
  }
}

Cell[] getAdjacent(int row, int col) {
  /**
   * Call on (row - 1, col) to get "parents". Call on (row+1, col) to get "children".
   * "Wraps around".
   */

  Cell[] adjacent = new Cell[3];

  try {
    adjacent[0] = cells[row][col-1];
  }
  catch (ArrayIndexOutOfBoundsException e) {
    adjacent[0] = cells[row][numCols-1];
  }

  adjacent[1] = cells[row][col];

  try {
    adjacent[2] = cells[row][col+1];
  }
  catch (ArrayIndexOutOfBoundsException e) {
    adjacent[2] = cells[row][0];
  }

  return adjacent;
}

void drawCells() {
  background(0);
  for (int row = 0; row < numRows; row++) {
    for (int col = 0; col < numCols; col++) {
      Cell cell = cells[row][col];

      float x = col * cellWidth + outlineWeight / 2;
      float y = row * cellHeight + outlineWeight / 2;

      color strokeColor = cell.getStrokeColor();
      color fillColor;
      if (coloredFill)
        fillColor = cell.getFillColor();
      else
        fillColor = color(cell.getActivation());
      stroke(strokeColor);
      fill(fillColor);

      rect(x, y, cellWidth - outlineWeight, cellHeight - outlineWeight);

      if (showText) {
        fill(round(1 - brightness(fillColor))); // Pick either black or white, for maximum contrast

        String a  = " A:" + nfs(cell.getActivation(), 1, 2);
        text(a,  x + outlineWeight, y + 10 + outlineWeight);
        if (row > 0) {
          String r0 = "R0:" + nfs(cell.getResponse(0), 1, 2);
          String r1 = "R1:" + nfs(cell.getResponse(1), 1, 2);
          String r2 = "R2:" + nfs(cell.getResponse(2), 1, 2);
          text(r0, x + outlineWeight, y + 20 + outlineWeight);
          text(r1, x + outlineWeight, y + 30 + outlineWeight);
          text(r2, x + outlineWeight, y + 40 + outlineWeight);
        }
      }
    }
  }
}
